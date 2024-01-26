// ∅ 2024 super-metal-mons

import Foundation

enum Sound: String, CaseIterable {
    case bomb
    case click
    case demonAbility
    case manaPickUp
    case move
    case endTurn
    case mysticAbility
    case pickupPotion
    case pickupBomb
    case choosePickup
    case scoreMana
    case scoreSupermana
    case spiritAbility
    case victory
    case defeat
    case didConnect
    
    var priority: Int {
        switch self {
        case .click, .endTurn, .move, .didConnect:
            return 0
        case .manaPickUp, .choosePickup, .mysticAbility, .spiritAbility, .demonAbility, .bomb, .pickupBomb, .pickupPotion:
            return 1
        case .scoreMana, .scoreSupermana, .victory, .defeat:
            return 2
        }
    }
    
    var url: URL? { return Bundle.main.url(forResource: rawValue, withExtension: "wav") }
    
}
