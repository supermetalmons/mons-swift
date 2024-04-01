// ∅ 2024 super-metal-mons

import Foundation

enum Input: Equatable {
    
    case location(Location)
    case modifier(Modifier)
    
    enum Modifier: String {
        case selectPotion, selectBomb, cancel
    }
    
}
