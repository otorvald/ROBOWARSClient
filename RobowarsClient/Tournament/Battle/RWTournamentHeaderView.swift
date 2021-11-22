//
//  RWTournamentHeaderView.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 22.11.2021.
//

import UIKit

class RWTournamentHeaderView: UIView, NibLoadable {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    func updateName(_ text: String) {
        nameLabel.text = text
    }
    
    func updateMessage(_ text: String) {
        messageLabel.text = text
    }
}
