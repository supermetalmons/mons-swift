// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    private struct Multiplier {
        static let confirmedScore = 1000
        
        static let faintedMon = -250
        static let faintedDrainer = -500
        static let drainerAtRisk = -250 // TODO: implement – the most comlex one - also might check angel
        
        static let manaCloseToSamePool = 400
        static let monWithManaCloseToAnyPool = 700
        static let extraForSupermana = 90
        static let extraForOpponentsMana = 90
        static let drainerCloseToMana = 300
        static let drainerHoldingMana = 350
        
        static let monCloseToCenter = 80
        static let hasConsumable = 125
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
                    score += myMonMultiplier * Multiplier.drainerCloseToMana / distance(from: location, to: .nearestMana)
                } else {
                    score += myMonMultiplier * Multiplier.monCloseToCenter / distance(from: location, to: .center)
                }
            case .monWithConsumable(let mon, _):
                let myMonMultiplier = mon.color == color ? 1 : -1
                let isDrainer = mon.kind == .drainer
                score += myMonMultiplier * Multiplier.hasConsumable
                if isDrainer {
                    score += myMonMultiplier * Multiplier.drainerCloseToMana / distance(from: location, to: .nearestMana)
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
        case nearestMana
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
        case .nearestMana:
            var min = Config.boardSize
            for (manaLocation, item) in board.items where item.mana != nil {
                let delta = max(abs(manaLocation.i - location.i), abs(manaLocation.j - location.j))
                if delta < min {
                    min = delta
                }
            }
            distance = min
        }
        return distance + 1
    }
    
}
