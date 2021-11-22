//
//  RWTournamentResults.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 19.11.2021.
//

import Foundation

protocol RWTournamentAnalytics: AnyObject {
    func handleShoot(result: ShootingResult, side: FieldSide)
}

class RWTournamentResults {
    private(set) var gameResults = [RWTournamentGameResults]()
    private var currentGame: RWTournamentGameResults?
    
    var leftStats: String? { currentGame?.leftStats }
    var rightStats: String? { currentGame?.rightStats }
    
    func reset() {
        gameResults.removeAll()
    }
    
    func prepareGame(config: RWGameConfiguration) {
        currentGame = RWTournamentGameResults(config: config)
    }
    
    func onTournamentEnd() {
        
    }
    
    func didFinishGame(withWinner: FieldSide) {
        guard let currentGame = currentGame else { return }
        currentGame.didFinishGame(withWinner: withWinner)
        gameResults.append(currentGame)
    }
}

extension RWTournamentResults: RWTournamentAnalytics {
    func handleShoot(result: ShootingResult, side: FieldSide) {
        currentGame?.handleShoot(result: result, side: side)
    }
}

class RWTournamentGameResults {
    let config: RWGameConfiguration
    let leftRobot = RWTournamentRobotStats()
    let rightRobot = RWTournamentRobotStats()
    
    var leftStats: String { leftRobot.stats }
    var rightStats: String { rightRobot.stats }
    
    init(config: RWGameConfiguration) {
        self.config = config
    }
    
    func didFinishGame(withWinner: FieldSide) {
        leftRobot.didFinishGame(winner: withWinner == .left)
        rightRobot.didFinishGame(winner: withWinner == .right)
    }
}

extension RWTournamentGameResults: RWTournamentAnalytics {
    func handleShoot(result: ShootingResult, side: FieldSide) {
        switch side {
        case .left: rightRobot.handleShoot(result: result)
        case .right: leftRobot.handleShoot(result: result)
        }
    }
}

class RWTournamentRobotStats {
    private(set) var shootCount: Int = 0
    private(set) var hitCount: Int = 0
    private(set) var killCount: Int = 0
    private(set) var winner = false
    var accuracy: Int {
        guard shootCount > 0 else { return 1 }
        return (hitCount * 100) / shootCount
    }
    
    var stats: String { "s: \(shootCount) h: \(hitCount) k: \(killCount)" }
    
    func didFinishGame(winner: Bool) {
        self.winner = winner
    }
    
    func handleShoot(result: ShootingResult) {
        switch result {
        case .killed:
            killCount += 1
            fallthrough
        case .damaged:
            hitCount += 1
            fallthrough
        case .missed, .reHit:
            shootCount += 1
        }
    }
}
