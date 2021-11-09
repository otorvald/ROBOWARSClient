//
//  ViewController.swift
//  RobowarsClient
//
//  Created by Maksym Bystryk on 04.10.2021.
//

import UIKit

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
    @IBOutlet weak var leftRobotName: UILabel!
    @IBOutlet weak var rightRobotName: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    
    @IBOutlet weak var participantSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var participantSelectionLeadingSpaceConstraint: NSLayoutConstraint!
    
    let gameManager = GameManager()
    var rightFieldView: FieldView?
    var leftFieldView: FieldView?
    
    private var startPressed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performInitialConfiguration()
        setupTableViews()
        gameManager.delegate = self
    }
    
    private func performInitialConfiguration() {
        leftRobotName.text = nil
        rightRobotName.text = nil
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
        mainInfoLabel.isHidden = !show
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
    
    @IBAction func didTapStartStopButton(_ sender: UIButton) {
        startPressed.toggle()
        startPressed ? gameManager.start() : gameManager.stop()
        //showParticipantSelectors(startPressed, animated: false)
    }
}


extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameManager.rightParticipants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "basicCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: id)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: id)
        }
        
        cell?.textLabel?.text = gameManager.rightParticipants[indexPath.row].name
        
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
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool) {
        let fieldView = field == .left ? leftFieldView : rightFieldView
        fieldView?.update(point: point, with: isHit ? .black : .red, isShoot: true)
    }
    
    func placeShips(withRects rects: [CGRect], onField field: FieldSide) {
        let fieldView = field == .left ? leftFieldView : rightFieldView
        fieldView?.place(rects: rects, color: .blue, shouldReset: true)
    }
}
