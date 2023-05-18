// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Mana: Equatable {
    case regular(color: Color), supermana
    
    func score(for player: Color) -> Int {
        switch self {
        case let .regular(color):
            return color == player ? 1 : 2
        case .supermana:
            return 2
        }
    }
    
}
