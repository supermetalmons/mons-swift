// ∅ 2024 super-metal-mons

import Foundation

enum Input: Equatable, Hashable {
    
    case location(Location)
    case modifier(Modifier)
    
    enum Modifier: String, Hashable {
        case selectPotion, selectBomb, cancel
    }
    
}
