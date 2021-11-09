//
//  Ship.swift
//  RobowarsClient
//
//  Created by Maksym Bystryk on 09.11.2021.
//

import Foundation
import UIKit

class Ship {
    let frame: CGRect
    var lives: [CGPoint]
    
    init(frame: CGRect) {
        self.frame = frame
        self.lives = Self.frameToLives(frame: frame)
    }
    
    func handleShoot(in position: CGPoint) -> ShootingResult {
        guard frame.contains(position) else { return .missed }
        if let index = lives.firstIndex(of: position) {
            lives.remove(at: index)
        }
        
        if lives.isEmpty { return .killed }
        
        return .damaged
    }
    
    private static func frameToLives(frame: CGRect) -> [CGPoint] {
        let minX = Int(round(frame.minX))
        let minY = Int(round(frame.minY))
        let width = Int(round(frame.width))
        let height = Int(round(frame.height))
        var lives = [CGPoint]()
        for h in 0..<height {
            let y = minY + h
            for w in 0..<width {
                let x = minX + w
                lives.append(CGPoint(x: CGFloat(x), y: CGFloat(y)))
            }
        }
        
        return lives
    }
}
