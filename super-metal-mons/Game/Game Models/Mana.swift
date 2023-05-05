// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Mana: Equatable {
    case regular(color: Color), supermana
    
    var score: Int {
        switch self {
        case .regular:
            return 1
        case .supermana:
            return 2
        }
    }
    
}
