// ∅ 2024 super-metal-mons

import Foundation

enum Input: Equatable, Codable, Hashable {
    
    case location(Location)
    case modifier(Modifier)
    
    enum Modifier: String, Codable, Hashable {
        case selectPotion, selectBomb, cancel
    }
    
}
