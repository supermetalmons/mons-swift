// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: we would want a parent model for PlayerMatch
// it might contain several matches. like a game session.

// TODO: how would i know about rematch proposal?

struct PlayerGameSession: Codable {
    
    enum Status: String, Codable {
        case waiting, started, ended
    }
    
    var currentMatch: Int
    var emojiId: Int
    var matches: [Int: PlayerMatch]
    
}

struct PlayerMatch: Codable {
    
    enum Status: String, Codable {
        case waiting, playing, surrendered, victory, defeat
    }
    
    let color: Color
    var emojiId: Int // TODO: remove from here
    var fen: String
    var moves: [[MonsGame.Input]]?
    var status: Status
    
}
