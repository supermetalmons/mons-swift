// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    enum Input: Equatable, Codable {
        case location(Location)
        case modifier(Modifier)
        
        enum Modifier: String, Codable {
            case selectPotion, selectBomb, cancel
        }
    }
    
}
