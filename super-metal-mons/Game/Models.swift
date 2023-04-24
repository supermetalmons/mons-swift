// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: split into files, refactor

extension Array<Array<Space>> {
    
    init?(fen: String) {
        let lines = fen.split(separator: "/")
        guard lines.count == 11 else { return nil }
        var spaces = [[Space]]()
        
        for line in lines {
            guard !line.isEmpty else { return nil }
            var lineSpaces = [Space]()
            var input = String(line)
            var prefix = input.prefix(3)
            while !prefix.isEmpty {
                input.removeFirst(3)
                
                if prefix.first == "n" {
                    guard let number = Int(prefix.dropFirst()) else { return nil }
                    let emptySpaces = (0..<number).map { _ in Space.empty }
                    lineSpaces.append(contentsOf: emptySpaces)
                } else if let space = Space(fen: String(prefix)) {
                    lineSpaces.append(space)
                } else {
                    return nil
                }
                
                prefix = input.prefix(3)
            }
            spaces.append(lineSpaces)
        }
        
        self = spaces
    }
    
    var fen: String {
        var lines = [String]()
        for row in self {
            var line = ""
            var emptySpaceCount = 0
            for item in row {
                let itemFen = item.fen
                if itemFen.isEmpty {
                    emptySpaceCount += 1
                } else {
                    if emptySpaceCount > 0 {
                        line += String(format: "n%02d", emptySpaceCount)
                        emptySpaceCount = 0
                    }
                    line += itemFen
                }
            }
            
            if emptySpaceCount > 0 {
                line += String(format: "n%02d", emptySpaceCount)
            }
            
            lines.append(line)
        }
        return lines.joined(separator: "/")
    }
    
}

enum Space {
    case mon(mon: Mon)
    case mana(mana: Mana)
    case monWithMana(mon: Mon, mana: Mana)
    case consumable(consumable: Consumable)
    case empty
    
    init?(fen: String) {
        guard !fen.isEmpty else {
            self = .empty
            return
        }
        
        guard fen.count == 3 else { return nil }
        let itemFen = String(fen.suffix(1))
        
        var mana: Mana? = nil
        if let item = Mana(fen: itemFen) {
            mana = item
        } else if let item = Consumable(fen: itemFen) {
            self = .consumable(consumable: item)
            return
        }
        
        
        let monFen = String(fen.prefix(2))
        if monFen != "xx" {
            guard let mon = Mon(fen: monFen) else { return nil }
            if let mana = mana {
                self = .monWithMana(mon: mon, mana: mana)
            } else {
                self = .mon(mon: mon)
            }
        } else if let mana = mana {
            self = .mana(mana: mana)
        } else {
            return nil
        }
        
    }
    
    var fen: String {
        var monFen = "xx"
        var itemFen = "x"
        switch self {
        case .empty:
            return ""
        case .mon(let mon):
            monFen = mon.fen
        case .mana(let mana):
            itemFen = mana.fen
        case .monWithMana(let mon, let mana):
            monFen = mon.fen
            itemFen = mana.fen
        case .consumable(let consumable):
            itemFen = consumable.fen
        }
        return monFen + itemFen
    }
    
}

enum Color {
    case red, blue
    
    init?(fen: String) {
        switch fen {
        case "r":
            self = .red
        case "b":
            self = .blue
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .red: return "r"
        case .blue: return "b"
        }
    }
}

struct Mon {
    
    var base: (i: Int, j: Int) {
        // TODO: DRY
        // TODO: parametrize with the board size? or put it all into a config.
        let isRed = color == .red
        switch kind {
        case .drainer:
            return isRed ? (10, 5) : (0, 5)
        case .angel:
            return isRed ? (10, 4) : (0, 6)
        case .spirit:
            return isRed ? (10, 6) : (0, 4)
        case .demon:
            return isRed ? (10, 3) : (0, 7)
        case .mystic:
            return isRed ? (10, 7) : (0, 3)
        }
        
    }
    
    enum Kind {
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
        
        self.color = first.isLowercase ? .blue : .red
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
        return (color == .red ? letter.uppercased() : letter) + cooldown
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

enum Mana {
    case regular(color: Color), superMana
    
    init?(fen: String) {
        switch fen {
        case "U": self = .superMana
        case "M": self = .regular(color: .red)
        case "m": self = .regular(color: .blue)
        default: return nil
        }
    }
    
    var fen: String {
        switch self {
        case let .regular(color: color):
            return color == .red ? "M" : "m"
        case .superMana:
            return "U"
        }
    }
}

enum Consumable {
    case potion
    
    init?(fen: String) {
        switch fen {
        case "P": self = .potion
        default: return nil
        }
    }
    
    var fen: String {
        switch self {
        case .potion: return "P"
        }
    }
}

extension Bool {
    
    init?(fen: String) {
        switch fen {
        case "1":
            self = true
        case "0":
            self = false
        default:
            return nil
        }
    }
    
    var fen: String {
        if self {
            return "1"
        } else {
            return "0"
        }
    }
    
}
