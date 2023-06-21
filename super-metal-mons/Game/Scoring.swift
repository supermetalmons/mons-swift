// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    func evaluateFor(color: Color) -> Int {
        let gameScore: Int
        switch color {
        case .white:
            gameScore = whiteScore - blackScore
        case .black:
            gameScore = blackScore - whiteScore
        }
                
        return gameScore
    }
    
}
