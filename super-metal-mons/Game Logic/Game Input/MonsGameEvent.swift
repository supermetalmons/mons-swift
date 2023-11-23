// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    enum Event {
        case monMove(item: Item, from: Location, to: Location)
        case manaMove(mana: Mana, from: Location, to: Location)
        case manaScored(mana: Mana, at: Location)
        case mysticAction(mystic: Mon, from: Location, to: Location)
        case demonAction(demon: Mon, from: Location, to: Location)
        case demonAdditionalStep(demon: Mon, from: Location, to: Location)
        case spiritTargetMove(item: Item, from: Location, to: Location)
        case pickupBomb(by: Mon, at: Location)
        case pickupPotion(by: Item, at: Location)
        case pickupMana(mana: Mana, by: Mon, at: Location)
        case monFainted(mon: Mon, from: Location, to: Location)
        case manaDropped(mana: Mana, at: Location)
        case supermanaBackToBase(from: Location, to: Location)
        case bombAttack(by: Mon, from: Location, to: Location)
        case monAwake(mon: Mon, at: Location)
        case bombExplosion(at: Location)
        case nextTurn(color: Color)
        case gameOver(winner: Color)
    }
    
}
