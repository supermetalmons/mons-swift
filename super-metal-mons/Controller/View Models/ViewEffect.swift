// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum ViewEffect {
    case updateGameStatus
    case selectBombOrPotion
    case updateCells([Location])
    case addHighlights([Highlight])
    case showTraces([Trace])
    case nextTurn
}
