//
//  Extensions.swift
//  RobowarsClient
//
//  Created by Max Bystryk on 06.10.2021.
//

import Foundation
import UIKit

extension UIView {
    func fillSuperview() {
        guard let superview = self.superview else { return }
        translatesAutoresizingMaskIntoConstraints = superview.translatesAutoresizingMaskIntoConstraints
        if translatesAutoresizingMaskIntoConstraints {
            autoresizingMask = [.flexibleWidth, .flexibleHeight]
            frame = superview.bounds
        } else {
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
            rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
        }
    }
}

public protocol NibLoadable {}

public extension NibLoadable where Self: UIView {
    static func fromNib<T: UIView>() -> T  {
        let nibBundle = Bundle(for: Self.self).loadNibNamed(String(describing: self), owner: nil, options: nil)
        return nibBundle![0] as! T
    }
}
