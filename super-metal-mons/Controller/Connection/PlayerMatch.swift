// ∅ 2024 super-metal-mons

import Foundation

struct PlayerMatch: Codable {
    
    enum Status: String, Codable {
        case waiting, playing, surrendered, victory, defeat, suggestedRematch, acceptedRematch, canceledRematch
    }
    
    let color: Color
    var emojiId: Int
    var fen: String
    var moves: [[Input]]?
    var status: Status
    var reaction: Reaction?
    
}
