// ∅ 2024 super-metal-mons

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
