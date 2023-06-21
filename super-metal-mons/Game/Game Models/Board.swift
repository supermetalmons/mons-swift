// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

class Board {
 
    private (set) var items: [Location: Item]
    
    init(items: [Location: Item] = Config.initialItems) {
        self.items = items
    }
    
    func removeItem(location: Location) {
        items.removeValue(forKey: location)
    }
    
    func put(item: Item, location: Location) {
        items[location] = item
    }
    
    func item(at location: Location) -> Item? {
        return items[location]
    }
    
    func square(at location: Location) -> Square {
        return Config.squares[location] ?? .regular
    }
    
}

extension Board {
    
    var allMonsBases: [Location] {
        return Config.squares.compactMap { location, square -> (Location?) in
            if case .monBase = square {
                return location
            } else {
                return nil
            }
        }
    }
    
    var supermanaBase: Location {
        return Config.squares.first(where: { location, square -> (Bool) in
            if case .supermanaBase = square {
                return true
            } else {
                return false
            }
        })!.key
    }
    
    func allMonsLocations(color: Color) -> [Location] {
        return items.compactMap { (location, item) -> Location? in
            return item.mon?.color == color ? location : nil
        }
    }
    
    func allFreeRegularManaLocations(color: Color) -> [Location] {
        return items.compactMap { (location, item) -> Location? in
            if case let .mana(mana) = item, case let .regular(manaColor) = mana, manaColor == color {
                return location
            } else {
                return nil
            }
        }
    }
    
    func base(mon: Mon) -> Location {
        return Config.squares.first(where: { location, square -> (Bool) in
            if case let .monBase(kind, color) = square, kind == mon.kind, color == mon.color {
                return true
            } else {
                return false
            }
        })!.key
    }
    
    func faintedMonsLocations(color: Color) -> [Location] {
        let faintedMonsLocations = items.compactMap { (location, item) -> Location? in
            switch item {
            case let .mon(mon: mon):
                if mon.color == color && mon.isFainted {
                    return location
                } else {
                    return nil
                }
            case .consumable, .mana, .monWithConsumable, .monWithMana:
                return nil
            }
        }
        
        return faintedMonsLocations
    }
    
    func findMana(color: Color) -> Location? {
        let locationWithItem = items.first(where: { location, item -> (Bool) in
            switch item {
            case let .mana(mana):
                if case let .regular(manaColor) = mana {
                    return manaColor == color
                } else {
                    return false
                }
            case .consumable, .monWithMana, .mon, .monWithConsumable:
                return false
            }
        })
        return locationWithItem?.key
    }
    
    func findAwakeAngel(color: Color) -> Location? {
        let locationWithItem = items.first(where: { location, item -> (Bool) in
            switch item {
            case let .monWithConsumable(mon, _), let .mon(mon):
                return mon.color == color && mon.kind == .angel && !mon.isFainted
            case .consumable, .mana, .monWithMana:
                return false
            }
        })
        return locationWithItem?.key
    }
    
}
