//
//  GameManager.swift
//  RobowarsClient
//
//  Created by Max Bystryk on 11.10.2021.
///

import UIKit

enum FieldSide {
    case right
    case left
}

enum GameState {
    case notReady
    case ready
    case inProgress
    case finished
    case paused
}

protocol GameManagerDelegate: AnyObject {
    func placeShips(withRects rects: [CGRect], onField field: FieldSide)
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool)
    func updateParticipantMessage(_ message: String, for side: FieldSide)
    func updateParticipantName(_ name: String, for side: FieldSide)
    func gameStateDidChange(to state: GameState)
}

class Participant {
    let robot: RobotProtocol
    let side: FieldSide
    let ships: [Ship]
    var aliveShips: [Ship] { ships.filter{ !$0.isKilled } }
    
    init(robot: RobotProtocol, side: FieldSide, ships: [Ship]) {
        self.robot = robot
        self.side = side
        self.ships = ships
    }
}

class GameManager {
    private let helper = GameManagerHelper()
    private(set) var isGameInProgrees = false
    private(set) var leftRobots: [RobotProtocol]
    private(set) var rightRobots: [RobotProtocol]
    private(set) var currentLeftParticipant: Participant?
    private(set) var currentRightParticipant: Participant?
    
    private(set) var shootingParticipant: Participant?
    private(set) var receiverParticipant: Participant?
    
    //MARK: - Game configuration
    private(set) var fieldRect = CGRect(x: 0, y: 0, width: 20, height: 20)
    private(set) var shipsCount = 6
    private(set) var shipSizes = [CGSize(width: 2, height: 3), CGSize(width: 3, height: 2)]
    
    private weak var gamingTimer: Timer?
    private var moveCount = 0
    private(set) var currentState: GameState = .notReady {
        didSet {
            delegate?.gameStateDidChange(to: currentState)
        }
    }
    
    private var selectedLeftRobotIndex: Int?
    private var selectedRightRobotIndex: Int?
    
    weak var delegate: GameManagerDelegate?
    
    init() {
        func createParticipants() -> [RobotProtocol] {
            return [PrimitiveRobot(), ArtificialTeapot(), ArtificialСalculator()]
        }
        
        leftRobots = createParticipants()
        rightRobots = createParticipants()
    }
    
    func startGame() {
        guard let _ = currentLeftParticipant,
              let _ = currentRightParticipant else { return }
        let randFlag = (Int.random(in: 0...1) % 2 == 0)
        shootingParticipant = randFlag ? currentLeftParticipant : currentRightParticipant
        receiverParticipant = randFlag ? currentRightParticipant : currentLeftParticipant
        gamingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        currentState = .inProgress
    }
    
    func pauseGame() {
        gamingTimer?.invalidate()
        currentState = .paused
    }
    
    func resumeGame() {
        gamingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        currentState = .inProgress
    }
    
    func stopGame() {
        gamingTimer?.invalidate()
        currentState = .finished
    }
    
    func resetGame() {
        guard let left = selectedLeftRobotIndex, let right = selectedRightRobotIndex else { return }
        setLeftParticipant(index: left)
        setRightParticipant(index: right)
        currentState = .ready
    }
    
    func setLeftParticipant(index: Int) {
        guard index < leftRobots.count else { return }
        helper.updateRules(fieldRect: fieldRect, shipsCount: shipsCount, shipSizes: shipSizes)
        let robot = leftRobots[index]
        selectedLeftRobotIndex = index
        informAboutRules(robot: robot)
        let side: FieldSide = .left
        let ships = loadShips(for: robot, onField: side)
        currentLeftParticipant = Participant(robot: robot, side: side, ships: ships)
        delegate?.updateParticipantMessage(robot.greetingMessage, for: .left)
        delegate?.updateParticipantName(robot.name, for: .left)
        updateToReadyStateIfNeeded()
    }
    
    func setRightParticipant(index: Int) {
        guard index < rightRobots.count else { return }
        helper.updateRules(fieldRect: fieldRect, shipsCount: shipsCount, shipSizes: shipSizes)
        let robot = rightRobots[index]
        selectedRightRobotIndex = index
        informAboutRules(robot: robot)
        let side: FieldSide = .right
        let ships = loadShips(for: robot, onField: side)
        currentRightParticipant = Participant(robot: robot, side: side, ships: ships)
        delegate?.updateParticipantMessage(robot.greetingMessage, for: .right)
        delegate?.updateParticipantName(robot.name, for: .right)
        updateToReadyStateIfNeeded()
    }
    
    @objc private func fireTimer() {
        guard let shootingParticipant = shootingParticipant,
              let receiverParticipant = receiverParticipant else { return }

        moveCount += 1

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
        
        //If there is a winner
        if receiverParticipant.aliveShips.isEmpty {
            showRobotsFinalMessages()
            shootingParticipant.robot.gameOver()
            receiverParticipant.robot.gameOver()
            stopGame()
        }
        
        DispatchQueue.main.async {
            self.delegate?.placeShoot(at: position, onField: fieldToShoot, isHit: result != .missed)
        }
        
        if result == .missed || result == .reHit { swapShooterAndReceiver() }
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
        robot.defineFieldRect(fieldRect)
        robot.defineShipsCount(shipsCount)
        robot.definePossibleShipSizes(shipSizes)
    }
    
    private func loadShips(for robot: RobotProtocol, onField field: FieldSide) -> [Ship] {
        var shipRects = robot.getShips()
        while(helper.validateShips(shipRects) != true) { //TODO: ban participant in case incorrect placement
            shipRects = robot.getShips()
        }
        delegate?.placeShips(withRects: shipRects, onField: field)
        return shipRects.map{ Ship(frame: $0) }
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

class GameManagerHelper {
    private var fieldRect: CGRect = .zero
    private var shipsCount: Int = 0
    private var shipSizes: [CGSize] = []
    func updateRules(fieldRect: CGRect, shipsCount: Int, shipSizes: [CGSize]) {
        self.fieldRect = fieldRect
        self.shipsCount = shipsCount
        self.shipSizes = shipSizes
    }
    
    func validateShootingPosition(_ point: CGPoint) -> Bool {
        return fieldRect.contains(point)
    }
    
    func validateShips(_ ships: [CGRect]) -> Bool {
        guard ships.count == shipsCount else {
            print("incorrect ships count")
            return false
        }
        var deadZones = [CGRect]()
        for ship in ships {
            guard shipSizes.contains(ship.size) else {
                print("incorrect ships size")
                return false
            }
            guard ship.minX.isLess(than: 0) == false,
                    ship.minY.isLess(than: 0) == false,
                    ship.maxX.isLessThanOrEqualTo(fieldRect.maxX),
                    ship.maxY.isLessThanOrEqualTo(fieldRect.maxY) else {
                print("incorrect coordinates size")
                return false
            }
            for deadZone in deadZones {
                guard deadZone.intersects(ship) == false else {
                    print("ships is too close")
                    return false
                }
            }
            deadZones.append(CGRect(x: ship.minX - 1, y: ship.minY - 1, width: ship.width + 2, height: ship.height + 2))
        }
        return true
    }
}
