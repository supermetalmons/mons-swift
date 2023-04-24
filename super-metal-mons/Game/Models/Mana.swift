// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Mana {
    case regular(color: Color), superMana
    
    init?(fen: String) {
        switch fen {
        case "U": self = .superMana
        case "M": self = .regular(color: .white)
        case "m": self = .regular(color: .black)
        default: return nil
        }
    }
    
    var fen: String {
        switch self {
        case let .regular(color: color):
            return color == .white ? "M" : "m"
        case .superMana:
            return "U"
        }
    }
}
