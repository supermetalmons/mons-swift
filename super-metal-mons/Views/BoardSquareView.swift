// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class BoardSquareView: UIView {
    
    let location: Location
    
    init(location: Location) {
        self.location = location
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
