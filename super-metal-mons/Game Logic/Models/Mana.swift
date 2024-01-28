// ∅ 2024 super-metal-mons

import Foundation

enum Mana: Equatable, Codable, Hashable {
    case regular(color: Color), supermana
    
    func score(for player: Color) -> Int {
        switch self {
        case let .regular(color):
            return color == player ? 1 : 2
        case .supermana:
            return 2
        }
    }
    
}
