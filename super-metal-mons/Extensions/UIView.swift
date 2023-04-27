// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

extension UIView {
    
    func addSubviewConstrainedToFrame(_ subview: UIView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        let firstConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": subview])
        let secondConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": subview])
        addConstraints(firstConstraints + secondConstraints)
    }
    
}
