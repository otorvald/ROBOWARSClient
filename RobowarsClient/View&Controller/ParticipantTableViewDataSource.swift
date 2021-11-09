//
//  ParticipantTableViewDataSource.swift
//  RobowarsClient
//
//  Created by Max Bystryk on 12.10.2021.
//

import Foundation
import UIKit

class ParticipantTableViewDataSource: NSObject, UITableViewDataSource {
    var participants = [RobotProtocol]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "basicStyle"
        var cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath)
        
        cell.textLabel?.text = participants[indexPath.row].name
        
        return cell
    }
    
}
