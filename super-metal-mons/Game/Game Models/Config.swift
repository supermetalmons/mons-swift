// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Config {
    
    static let boardSize = 11
    static let targetScore = 5
    
    static let monsMovesPerTurn = 5
    static let manaMovesPerTurn = 1
    static let actionsPerTurn = 1
        
    static let squares: [Location: Square] = [
        Location(0, 0): .manaPool(color: .black),
        Location(0, 10): .manaPool(color: .black),
        Location(10, 0): .manaPool(color: .white),
        Location(10, 10): .manaPool(color: .white),
        
        Location(0, 3): .monBase(kind: .mystic, color: .black),
        Location(0, 4): .monBase(kind: .spirit, color: .black),
        Location(0, 5): .monBase(kind: .drainer, color: .black),
        Location(0, 6): .monBase(kind: .angel, color: .black),
        Location(0, 7): .monBase(kind: .demon, color: .black),
        
        Location(10, 3): .monBase(kind: .demon, color: .white),
        Location(10, 4): .monBase(kind: .angel, color: .white),
        Location(10, 5): .monBase(kind: .drainer, color: .white),
        Location(10, 6): .monBase(kind: .spirit, color: .white),
        Location(10, 7): .monBase(kind: .mystic, color: .white),
        
        Location(3, 4): .manaBase(color: .black),
        Location(3, 6): .manaBase(color: .black),
        Location(7, 4): .manaBase(color: .white),
        Location(7, 6): .manaBase(color: .white),
        
        Location(4, 3): .manaBase(color: .black),
        Location(4, 5): .manaBase(color: .black),
        Location(4, 7): .manaBase(color: .black),
        Location(6, 3): .manaBase(color: .white),
        Location(6, 5): .manaBase(color: .white),
        Location(6, 7): .manaBase(color: .white),
        
        Location(5, 0): .consumableBase,
        Location(5, 10): .consumableBase,
        Location(5, 5): .supermanaBase,
    ]
    
}

extension Config {
    
    static let initialItems: [Location: Item] = {
        let items = squares.compactMapValues { square -> Item? in
            switch square {
            case .regular, .manaPool:
                return nil
            case .monBase(let kind, let color):
                return .mon(mon: Mon(kind: kind, color: color))
            case .manaBase(let color):
                return .mana(mana: .regular(color: color))
            case .supermanaBase:
                return .mana(mana: .supermana)
            case .consumableBase:
                return .consumable(consumable: .bombOrPotion)
            }
        }
        return items
    }()
    
    static let monsBases: Set<Location> = {
        let bases = squares.compactMap { (location, square) -> Location? in
            switch square {
            case .regular, .manaPool, .manaBase, .supermanaBase, .consumableBase:
                return nil
            case .monBase:
                return location
            }
        }
        return Set(bases)
    }()
    
}
