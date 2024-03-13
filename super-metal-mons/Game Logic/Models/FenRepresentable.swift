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
        var components = fen.split(separator: " ")
        switch components.removeFirst() {
        case "mm":
            guard components.count == 3,
                  let item = Item(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .monMove(item: item, from: from, to: to)
        case "mma":
            guard components.count == 3,
                  let mana = Mana(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .manaMove(mana: mana, from: from, to: to)
        case "ms":
            guard components.count == 2,
                  let mana = Mana(fen: String(components[0])),
                  let at = Location(fen: String(components[1])) else { return nil }
            self = .manaScored(mana: mana, at: at)
        case "ma":
            guard components.count == 3,
                  let item = Mon(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .mysticAction(mystic: item, from: from, to: to)
        case "da":
            guard components.count == 3,
                  let item = Mon(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .demonAction(demon: item, from: from, to: to)
        case "das":
            guard components.count == 3,
                  let item = Mon(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .demonAdditionalStep(demon: item, from: from, to: to)
        case "stm":
            guard components.count == 3,
                  let item = Item(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .spiritTargetMove(item: item, from: from, to: to)
        case "pb":
            guard components.count == 2,
                  let item = Mon(fen: String(components[0])),
                  let at = Location(fen: String(components[1])) else { return nil }
            self = .pickupBomb(by: item, at: at)
        case "pp":
            guard components.count == 2,
                  let item = Item(fen: String(components[0])),
                  let at = Location(fen: String(components[1])) else { return nil }
            self = .pickupPotion(by: item, at: at)
        case "pm":
            guard components.count == 3,
                  let mana = Mana(fen: String(components[0])),
                  let by = Mon(fen: String(components[1])),
                  let at = Location(fen: String(components[2])) else { return nil }
            self = .pickupMana(mana: mana, by: by, at: at)
        case "mf":
            guard components.count == 3,
                  let item = Mon(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .monFainted(mon: item, from: from, to: to)
        case "md":
            guard components.count == 2,
                  let mana = Mana(fen: String(components[0])),
                  let at = Location(fen: String(components[1])) else { return nil }
            self = .manaDropped(mana: mana, at: at)
        case "sb":
            guard components.count == 2,
                  let from = Location(fen: String(components[0])),
                  let to = Location(fen: String(components[1])) else { return nil }
            self = .supermanaBackToBase(from: from, to: to)
        case "ba":
            guard components.count == 3,
                  let item = Mon(fen: String(components[0])),
                  let from = Location(fen: String(components[1])),
                  let to = Location(fen: String(components[2])) else { return nil }
            self = .bombAttack(by: item, from: from, to: to)
        case "maw":
            guard components.count == 2,
                  let item = Mon(fen: String(components[0])),
                  let at = Location(fen: String(components[1])) else { return nil }
            self = .monAwake(mon: item, at: at)
        case "be":
            guard components.count == 1,
                  let at = Location(fen: String(components[0])) else { return nil }
            self = .bombExplosion(at: at)
        case "nt":
            guard components.count == 1,
                  let color = Color(fen: String(components[0])) else { return nil }
            self = .nextTurn(color: color)
        case "go":
            guard components.count == 1,
                  let color = Color(fen: String(components[0])) else { return nil }
            self = .gameOver(winner: color)
        default:
            return nil
        }
    }
    
    var fen: String {
        let components: [String]
        switch self {
        case .monMove(let item, let from, let to):
            components = ["mm", item.fen, from.fen, to.fen]
        case .manaMove(let mana, let from, let to):
            components = ["mma", mana.fen, from.fen, to.fen]
        case .manaScored(let mana, let at):
            components = ["ms", mana.fen, at.fen]
        case .mysticAction(let mystic, let from, let to):
            components = ["ma", mystic.fen, from.fen, to.fen]
        case .demonAction(let demon, let from, let to):
            components = ["da", demon.fen, from.fen, to.fen]
        case .demonAdditionalStep(let demon, let from, let to):
            components = ["das", demon.fen, from.fen, to.fen]
        case .spiritTargetMove(let item, let from, let to):
            components = ["stm", item.fen, from.fen, to.fen]
        case .pickupBomb(let by, let at):
            components = ["pb", by.fen, at.fen]
        case .pickupPotion(let by, let at):
            components = ["pp", by.fen, at.fen]
        case .pickupMana(let mana, let by, let at):
            components = ["pm", mana.fen, by.fen, at.fen]
        case .monFainted(let mon, let from, let to):
            components = ["mf", mon.fen, from.fen, to.fen]
        case .manaDropped(let mana, let at):
            components = ["md", mana.fen, at.fen]
        case .supermanaBackToBase(let from, let to):
            components = ["sb", from.fen, to.fen]
        case .bombAttack(let by, let from, let to):
            components = ["ba", by.fen, from.fen, to.fen]
        case .monAwake(let mon, let at):
            components = ["maw", mon.fen, at.fen]
        case .bombExplosion(let at):
            components = ["be", at.fen]
        case .nextTurn(let color):
            components = ["nt", color.fen]
        case .gameOver(let winner):
            components = ["go", winner.fen]
        }
        return components.joined(separator: " ")
    }
    
}

extension NextInput: FenRepresentable {
    
    init?(fen: String) {
        let components = fen.split(separator: " ")
        guard components.count == 3 else { return nil }
        if let input = Input(fen: String(components[0])), let kind = NextInput.Kind(fen: String(components[1])) {
            self.input = input
            self.kind = kind
            self.actorMonItem = Item(fen: String(components[2]))
        } else {
            return nil
        }
    }
    
    var fen: String {
        return [input.fen, kind.fen, actorMonItem?.fen ?? "o"].joined(separator: " ")
    }
    
}

extension NextInput.Kind: FenRepresentable {
    
    init?(fen: String) {
        switch fen {
        case "mm":
            self = .monMove
        case "mma":
            self = .manaMove
        case "ma":
            self = .mysticAction
        case "da":
            self = .demonAction
        case "das":
            self = .demonAdditionalStep
        case "stc":
            self = .spiritTargetCapture
        case "stm":
            self = .spiritTargetMove
        case "sc":
            self = .selectConsumable
        case "ba":
            self = .bombAttack
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .monMove:
            return "mm"
        case .manaMove:
            return "mma"
        case .mysticAction:
            return "ma"
        case .demonAction:
            return "da"
        case .demonAdditionalStep:
            return "das"
        case .spiritTargetCapture:
            return "stc"
        case .spiritTargetMove:
            return "stm"
        case .selectConsumable:
            return "sc"
        case .bombAttack:
            return "ba"
        }
    }
    
}

extension Location: FenRepresentable {
    
    init?(fen: String) {
        let components = fen.split(separator: ",")
        guard components.count == 2 else { return nil }
        if let i = Int(components[0]), let j = Int(components[1]) {
            self.i = i
            self.j = j
        } else {
            return nil
        }
    }
    
    var fen: String {
        return "\(i),\(j)"
    }
    
}

extension Input.Modifier: FenRepresentable {
    
    init?(fen: String) {
        switch fen {
        case "p":
            self = .selectPotion
        case "b":
            self = .selectBomb
        case "c":
            self = .cancel
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .selectPotion:
            return "p"
        case .selectBomb:
            return "b"
        case .cancel:
            return "c"
        }
    }
    
}

extension Input: FenRepresentable {
    
    init?(fen: String) {
        switch fen.first {
        case "l":
            if let location = Location(fen: String(fen.dropFirst())) {
                self = .location(location)
            } else {
                return nil
            }
        case "m":
            if let modifier = Modifier(fen: String(fen.dropFirst())) {
                self = .modifier(modifier)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .location(let location):
            return "l" + location.fen
        case .modifier(let modifier):
            return "m" + modifier.fen
        }
    }
    
}

extension Output: FenRepresentable {
    
    init?(fen: String) {
        switch fen.first {
        case "i":
            self = .invalidInput
        case "l":
            let fens = fen.dropFirst().split(separator: "/")
            let locations = fens.compactMap { Location(fen: String($0)) }
            if locations.count == fens.count {
                self = .locationsToStartFrom(locations)
            } else {
                return nil
            }
        case "n":
            let fens = fen.dropFirst().split(separator: "/")
            let nextInputs = fens.compactMap { NextInput(fen: String($0)) }
            if nextInputs.count == fens.count {
                self = .nextInputOptions(nextInputs)
            } else {
                return nil
            }
        case "e":
            let fens = fen.dropFirst().split(separator: "/")
            let events = fens.compactMap { Event(fen: String($0)) }
            if events.count == fens.count {
                self = .events(events)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    var fen: String {
        switch self {
        case .invalidInput:
            return "i"
        case .locationsToStartFrom(let locations):
            return "l" + locations.map { $0.fen }.sorted().joined(separator: "/")
        case .nextInputOptions(let nextInputOptions):
            return "n" + nextInputOptions.map { $0.fen }.sorted().joined(separator: "/")
        case .events(let events):
            return "e" + events.map { $0.fen }.sorted().joined(separator: "/")
        }
    }
    
}

extension Array where Element == Input {
    
    var fen: String {
        return map { $0.fen }.joined(separator: ";")
    }
    
    init?(fen: String) {
        let fens = fen.split(separator: ";")
        let inputs = fens.compactMap { Input(fen: String($0)) }
        if fens.count == inputs.count {
            self = inputs
        } else {
            return nil
        }
    }
    
}
