//
//  ViewController.swift
//  RobowarsClient
//
//  Created by Maksym Bystryk on 04.10.2021.
//

import UIKit

enum StartButtonState {
    case start
    case stop
    case reset
    case disabled
}

fileprivate struct ViewConfig {
    static let participantSelectorWidth: CGFloat = 250
    static let participantSelectorLeadingSpace: CGFloat = 30
    static let participantSelectorAnimatingDuration: CGFloat = 0.33
    static let tableViewCellHeight: CGFloat = 40
}

class MainViewController: UIViewController {
    @IBOutlet weak var leftParticipantSelectorTableView: UITableView!
    @IBOutlet weak var rightParticipantSelectorTableView: UITableView!
    @IBOutlet weak var versulLabel: UILabel!
    @IBOutlet weak var leftFieldContentView: UIView!
    @IBOutlet weak var rightFieldContentView: UIView!
    @IBOutlet weak var mainInfoLabel: UILabel!
    @IBOutlet weak var leftRobotMessageLabel: UILabel!
    @IBOutlet weak var rightRobotMessageLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBOutlet weak var participantSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var participantSelectionLeadingSpaceConstraint: NSLayoutConstraint!
    
    let gameManager = GameManager()
    var rightFieldView: FieldView?
    var leftFieldView: FieldView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performInitialConfiguration()
        setupTableViews()
        gameManager.delegate = self
        
        updateStartStopButtonState(.disabled)
        pauseButton.isEnabled = false
    }
    
    private func performInitialConfiguration() {
        leftRobotMessageLabel.text = "***"
        rightRobotMessageLabel.text = "***"
        setupEmptyFields(withSize: 20)
    }
    
    private func setupEmptyFields(withSize squareSize: Int) {
        let rightFieldView = FieldView(squareSize: squareSize, frame: .zero)
        let leftFieldView = FieldView(squareSize: squareSize, frame: .zero)
        rightFieldContentView.addSubview(rightFieldView)
        leftFieldContentView.addSubview(leftFieldView)
        rightFieldView.fillSuperview()
        leftFieldView.fillSuperview()
        self.leftFieldView = leftFieldView
        self.rightFieldView = rightFieldView
    }
    
    func showParticipantSelectors(_ show: Bool, animated: Bool) {
        let selectorWidth = show ? ViewConfig.participantSelectorWidth : 0
        let duration = animated ? ViewConfig.participantSelectorAnimatingDuration : 0
        let leadingSpace = show ? ViewConfig.participantSelectorLeadingSpace : 0
        versulLabel.isHidden = !show
        participantSelectionLeadingSpaceConstraint.constant = leadingSpace
        
        UIView.animate(withDuration: duration) {
            self.participantSelectorWidthConstraint.constant = selectorWidth
            self.view.layoutIfNeeded()
        }
    }
    
    func setupTableViews() {
        leftParticipantSelectorTableView.dataSource = self
        leftParticipantSelectorTableView.delegate = self
        leftParticipantSelectorTableView.reloadData()
        
        rightParticipantSelectorTableView.dataSource = self
        rightParticipantSelectorTableView.delegate = self
        rightParticipantSelectorTableView.reloadData()
    }
    
    private func updateStartStopButtonState(_ state: StartButtonState) {
        switch state {
        case .start:
            startStopButton.setTitle("Start", for: .normal)
            startStopButton.isEnabled = true
        case .stop:
            startStopButton.setTitle("Stop", for: .normal)
            startStopButton.isEnabled = true
        case .disabled:
            startStopButton.isEnabled = false
        case .reset:
            startStopButton.isEnabled = true
            startStopButton.setTitle("Reset", for: .normal)
        }
        
        startStopButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
    }
    
    @IBAction func didTapStartStopButton(_ sender: UIButton) {
        switch gameManager.currentState {
        case .ready:
            gameManager.startGame()
            showParticipantSelectors(false, animated: true)
            updateStartStopButtonState(.stop)
        case .inProgress:
            gameManager.stopGame()
            showParticipantSelectors(true, animated: true)
            updateStartStopButtonState(.reset)
        case .finished:
            gameManager.resetGame()
            updateStartStopButtonState(.start)
        default:
            break
        }
    }
    
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        
    }
    
}


extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameManager.rightRobots.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "basicCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: id)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: id)
        }
        
        cell?.textLabel?.text = gameManager.rightRobots[indexPath.row].name
        cell?.backgroundColor = .darkGray
        cell?.textLabel?.textColor = .systemGreen
        cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        cell?.selectionStyle = .gray
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ViewConfig.tableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case leftParticipantSelectorTableView:
            gameManager.setLeftParticipant(index: indexPath.row)
        case rightParticipantSelectorTableView:
            gameManager.setRightParticipant(index: indexPath.row)
        default:
            break
        }
    }
}


extension MainViewController: GameManagerDelegate {
    func updateParticipantMessage(_ message: String, for side: FieldSide) {
        if side == .left {
            leftRobotMessageLabel.text = message
        } else {
            rightRobotMessageLabel.text = message
        }
    }
    
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool) {
        let fieldView = field == .left ? leftFieldView : rightFieldView
        fieldView?.update(point: point, with: isHit ? .black : .red, textColor: isHit ? .white : .black)
    }
    
    func placeShips(withRects rects: [CGRect], onField field: FieldSide) {
        let fieldView = field == .left ? leftFieldView : rightFieldView
        fieldView?.place(rects: rects, color: .blue, shouldReset: true)
    }
    
    func gameStateDidChange(to state: GameState) {
        switch state {
        case .notReady:
            mainInfoLabel.text = "Please choose the participants"
            updateStartStopButtonState(.disabled)
        case .ready:
            mainInfoLabel.text = "Press Start to begin"
            updateStartStopButtonState(.start)
            showParticipantSelectors(true, animated: true)
        case .inProgress:
            mainInfoLabel.text = "Game in progress"
            updateStartStopButtonState(.stop)
        case .finished:
            mainInfoLabel.text = "Game has been finished"
            updateStartStopButtonState(.reset)
        case .paused:
            mainInfoLabel.text = "Game has been paused. Press Resume to continue."
        }
    }
}
