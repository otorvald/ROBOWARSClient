//
//  RWTournamentResultView.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 22.11.2021.
//

import UIKit

protocol RWTournamentResultViewDelegate: AnyObject {
    func onRestartButtonPressed()
}

class RWTournamentResultView: UIView, NibLoadable {
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: RWTournamentResultViewDelegate?
    private var result = [RWTournamentGameResults]()
    
    func updateWith(result: [RWTournamentGameResults]) {
        self.result = result
        tableView.reloadData()
    }

    @IBAction func onRestartButtonPressed(_ sender: Any) {
        delegate?.onRestartButtonPressed()
    }
}

extension RWTournamentResultView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 174
    }
}

extension RWTournamentResultView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "ResultTableViewCell"
        let cell: ResultTableViewCell
        if let reusableCell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ResultTableViewCell {
            cell = reusableCell
        } else {
            cell = ResultTableViewCell.fromNib()
        }
        cell.updateWith(round: indexPath.row + 1, results: result[indexPath.row])
        return cell
    }
}
