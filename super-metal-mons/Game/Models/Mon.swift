// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Mon {
    
    var base: (i: Int, j: Int) {
        // TODO: DRY
        // TODO: parametrize with the board size? or put it all into a config.
        let isWhite = color == .white
        switch kind {
        case .drainer:
            return isWhite ? (10, 5) : (0, 5)
        case .angel:
            return isWhite ? (10, 4) : (0, 6)
        case .spirit:
            return isWhite ? (10, 6) : (0, 4)
        case .demon:
            return isWhite ? (10, 3) : (0, 7)
        case .mystic:
            return isWhite ? (10, 7) : (0, 3)
        }
        
    }
    
    enum Kind: String {
        case demon, drainer, angel, spirit, mystic
    }
    
    let kind: Kind
    let color: Color
    private var cooldown: Int
    
    var isFainted: Bool {
        return cooldown > 0
    }
    
    init(kind: Kind, color: Color) {
        self.kind = kind
        self.color = color
        self.cooldown = 0
    }
    
    init?(fen: String) {
        guard fen.count == 2, let first = fen.first, let last = fen.last, let cooldown = Int(String(last)) else { return nil }
        
        switch first.lowercased() {
        case "e": self.kind = .demon
        case "d": self.kind = .drainer
        case "a": self.kind = .angel
        case "s": self.kind = .spirit
        case "y": self.kind = .mystic
        default: return nil
        }
        
        self.color = first.isLowercase ? .black : .white
        self.cooldown = cooldown
    }
    
    var fen: String {
        let letter: String
        switch kind {
        case .demon: letter = "e"
        case .drainer: letter = "d"
        case .angel: letter = "a"
        case .spirit: letter = "s"
        case .mystic: letter = "y"
        }
        let cooldown = String(cooldown % 10)
        return (color == .white ? letter.uppercased() : letter) + cooldown
    }
    
    mutating func faint() {
        cooldown = 2
    }
    
    mutating func decreaseCooldown() {
        if cooldown > 0 {
            cooldown -= 1
        }
    }
    
}
