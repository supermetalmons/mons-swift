// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

class Board {
 
    // TODO: MAKE IT PRIVATE
    private (set) var items: [Location: Item]
    
    init(items: [Location: Item] = Config.initialItems) {
        self.items = items
    }
    
    func removeAnyItem(location: Location) {
        items.removeValue(forKey: location)
    }
    
    func remove(item: Item, location: Location) {
        if item == items[location] {
            items.removeValue(forKey: location)
        }
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
    
    var supermanaBase: Location {
        return Config.squares.first(where: { location, square -> (Bool) in
            if case .supermanaBase = square {
                return true
            } else {
                return false
            }
        })!.key
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
