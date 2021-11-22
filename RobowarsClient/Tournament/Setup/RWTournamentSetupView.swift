//
//  RWTournamentSetupView.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 19.11.2021.
//

import UIKit

protocol RWTournamentParticipant {
    var name: String { get }
}

protocol RWTournamentSetupViewDelegate: AnyObject {
    func onLeftParticipantSelected(participant: RWTournamentParticipant)
    func onRightParticipantSelected(participant: RWTournamentParticipant)
    func onGameFieldSelected(field: RWGameConfiguration)
    func onMaxGameCountSelected(count: Int)
    func onTournamentSetupStartButtonPressed()
}

class RWTournamentSetupView: UIView, NibLoadable {
    private let cellHeight: CGFloat = 44
    
    @IBOutlet private weak var leftTable: UITableView!
    @IBOutlet private weak var leftTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var leftTableLeading: NSLayoutConstraint!
    
    @IBOutlet private weak var rightTable: UITableView!
    @IBOutlet private weak var rightTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var rightTableTrailing: NSLayoutConstraint!
    
    @IBOutlet private weak var versusLabel: UILabel!
    @IBOutlet private weak var versusLabelCenterY: NSLayoutConstraint!
    
    @IBOutlet private weak var startButton: UIButton!
    
    @IBOutlet private weak var fieldSizeTable: UITableView!
    @IBOutlet private weak var numberOfRoundsTable: UITableView!
    
    private var leftParticipants = [RWTournamentParticipant]()
    private var rightParticipants = [RWTournamentParticipant]()
    private var fieldSizes = [RWGameConfiguration]()
    private var maxGameCount: Int = 6
    
    weak var delegate: RWTournamentSetupViewDelegate?
    
    func setupData(leftParticipants: [RWTournamentParticipant], rightParticipants: [RWTournamentParticipant]) {
        self.leftParticipants = leftParticipants
        self.rightParticipants = rightParticipants
        setupParticipantsTables()
    }
    
    func setupConfigs(fieldSizes: [RWGameConfiguration], maxGameCount: Int) {
        self.fieldSizes = fieldSizes
        self.maxGameCount = maxGameCount
        setupConfigTables()
    }
    
    private func setupParticipantsTables() {
        leftTableHeight.constant = CGFloat(leftParticipants.count) * cellHeight
        rightTableHeight.constant = CGFloat(rightParticipants.count) * cellHeight
        leftTable.reloadData()
        rightTable.reloadData()
    }
    
    private func setupConfigTables() {
        fieldSizeTable.reloadData()
        numberOfRoundsTable.reloadData()
    }
    
    func show(completion: (() -> Void)?) {
        guard let leftTableLeadingConstraint = leftTableLeading,
              let rightTableTrailingConstraint = rightTableTrailing,
              let versusLabelCenterYConstraint = versusLabelCenterY else {
                  completion?()
                  return
              }
        leftTableLeadingConstraint.constant = -leftTable.frame.width
        rightTableTrailingConstraint.constant = -rightTable.frame.width
        versusLabelCenterYConstraint.constant = -frame.midY
        updateConstraints()
        layoutIfNeeded()
        leftTableLeadingConstraint.constant = 20
        rightTableTrailingConstraint.constant = 20
        versusLabelCenterYConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .allowUserInteraction, animations: {
            self.layoutIfNeeded()
        }, completion: {
            _ in
            completion?()
        })
    }
    
    func hide(completion: (() -> Void)?) {
        guard let leftTableLeadingConstraint = leftTableLeading,
              let rightTableTrailingConstraint = rightTableTrailing,
              let versusLabelCenterYConstraint = versusLabelCenterY else {
                  completion?()
                  return
              }
        leftTableLeadingConstraint.constant = 20
        rightTableTrailingConstraint.constant = 20
        versusLabelCenterYConstraint.constant = 0
        let leftTableNewConstant = -leftTable.frame.width
        let rightTableNewConstant = -rightTable.frame.width
        let versusLabelNewConstant = -frame.midY
        updateConstraints()
        layoutIfNeeded()
        leftTableLeadingConstraint.constant = leftTableNewConstant
        rightTableTrailingConstraint.constant = rightTableNewConstant
        versusLabelCenterYConstraint.constant = versusLabelNewConstant
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .allowUserInteraction, animations: {
            self.layoutIfNeeded()
        }, completion: {
            _ in
            completion?()
        })
    }
    
    func showStartButton(_ show: Bool) {
        startButton.isHidden = !show
    }
    
    @IBAction func onStartButtonPressed(_ sender: Any) {
        delegate?.onTournamentSetupStartButtonPressed()
    }
}

extension RWTournamentSetupView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case leftTable: delegate?.onLeftParticipantSelected(participant: leftParticipants[indexPath.row])
        case rightTable: delegate?.onRightParticipantSelected(participant: rightParticipants[indexPath.row])
        case fieldSizeTable: delegate?.onGameFieldSelected(field: fieldSizes[indexPath.row])
        case numberOfRoundsTable: delegate?.onMaxGameCountSelected(count: indexPath.row + 1)
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}

extension RWTournamentSetupView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case leftTable: return leftParticipants.count
        case rightTable: return rightParticipants.count
        case fieldSizeTable: return fieldSizes.count
        case numberOfRoundsTable: return maxGameCount
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case leftTable: return cellForParticipant(tableView, leftParticipants[indexPath.row])
        case rightTable: return cellForParticipant(tableView, rightParticipants[indexPath.row])
        case fieldSizeTable: return cellForGameConfiguration(tableView, fieldSizes[indexPath.row])
        case numberOfRoundsTable: return cellForGameCount(tableView, indexPath)
        default: return UITableViewCell()
        }
    }
    
    private func cellForParticipant(_ tableView: UITableView, _ participant: RWTournamentParticipant) -> UITableViewCell {
        let id = "basicCell"
        var cell: UITableViewCell
        if let reusableCell = tableView.dequeueReusableCell(withIdentifier: id) {
            cell = reusableCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: id)
        }
        cell.textLabel?.text = participant.name
        cell.backgroundColor = .darkGray
        cell.textLabel?.textColor = .systemGreen
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 36)
        cell.selectionStyle = .gray
        return cell
    }
    
    private func cellForGameCount(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let id = "basicCell"
        var cell: UITableViewCell
        if let reusableCell = tableView.dequeueReusableCell(withIdentifier: id) {
            cell = reusableCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: id)
        }
        cell.textLabel?.text = "number of games \(indexPath.row + 1)"
        cell.backgroundColor = .darkGray
        cell.textLabel?.textColor = .systemGreen
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 36)
        cell.selectionStyle = .gray
        return cell
    }
    
    private func cellForGameConfiguration(_ tableView: UITableView, _ configuration: RWGameConfiguration) -> UITableViewCell {
        let id = "basicCell"
        var cell: UITableViewCell
        if let reusableCell = tableView.dequeueReusableCell(withIdentifier: id) {
            cell = reusableCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: id)
        }
        cell.textLabel?.text = configuration.description
        cell.backgroundColor = .darkGray
        cell.textLabel?.textColor = .systemGreen
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cell.selectionStyle = .gray
        return cell
    }
}
