// ∅ 2024 super-metal-mons

import Foundation

enum Square: Equatable {
    case regular
    case consumableBase
    case supermanaBase
    case manaBase(color: Color)
    case manaPool(color: Color)
    case monBase(kind: Mon.Kind, color: Color)
}
