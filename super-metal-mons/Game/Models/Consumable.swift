// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Consumable {
    case potion
    
    init?(fen: String) {
        switch fen {
        case "P": self = .potion
        default: return nil
        }
    }
    
    var fen: String {
        switch self {
        case .potion: return "P"
        }
    }
}
