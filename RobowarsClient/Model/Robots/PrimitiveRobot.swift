//
//  PrimitiveRobot.swift
//  RobowarsClient
//
//  Created by Max Bystryk on 12.10.2021.
//

import UIKit

//ONLY FOR EXAMPLE! YOU SHOULD IMPLEMENT YOUR OWN ROBOT
class PrimitiveRobot: RobotProtocol {
    //MARK: - Robot Protocol Properties
    let name = "Vedro Dyravoe"
    let greetingMessage: String = "I don't have idea what i'm doing"
    let winMessage: String = "Whaaaat??"
    let loseMessage: String = "Okay("
    
    //MARK: - Private Properties
    var fieldRect: CGRect?
    var shipsCount: Int?
    var possibleShipSizes: [CGSize]?
    
    var myShips: [CGSize]?
    
    func defineFieldRect(_ rect: CGRect) {
        self.fieldRect = rect
    }
    
    func defineShipsCount(_ count: Int) {
        self.shipsCount = count
    }
    
    func definePossibleShipSizes(_ sizes: [CGSize]) {
        self.possibleShipSizes = sizes
    }
    
    func getShips() -> [CGRect] {
        return plaсeShips()
    }
    
    func enemyDidShoot(at: CGPoint) {
        print("I don't care about enemy's shoot=)")
    }
    
    func getNextShootingPosition() -> CGPoint {
        return calculateShootingPosition()
    }
    
    func didHandleShoot(in position: CGPoint, with result: ShootingResult) {
        print("I don't care about my shooting result=)")
    }
    
    func gameOver() {
        
    }
    
    private func calculateShootingPosition() -> CGPoint {
        guard let fieldRect = fieldRect else { return CGPoint(x: 0, y: 0) }
        
        return CGPoint(x: Int.random(in: 0...Int(fieldRect.maxX-1)),
                       y: Int.random(in: 0...Int(fieldRect.maxY-1)))
    }
    
    private func plaсeShips() -> [CGRect] {
        guard let shipsCount = shipsCount,
                let sizes = possibleShipSizes,
                let field = fieldRect else { return [] }
        return ArtificialHelper.randomShipsFor(field, sizes: sizes, shipsCount: shipsCount)
    }
}
