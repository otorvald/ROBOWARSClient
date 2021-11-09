//
//  RobotProtocol.swift
//  RobowarsClient
//
//  Created by Maksym Bystryk on 04.10.2021.
//

import UIKit

enum ShootingResult {
    case killed
    case damaged
    case missed
}

/*If you want to take a part in Robowars Tournament, you need to implement your own Robot.
 Robot should conform to this protocol and provide shooting positions on Client Application requests.
 Internaly your Robot may have its own model of battle field, use complicated algorithms or just shoot randomly.
 It's completely up to you. But in any case you have to implement all the methods and properties required by this protocol.
 
 CGRect, CGPoint and CGSize uses CGFloat for calculations. It makes possible to deal with float point numbers, but don't use such numbers! Use only integer values (in CGFloat format of course) for positions of ships etc., because client will be convert Floats to Integers anyway.
 
 Show your imagination and GOOD LUCK IN ROBOWARS =) */

protocol RobotProtocol {
    //Robot's name
    var name: String { get }
    
    //This message will be printed on the start of the duel
    var greetingMessage: String { get }
    
    //This message will be printed in case of your Robot win
    var winMessage: String { get }
    
    //This message will be printed in case of your Robot lose
    var loseMessage: String { get }
    
    /*This method will be called on duel start, and your Robot will be informed about field rect.
     By default Robowars rect has 20x20 points with origin 0.0.
     But try not to get attach to this restrictions and implement flexible robots that are able to work with any field rect. (Optionaly)*/
    func defineFieldRect(_ rect: CGRect)
    
    /*Informs your Robot about required amount of ships
     By default it's 5 ships, but try not to get attached to this value*/
    func defineShipsCount(_ count: Int)
    
    /*Informs your Robot about ship size. All the ships should correspond to this size (or sizes).
     All the ships are simple CGRects. It can't have any difficult shape.
     By defaults it's 2X3 points or 3X2, but try not to get attached to this value.*/
    func definePossibleShipSizes(_ size: [CGSize])
    
    /*Ships on their positions should be provided here.
     This method is called after the previous ones, so you at this point your Robot should be able to provide the ships according to all requirement. Each ship - it's just a rect with unique origin but the same size that is provided by the previous method.
     IMPORTANT: Ships can't be attached to each other. Between two ships should be at least one point on each side.
     All the ships, that do not correspond this and aforementioned requirements, will be disqualified (not added on the battlefield).*/
    func getShips() -> [CGRect]
    
    /*Robot's current enemy shoots on this position. Your robot can handle if needed, or just igrore it.
     General game state is handled on the client side anyway. */
    func enemyDidShoot(at: CGPoint)
    
    /*Here your Robot should provide the position for the next shoot. This position should be calculated on your side.
     Client calls this method when it's your turn to shoot. You can't ignore this!*/
    func getNextShootingPosition() -> CGPoint
    
    /**After getting shooting position client will return
     shooting result using this method.
     You can keep records about all your shoots to make your robot more effective.*/
    func didHandleShoot(in position: CGPoint, with result: ShootingResult)
    
    /*Is called when game is finished. You can ignore this.*/
    func gameOver()
}
