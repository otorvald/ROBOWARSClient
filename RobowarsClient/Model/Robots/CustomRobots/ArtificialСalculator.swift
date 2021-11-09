//
//  ArtificialСalculator.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 02.11.2021.
//

import UIKit

class ArtificialСalculator {
    //MARK: - Robot Protocol Properties
    var name: String { "Сalculator" }
    var greetingMessage: String? { "Artificial: Yes! intelligence: No!" }
    var winMessage: String? { "100% success" }
    var loseMessage: String? { "Impossible!!!" }
    
    //MARK: - Private Properties
    private var fieldRect: CGRect = .zero
    private var shipsCount: Int = 0
    private var possibleShipSizes: [CGSize] = []
    private var brain: ArtificialBrain?
}

extension ArtificialСalculator: RobotProtocol {
    func defineFieldRect(_ rect: CGRect) { fieldRect = rect }
    func defineShipsCount(_ count: Int) { shipsCount = count }
    func definePossibleShipSizes(_ sizes: [CGSize]) { possibleShipSizes = sizes }
    func enemyDidShoot(at: CGPoint) {}
    func getNextShootingPosition() -> CGPoint {
        guard let brain = brain else { fatalError("NO Brain!") }
        return brain.calculateShootingPosition()
    }
    func gameOver() { brain = nil }

    func getShips() -> [CGRect] { 
        let newBrain = ArtificialBrain.init(fieldRect: fieldRect, possibleShipSizes: possibleShipSizes, count: shipsCount)
        brain = newBrain
        return newBrain.getShips()
    }
    
    func didHandleShoot(in position: CGPoint, with result: ShootingResult) {
        guard let brain = brain else { fatalError("NO Brain!") }
        brain.didHandleShoot(in: position, with: result)
    }
}

fileprivate class ArtificialBrain {
    private typealias Helper = ArtificialHelper
    
    // MARK: - Private Properties
    private let field: CGRect
    private let shipSizes: [CGSize]
    private let shipsCount: Int
    let fieldState: FieldState
    private var enemyShip: ArtificialEnemyShip?

    // MARK: - Initialisers
    init(fieldRect: CGRect, possibleShipSizes: [CGSize], count: Int) {
        field = fieldRect
        shipSizes = possibleShipSizes
        shipsCount = count
        fieldState = FieldState(fieldRect)
    }

    // MARK: - Public Methods
    func getShips() -> [CGRect] {
        return Helper.randomShipsFor(field, sizes: shipSizes, shipsCount: shipsCount)
    }
    
    func didHandleShoot(in position: CGPoint, with result: ShootingResult) {
        fieldState.placeShoot(in: position, with: result)
        guard result != .missed else { return }
        if enemyShip == nil { enemyShip = ArtificialEnemyShip() }
        enemyShip?.addHit(in: position)
        if result == .killed { onShipKilled() }
    }
    
    func calculateShootingPosition() -> CGPoint {
        fieldState.printState()
        guard let enemyShip = enemyShip,
                enemyShip.successHits.isEmpty == false else {
            self.enemyShip = nil
            return randomShootingPosition()
        }
        return shootingPositionFor(enemyShip)
    }
    
    // MARK: - Private Methods
    private func onShipKilled() {
        guard let ship = enemyShip else { return }
        fieldState.markDeadShip(at: ship.successHits)
        print("onShipKilled")
        fieldState.printState()
        enemyShip = nil
    }
    
    private func randomShootingPosition() -> CGPoint {
        var position = Helper.randomShootingPosition(field)
        while(validatePositionForHit(position) == false) {
            position = Helper.randomShootingPosition(field)
        }
        return position
    }
    
    private func validatePositionForHit(_ position: CGPoint) -> Bool {
        return fieldState.isEmptyPosition(position)
    }
    
    private func shootingPositionFor(_ ship: ArtificialEnemyShip) -> CGPoint {
        let possibleShipSizes = possibleEnemyShipSizesFor(ship)
        for size in possibleShipSizes {
            if let location = possibleShipLocationFor(ship, size: size) {
                return shootingPositionFor(location: location)
            }
        }
        self.enemyShip = nil
        return randomShootingPosition()
    }
    
    private func possibleEnemyShipSizesFor(_ ship: ArtificialEnemyShip) -> [CGSize] {
        guard let frame = ship.possibleShipFrame else { return shipSizes }
        return shipSizes.filter{ frame.width <= $0.width && frame.height <= $0.height }
    }
     
    private func possibleShipLocationFor(_ ship: ArtificialEnemyShip, size: CGSize) -> CGRect? {
        guard var frame = ship.possibleShipFrame else { return nil }
        let mixX = Int(round(frame.minX))
        let minY = Int(round(frame.minY))
        let dx = Int(round(size.width - frame.width))
        let dy = Int(round(size.height - frame.height))
        frame.size = size
        for x in 0...dx {
            for y in 0...dy {
                frame.origin.x = CGFloat(mixX - x)
                frame.origin.y = CGFloat(minY - y)
                if fieldState.canFitShipAt(frame) {
                    return frame
                }
            }
        }
        return nil
    }
    
    private func shootingPositionFor(location: CGRect) -> CGPoint {
        guard let position = fieldState.emptyPositionFor(location) else {
            self.enemyShip = nil
            return randomShootingPosition()
        }
        return position
    }
}

fileprivate enum FieldCell: Int {
    case empty = 0
    case missed = 1
    case hit = 2
    case killed = 3
    case wrecks = 4
    init(_ rawValue: Int) {
        switch rawValue {
        case 1: self = .missed
        case 2: self = .hit
        case 3: self = .killed
        case 4: self = .wrecks
        default: self = .empty
        }
    }
}
 
extension FieldCell: CustomStringConvertible {
    var description: String {
        switch self {
        case .missed: return "*"
        case .hit: return "x"
        case .killed: return "X"
        case .wrecks: return "o"
        case .empty: return "."
        }
    }
    
    var canBeShip: Bool {
        switch self {
        case .missed, .wrecks: return false
        default: return true
        }
    }
}

fileprivate class FieldState {
    private let x: Int
    private let y: Int
    private let width: Int
    private let height: Int
    private var field = [[Int]]()
    
    init(_ rect: CGRect) {
        x = Int(round(rect.minX))
        y = Int(round(rect.minY))
        width = Int(round(rect.width))
        height = Int(round(rect.height))
        createEmptyField()
    }
    
    func placeShoot(in position: CGPoint, with result: ShootingResult) {
        let x = Int(round(position.x)) - x
        let y = Int(round(position.y)) - y
        guard x >= 0, x < width, y >= 0, y < height else { return }
        field[y][x] = result.fieldNum
    }
    
    func markDeadShip(at positions: [CGPoint]) {
        for position in positions {
            plaseShipWrecksAt(position)
        }
    }
    
    func isEmptyPosition(_ position: CGPoint) -> Bool {
        guard let state = stateAtPosition(position) else { return false }
        return state == FieldCell.empty.rawValue
    }
    
    func emptyPositionFor(_ location: CGRect) -> CGPoint? {
        let x = Int(round(location.minX))
        let y = Int(round(location.minY))
        let width = Int(round(location.width))
        let height = Int(round(location.height))
        for h in 0..<height {
            for w in 0..<width {
                let position = CGPoint(x: x + w, y: y + h)
                if isEmptyPosition(position) { return position }
            }
        }
        return nil
    }
    
    func canFitShipAt(_ location: CGRect) -> Bool {
        let x = Int(round(location.minX))
        let y = Int(round(location.minY))
        let width = Int(round(location.width))
        let height = Int(round(location.height))
        for h in 0..<height {
            for w in 0..<width {
                let position = CGPoint(x: x + w, y: y + h)
                guard let state = stateAtPosition(position),
                      FieldCell(state).canBeShip else { return false }
            }
        }
        return true
    }
    
    func printState() {
        print("fieldState:")
        for y in 0..<height{
            print(field[y].map{FieldCell($0).description}.joined(separator: " "))
        }
    }
    
    private func createEmptyField() {
        field = [[Int]](repeating: [Int](repeating: 0, count: height), count: width)
    }
    
    private func stateAtPosition(_ position: CGPoint) -> Int? {
        let x = Int(round(position.x)) - x
        let y = Int(round(position.y)) - y
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        return field[y][x]
    }
    
    private func plaseShipWrecksAt(_ position: CGPoint) {
        let x = Int(round(position.x)) - x
        let y = Int(round(position.y)) - y
        guard field[y][x] == FieldCell.hit.rawValue else {
            print("incorrect field state or position \(position)")
            printState()
            return
        }
        field[y][x] = FieldCell.killed.rawValue
        func placeWreckAt(x: Int, y: Int) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            guard field[y][x] == FieldCell.empty.rawValue else { return }
            field[y][x] = FieldCell.wrecks.rawValue
        }
        placeWreckAt(x: x-1, y: y-1)
        placeWreckAt(x: x, y: y-1)
        placeWreckAt(x: x+1, y: y-1)
        placeWreckAt(x: x-1, y: y)
        placeWreckAt(x: x, y: y)
        placeWreckAt(x: x+1, y: y)
        placeWreckAt(x: x-1, y: y+1)
        placeWreckAt(x: x, y: y+1)
        placeWreckAt(x: x+1, y: y+1)
    }
}

fileprivate extension ShootingResult {
    var fieldNum: Int { return self == .missed ? 1 : 2 }
}

fileprivate class ArtificialEnemyShip {
    private(set) var successHits = [CGPoint]()
    
    func addHit(in position: CGPoint) {
        successHits.append(position)
    }
    
    var possibleShipFrame: CGRect? {
        guard let firstHit = successHits.first else { return nil }
        var minX = firstHit.x
        var maxX = firstHit.x
        var minY = firstHit.y
        var maxY = firstHit.y
        for hit in successHits {
            minX = min(minX, hit.x)
            maxX = max(maxX, hit.x)
            minY = min(minY, hit.y)
            maxY = max(maxY, hit.y)
        }
        let width = maxX - minX + 1
        let height = maxY - minY + 1
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
}
