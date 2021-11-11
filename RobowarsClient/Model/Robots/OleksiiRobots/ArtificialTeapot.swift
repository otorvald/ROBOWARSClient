//
//  ArtificialTeapot.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 02.11.2021.
//

import UIKit

enum ArtificialTeapotHitResults: Int {
    case zero = 0
    case hit = 1
    case miss = 2
}

class ArtificialTeapot {
    private typealias Helper = ArtificialHelper
    
    //MARK: - Robot Protocol Properties
    var name: String { "Teapot" }
    var greetingMessage: String { "Praise for the great coincidence" }
    var winMessage: String { "Lucky me" }
    var loseMessage: String { "Next time I will be more lucky" }
    
    //MARK: - Private Properties
    private var fieldRect: CGRect = .zero
    private var shipsCount: Int = 0
    private var possibleShipSizes: [CGSize] = []
    private var enemyFieldResults: [[Int]] = []

    // MARK: - Private Methods
    private func calculateShootingPosition() -> CGPoint {
        var position = Helper.randomShootingPosition(fieldRect)
        while(validatePositionForHit(position) == false) {
            position = Helper.randomShootingPosition(fieldRect)
        }
        return position
    }
    
    private func validatePositionForHit(_ position: CGPoint) -> Bool {
        let x = Int(round(position.x))
        let y = Int(round(position.y))
        return enemyFieldResults[y][x] == 0
    }
    
    private func resetEnemyField() {
        enemyFieldResults.removeAll()
        let width = Int(round(fieldRect.width))
        let height = Int(round(fieldRect.height))
        var rows = [[Int]]()
        for _ in 0..<height {
            var row = [Int]()
            for _ in 0..<width {
                row.append(ArtificialTeapotHitResults.zero.rawValue)
            }
            rows.append(row)
        }
        enemyFieldResults = rows
    }
}

// MARK: - RobotProtocol
extension ArtificialTeapot: RobotProtocol {
    func defineFieldRect(_ rect: CGRect) { fieldRect = rect }
    
    func defineShipsCount(_ count: Int) { shipsCount = count }
    
    func definePossibleShipSizes(_ sizes: [CGSize]) { possibleShipSizes = sizes }
    
    func getShips() -> [CGRect] {
        resetEnemyField()
        return Helper.randomShipsFor(fieldRect, sizes: possibleShipSizes, shipsCount: shipsCount)
    }
    
    func enemyDidShoot(at: CGPoint) {}
    
    func getNextShootingPosition() -> CGPoint {
        return calculateShootingPosition()
    }
    
    func didHandleShoot(in position: CGPoint, with result: ShootingResult) {
        let x = Int(round(position.x))
        let y = Int(round(position.y))
        enemyFieldResults[y][x] = result.hitResults.rawValue
    }
    
    func gameOver() {}
}

fileprivate extension ShootingResult {
    var hitResults: ArtificialTeapotHitResults {
        switch self {
        case .missed, .reHit: return .miss
        case .damaged, .killed: return .hit
        }
    }
}
