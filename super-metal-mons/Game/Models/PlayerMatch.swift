// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct PlayerMatch: Codable {
    
    enum Status: String, Codable {
        case waiting, playing, surrendered, victory, defeat
    }
    
    let color: Color
    var emojiId: Int
    var fen: String
    var moves: [[MonsGame.Input]]?
    var status: Status
    
}
