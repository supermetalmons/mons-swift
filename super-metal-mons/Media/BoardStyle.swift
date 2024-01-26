// ∅ 2024 super-metal-mons

import Foundation

enum BoardStyle: String {
    
    case pixel
    
    var namespace: String {
        return rawValue + "/"
    }
    
}
