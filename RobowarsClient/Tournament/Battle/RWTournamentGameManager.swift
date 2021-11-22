//
//  RWTournamentGameManager.swift
//  RobowarsClient
//
//  Copy/paste and change GameManager.swift by Oleksiy Zhuk on 19.11.2021.
//

import UIKit

class RWTournamentGameManager {
    weak var delegate: GameManagerDelegate?
    var timeInterval: TimeInterval = 0.1
    private(set) var gameConfiguration: RWGameConfiguration = .huge
    
    weak var analytics: RWTournamentAnalytics?
    private var isGameInProgrees = false
    private var leftRobot: RobotProtocol?
    private var rightRobot: RobotProtocol?
    private var leftIsFirst: Bool = true
    private var currentLeftParticipant: Participant?
    private var currentRightParticipant: Participant?
    private var shootingParticipant: Participant?
    private var receiverParticipant: Participant?
    private let helper = GameManagerHelper()
    private weak var gamingTimer: Timer?
    private(set) var currentState: GameState = .notReady {
        didSet {
            delegate?.gameStateDidChange(to: currentState)
        }
    }
    
    func setup(leftRobot: RobotProtocol, rightRobot: RobotProtocol, configuration: RWGameConfiguration, leftIsFirst: Bool){
        self.leftRobot = leftRobot
        self.rightRobot = rightRobot
        self.gameConfiguration = configuration
        self.leftIsFirst = leftIsFirst
    }
    
    func prepareGame() {
        guard let leftRobot = leftRobot,
              let rightRobot = rightRobot else { return }
        performInitialSetup(for: leftRobot, on: .left)
        performInitialSetup(for: rightRobot, on: .right)
        shootingParticipant = leftIsFirst ? currentLeftParticipant : currentRightParticipant
        receiverParticipant = leftIsFirst ? currentRightParticipant : currentLeftParticipant
        currentState = .ready
    }
    
    func startGame() {
        guard currentState == .ready else { return }
        gamingTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        currentState = .inProgress
    }
    
    func pauseGame() {
        gamingTimer?.invalidate()
        currentState = .paused
    }
    
    func resumeGame() {
        gamingTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        currentState = .inProgress
    }
    
    func stopGame() {
        gamingTimer?.invalidate()
        currentState = .finished
    }
    
    func resetGame() {
        guard let leftRobot = leftRobot, let rightRobot = rightRobot else { return }
        performInitialSetup(for: leftRobot, on: .left)
        performInitialSetup(for: rightRobot, on: .right)
        currentState = .ready
    }
    
    @objc private func fireTimer() {
        guard let shootingParticipant = shootingParticipant,
              let receiverParticipant = receiverParticipant else { return }

        let fieldToShoot = receiverParticipant.side
        let position = shootingParticipant.robot.getNextShootingPosition()
        guard helper.validateShootingPosition(position) else {
            shootingParticipant.robot.didHandleShoot(in: position, with: .missed)
            swapShooterAndReceiver()
            return
        }
        receiverParticipant.robot.enemyDidShoot(at: position)
        var result = ShootingResult.missed
        
        for ship in receiverParticipant.ships {
            result = ship.handleShoot(in: position)
            if result == .missed { continue }
            break
        }
        
        shootingParticipant.robot.didHandleShoot(in: position, with: result)
        analytics?.handleShoot(result: result, side: fieldToShoot)
        
        //If there is a winner
        if receiverParticipant.aliveShips.isEmpty {
            showRobotsFinalMessages()
            shootingParticipant.robot.gameOver()
            receiverParticipant.robot.gameOver()
            stopGame()
            delegate?.didFinishGame(withWinner: shootingParticipant.robot.name, on: shootingParticipant.side)
        }
        
        DispatchQueue.main.async {
            self.delegate?.placeShoot(at: position, onField: fieldToShoot, isHit: result != .missed)
        }
        
        if result == .missed || result == .reHit { swapShooterAndReceiver() }
    }
    
    private func performInitialSetup(for robot: RobotProtocol, on side: FieldSide) {
        helper.updateRules(fieldRect: gameConfiguration.fieldRect,
                           shipsCount: gameConfiguration.shipsCount,
                           shipSizes: gameConfiguration.shipSizes)
        informAboutRules(robot: robot)
        let shipRects = robot.getShips()
        let ships = shipRects.map { Ship(frame: $0) }
        delegate?.placeShips(withRects: shipRects, onField: side)
        delegate?.updateParticipantMessage(robot.greetingMessage, for: side)
        delegate?.updateParticipantName(robot.name, for: side)
        if side == .right {
            currentRightParticipant = Participant(robot: robot, side: side, ships: ships)
        } else {
            currentLeftParticipant = Participant(robot: robot, side: side, ships: ships)
        }
        
        do {
            try helper.validateShips(shipRects)
            delegate?.didPlaceShipsForRobot(name: robot.name)
            updateToReadyStateIfNeeded()
        } catch {
            delegate?.shipPlacementDidFail(with: error as! ShipPlacementError, forRobotWithName: robot.name)
        }
    }
    
    private func updateToReadyStateIfNeeded() {
        guard let _ = currentLeftParticipant,
              let _ = currentRightParticipant,
              currentState != .ready else { return }
        
        currentState = .ready
    }
    
    private func swapShooterAndReceiver() {
        let receiver = receiverParticipant
        receiverParticipant = shootingParticipant
        shootingParticipant = receiver
    }
    
    private func informAboutRules(robot: RobotProtocol) {
        robot.defineFieldRect(gameConfiguration.fieldRect)
        robot.defineShipsCount(gameConfiguration.shipsCount)
        robot.definePossibleShipSizes(gameConfiguration.shipSizes)
    }
    
    private func showRobotsFinalMessages() {
        guard let shootingParticipant = shootingParticipant,
              let receiverParticipant = receiverParticipant else { return }
        let winnerMessage = shootingParticipant.robot.winMessage
        let looserMessage = receiverParticipant.robot.loseMessage
        let leftMessage = shootingParticipant.side == .left ? winnerMessage : looserMessage
        let rightMessage = receiverParticipant.side == .right ? looserMessage : winnerMessage
        delegate?.updateParticipantMessage(leftMessage, for: .left)
        delegate?.updateParticipantMessage(rightMessage, for: .right)
    }
}
