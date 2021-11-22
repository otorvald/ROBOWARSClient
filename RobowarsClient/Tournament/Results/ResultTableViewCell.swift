//
//  ResultTableViewCell.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 22.11.2021.
//

import UIKit

class ResultTableViewCell: UITableViewCell, NibLoadable {
    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var leftWinnerLabel: UILabel!
    @IBOutlet weak var rightWinnerLabel: UILabel!
    @IBOutlet var leftStatsLabels: [UILabel]!
    @IBOutlet var rightStatsLabels: [UILabel]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func updateWith(round: Int, results: RWTournamentGameResults) {
        roundLabel.text = "Round \(round)"
        leftWinnerLabel.isHidden = results.leftRobot.winner == false
        rightWinnerLabel.isHidden = results.rightRobot.winner == false
        updateLabelsForRobot(leftStatsLabels, results.leftRobot)
        updateLabelsForRobot(rightStatsLabels, results.rightRobot)
    }
    
    private func updateLabelsForRobot(_ labels: [UILabel], _ robot: RWTournamentRobotStats) {
        labels[0].text = "shootCount \(robot.shootCount)"
        labels[1].text = "hitCount \(robot.hitCount)"
        labels[2].text = "killCount \(robot.killCount)"
        labels[3].text = "accuracy \(robot.accuracy)"
    }
}
