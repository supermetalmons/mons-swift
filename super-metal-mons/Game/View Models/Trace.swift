// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

struct Trace {
    
    enum Kind {
        case monMove, manaMove, mysticAction, demonAction, spiritTargetCapture, spiritTargetMove, demonAdditionalStep, bomb
    }
    
    let from: Location
    let to: Location
    let kind: Kind
    
    
    var proportionalWidth: CGFloat {
        return 0.2
    }
    
    func fromPointRelativePosition(boardSize: Int, isFlipped: Bool) -> CGPoint {
        let half = CGFloat(1) / CGFloat(boardSize * 2)
        let x = isFlipped ? (boardSize - from.j - 1) : from.j
        let y = isFlipped ? (boardSize - from.i - 1) : from.i
        let fromPosition = CGPoint(x: CGFloat(x) / CGFloat(boardSize) + half, y: CGFloat(y) / CGFloat(boardSize) + half)
        return fromPosition
    }
    
    func toPointRelativePosition(boardSize: Int, isFlipped: Bool) -> CGPoint {
        let half = CGFloat(1) / CGFloat(boardSize * 2)
        let x = isFlipped ? (boardSize - to.j - 1) : to.j
        let y = isFlipped ? (boardSize - to.i - 1) : to.i
        let toPosition = CGPoint(x: CGFloat(x) / CGFloat(boardSize) + half, y: CGFloat(y) / CGFloat(boardSize) + half)
        return toPosition
    }
    
}
