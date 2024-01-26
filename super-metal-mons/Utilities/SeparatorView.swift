// ∅ 2024 super-metal-mons

import UIKit

class SeparatorView: UIView {

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        constraints.first?.constant = CGFloat.pixel
    }

}

