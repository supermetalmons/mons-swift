// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: refactor? see usages
enum ViewEffect {
    case updateCell(Location)
    case updateGameStatus
    case selectBombOrPotion
    case highlight(Highlight)
}
