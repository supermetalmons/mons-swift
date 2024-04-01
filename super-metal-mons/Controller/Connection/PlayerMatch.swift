// ∅ 2024 super-metal-mons

import Foundation

struct PlayerMatch: Codable {
    
    enum Status: String, Codable {
        case waiting, playing, surrendered, victory, defeat, suggestedRematch, acceptedRematch, canceledRematch
    }
    
    private enum CodingKeys: String, CodingKey {
        case color, emojiId, fen, moves, status, reaction
    }
    
    let color: Color
    var emojiId: Int
    var fen: String
    var moves: [[Input]]
    var status: Status
    var reaction: Reaction?
    
    var isIncompatibleFormat = false
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        color = try container.decode(Color.self, forKey: .color)
        emojiId = try container.decode(Int.self, forKey: .emojiId)
        fen = try container.decode(String.self, forKey: .fen)
        status = try container.decode(Status.self, forKey: .status)
        reaction = try container.decodeIfPresent(Reaction.self, forKey: .reaction)
        
        do {
            let movesFens = try container.decode(Array<String>.self, forKey: .moves)
            let moves = movesFens.compactMap { Array<Input>(fen: $0) }
            if movesFens.count != moves.count {
                isIncompatibleFormat = true
                self.moves = []
            } else {
                self.moves = moves
            }
        } catch {
            self.moves = []
            isIncompatibleFormat = true
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(emojiId, forKey: .emojiId)
        try container.encode(fen, forKey: .fen)
        try container.encode(status, forKey: .status)
        if let reaction = reaction {
            try container.encode(reaction, forKey: .reaction)
        }
        
        let movesFens = moves.map { $0.fen }
        try container.encode(movesFens, forKey: .moves)
    }

    init(color: Color, emojiId: Int, fen: String, status: Status) {
        self.color = color
        self.emojiId = emojiId
        self.fen = fen
        self.status = status
        self.moves = []
    }
    
}
