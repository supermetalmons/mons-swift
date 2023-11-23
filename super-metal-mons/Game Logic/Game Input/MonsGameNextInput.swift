// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    struct NextInput {
        
        enum Kind {
            case monMove, manaMove
            case mysticAction, demonAction, demonAdditionalStep, spiritTargetCapture, spiritTargetMove
            case selectConsumable, bombAttack
        }
        
        let input: Input
        let kind: Kind
        let actorMonItem: Item?
        
        init(input: Input, kind: Kind, actorMonItem: Item? = nil) {
            self.input = input
            self.kind = kind
            self.actorMonItem = actorMonItem
        }
        
    }
    
}
