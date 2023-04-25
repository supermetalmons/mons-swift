// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

struct Colors {
    
    static func square(_ square: Square) -> UIColor {
        return named("square/" + square.rawValue)
    }
    
    private static func named(_ name: String) -> UIColor {
        return UIColor(named: name)!
    }
    
}
