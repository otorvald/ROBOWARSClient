//
//  RWTournamentViewController.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 19.11.2021.
//

import UIKit

struct RWGameConfiguration {
    let fieldRect: CGRect
    let shipsCount: Int
    let shipSizes: [CGSize]
}

extension RWGameConfiguration: CustomStringConvertible {
    var description: String {
        let sizes: String = "[\(shipSizes.map{ "\(Int($0.width))x\(Int($0.height))" }.joined(separator: ", "))]"
        return "field: \(Int(fieldRect.width))x\(Int(fieldRect.height)) ships: \(shipsCount), sizes: \(sizes)"
    }
}

extension RWGameConfiguration {
    static let huge = RWGameConfiguration(fieldRect: CGRect(x: 0, y: 0, width: 40, height: 40),
                                           shipsCount: 10,
                                           shipSizes: [CGSize(width: 6, height: 8), CGSize(width: 8, height: 6)])
    
    static let tall = RWGameConfiguration(fieldRect: CGRect(x: 0, y: 0, width: 30, height: 30),
                                          shipsCount: 30,
                                          shipSizes: [CGSize(width: 1, height: 8), CGSize(width: 8, height: 1)])
    
    static let fat = RWGameConfiguration(fieldRect: CGRect(x: 0, y: 0, width: 30, height: 30),
                                           shipsCount: 2,
                                           shipSizes: [CGSize(width: 10, height: 10)])
    
    static let normal = RWGameConfiguration(fieldRect: CGRect(x: 0, y: 0, width: 20, height: 20),
                                            shipsCount: 12,
                                            shipSizes: [CGSize(width: 3, height: 2), CGSize(width: 2, height: 3)])

    static let werd = RWGameConfiguration(fieldRect: CGRect(x: 0, y: 0, width: 20, height: 20),
                                           shipsCount: 1,
                                           shipSizes: [CGSize(width: 3, height: 5), CGSize(width: 5, height: 3)])
}

struct RWParticipant: RWTournamentParticipant {
    let robot: RobotProtocol
    var name: String { robot.name }
}

class RWTournamentViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!

    private let setupView: RWTournamentSetupView = .fromNib()
    private let battleView: RWTournamentBattleView = .fromNib()
    private let resultView: RWTournamentResultView = .fromNib()
    private let tournamentManager = RWTournamentManager()
    private var leftParticipant: RWParticipant?
    private var rightParticipant: RWParticipant?
    
    private let gameConfigTypes: [RWGameConfiguration] = [.huge, .tall, .fat, .normal, .werd]
    private let maxGameRounds: Int = 10
    private var selectedField: RWGameConfiguration?
    private var selectedGameRounds: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView.isHidden = true
        contentView.addSubview(setupView)
        setupView.fillSuperview()
        setupView.delegate = self
        
        contentView.addSubview(battleView)
        battleView.fillSuperview()
        battleView.delegate = self
        battleView.isHidden = true
        
        resultView.isHidden = true
        contentView.addSubview(resultView)
        resultView.fillSuperview()
        resultView.delegate = self
        
        tournamentManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showSetupView()
    }
    
    private func getParticipants() -> [RWParticipant] {
        [RWParticipant(robot: PrimitiveRobot()),
         RWParticipant(robot: ArtificialTeapot()),
         RWParticipant(robot: ArtificialСalculator()),
         RWParticipant(robot: ArtificalGunner())]
    }
    
    private func showSetupView() {
        battleView.isHidden = true
        resultView.isHidden = true
        setupView.setupData(leftParticipants: getParticipants(), rightParticipants: getParticipants())
        setupView.setupConfigs(fieldSizes: gameConfigTypes, maxGameCount: maxGameRounds)
        setupView.isHidden = false
        setupView.showStartButton(false)
        setupView.show { print( "setupView shown" ) }
    }
    
    private func showStartButtonIfReady() {
        if let _ = selectedField, let _ = selectedGameRounds, let _ = rightParticipant, let _ = leftParticipant {
            setupView.showStartButton(true)
        } else {
            setupView.showStartButton(false)
        }
    }
    
    private func startTournament() {
        guard let leftParticipant = leftParticipant,
              let rightParticipant = rightParticipant,
              let selectedField = selectedField,
              let selectedGameRounds = selectedGameRounds else { return }
        let games = [RWGameConfiguration].init(repeating: selectedField, count: selectedGameRounds)
        let configuration = RWTournamentConfiguration(games: games)
        showBattleView{
            self.tournamentManager
                .startTournament(configuration: configuration,
                                 leftParticipant: leftParticipant,
                                 rightParticipant: rightParticipant)
        }
    }
    
    private func showBattleView(completion: (() -> Void)?) {
        setupView.isHidden = true
        battleView.isHidden = false
        resultView.isHidden = true
        battleView.show(completion: completion)
    }
    
    private func showResultView() {
        setupView.isHidden = true
        battleView.isHidden = true
        resultView.isHidden = false
        resultView.updateWith(result: tournamentManager.tournamentResults.gameResults)
    }
}

extension RWTournamentViewController: RWTournamentSetupViewDelegate {
    func onLeftParticipantSelected(participant: RWTournamentParticipant) {
        if let participant = participant as? RWParticipant {
            leftParticipant = participant
        }
        showStartButtonIfReady()
    }
    
    func onRightParticipantSelected(participant: RWTournamentParticipant) {
        if let participant = participant as? RWParticipant {
            rightParticipant = participant
        }
        showStartButtonIfReady()
    }
    
    func onTournamentSetupStartButtonPressed() {
        setupView.hide { self.startTournament() }
    }
    
    func onGameFieldSelected(field: RWGameConfiguration) {
        selectedField = field
        showStartButtonIfReady()
    }
    
    func onMaxGameCountSelected(count: Int) {
        selectedGameRounds = count
        showStartButtonIfReady()
    }
}

extension RWTournamentViewController: RWTournamentManagerDelegate {
    func gameStartedWith(configuration: RWGameConfiguration) {
        battleView.setupEmptyFields(withSize: Int(configuration.fieldRect.size.width))
    }
    
    func placeShips(withRects rects: [CGRect], onField field: FieldSide) {
        battleView.placeShips(withRects: rects, onField: field)
    }
    
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool){
        battleView.placeShoot(at: point, onField: field, isHit: isHit)
        let (left, right) = tournamentManager.gameStats
        battleView.updateFooterMessages(left: left, right: right)
    }
    
    func updateParticipantMessage(_ message: String, for side: FieldSide){
        battleView.updateParticipantMessage(message, for: side)
    }
    
    func updateParticipantName(_ name: String, for side: FieldSide){
        battleView.updateParticipantName(name, for: side)
    }
    
    func didPlaceShipsForRobot(name: String){
        
    }
    
    func gameStateDidChange(to state: GameState) {
        switch state {
        case .notReady: break
        case .ready: battleView.updateFooter(buttonText: "Start", showSlider: true)
        case .inProgress: battleView.updateFooter(buttonText: "Pause", showSlider: false)
        case .finished: battleView.updateFooter(buttonText: "Continue", showSlider: true)
        case .paused: battleView.updateFooter(buttonText: "Resume", showSlider: true)
        }
    }
    
    func onTournamentEnd() {
        showResultView()
    }
}

extension RWTournamentViewController: RWTournamentBattleViewDelegate {
    func onFooterButtonPressed() {
        tournamentManager.onFooterButtonPressed(sliderValue: battleView.sliderValue)
    }
    
    func onResetButtonPressed() {
        tournamentManager.reset()
        showSetupView()
    }
}
 
extension RWTournamentViewController: RWTournamentResultViewDelegate {
    func onRestartButtonPressed() {
        tournamentManager.reset()
        showSetupView()
    }
}
