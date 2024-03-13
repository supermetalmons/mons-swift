// ∅ 2024 super-metal-mons

import Foundation

protocol FenRepresentable {
    
    var fen: String { get }
    
}

extension MonsGame: FenRepresentable {
    
    convenience init?(fen: String) {
        let fields = fen.split(separator: " ")
        guard fields.count == 10,
              let whiteScore = Int(fields[0]),
              let blackScore = Int(fields[1]),
              let activeColor = Color(fen: String(fields[2])),
              let actionsUsedCount = Int(fields[3]),
              let manaMovesCount = Int(fields[4]),
              let monsMovesCount = Int(fields[5]),
              let whitePotionsCount = Int(fields[6]),
              let blackPotionsCount = Int(fields[7]),
              let turnNumber = Int(fields[8]),
              let board = Board(fen: String(fields[9]))
        else { return nil }
        
        self.init(board: board, whiteScore: whiteScore, blackScore: blackScore, activeColor: activeColor, actionsUsedCount: actionsUsedCount, manaMovesCount: manaMovesCount, monsMovesCount: monsMovesCount, whitePotionsCount: whitePotionsCount, blackPotionsCount: blackPotionsCount, turnNumber: turnNumber)
    }
    
    var fen: String {
        let fields = [
            String(whiteScore),
            String(blackScore),
            activeColor.fen,
            String(actionsUsedCount),
            String(manaMovesCount),
            String(monsMovesCount),
            String(whitePotionsCount),
            String(blackPotionsCount),
            String(turnNumber),
            board.fen
        ]
        return fields.joined(separator: " ")
    }
    
}

extension Item: FenRepresentable {
    
    init?(fen: String) {
        guard !fen.isEmpty else { return nil }
        guard fen.count == 3 else { return nil }
        
        let itemFen = String(fen.suffix(1))
        var mana: Mana? = nil
        var consumable: Consumable? = nil
        
        if let item = Mana(fen: itemFen) {
            mana = item
        } else if let item = Consumable(fen: itemFen) {
            consumable = item
        }
        
        let monFen = String(fen.prefix(2))
        if monFen != "xx" {
            guard let mon = Mon(fen: monFen) else { return nil }
            if let mana = mana {
                self = .monWithMana(mon: mon, mana: mana)
            } else if let consumable = consumable {
                self = .monWithConsumable(mon: mon, consumable: consumable)
            } else {
                self = .mon(mon: mon)
            }
        } else if let mana = mana {
            self = .mana(mana: mana)
        } else if let consumable = consumable {
            self = .consumable(consumable: consumable)
        } else {
            return nil
        }
        
    }
    
    var fen: String {
        var monFen = "xx"
        var itemFen = "x"
        switch self {
        case .mon(let mon):
            monFen = mon.fen
        case .mana(let mana):
            itemFen = mana.fen
        case .monWithMana(let mon, let mana):
            monFen = mon.fen
            itemFen = mana.fen
        case .monWithConsumable(let mon, let consumable):
            monFen = mon.fen
            itemFen = consumable.fen
        case .consumable(let consumable):
            itemFen = consumable.fen
        }
        return monFen + itemFen
    }
    
}

extension Board: FenRepresentable {
    
    var fen: String {
        var lines = [String]()
        var squares: [[Item?]] = Array(repeating: Array(repeating: nil, count: Config.boardSize), count: Config.boardSize)
        
        for location in items.keys {
            squares[location.i][location.j] = item(at: location)
        }
        
        for row in squares {
            var line = ""
            var emptySpaceCount = 0
            for item in row {
                let itemFen = item?.fen ?? ""
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
    
    convenience init?(fen: String) {
        let lines = fen.split(separator: "/")
        guard lines.count == Config.boardSize else { return nil }
        var items = [[Item?]]()
        
        for line in lines {
            guard !line.isEmpty else { return nil }
            var lineItems = [Item?]()
            var input = String(line)
            var prefix = input.prefix(3)
            while !prefix.isEmpty {
                input.removeFirst(3)
                
                if prefix.first == "n" {
                    guard let number = Int(prefix.dropFirst()) else { return nil }
                    lineItems.append(contentsOf: Array(repeating: nil, count: number))
                } else if let item = Item(fen: String(prefix)) {
                    lineItems.append(item)
                } else {
                    return nil
                }
                
                prefix = input.prefix(3)
            }
            items.append(lineItems)
        }
        
        var dict = [Location: Item]()
        for (i, line) in items.enumerated() {
            for (j, item) in line.enumerated() {
                if let item = item {
                    dict[Location(i, j)] = item
                }
            }
        }
        self.init(items: dict)
    }
    
}

extension Mon: FenRepresentable {
    init?(fen: String) {
        guard fen.count == 2, let first = fen.first, let last = fen.last, let cooldown = Int(String(last)) else { return nil }
        
        let kind: Kind
        switch first.lowercased() {
        case "e": kind = .demon
        case "d": kind = .drainer
        case "a": kind = .angel
        case "s": kind = .spirit
        case "y": kind = .mystic
        default: return nil
        }
        
        let color: Color = first.isLowercase ? .black : .white
        self.init(kind: kind, color: color, cooldown: cooldown)
        
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
}

extension Mana: FenRepresentable {
    init?(fen: String) {
        switch fen {
        case "U": self = .supermana
        case "M": self = .regular(color: .white)
        case "m": self = .regular(color: .black)
        default: return nil
        }
    }
    
    var fen: String {
        switch self {
        case let .regular(color: color):
            return color == .white ? "M" : "m"
        case .supermana:
            return "U"
        }
    }
}

extension Color: FenRepresentable {
    
    init?(fen: String) {
        switch fen {
        case "w":
            self = .white
        case "b":
            self = .black
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .white: return "w"
        case .black: return "b"
        }
    }
    
}

extension Consumable: FenRepresentable {
    
    init?(fen: String) {
        switch fen {
        case "P": self = .potion
        case "B": self = .bomb
        case "Q": self = .bombOrPotion
        default: return nil
        }
    }
    
    var fen: String {
        switch self {
        case .potion: return "P"
        case .bomb: return "B"
        case .bombOrPotion: return "Q"
        }
    }
    
}

extension Event: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}

extension NextInput: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}

extension NextInput.Kind: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}

extension Location: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}

extension Input.Modifier: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}

extension Input: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}

extension Output: FenRepresentable {
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
    var fen: String {
        // TODO: implement
        return ""
    }
    
}
