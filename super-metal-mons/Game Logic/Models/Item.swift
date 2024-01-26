// ∅ 2024 super-metal-mons

import Foundation

enum Item: Equatable {
    case mon(mon: Mon)
    case mana(mana: Mana)
    case monWithMana(mon: Mon, mana: Mana)
    case monWithConsumable(mon: Mon, consumable: Consumable)
    case consumable(consumable: Consumable)
    
    var mon: Mon? {
        switch self {
        case .mon(let mon), .monWithMana(let mon, _), .monWithConsumable(let mon, _):
            return mon
        case .mana, .consumable:
            return nil
        }
    }
    
    var mana: Mana? {
        switch self {
        case .mon, .monWithConsumable, .consumable:
            return nil
        case .mana(let mana), .monWithMana(_, let mana):
            return mana
        }
    }
    
    var consumable: Consumable? {
        switch self {
        case .mon, .mana, .monWithMana:
            return nil
        case .monWithConsumable(_, let consumable), .consumable(let consumable):
            return consumable
        }
    }
    
}
