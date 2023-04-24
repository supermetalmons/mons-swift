// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Color {
    case white, black
    
    init?(fen: String) {
        switch fen {
        case "w":
            self = .white
        case "b":
            self = .black
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .white: return "w"
        case .black: return "b"
        }
    }
}
