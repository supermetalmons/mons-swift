// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    private struct Multiplier {
        static let confirmedScore = 1000
        static let faintedMon = -250
        static let faintedDrainer = -600
        static let drainerAtRisk = -350
        static let manaCloseToSamePool = 400
        static let monWithManaCloseToAnyPool = 700
        static let extraForSupermana = 90
        static let extraForOpponentsMana = 90
        static let drainerCloseToMana = 300
        static let drainerHoldingMana = 350
        static let monCloseToCenter = 40
        static let hasConsumable = 110
    }
    
    func evaluateFor(color: Color) -> Int {
        var score: Int

        switch color {
        case .white:
            score = (whiteScore - blackScore) * Multiplier.confirmedScore
            score += (whitePotionsCount - blackPotionsCount) * Multiplier.hasConsumable
        case .black:
            score = (blackScore - whiteScore) * Multiplier.confirmedScore
            score += (blackPotionsCount - whitePotionsCount) * Multiplier.hasConsumable
        }
        
        score *= Multiplier.confirmedScore
        
        for (location, item) in board.items {
            switch item {
            case .mon(let mon):
                let myMonMultiplier = mon.color == color ? 1 : -1
                let isDrainer = mon.kind == .drainer
                
                if mon.isFainted {
                    score += myMonMultiplier * (isDrainer ? Multiplier.faintedDrainer : Multiplier.faintedMon)
                } else if isDrainer {
                    let (danger, minMana, angelNearby) = drainerDistances(color: mon.color, from: location)
                    score += myMonMultiplier * Multiplier.drainerCloseToMana / minMana
                    if !angelNearby {
                        score += myMonMultiplier * Multiplier.drainerAtRisk / danger
                    }
                } else {
                    score += myMonMultiplier * Multiplier.monCloseToCenter / distance(from: location, to: .center)
                }
            case .monWithConsumable(let mon, _):
                let myMonMultiplier = mon.color == color ? 1 : -1
                let isDrainer = mon.kind == .drainer
                score += myMonMultiplier * Multiplier.hasConsumable
                if isDrainer {
                    let (danger, minMana, angelNearby) = drainerDistances(color: mon.color, from: location)
                    score += myMonMultiplier * Multiplier.drainerCloseToMana / minMana
                    if !angelNearby {
                        score += myMonMultiplier * Multiplier.drainerAtRisk / danger
                    }
                } else {
                    score += myMonMultiplier * Multiplier.monCloseToCenter / distance(from: location, to: .center)
                }
            case .mana:
                score += Multiplier.manaCloseToSamePool / distance(from: location, to: .closestPool(color: color))
            case .monWithMana(let mon, let mana):
                let myMonMultiplier = mon.color == color ? 1 : -1
                let manaExtra: Int
                
                switch mana {
                case let .regular(color: manaColor):
                    manaExtra = manaColor == color ? 0 : Multiplier.extraForOpponentsMana
                case .supermana:
                    manaExtra = Multiplier.extraForSupermana
                }
                score += myMonMultiplier * Multiplier.drainerHoldingMana
                score += myMonMultiplier * (Multiplier.monWithManaCloseToAnyPool + manaExtra) / distance(from: location, to: .anyClosestPool)
            case .consumable:
                continue
            }
        }
        
        return score
    }
    
    private enum Destination {
        case center
        case anyClosestPool
        case closestPool(color: Color)
    }
    
    private func drainerDistances(color: Color, from location: Location) -> (danger: Int, mana: Int, angelNearby: Bool) {
        var minMana = Config.boardSize
        var minDanger = Config.boardSize
        var angelNearby = false
        
        for (itemLocation, item) in board.items {
            switch item {
            case .mana:
                let delta = itemLocation.distance(to: location)
                if delta < minMana {
                    minMana = delta
                }
            case .mon(mon: let mon), .monWithConsumable(mon: let mon, consumable: _):
                if mon.color == color.other, !mon.isFainted, mon.kind == .mystic || mon.kind == .demon || item.consumable != nil {
                    let delta = itemLocation.distance(to: location)
                    if delta < minDanger {
                        minDanger = delta
                    }
                } else if mon.color == color, !mon.isFainted, mon.kind == .angel, itemLocation.distance(to: location) == 1 {
                    angelNearby = true
                }
            case .consumable:
                let delta = itemLocation.distance(to: location)
                if delta < minDanger {
                    minDanger = delta
                }
            case .monWithMana:
                continue
            }
        }
        
        return (minDanger, minMana, angelNearby)
    }
    
    private func distance(from location: Location, to destination: Destination) -> Int {
        let distance: Int
        switch destination {
        case .center:
            distance = abs(Config.boardCenterIndex - location.i)
        case .anyClosestPool:
            distance = max(min(location.i, abs(Config.maxLocationIndex - location.i)), min(location.j, abs(Config.maxLocationIndex - location.j)))
        case .closestPool(let color):
            let poolRow = color == .white ? Config.maxLocationIndex : 0
            distance = max(abs(poolRow - location.i), min(location.j, abs(Config.maxLocationIndex - location.j)))
        }
        return distance + 1
    }
    
}
