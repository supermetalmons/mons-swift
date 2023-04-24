// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SeparatorView: UIView {

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        constraints.first?.constant = CGFloat.pixel
    }

}

