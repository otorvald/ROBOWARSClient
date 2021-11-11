//
//  ArtificialHelper.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 03.11.2021.
//

import UIKit
 
class ArtificialHelper {
    static func randomShootingPosition(_ fieldRect: CGRect) -> CGPoint {
        return CGPoint(x: Int.random(in: 0...Int(fieldRect.maxX-1)),
                       y: Int.random(in: 0...Int(fieldRect.maxY-1)))
    }
    
    static func randomShipsFor(_ field: CGRect, sizes: [CGSize], shipsCount: Int) -> [CGRect] {
        var deadZones = [CGRect]()
        var ships = [CGRect]()
        func addShip(_ ship: CGRect) {
            ships.append(ship)
            deadZones.append(CGRect(x: ship.minX - 1, y: ship.minY - 1, width: ship.width + 2, height: ship.height + 2))
        }
        func validateShip(_ ship: CGRect) -> Bool {
            for deadZone in deadZones {
                guard deadZone.intersects(ship) == false else {
                    return false
                }
            }
            return true
        }
        for _ in 0..<shipsCount {
            var ship = randomShipPositionFor(field, sizes: sizes)
            while validateShip(ship) == false {
                ship = randomShipPositionFor(field, sizes: sizes)
            }
            addShip(ship)
        }
        return ships
    }
    
    private static func randomShipPositionFor(_ field: CGRect, sizes: [CGSize]) -> CGRect {
        let size = sizes[Int.random(in: 0..<sizes.count)]
        let originX = Int.random(in: 0...Int(field.maxX-size.width))
        let originY = Int.random(in: 0...Int(field.maxY-size.height))
        let ship = CGRect(origin: CGPoint(x: originX, y: originY), size: size)
        return ship
    }
}
