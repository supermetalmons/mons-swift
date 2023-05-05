// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Color {
    case white, black
    
    var other: Color {
        switch self {
        case .black:
            return .white
        case .white:
            return .black
        }
    }
    
}
