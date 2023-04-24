// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension Bool {
    
    init?(fen: String) {
        switch fen {
        case "1":
            self = true
        case "0":
            self = false
        default:
            return nil
        }
    }
    
    var fen: String {
        if self {
            return "1"
        } else {
            return "0"
        }
    }
    
}
