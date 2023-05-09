// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Sound: String, CaseIterable {
    case bomb
    case click
    case demonAbility
    case manaPickUp
    case move
    case moveMana
    case mysticAbility
    case pickUpPotion
    case scoreMana
    case scoreSupermana
    case spiritAbility
    
    var priority: Int {
        switch self {
        case .click, .moveMana, .move:
            return 0
        case .manaPickUp, .pickUpPotion, .mysticAbility, .spiritAbility, .demonAbility, .bomb:
            return 1
        case .scoreMana, .scoreSupermana:
            return 2
        }
    }
    
}
