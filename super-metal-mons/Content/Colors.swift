// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

struct Colors {
    
    static var squareDark: UIColor { named(#function) }
    static var squareLight: UIColor { named(#function) }
    static var squareMana: UIColor { named(#function) }
    static var squareSpecial: UIColor { named(#function) }
    static var squareConsumable: UIColor { named(#function) }
    
    private static func named(_ name: String) -> UIColor {
        return UIColor(named: name)!
    }
    
}
