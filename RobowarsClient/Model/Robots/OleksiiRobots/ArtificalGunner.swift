//
//  ArtificalGunner.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 10.11.2021.
//

import UIKit

class ArtificalGunner {
    //MARK: - Robot Protocol Properties
    let name = "Mafioso"
    let greetingMessage = "No one will ever kill me, they wouldn’t dare"
    let winMessage = "See you in hell!"
    let loseMessage = "I’m only going out for a few minutes"
    
    //MARK: - Private Properties
    private var fieldRect: CGRect = .zero
    private var shipsCount: Int = 0
    private var possibleShipSizes: [CGSize] = []
    private var godfather: Godfather = Godfather()
}

extension ArtificalGunner: RobotProtocol {
    func defineFieldRect(_ rect: CGRect) { fieldRect = rect }
    func defineShipsCount(_ count: Int) { shipsCount = count }
    func definePossibleShipSizes(_ sizes: [CGSize]) { possibleShipSizes = sizes }
    func enemyDidShoot(at: CGPoint) {}
    func getNextShootingPosition() -> CGPoint {
        return godfather.showMeTheTarget()
    }
    func gameOver() {}
    func getShips() -> [CGRect] {
        godfather = Godfather.moveToNewCity(map: fieldRect, competitorSizes: possibleShipSizes, competitors: shipsCount)
        return godfather.prepareAnAmbush()
    }
    
    func didHandleShoot(in position: CGPoint, with result: ShootingResult) {
        godfather.analyseTheSituation(in: position, with: result)
    }
}

fileprivate class Godfather {
    private typealias Helper = ArtificialHelper
    
    // MARK: - Private Properties
    private let map: CGRect
    private let competitorSizes: [CGSize]
    private let competitors: Int
    let cityState: CityState
    private var enemy: EnemyFighter?
    private var lastSmokePosition: CGPoint?
    private let smokeInterval: CGSize

    // MARK: - Initialisers
    init(map: CGRect = .zero, competitorSizes: [CGSize] = [], competitors: Int = 0) {
        self.map = map
        self.competitorSizes = competitorSizes
        self.competitors = competitors
        cityState = CityState(map)
        smokeInterval = Self.smokeIntervalFor(competitorSizes)
    }
    
    static func moveToNewCity(map: CGRect, competitorSizes: [CGSize], competitors: Int) -> Godfather {
        return Godfather(map: map, competitorSizes: competitorSizes, competitors: competitors)
    }
    
    private static func smokeIntervalFor(_ competitorSizes: [CGSize]) -> CGSize {
        var minWidth = competitorSizes.first?.width ?? 1
        var minHeight = competitorSizes.first?.height ?? 1
        competitorSizes.forEach{
            minWidth = min(minWidth, $0.width)
            minHeight = min(minHeight, $0.height)
        }
        return CGSize(width: max(1, minWidth), height: max(1, minHeight))
    }

    // MARK: - Public Methods
    func prepareAnAmbush() -> [CGRect] {
        return Helper.randomShipsFor(map, sizes: competitorSizes, shipsCount: competitors)
    }
    
    func analyseTheSituation(in position: CGPoint, with result: ShootingResult) {
        cityState.placeShoot(in: position, with: result)
        guard result != .missed else { return }
        if enemy == nil { enemy = EnemyFighter() }
        enemy?.addHit(in: position)
        if result == .killed { onEnemyKilled() }
    }
    
    func showMeTheTarget() -> CGPoint {
        guard let enemy = enemy,
              enemy.hits.isEmpty == false else {
            self.enemy = nil
            return smokeThemUp()
        }
        return shootingPositionFor(enemy)
    }
    
    // MARK: - Private Methods
    private func onEnemyKilled() {
        guard let enemy = enemy else { return }
        cityState.markDeadShip(at: enemy.hits)
        self.enemy = nil
    }
    
    private func smokeThemUp() -> CGPoint {
        guard let lastSmokePosition = lastSmokePosition else {
            let position = CGPoint(x: map.minX + smokeInterval.width - 1, y: map.minY + smokeInterval.height - 1)
            lastSmokePosition = position
            return position
        }
        let position = nextSmokePosition(for: lastSmokePosition)
        self.lastSmokePosition = position
        return position
    }
    
    private func nextSmokePosition(for position: CGPoint) -> CGPoint {
        var newX = position.x + smokeInterval.width
        var newY = position.y
        if newX >= map.maxX {
            newX = map.minX + smokeInterval.width - 1
            newY = position.y + smokeInterval.height
        }
        let newPosition = CGPoint(x: newX, y: newY)
        if validatePositionForHit(newPosition) {
            return newPosition
        }
        return nextSmokePosition(for: newPosition)
    }
    
    private func validatePositionForHit(_ position: CGPoint) -> Bool {
        return cityState.isEmptyPosition(position)
    }
    
    private func shootingPositionFor(_ enemy: EnemyFighter) -> CGPoint {
        let possibleShipSizes = possibleEnemySizesFor(enemy)
        for size in possibleShipSizes {
            if let location = possibleEnemyLocationFor(enemy, size: size) {
                return shootingPositionFor(location: location)
            }
        }
        self.enemy = nil
        return smokeThemUp()
    }
    
    private func possibleEnemySizesFor(_ enemy: EnemyFighter) -> [CGSize] {
        guard let frame = enemy.possibleFrame else { return competitorSizes }
        return competitorSizes.filter{ frame.width <= $0.width && frame.height <= $0.height }
    }
     
    private func possibleEnemyLocationFor(_ enemy: EnemyFighter, size: CGSize) -> CGRect? {
        guard var frame = enemy.possibleFrame else { return nil }
        let mixX = Int(round(frame.minX))
        let minY = Int(round(frame.minY))
        let dx = Int(round(size.width - frame.width))
        let dy = Int(round(size.height - frame.height))
        frame.size = size
        for x in 0...dx {
            for y in 0...dy {
                frame.origin.x = CGFloat(mixX - x)
                frame.origin.y = CGFloat(minY - y)
                if cityState.canFitGroupAt(frame) {
                    return frame
                }
            }
        }
        return nil
    }
    
    private func shootingPositionFor(location: CGRect) -> CGPoint {
        guard let position = cityState.emptyPositionFor(location) else {
            self.enemy = nil
            return smokeThemUp()
        }
        return position
    }
}

fileprivate enum CityFlat: Int {
    case empty = 0
    case missed = 1
    case hit = 2
    case killed = 3
    case police = 4
    init(_ rawValue: Int) {
        switch rawValue {
        case 1: self = .missed
        case 2: self = .hit
        case 3: self = .killed
        case 4: self = .police
        default: self = .empty
        }
    }
}
 
extension CityFlat: CustomStringConvertible {
    var description: String {
        switch self {
        case .missed: return "*"
        case .hit: return "x"
        case .killed: return "X"
        case .police: return "o"
        case .empty: return "."
        }
    }
    
    var hasBody: Bool {
        switch self {
        case .missed, .police: return false
        default: return true
        }
    }
}

fileprivate class CityState {
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
            placePoliceAtBody(position)
        }
    }
    
    func isEmptyPosition(_ position: CGPoint) -> Bool {
        guard let state = stateAtPosition(position) else { return false }
        return state == CityFlat.empty.rawValue
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
    
    func canFitGroupAt(_ location: CGRect) -> Bool {
        let x = Int(round(location.minX))
        let y = Int(round(location.minY))
        let width = Int(round(location.width))
        let height = Int(round(location.height))
        for h in 0..<height {
            for w in 0..<width {
                let position = CGPoint(x: x + w, y: y + h)
                guard let state = stateAtPosition(position),
                      CityFlat(state).hasBody else { return false }
            }
        }
        return true
    }
    
    func printState() {
        print("fieldState:")
        for y in 0..<height{
            print(field[y].map{CityFlat($0).description}.joined(separator: " "))
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
    
    private func placePoliceAtBody(_ position: CGPoint) {
        let x = Int(round(position.x)) - x
        let y = Int(round(position.y)) - y
        guard field[y][x] == CityFlat.hit.rawValue else {
            return
        }
        field[y][x] = CityFlat.killed.rawValue
        func placePoliceAt(x: Int, y: Int) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            guard field[y][x] == CityFlat.empty.rawValue else { return }
            field[y][x] = CityFlat.police.rawValue
        }
        placePoliceAt(x: x-1, y: y-1)
        placePoliceAt(x: x, y: y-1)
        placePoliceAt(x: x+1, y: y-1)
        placePoliceAt(x: x-1, y: y)
        placePoliceAt(x: x, y: y)
        placePoliceAt(x: x+1, y: y)
        placePoliceAt(x: x-1, y: y+1)
        placePoliceAt(x: x, y: y+1)
        placePoliceAt(x: x+1, y: y+1)
    }
}

fileprivate extension ShootingResult {
    var fieldNum: Int { return self == .missed ? 1 : 2 }
}

fileprivate class EnemyFighter {
    private(set) var hits = [CGPoint]()
    
    func addHit(in position: CGPoint) {
        hits.append(position)
    }
    
    var possibleFrame: CGRect? {
        guard let firstHit = hits.first else { return nil }
        var minX = firstHit.x
        var maxX = firstHit.x
        var minY = firstHit.y
        var maxY = firstHit.y
        for hit in hits {
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
