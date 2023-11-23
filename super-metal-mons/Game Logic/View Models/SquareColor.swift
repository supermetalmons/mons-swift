// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: refactor?
enum SquareColor: String {
    case white
    case black
    case mana
    case supermana
    case pool
    case consumable
}

extension Square {
    
    func color(location: Location) -> SquareColor {
        switch self {
        case .regular, .monBase:
            return (location.i + location.j).isMultiple(of: 2) ? .white : .black
        case .consumableBase:
            return .consumable
        case .supermanaBase:
            return .supermana
        case .manaBase:
            return .mana
        case .manaPool:
            return .pool
        }
    }
    
}
