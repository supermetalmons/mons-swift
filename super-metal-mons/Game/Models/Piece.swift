// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Piece {
    case mon(mon: Mon)
    case mana(mana: Mana)
    case monWithMana(mon: Mon, mana: Mana)
    case consumable(consumable: Consumable)
    case none
    
    init?(fen: String) {
        guard !fen.isEmpty else {
            self = .none
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
        case .none:
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

extension Array<Array<Piece>> {
    
    init?(fen: String) {
        let lines = fen.split(separator: "/")
        guard lines.count == 11 else { return nil }
        var pieces = [[Piece]]()
        
        for line in lines {
            guard !line.isEmpty else { return nil }
            var linePieces = [Piece]()
            var input = String(line)
            var prefix = input.prefix(3)
            while !prefix.isEmpty {
                input.removeFirst(3)
                
                if prefix.first == "n" {
                    guard let number = Int(prefix.dropFirst()) else { return nil }
                    let emptySpaces = (0..<number).map { _ in Piece.none }
                    linePieces.append(contentsOf: emptySpaces)
                } else if let piece = Piece(fen: String(prefix)) {
                    linePieces.append(piece)
                } else {
                    return nil
                }
                
                prefix = input.prefix(3)
            }
            pieces.append(linePieces)
        }
        
        self = pieces
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
