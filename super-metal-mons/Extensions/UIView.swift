// ∅ 2024 super-metal-mons

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
