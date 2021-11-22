//
//  RWTournamentManager.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 19.11.2021.
//

import UIKit

struct RWTournamentConfiguration {
    let games: [RWGameConfiguration]
}

protocol RWTournamentManagerDelegate: AnyObject {
    func gameStartedWith(configuration: RWGameConfiguration)
    func placeShips(withRects rects: [CGRect], onField field: FieldSide)
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool)
    func updateParticipantMessage(_ message: String, for side: FieldSide)
    func updateParticipantName(_ name: String, for side: FieldSide)
    func didPlaceShipsForRobot(name: String)
    func gameStateDidChange(to state: GameState)
    func onTournamentEnd()
}

class RWTournamentManager {
    weak var delegate: RWTournamentManagerDelegate?
    private var configuration = RWTournamentConfiguration(games: [])
    private let gameManager = RWTournamentGameManager()
    let tournamentResults = RWTournamentResults()
    private var leftParticipant: RWParticipant!
    private var rightParticipant: RWParticipant!
    private var gameNum: Int = 0
    
    var gameStats: (String?, String?) { (tournamentResults.leftStats, tournamentResults.rightStats) }

    func startTournament(configuration: RWTournamentConfiguration, leftParticipant: RWParticipant, rightParticipant: RWParticipant) {
        self.configuration = configuration
        self.leftParticipant = leftParticipant
        self.rightParticipant = rightParticipant
        gameNum = 0
        tournamentResults.reset()
        gameManager.delegate = self
        prepareGame()
    }
    
    func reset() {
        gameManager.stopGame()
    }
    
    func onFooterButtonPressed(sliderValue: Float) {
        let gameSpeed = Int(sliderValue)
        gameManager.timeInterval = 1.0 / TimeInterval(1<<gameSpeed)
        switch gameManager.currentState {
        case .notReady: prepareGame()
        case .ready: startGame()
        case .inProgress: gameManager.pauseGame()
        case .finished: onGameEnded()
        case .paused: gameManager.resumeGame()
        }
    }
    
    private func prepareGame() {
        let config = configuration.games[gameNum]
        gameManager.setup(leftRobot: leftParticipant.robot,
                          rightRobot: rightParticipant.robot,
                          configuration: config,
                          leftIsFirst: gameNum % 2 == 0)
        delegate?.gameStartedWith(configuration: config)
        tournamentResults.prepareGame(config: config)
        gameManager.analytics = tournamentResults
        gameManager.prepareGame()
    }
    
    private func startGame() {
        gameManager.startGame()
    }
    
    private func onGameEnded () {
        gameNum += 1
        guard gameNum < configuration.games.count else {
            onTournamentEnd()
            return
        }
        prepareGame()
    }
    
    private func onTournamentEnd() {
        tournamentResults.onTournamentEnd()
        delegate?.onTournamentEnd()
    }
}

extension RWTournamentManager: GameManagerDelegate {
    func placeShips(withRects rects: [CGRect], onField field: FieldSide) {
        delegate?.placeShips(withRects: rects, onField: field)
    }
    
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool) {
        delegate?.placeShoot(at: point, onField: field, isHit: isHit)
    }
    
    func updateParticipantMessage(_ message: String, for side: FieldSide) {
        delegate?.updateParticipantMessage(message, for: side)
    }
    
    func updateParticipantName(_ name: String, for side: FieldSide) {
        delegate?.updateParticipantName(name, for: side)
    }
    
    func gameStateDidChange(to state: GameState) {
        delegate?.gameStateDidChange(to: state)
    }
    
    func shipPlacementDidFail(with error: ShipPlacementError, forRobotWithName name: String) {
        print( error.messageWith(robot: name) )
        gameManager.prepareGame()
    }
    
    func didPlaceShipsForRobot(name: String) {
        delegate?.didPlaceShipsForRobot(name: name)
    }
    
    func didFinishGame(withWinner winnerName: String, on side: FieldSide) {
        tournamentResults.didFinishGame(withWinner: side)
    }
}

extension ShipPlacementError {
    func messageWith(robot name: String) -> String {
        switch self {
        case .incorrectShipCount: return "Robot \(name) returns wrong amount of ships!"
        case .incorrectShipSize: return "Robot \(name) returns ships with incorrect size!"
        case .shipsIntersection: return "Robot \(name) returns ships that intersect each other or are connected!"
        case .shipsOutOfField: return "Robot \(name) returns ships with out of field positions!"
        }
    }
}
