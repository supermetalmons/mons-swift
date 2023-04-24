// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Effect {
    case availableForStep((Int, Int))
    case updateCell((Int, Int)) // TODO: use Location here as well
    case setSelected((Int, Int))
    case updateGameStatus
}
