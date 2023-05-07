// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: do not use in Game logic
enum ViewEffect {
    case availableToStartFrom(Location)
    case availableForSpiritAction(Location)
    case availableForStep(Location)
    case availableForAction(Location)
    case updateCell(Location)
    case setSelected(Location)
    case updateGameStatus
    case selectBombOrPotion
}
