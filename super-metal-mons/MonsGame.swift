// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

class MonsGame {
    let version: Int
    
    let redScore: Int
    let blueScore: Int
    
    let activeColor: Color
    let actionUsed: Bool
    let manaMoved: Bool
    let monsMovesCount: Int
    
    let redPotionsCount: Int
    let bluePotionsCount: Int
    
    let turnNumber: Int
    var board: [[Space]]
    
    init() {
        self.version = 1
        self.redScore = 0
        self.blueScore = 0
        self.activeColor = .red
        self.actionUsed = false
        self.manaMoved = false
        self.monsMovesCount = 0
        self.redPotionsCount = 0
        self.bluePotionsCount = 0
        self.turnNumber = 1
        self.board = [
            [.empty, .empty, .empty,
             .mon(mon: Mon(kind: .mystic, color: .blue)),
             .mon(mon: Mon(kind: .spirit, color: .blue)),
             .mon(mon: Mon(kind: .drainer, color: .blue)),
             .mon(mon: Mon(kind: .angel, color: .blue)),
             .mon(mon: Mon(kind: .demon, color: .blue)),
             .empty, .empty, .empty],
            
            [.empty, .empty,  .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty],
            [.empty, .empty,  .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty],
            
            [.empty, .empty,  .empty, .empty,
             .mana(mana: .regular(color: .blue)),
             .empty,
             .mana(mana: .regular(color: .blue)),
             .empty, .empty, .empty, .empty],
            
            [.empty, .empty,  .empty,
             .mana(mana: .regular(color: .blue)),
             .empty,
             .mana(mana: .regular(color: .blue)),
             .empty,
             .mana(mana: .regular(color: .blue)),
             .empty, .empty, .empty],
            
            [.consumable(consumable: .potion),
             .empty,  .empty, .empty, .empty,
             .mana(mana: .superMana),
             .empty, .empty, .empty, .empty,
             .consumable(consumable: .potion)],
            
            [.empty, .empty,  .empty,
             .mana(mana: .regular(color: .red)),
             .empty,
             .mana(mana: .regular(color: .red)),
             .empty,
             .mana(mana: .regular(color: .red)),
             .empty, .empty, .empty],
            
            [.empty, .empty,  .empty, .empty,
             .mana(mana: .regular(color: .red)),
             .empty,
             .mana(mana: .regular(color: .red)),
             .empty, .empty, .empty, .empty],
            
            [.empty, .empty,  .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty],
            [.empty, .empty,  .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty],
            
            [.empty, .empty, .empty,
             .mon(mon: Mon(kind: .demon, color: .red)),
             .mon(mon: Mon(kind: .angel, color: .red)),
             .mon(mon: Mon(kind: .drainer, color: .red)),
             .mon(mon: Mon(kind: .spirit, color: .red)),
             .mon(mon: Mon(kind: .mystic, color: .red)),
             .empty, .empty, .empty],
        ]
    }
    
    init?(fen: String) {
        let fields = fen.split(separator: " ")
        guard fields.count == 11,
              let version = Int(fields[0]),
              let redScore = Int(fields[1]),
              let blueScore = Int(fields[2]),
              let activeColor = Color(fen: String(fields[3])),
              let actionUsed = Bool(fen: String(fields[4])),
              let manaMoved = Bool(fen: String(fields[5])),
              let monsMovesCount = Int(fields[6]),
              let redPotionsCount = Int(fields[7]),
              let bluePotionsCount = Int(fields[8]),
              let turnNumber = Int(fields[9]),
              let board = [[Space]](fen: String(fields[10]))
        else { return nil }
        
        self.version = version
        self.redScore = redScore
        self.blueScore = blueScore
        self.activeColor = activeColor
        self.actionUsed = actionUsed
        self.manaMoved = manaMoved
        self.monsMovesCount = monsMovesCount
        self.redPotionsCount = redPotionsCount
        self.bluePotionsCount = bluePotionsCount
        self.turnNumber = turnNumber
        self.board = board
    }
    
    // TODO: implement better
    func move(from: (Int, Int), to: (Int, Int)) {
        board[to.0][to.1] = board[from.0][from.1]
        board[from.0][from.1] = .empty
    }
    
    func endTurn() {
        // TODO: implement
    }
    
    var isGameOver: Bool {
        return redScore == 5 || blueScore == 5
    }
    
    var fen: String {
        let fields = [
            String(version),
            String(redScore),
            String(blueScore),
            activeColor.fen,
            actionUsed.fen,
            manaMoved.fen,
            String(monsMovesCount),
            String(redPotionsCount),
            String(bluePotionsCount),
            String(turnNumber),
            board.fen
        ]
        return fields.joined(separator: " ")
    }
}

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
    
    enum Kind {
        case demon, drainer, angel, spirit, mystic
    }
    
    let kind: Kind
    let color: Color
    let isFainted: Bool
    
    init(kind: Kind, color: Color) {
        self.kind = kind
        self.color = color
        self.isFainted = false
    }
    
    init?(fen: String) {
        guard fen.count == 2, let first = fen.first, let last = fen.last else { return nil }
        
        switch first.lowercased() {
        case "e": self.kind = .demon
        case "d": self.kind = .drainer
        case "a": self.kind = .angel
        case "s": self.kind = .spirit
        case "y": self.kind = .mystic
        default: return nil
        }
        
        self.color = first.isLowercase ? .blue : .red
        
        switch last {
        case "f": self.isFainted = true
        case "o": self.isFainted = false
        default: return nil
        }
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
        let modifier = isFainted ? "f" : "o"
        return (color == .red ? letter.uppercased() : letter) + modifier
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


/*
 
 

import { Chess } from 'chess.js'

const chess = new Chess()

while (!chess.isGameOver()) {
  const moves = chess.moves()
  const move = moves[Math.floor(Math.random() * moves.length)]
  chess.move(move)
}
console.log(chess.pgn())


This library includes two parsers (permissive and strict) which are used to parse different forms of chess move notation. The permissive parser (the default) is able to handle many derivates of algebraic notation (e.g. Nf3, g1f3, g1-f3, Ng1f3, Ng1-f3, Ng1xf3). The strict parser only accepts moves in Standard Algebraic Notation and requires that they strictly adhere to the specification. The strict parser runs slightly faster but is much less forgiving of non-standard notation.

// board defaults to the starting position when called with no parameters
const chess = new Chess()

// pass in a FEN string to load a particular position
const chess = new Chess(
  'r1k4r/p2nb1p1/2b4p/1p1n1p2/2PP4/3Q1NB1/1P3PPP/R5K1 b - - 0 19'
)


 const chess = new Chess()

 // make some moves
 chess.move('e4')
 chess.move('e5')
 chess.move('f4')
 
 
 chess.ascii()
 // -> '   +------------------------+
 //      8 | .  n  b  q  .  .  .  r |
 //      7 | p  .  .  p  .  p  .  p |
 //      6 | .  .  .  .  .  .  .  . |
 //      5 | .  .  .  .  p  .  .  . |
 //      4 | .  .  .  .  P  P  .  . |
 //      3 | .  .  .  .  .  .  .  . |
 //      2 | P  P  P  P  .  .  P  P |
 //      1 | R  N  B  .  K  B  N  R |
 //        +------------------------+
 //          a  b  c  d  e  f  g  h'
 

 .board()

 Returns an 2D array representation of the current position. Empty squares are represented by null.

 const chess = new Chess()

 chess.board()
 // -> [[{square: 'a8', type: 'r', color: 'b'},
         {square: 'b8', type: 'n', color: 'b'},
         {square: 'c8', type: 'b', color: 'b'},
         {square: 'd8', type: 'q', color: 'b'},
         {square: 'e8', type: 'k', color: 'b'},
         {square: 'f8', type: 'b', color: 'b'},
         {square: 'g8', type: 'n', color: 'b'},
         {square: 'h8', type: 'r', color: 'b'}],
         [...],
         [...],
         [...],
         [...],
         [...],
         [{square: 'a1', type: 'r', color: 'w'},
          {square: 'b1', type: 'n', color: 'w'},
          {square: 'c1', type: 'b', color: 'w'},
          {square: 'd1', type: 'q', color: 'w'},
          {square: 'e1', type: 'k', color: 'w'},
          {square: 'f1', type: 'b', color: 'w'},
          {square: 'g1', type: 'n', color: 'w'},
          {square: 'h1', type: 'r', color: 'w'}]]
 .clear()

 Clears the board.

 chess.clear()
 chess.fen()
 // -> '8/8/8/8/8/8/8/8 w - - 0 1' <- empty board
 .deleteComment()

 Delete and return the comment for the current position, if it exists.

 const chess = new Chess()

 chess.loadPgn('1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 {giuoco piano} *')

 chess.getComment()
 // -> "giuoco piano"

 chess.deleteComment()
 // -> "giuoco piano"

 chess.getComment()
 // -> undefined
 .deleteComments()

 Delete and return comments for all positions.

 const chess = new Chess()

 chess.loadPgn(
   "1. e4 e5 {king's pawn opening} 2. Nf3 Nc6 3. Bc4 Bc5 {giuoco piano} *"
 )

 chess.deleteComments()
 // -> [
 //     {
 //       fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2",
 //       comment: "king's pawn opening"
 //     },
 //     {
 //       fen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
 //       comment: "giuoco piano"
 //     }
 //    ]

 chess.getComments()
 // -> []
 .fen()

 Returns the FEN string for the current position. Note, the en passant square is only included if the side-to-move can legally capture en passant.

 const chess = new Chess()

 // make some moves
 chess.move('e4')
 chess.move('e5')
 chess.move('f4')

 chess.fen()
 // -> 'rnbqkbnr/pppp1ppp/8/4p3/4PP2/8/PPPP2PP/RNBQKBNR b KQkq - 0 2'
 .get(square)

 Returns the piece on the square:

 chess.clear()
 chess.put({ type: chess.PAWN, color: chess.BLACK }, 'a5') // put a black pawn on a5

 chess.get('a5')
 // -> { type: 'p', color: 'b' },
 chess.get('a6')
 // -> null
 .getComment()

 Retrieve the comment for the current position, if it exists.

 const chess = new Chess()

 chess.loadPgn('1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 {giuoco piano} *')

 chess.getComment()
 // -> "giuoco piano"
 .getComments()

 Retrieve comments for all positions.

 const chess = new Chess()

 chess.loadPgn(
   "1. e4 e5 {king's pawn opening} 2. Nf3 Nc6 3. Bc4 Bc5 {giuoco piano} *"
 )

 chess.getComments()
 // -> [
 //     {
 //       fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2",
 //       comment: "king's pawn opening"
 //     },
 //     {
 //       fen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
 //       comment: "giuoco piano"
 //     }
 //    ]
 .header()

 Allows header information to be added to PGN output. Any number of key/value pairs can be passed to .header().

 chess.header('White', 'Robert James Fischer')
 chess.header('Black', 'Mikhail Tal')

 // or

 chess.header('White', 'Morphy', 'Black', 'Anderssen', 'Date', '1858-??-??')
 Calling .header() without any arguments returns the header information as an object.

 chess.header()
 // -> { White: 'Morphy', Black: 'Anderssen', Date: '1858-??-??' }
 .history([ options ])

 Returns a list containing the moves of the current game. Options is an optional parameter which may contain a 'verbose' flag. See .moves() for a description of the verbose move fields. A FEN string of the position prior to the move being made is added to the verbose history output.

 const chess = new Chess()
 chess.move('e4')
 chess.move('e5')
 chess.move('f4')
 chess.move('exf4')

 chess.history()
 // -> ['e4', 'e5', 'f4', 'exf4']

 chess.history({ verbose: true })
 // -->
 // [
 //   {
 //     before: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
 //     after: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
 //     color: 'w',
 //     piece: 'p',
 //     from: 'e2',
 //     to: 'e4',
 //     san: 'e4',
 //     lan: 'e2e4',
 //     flags: 'b'
 //   },
 //   {
 //     before: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
 //     after: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
 //     color: 'b',
 //     piece: 'p',
 //     from: 'e7',
 //     to: 'e5',
 //     san: 'e5',
 //     lan: 'e7e5',
 //     flags: 'b'
 //   },
 //   {
 //     before: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
 //     after: 'rnbqkbnr/pppp1ppp/8/4p3/4PP2/8/PPPP2PP/RNBQKBNR b KQkq - 0 2',
 //     color: 'w',
 //     piece: 'p',
 //     from: 'f2',
 //     to: 'f4',
 //     san: 'f4',
 //     lan: 'f2f4',
 //     flags: 'b'
 //   },
 //   {
 //     before: 'rnbqkbnr/pppp1ppp/8/4p3/4PP2/8/PPPP2PP/RNBQKBNR b KQkq - 0 2',
 //     after: 'rnbqkbnr/pppp1ppp/8/8/4Pp2/8/PPPP2PP/RNBQKBNR w KQkq - 0 3',
 //     color: 'b',
 //     piece: 'p',
 //     from: 'e5',
 //     to: 'f4',
 //     san: 'exf4',
 //     lan: 'e5f4',
 //     flags: 'c',
 //     captured: 'p'
 //   }
 // ]
 .inCheck()

 Returns true or false if the side to move is in check.

 const chess = new Chess(
   'rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3'
 )
 chess.inCheck()
 // -> true
 .isAttacked(square, color)

 Returns true if the square is attacked by any piece of the given color.

 const chess = new Chess()
 chess.isAttacked('f3', Chess.WHITE)
 // -> true (we can attack empty squares)

 chess.isAttacked('f6', Chess.BLACK)
 // -> true (side to move (e.g. the value returned by .turn) is ignored)

 chess.load(Chess.DEFAULT_POSITION)
 chess.isAttacked('e2', Chess.WHITE)
 // -> true (we can attack our own pieces)

 chess.load('4k3/4n3/8/8/8/8/4R3/4K3 w - - 0 1')
 chess.isAttacked('c6', Chess.BLACK)
 // -> true (pieces still attack a square if even they are pinned)
 .isCheckmate()

 Returns true or false if the side to move has been checkmated.

 const chess = new Chess(
   'rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3'
 )
 chess.isCheckmate()
 // -> true
 .isDraw()

 Returns true or false if the game is drawn (50-move rule or insufficient material).

 const chess = new Chess('4k3/4P3/4K3/8/8/8/8/8 b - - 0 78')
 chess.isDraw()
 // -> true
 .isInsufficientMaterial()

 Returns true if the game is drawn due to insufficient material (K vs. K, K vs. KB, or K vs. KN) otherwise false.

 const chess = new Chess('k7/8/n7/8/8/8/8/7K b - - 0 1')
 chess.isInsufficientMaterial()
 // -> true
 .isGameOver()

 Returns true if the game has ended via checkmate, stalemate, draw, threefold repetition, or insufficient material. Otherwise, returns false.

 const chess = new Chess()
 chess.isGameOver()
 // -> false

 // stalemate
 chess.load('4k3/4P3/4K3/8/8/8/8/8 b - - 0 78')
 chess.isGameOver()
 // -> true

 // checkmate
 chess.load('rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3')
 chess.isGameOver()
 // -> true
 .isStalemate()

 Returns true or false if the side to move has been stalemated.

 const chess = new Chess('4k3/4P3/4K3/8/8/8/8/8 b - - 0 78')
 chess.isStalemate()
 // -> true
 .isThreefoldRepetition()

 Returns true or false if the current board position has occurred three or more times.

 const chess = new Chess('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
 // -> true
 // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq occurs 1st time
 chess.isThreefoldRepetition()
 // -> false

 chess.move('Nf3') chess.move('Nf6') chess.move('Ng1') chess.move('Ng8')
 // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq occurs 2nd time
 chess.isThreefoldRepetition()
 // -> false

 chess.move('Nf3') chess.move('Nf6') chess.move('Ng1') chess.move('Ng8')
 // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq occurs 3rd time
 chess.isThreefoldRepetition()
 // -> true
 .load(fen)

 Clears the board and loads the provided FEN string. The castling rights, en passant square and move numbers are defaulted to - - 0 1 if ommitted. Throws an exception if the FEN is invalid.

 const chess = new Chess()
 chess.load('4r3/8/2p2PPk/1p6/pP2p1R1/P1B5/2P2K2/3r4 w - - 1 45')

 try {
   chess.load('4r3/8/X12XPk/1p6/pP2p1R1/P1B5/2P2K2/3r4 w - - 1 45')
 } catch (e) {
   console.log(e)
 }
 // -> Error: Invalid FEN: piece data is invalid (invalid piece)
 .loadPgn(pgn, [ options ])

 Load the moves of a game stored in Portable Game Notation. pgn should be a string. Options is an optional object which may contain a string newlineChar and a boolean strict.

 The newlineChar is a string representation of a valid RegExp fragment and is used to process the PGN. It defaults to \r?\n. Special characters should not be pre-escaped, but any literal special characters should be escaped as is normal for a RegExp. Keep in mind that backslashes in JavaScript strings must themselves be escaped (see sloppyPgn example below). Avoid using a newlineChar that may occur elsewhere in a PGN, such as . or x, as this will result in unexpected behavior.

 The strict flag is a boolean (default: false) that instructs chess.js to only parse moves in Standard Algebraic Notation form. See .move documentation for more information about non-SAN notations.

 The method will throw and exception if the PGN fails to parse.

 const chess = new Chess()
 const pgn = [
   '[Event "Casual Game"]',
   '[Site "Berlin GER"]',
   '[Date "1852.??.??"]',
   '[EventDate "?"]',
   '[Round "?"]',
   '[Result "1-0"]',
   '[White "Adolf Anderssen"]',
   '[Black "Jean Dufresne"]',
   '[ECO "C52"]',
   '[WhiteElo "?"]',
   '[BlackElo "?"]',
   '[PlyCount "47"]',
   '',
   '1.e4 e5 2.Nf3 Nc6 3.Bc4 Bc5 4.b4 Bxb4 5.c3 Ba5 6.d4 exd4 7.O-O',
   'd3 8.Qb3 Qf6 9.e5 Qg6 10.Re1 Nge7 11.Ba3 b5 12.Qxb5 Rb8 13.Qa4',
   'Bb6 14.Nbd2 Bb7 15.Ne4 Qf5 16.Bxd3 Qh5 17.Nf6+ gxf6 18.exf6',
   'Rg8 19.Rad1 Qxf3 20.Rxe7+ Nxe7 21.Qxd7+ Kxd7 22.Bf5+ Ke8',
   '23.Bd7+ Kf8 24.Bxe7# 1-0',
 ]

 chess.loadPgn(pgn.join('\n'))

 chess.ascii()
 // -> '  +------------------------+
 //     8 | .  r  .  .  .  k  r  . |
 //     7 | p  b  p  B  B  p  .  p |
 //     6 | .  b  .  .  .  P  .  . |
 //     5 | .  .  .  .  .  .  .  . |
 //     4 | .  .  .  .  .  .  .  . |
 //     3 | .  .  P  .  .  q  .  . |
 //     2 | P  .  .  .  .  P  P  P |
 //     1 | .  .  .  R  .  .  K  . |
 //       +------------------------+
 //         a  b  c  d  e  f  g  h'

 // Parse non-standard move formats and unusual line separators
 const sloppyPgn = [
   '[Event "Wijk aan Zee (Netherlands)"]',
   '[Date "1971.01.26"]',
   '[Result "1-0"]',
   '[White "Tigran Vartanovich Petrosian"]',
   '[Black "Hans Ree"]',
   '[ECO "A29"]',
   '',
   '1. Pc2c4 Pe7e5', // non-standard
   '2. Nc3 Nf6',
   '3. Nf3 Nc6',
   '4. g2g3 Bb4', // non-standard
   '5. Nd5 Nxd5',
   '6. c4xd5 e5-e4', // non-standard
   '7. dxc6 exf3',
   '8. Qb3 1-0',
 ].join(':')

 chess.loadPgn(sloppyPgn, { newlineChar: ':' })
 // works by default

 chess.loadPgn(sloppyPgn, { newlineChar: ':', strict: true })
 // Error: Invalid move in PGN: Pc2c4
 .move(move, [ options ])

 Makes a move on the board and returns a move object if the move was legal. The move argument can be either a string in Standard Algebraic Notation (SAN) or a move object. Throws an 'Illegal move' exception if the move was illegal.

 .move() - Standard Algebraic Notation (SAN)

 const chess = new Chess()

 chess.move('e4')
 // -> { color: 'w', from: 'e2', to: 'e4', flags: 'b', piece: 'p', san: 'e4' }

 chess.move('nf6') // SAN is case sensitive!!
 // Error: Invalid move: nf6

 chess.move('Nf6')
 // -> { color: 'b', from: 'g8', to: 'f6', flags: 'n', piece: 'n', san: 'Nf6' }
 .move() - Object Notation

 A move object contains to, from and, promotion (only when necessary) fields.

 const chess = new Chess()

 chess.move({ from: 'g2', to: 'g3' })
 // -> { color: 'w', from: 'g2', to: 'g3', flags: 'n', piece: 'p', san: 'g3' }
 .move() - Permissive Parser

 The permissive (default) move parser can be used to parse a variety of non-standard move notations. Users may specify an { strict: true } flag to verify that all supplied moves adhere to the Standard Algebraic Notation specification.

 const chess = new Chess()

 // permissive parser accepts various forms of algebraic notation
 chess.move('e2e4')
 chess.move('e7-e5')
 chess.move('Pf2-f4')
 chess.move('ef4') // missing 'x' in capture
 chess.move('Ng1-f3')
 chess.move('d7xd6') // ignore 'x' when not a capture
 chess.move('d4')

 // correctly parses incorrectly disambiguated moves
 chess.load('r2qkbnr/ppp2ppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R b KQkq - 3 7')

 chess.move('Nge7') // Ne7 is unambiguous because the knight on c6 is pinned
 chess.undo()
 chess.move('Nge7', { strict: true }) // strict SAN requires Ne7
 // Error: Invalid move: Nge7
 .moves({ piece?: Piece, square?: Square, verbose?: Boolean }?)

 Returns a list of legal moves from the current position. This function takes an optional object which can be used to generate detailed move objects or to restrict the move generator to specific squares or pieces.

 const chess = new Chess()
 chess.moves()
 // -> ['a3', 'a4', 'b3', 'b4', 'c3', 'c4', 'd3', 'd4', 'e3', 'e4',
 //     'f3', 'f4', 'g3', 'g4', 'h3', 'h4', 'Na3', 'Nc3', 'Nf3', 'Nh3']

 chess.moves({ square: 'e2' }) // single square move generation
 // -> ['e3', 'e4']

 chess.moves({ piece: 'n' }) // generate moves for piece type
 // ['Na3', 'Nc3', 'Nf3', 'Nh3']

 chess.moves({ verbose: true }) // return verbose moves
 // -> [{ color: 'w', from: 'a2', to: 'a3',
 //       flags: 'n', piece: 'p',
 //       san 'a3', 'lan', 'a2a3',
 //       before: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
 //       after: 'rnbqkbnr/pppppppp/8/8/8/P7/1PPPPPPP/RNBQKBNR b KQkq - 0 1'
 //       # a `captured` field is included when the move is a capture
 //       # a `promotion` field is included when the move is a promotion
 //     },
 //     ...
 //     ]
 Move Objects (e.g. when { verbose: true })

 The color field indicates the color of the moving piece (w or b).

 The from and to fields are from and to squares in algebraic notation.

 The piece, captured, and promotion fields contain the lowercase representation of the applicable piece (pnbrqk). The captured and promotion fields are only present when the move is a valid capture or promotion.

 The san field is the move in Standard Algebraic Notation (SAN). The lan field is the move in Long Algebraic Notation (LAN).

 The before and after keys contain the FEN of the position before and after the move.

 The flags field contains one or more of the string values:

 n - a non-capture
 b - a pawn push of two squares
 e - an en passant capture
 c - a standard capture
 p - a promotion
 k - kingside castling
 q - queenside castling
 A flags value of pc would mean that a pawn captured a piece on the 8th rank and promoted.

 .pgn([ options ])

 Returns the game in PGN format. Options is an optional parameter which may include max width and/or a newline character settings.

 const chess = new Chess()
 chess.header('White', 'Plunky', 'Black', 'Plinkie')
 chess.move('e4')
 chess.move('e5')
 chess.move('Nc3')
 chess.move('Nc6')

 chess.pgn({ maxWidth: 5, newline: '<br />' })
 // -> '[White "Plunky"]<br />[Black "Plinkie"]<br /><br />1. e4 e5<br />2. Nc3 Nc6'
 .put(piece, square)

 Place a piece on the square where piece is an object with the form { type: ..., color: ... }. Returns true if the piece was successfully placed, otherwise, the board remains unchanged and false is returned. put() will fail when passed an invalid piece or square, or when two or more kings of the same color are placed.

 chess.clear()

 chess.put({ type: chess.PAWN, color: chess.BLACK }, 'a5') // put a black pawn on a5
 // -> true
 chess.put({ type: 'k', color: 'w' }, 'h1') // shorthand
 // -> true

 chess.fen()
 // -> '8/8/8/p7/8/8/8/7K w - - 0 0'

 chess.put({ type: 'z', color: 'w' }, 'a1') // invalid piece
 // -> false

 chess.clear()

 chess.put({ type: 'k', color: 'w' }, 'a1')
 // -> true

 chess.put({ type: 'k', color: 'w' }, 'h1') // fail - two kings
 // -> false
 .remove(square)

 Remove and return the piece on square.

 chess.clear()
 chess.put({ type: chess.PAWN, color: chess.BLACK }, 'a5') // put a black pawn on a5
 chess.put({ type: chess.KING, color: chess.WHITE }, 'h1') // put a white king on h1

 chess.remove('a5')
 // -> { type: 'p', color: 'b' },
 chess.remove('h1')
 // -> { type: 'k', color: 'w' },
 chess.remove('e1')
 // -> null
 .reset()

 Reset the board to the initial starting position.

 .setComment(comment)

 Comment on the current position.

 const chess = new Chess()

 chess.move('e4')
 chess.setComment("king's pawn opening")

 chess.pgn()
 // -> "1. e4 {king's pawn opening}"
 .squareColor(square)

 Returns the color of the square ('light' or 'dark').

 const chess = Chess()
 chess.squareColor('h1')
 // -> 'light'
 chess.squareColor('a7')
 // -> 'dark'
 chess.squareColor('bogus square')
 // -> null
 .turn()

 Returns the current side to move.

 chess.load('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1')
 chess.turn()
 // -> 'b'
 .undo()

 Takeback the last half-move, returning a move object if successful, otherwise null.

 const chess = new Chess()

 chess.fen()
 // -> 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
 chess.move('e4')
 chess.fen()
 // -> 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'

 chess.undo()
 //  {
 //    color: 'w',
 //    piece: 'p',
 //    from: 'e2',
 //    to: 'e4',
 //    san: 'e4',
 //    flags: 'b',
 //    lan: 'e2e4',
 //    before: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
 //    after: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'
 //  }

 chess.fen()
 // -> 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
 chess.undo()
 // -> null
 .validateFen(fen):

 Returns a validation object specifying validity or the errors found within the FEN string.

 chess.validateFen('2n1r3/p1k2pp1/B1p3b1/P7/5bP1/2N1B3/1P2KP2/2R5 b - - 4 25')
 // -> { ok: true }

 chess.validateFen('4r3/8/X12XPk/1p6/pP2p1R1/P1B5/2P2K2/3r4 w - - 1 45')
 // -> { ok: false,
 //     error: '1st field (piece positions) is invalid [invalid piece].' }
 
 
 
 ⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️
 
 
 
/**
 * @license
 * Copyright (c) 2023, Jeff Hlywa (jhlywa@gmail.com)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

export const WHITE = 'w'
export const BLACK = 'b'

export const PAWN = 'p'
export const KNIGHT = 'n'
export const BISHOP = 'b'
export const ROOK = 'r'
export const QUEEN = 'q'
export const KING = 'k'

export type Color = 'w' | 'b'
export type PieceSymbol = 'p' | 'n' | 'b' | 'r' | 'q' | 'k'

// prettier-ignore
export type Square =
    'a8' | 'b8' | 'c8' | 'd8' | 'e8' | 'f8' | 'g8' | 'h8' |
    'a7' | 'b7' | 'c7' | 'd7' | 'e7' | 'f7' | 'g7' | 'h7' |
    'a6' | 'b6' | 'c6' | 'd6' | 'e6' | 'f6' | 'g6' | 'h6' |
    'a5' | 'b5' | 'c5' | 'd5' | 'e5' | 'f5' | 'g5' | 'h5' |
    'a4' | 'b4' | 'c4' | 'd4' | 'e4' | 'f4' | 'g4' | 'h4' |
    'a3' | 'b3' | 'c3' | 'd3' | 'e3' | 'f3' | 'g3' | 'h3' |
    'a2' | 'b2' | 'c2' | 'd2' | 'e2' | 'f2' | 'g2' | 'h2' |
    'a1' | 'b1' | 'c1' | 'd1' | 'e1' | 'f1' | 'g1' | 'h1'

export const DEFAULT_POSITION =
  'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'

export type Piece = {
  color: Color
  type: PieceSymbol
}

type InternalMove = {
  color: Color
  from: number
  to: number
  piece: PieceSymbol
  captured?: PieceSymbol
  promotion?: PieceSymbol
  flags: number
}

interface History {
  move: InternalMove
  kings: Record<Color, number>
  turn: Color
  castling: Record<Color, number>
  epSquare: number
  halfMoves: number
  moveNumber: number
}

export type Move = {
  color: Color
  from: Square
  to: Square
  piece: PieceSymbol
  captured?: PieceSymbol
  promotion?: PieceSymbol
  flags: string
  san: string
  lan: string
  before: string
  after: string
}

const EMPTY = -1

const FLAGS: Record<string, string> = {
  NORMAL: 'n',
  CAPTURE: 'c',
  BIG_PAWN: 'b',
  EP_CAPTURE: 'e',
  PROMOTION: 'p',
  KSIDE_CASTLE: 'k',
  QSIDE_CASTLE: 'q',
}

// prettier-ignore
export const SQUARES: Square[] = [
  'a8', 'b8', 'c8', 'd8', 'e8', 'f8', 'g8', 'h8',
  'a7', 'b7', 'c7', 'd7', 'e7', 'f7', 'g7', 'h7',
  'a6', 'b6', 'c6', 'd6', 'e6', 'f6', 'g6', 'h6',
  'a5', 'b5', 'c5', 'd5', 'e5', 'f5', 'g5', 'h5',
  'a4', 'b4', 'c4', 'd4', 'e4', 'f4', 'g4', 'h4',
  'a3', 'b3', 'c3', 'd3', 'e3', 'f3', 'g3', 'h3',
  'a2', 'b2', 'c2', 'd2', 'e2', 'f2', 'g2', 'h2',
  'a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1'
]

const BITS: Record<string, number> = {
  NORMAL: 1,
  CAPTURE: 2,
  BIG_PAWN: 4,
  EP_CAPTURE: 8,
  PROMOTION: 16,
  KSIDE_CASTLE: 32,
  QSIDE_CASTLE: 64,
}

/*
 * NOTES ABOUT 0x88 MOVE GENERATION ALGORITHM
 * ----------------------------------------------------------------------------
 * From https://github.com/jhlywa/chess.js/issues/230
 *
 * A lot of people are confused when they first see the internal representation
 * of chess.js. It uses the 0x88 Move Generation Algorithm which internally
 * stores the board as an 8x16 array. This is purely for efficiency but has a
 * couple of interesting benefits:
 *
 * 1. 0x88 offers a very inexpensive "off the board" check. Bitwise AND (&) any
 *    square with 0x88, if the result is non-zero then the square is off the
 *    board. For example, assuming a knight square A8 (0 in 0x88 notation),
 *    there are 8 possible directions in which the knight can move. These
 *    directions are relative to the 8x16 board and are stored in the
 *    PIECE_OFFSETS map. One possible move is A8 - 18 (up one square, and two
 *    squares to the left - which is off the board). 0 - 18 = -18 & 0x88 = 0x88
 *    (because of two-complement representation of -18). The non-zero result
 *    means the square is off the board and the move is illegal. Take the
 *    opposite move (from A8 to C7), 0 + 18 = 18 & 0x88 = 0. A result of zero
 *    means the square is on the board.
 *
 * 2. The relative distance (or difference) between two squares on a 8x16 board
 *    is unique and can be used to inexpensively determine if a piece on a
 *    square can attack any other arbitrary square. For example, let's see if a
 *    pawn on E7 can attack E2. The difference between E7 (20) - E2 (100) is
 *    -80. We add 119 to make the ATTACKS array index non-negative (because the
 *    worst case difference is A8 - H1 = -119). The ATTACKS array contains a
 *    bitmask of pieces that can attack from that distance and direction.
 *    ATTACKS[-80 + 119=39] gives us 24 or 0b11000 in binary. Look at the
 *    PIECE_MASKS map to determine the mask for a given piece type. In our pawn
 *    example, we would check to see if 24 & 0x1 is non-zero, which it is
 *    not. So, naturally, a pawn on E7 can't attack a piece on E2. However, a
 *    rook can since 24 & 0x8 is non-zero. The only thing left to check is that
 *    there are no blocking pieces between E7 and E2. That's where the RAYS
 *    array comes in. It provides an offset (in this case 16) to add to E7 (20)
 *    to check for blocking pieces. E7 (20) + 16 = E6 (36) + 16 = E5 (52) etc.
 */

// prettier-ignore
// eslint-disable-next-line
const Ox88: Record<Square, number> = {
  a8:   0, b8:   1, c8:   2, d8:   3, e8:   4, f8:   5, g8:   6, h8:   7,
  a7:  16, b7:  17, c7:  18, d7:  19, e7:  20, f7:  21, g7:  22, h7:  23,
  a6:  32, b6:  33, c6:  34, d6:  35, e6:  36, f6:  37, g6:  38, h6:  39,
  a5:  48, b5:  49, c5:  50, d5:  51, e5:  52, f5:  53, g5:  54, h5:  55,
  a4:  64, b4:  65, c4:  66, d4:  67, e4:  68, f4:  69, g4:  70, h4:  71,
  a3:  80, b3:  81, c3:  82, d3:  83, e3:  84, f3:  85, g3:  86, h3:  87,
  a2:  96, b2:  97, c2:  98, d2:  99, e2: 100, f2: 101, g2: 102, h2: 103,
  a1: 112, b1: 113, c1: 114, d1: 115, e1: 116, f1: 117, g1: 118, h1: 119
}

const PAWN_OFFSETS = {
  b: [16, 32, 17, 15],
  w: [-16, -32, -17, -15],
}

const PIECE_OFFSETS = {
  n: [-18, -33, -31, -14, 18, 33, 31, 14],
  b: [-17, -15, 17, 15],
  r: [-16, 1, 16, -1],
  q: [-17, -16, -15, 1, 17, 16, 15, -1],
  k: [-17, -16, -15, 1, 17, 16, 15, -1],
}

// prettier-ignore
const ATTACKS = [
  20, 0, 0, 0, 0, 0, 0, 24,  0, 0, 0, 0, 0, 0,20, 0,
   0,20, 0, 0, 0, 0, 0, 24,  0, 0, 0, 0, 0,20, 0, 0,
   0, 0,20, 0, 0, 0, 0, 24,  0, 0, 0, 0,20, 0, 0, 0,
   0, 0, 0,20, 0, 0, 0, 24,  0, 0, 0,20, 0, 0, 0, 0,
   0, 0, 0, 0,20, 0, 0, 24,  0, 0,20, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0,20, 2, 24,  2,20, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 2,53, 56, 53, 2, 0, 0, 0, 0, 0, 0,
  24,24,24,24,24,24,56,  0, 56,24,24,24,24,24,24, 0,
   0, 0, 0, 0, 0, 2,53, 56, 53, 2, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0,20, 2, 24,  2,20, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0,20, 0, 0, 24,  0, 0,20, 0, 0, 0, 0, 0,
   0, 0, 0,20, 0, 0, 0, 24,  0, 0, 0,20, 0, 0, 0, 0,
   0, 0,20, 0, 0, 0, 0, 24,  0, 0, 0, 0,20, 0, 0, 0,
   0,20, 0, 0, 0, 0, 0, 24,  0, 0, 0, 0, 0,20, 0, 0,
  20, 0, 0, 0, 0, 0, 0, 24,  0, 0, 0, 0, 0, 0,20
];

// prettier-ignore
const RAYS = [
   17,  0,  0,  0,  0,  0,  0, 16,  0,  0,  0,  0,  0,  0, 15, 0,
    0, 17,  0,  0,  0,  0,  0, 16,  0,  0,  0,  0,  0, 15,  0, 0,
    0,  0, 17,  0,  0,  0,  0, 16,  0,  0,  0,  0, 15,  0,  0, 0,
    0,  0,  0, 17,  0,  0,  0, 16,  0,  0,  0, 15,  0,  0,  0, 0,
    0,  0,  0,  0, 17,  0,  0, 16,  0,  0, 15,  0,  0,  0,  0, 0,
    0,  0,  0,  0,  0, 17,  0, 16,  0, 15,  0,  0,  0,  0,  0, 0,
    0,  0,  0,  0,  0,  0, 17, 16, 15,  0,  0,  0,  0,  0,  0, 0,
    1,  1,  1,  1,  1,  1,  1,  0, -1, -1,  -1,-1, -1, -1, -1, 0,
    0,  0,  0,  0,  0,  0,-15,-16,-17,  0,  0,  0,  0,  0,  0, 0,
    0,  0,  0,  0,  0,-15,  0,-16,  0,-17,  0,  0,  0,  0,  0, 0,
    0,  0,  0,  0,-15,  0,  0,-16,  0,  0,-17,  0,  0,  0,  0, 0,
    0,  0,  0,-15,  0,  0,  0,-16,  0,  0,  0,-17,  0,  0,  0, 0,
    0,  0,-15,  0,  0,  0,  0,-16,  0,  0,  0,  0,-17,  0,  0, 0,
    0,-15,  0,  0,  0,  0,  0,-16,  0,  0,  0,  0,  0,-17,  0, 0,
  -15,  0,  0,  0,  0,  0,  0,-16,  0,  0,  0,  0,  0,  0,-17
];

const PIECE_MASKS = { p: 0x1, n: 0x2, b: 0x4, r: 0x8, q: 0x10, k: 0x20 }

const SYMBOLS = 'pnbrqkPNBRQK'

const PROMOTIONS: PieceSymbol[] = [KNIGHT, BISHOP, ROOK, QUEEN]

const RANK_1 = 7
const RANK_2 = 6
/*
 * const RANK_3 = 5
 * const RANK_4 = 4
 * const RANK_5 = 3
 * const RANK_6 = 2
 */
const RANK_7 = 1
const RANK_8 = 0

const ROOKS = {
  w: [
    { square: Ox88.a1, flag: BITS.QSIDE_CASTLE },
    { square: Ox88.h1, flag: BITS.KSIDE_CASTLE },
  ],
  b: [
    { square: Ox88.a8, flag: BITS.QSIDE_CASTLE },
    { square: Ox88.h8, flag: BITS.KSIDE_CASTLE },
  ],
}

const SECOND_RANK = { b: RANK_7, w: RANK_2 }

const TERMINATION_MARKERS = ['1-0', '0-1', '1/2-1/2', '*']

// Extracts the zero-based rank of an 0x88 square.
function rank(square: number): number {
  return square >> 4
}

// Extracts the zero-based file of an 0x88 square.
function file(square: number): number {
  return square & 0xf
}

function isDigit(c: string): boolean {
  return '0123456789'.indexOf(c) !== -1
}

// Converts a 0x88 square to algebraic notation.
function algebraic(square: number): Square {
  const f = file(square)
  const r = rank(square)
  return ('abcdefgh'.substring(f, f + 1) +
    '87654321'.substring(r, r + 1)) as Square
}

function swapColor(color: Color): Color {
  return color === WHITE ? BLACK : WHITE
}

export function validateFen(fen: string) {
  // 1st criterion: 6 space-seperated fields?
  const tokens = fen.split(/\s+/)
  if (tokens.length !== 6) {
    return {
      ok: false,
      error: 'Invalid FEN: must contain six space-delimited fields',
    }
  }

  // 2nd criterion: move number field is a integer value > 0?
  const moveNumber = parseInt(tokens[5], 10)
  if (isNaN(moveNumber) || moveNumber <= 0) {
    return {
      ok: false,
      error: 'Invalid FEN: move number must be a positive integer',
    }
  }

  // 3rd criterion: half move counter is an integer >= 0?
  const halfMoves = parseInt(tokens[4], 10)
  if (isNaN(halfMoves) || halfMoves < 0) {
    return {
      ok: false,
      error:
        'Invalid FEN: half move counter number must be a non-negative integer',
    }
  }

  // 4th criterion: 4th field is a valid e.p.-string?
  if (!/^(-|[abcdefgh][36])$/.test(tokens[3])) {
    return { ok: false, error: 'Invalid FEN: en-passant square is invalid' }
  }

  // 5th criterion: 3th field is a valid castle-string?
  if (/[^kKqQ-]/.test(tokens[2])) {
    return { ok: false, error: 'Invalid FEN: castling availability is invalid' }
  }

  // 6th criterion: 2nd field is "w" (white) or "b" (black)?
  if (!/^(w|b)$/.test(tokens[1])) {
    return { ok: false, error: 'Invalid FEN: side-to-move is invalid' }
  }

  // 7th criterion: 1st field contains 8 rows?
  const rows = tokens[0].split('/')
  if (rows.length !== 8) {
    return {
      ok: false,
      error: "Invalid FEN: piece data does not contain 8 '/'-delimited rows",
    }
  }

  // 8th criterion: every row is valid?
  for (let i = 0; i < rows.length; i++) {
    // check for right sum of fields AND not two numbers in succession
    let sumFields = 0
    let previousWasNumber = false

    for (let k = 0; k < rows[i].length; k++) {
      if (isDigit(rows[i][k])) {
        if (previousWasNumber) {
          return {
            ok: false,
            error: 'Invalid FEN: piece data is invalid (consecutive number)',
          }
        }
        sumFields += parseInt(rows[i][k], 10)
        previousWasNumber = true
      } else {
        if (!/^[prnbqkPRNBQK]$/.test(rows[i][k])) {
          return {
            ok: false,
            error: 'Invalid FEN: piece data is invalid (invalid piece)',
          }
        }
        sumFields += 1
        previousWasNumber = false
      }
    }
    if (sumFields !== 8) {
      return {
        ok: false,
        error: 'Invalid FEN: piece data is invalid (too many squares in rank)',
      }
    }
  }

  if (
    (tokens[3][1] == '3' && tokens[1] == 'w') ||
    (tokens[3][1] == '6' && tokens[1] == 'b')
  ) {
    return { ok: false, error: 'Invalid FEN: illegal en-passant square' }
  }

  const kings = [
    { color: 'white', regex: /K/g },
    { color: 'black', regex: /k/g },
  ]

  for (const { color, regex } of kings) {
    if (!regex.test(tokens[0])) {
      return { ok: false, error: `Invalid FEN: missing ${color} king` }
    }

    if ((tokens[0].match(regex) || []).length > 1) {
      return { ok: false, error: `Invalid FEN: too many ${color} kings` }
    }
  }

  return { ok: true }
}

// this function is used to uniquely identify ambiguous moves
function getDisambiguator(move: InternalMove, moves: InternalMove[]) {
  const from = move.from
  const to = move.to
  const piece = move.piece

  let ambiguities = 0
  let sameRank = 0
  let sameFile = 0

  for (let i = 0, len = moves.length; i < len; i++) {
    const ambigFrom = moves[i].from
    const ambigTo = moves[i].to
    const ambigPiece = moves[i].piece

    /*
     * if a move of the same piece type ends on the same to square, we'll need
     * to add a disambiguator to the algebraic notation
     */
    if (piece === ambigPiece && from !== ambigFrom && to === ambigTo) {
      ambiguities++

      if (rank(from) === rank(ambigFrom)) {
        sameRank++
      }

      if (file(from) === file(ambigFrom)) {
        sameFile++
      }
    }
  }

  if (ambiguities > 0) {
    if (sameRank > 0 && sameFile > 0) {
      /*
       * if there exists a similar moving piece on the same rank and file as
       * the move in question, use the square as the disambiguator
       */
      return algebraic(from)
    } else if (sameFile > 0) {
      /*
       * if the moving piece rests on the same file, use the rank symbol as the
       * disambiguator
       */
      return algebraic(from).charAt(1)
    } else {
      // else use the file symbol
      return algebraic(from).charAt(0)
    }
  }

  return ''
}

function addMove(
  moves: InternalMove[],
  color: Color,
  from: number,
  to: number,
  piece: PieceSymbol,
  captured: PieceSymbol | undefined = undefined,
  flags: number = BITS.NORMAL
) {
  const r = rank(to)

  if (piece === PAWN && (r === RANK_1 || r === RANK_8)) {
    for (let i = 0; i < PROMOTIONS.length; i++) {
      const promotion = PROMOTIONS[i]
      moves.push({
        color,
        from,
        to,
        piece,
        captured,
        promotion,
        flags: flags | BITS.PROMOTION,
      })
    }
  } else {
    moves.push({
      color,
      from,
      to,
      piece,
      captured,
      flags,
    })
  }
}

function inferPieceType(san: string) {
  let pieceType = san.charAt(0)
  if (pieceType >= 'a' && pieceType <= 'h') {
    const matches = san.match(/[a-h]\d.*[a-h]\d/)
    if (matches) {
      return undefined
    }
    return PAWN
  }
  pieceType = pieceType.toLowerCase()
  if (pieceType === 'o') {
    return KING
  }
  return pieceType as PieceSymbol
}

// parses all of the decorators out of a SAN string
function strippedSan(move: string) {
  return move.replace(/=/, '').replace(/[+#]?[?!]*$/, '')
}

export class Chess {
  private _board = new Array<Piece>(128)
  private _turn: Color = WHITE
  private _header: Record<string, string> = {}
  private _kings: Record<Color, number> = { w: EMPTY, b: EMPTY }
  private _epSquare = -1
  private _halfMoves = 0
  private _moveNumber = 0
  private _history: History[] = []
  private _comments: Record<string, string> = {}
  private _castling: Record<Color, number> = { w: 0, b: 0 }

  constructor(fen = DEFAULT_POSITION) {
    this.load(fen)
  }

  clear(keepHeaders = false) {
    this._board = new Array<Piece>(128)
    this._kings = { w: EMPTY, b: EMPTY }
    this._turn = WHITE
    this._castling = { w: 0, b: 0 }
    this._epSquare = EMPTY
    this._halfMoves = 0
    this._moveNumber = 1
    this._history = []
    this._comments = {}
    this._header = keepHeaders ? this._header : {}
    this._updateSetup(this.fen())
  }

  load(fen: string, keepHeaders = false) {
    let tokens = fen.split(/\s+/)

    // append commonly omitted fen tokens
    if (tokens.length >= 2 && tokens.length < 6) {
      const adjustments = ['-', '-', '0', '1']
      fen = tokens.concat(adjustments.slice(-(6 - tokens.length))).join(' ')
    }

    tokens = fen.split(/\s+/)

    const { ok, error } = validateFen(fen)
    if (!ok) {
      throw new Error(error)
    }

    const position = tokens[0]
    let square = 0

    this.clear(keepHeaders)

    for (let i = 0; i < position.length; i++) {
      const piece = position.charAt(i)

      if (piece === '/') {
        square += 8
      } else if (isDigit(piece)) {
        square += parseInt(piece, 10)
      } else {
        const color = piece < 'a' ? WHITE : BLACK
        this.put(
          { type: piece.toLowerCase() as PieceSymbol, color },
          algebraic(square)
        )
        square++
      }
    }

    this._turn = tokens[1] as Color

    if (tokens[2].indexOf('K') > -1) {
      this._castling.w |= BITS.KSIDE_CASTLE
    }
    if (tokens[2].indexOf('Q') > -1) {
      this._castling.w |= BITS.QSIDE_CASTLE
    }
    if (tokens[2].indexOf('k') > -1) {
      this._castling.b |= BITS.KSIDE_CASTLE
    }
    if (tokens[2].indexOf('q') > -1) {
      this._castling.b |= BITS.QSIDE_CASTLE
    }

    this._epSquare = tokens[3] === '-' ? EMPTY : Ox88[tokens[3] as Square]
    this._halfMoves = parseInt(tokens[4], 10)
    this._moveNumber = parseInt(tokens[5], 10)

    this._updateSetup(this.fen())
  }

  fen() {
    let empty = 0
    let fen = ''

    for (let i = Ox88.a8; i <= Ox88.h1; i++) {
      if (this._board[i]) {
        if (empty > 0) {
          fen += empty
          empty = 0
        }
        const { color, type: piece } = this._board[i]

        fen += color === WHITE ? piece.toUpperCase() : piece.toLowerCase()
      } else {
        empty++
      }

      if ((i + 1) & 0x88) {
        if (empty > 0) {
          fen += empty
        }

        if (i !== Ox88.h1) {
          fen += '/'
        }

        empty = 0
        i += 8
      }
    }

    let castling = ''
    if (this._castling[WHITE] & BITS.KSIDE_CASTLE) {
      castling += 'K'
    }
    if (this._castling[WHITE] & BITS.QSIDE_CASTLE) {
      castling += 'Q'
    }
    if (this._castling[BLACK] & BITS.KSIDE_CASTLE) {
      castling += 'k'
    }
    if (this._castling[BLACK] & BITS.QSIDE_CASTLE) {
      castling += 'q'
    }

    // do we have an empty castling flag?
    castling = castling || '-'

    let epSquare = '-'
    /*
     * only print the ep square if en passant is a valid move (pawn is present
     * and ep capture is not pinned)
     */
    if (this._epSquare !== EMPTY) {
      const bigPawnSquare = this._epSquare + (this._turn === WHITE ? 16 : -16)
      const squares = [bigPawnSquare + 1, bigPawnSquare - 1]

      for (const square of squares) {
        // is the square off the board?
        if (square & 0x88) {
          continue
        }

        const color = this._turn

        // is there a pawn that can capture the epSquare?
        if (
          this._board[square]?.color === color &&
          this._board[square]?.type === PAWN
        ) {
          // if the pawn makes an ep capture, does it leave it's king in check?
          this._makeMove({
            color,
            from: square,
            to: this._epSquare,
            piece: PAWN,
            captured: PAWN,
            flags: BITS.EP_CAPTURE,
          })
          const isLegal = !this._isKingAttacked(color)
          this._undoMove()

          // if ep is legal, break and set the ep square in the FEN output
          if (isLegal) {
            epSquare = algebraic(this._epSquare)
            break
          }
        }
      }
    }

    return [
      fen,
      this._turn,
      castling,
      epSquare,
      this._halfMoves,
      this._moveNumber,
    ].join(' ')
  }

  /*
   * Called when the initial board setup is changed with put() or remove().
   * modifies the SetUp and FEN properties of the header object. If the FEN
   * is equal to the default position, the SetUp and FEN are deleted the setup
   * is only updated if history.length is zero, ie moves haven't been made.
   */
  private _updateSetup(fen: string) {
    if (this._history.length > 0) return

    if (fen !== DEFAULT_POSITION) {
      this._header['SetUp'] = '1'
      this._header['FEN'] = fen
    } else {
      delete this._header['SetUp']
      delete this._header['FEN']
    }
  }

  reset() {
    this.load(DEFAULT_POSITION)
  }

  get(square: Square) {
    return this._board[Ox88[square]] || false
  }

  put({ type, color }: { type: PieceSymbol; color: Color }, square: Square) {
    // check for piece
    if (SYMBOLS.indexOf(type.toLowerCase()) === -1) {
      return false
    }

    // check for valid square
    if (!(square in Ox88)) {
      return false
    }

    const sq = Ox88[square]

    // don't let the user place more than one king
    if (
      type == KING &&
      !(this._kings[color] == EMPTY || this._kings[color] == sq)
    ) {
      return false
    }

    this._board[sq] = { type: type as PieceSymbol, color: color as Color }

    if (type === KING) {
      this._kings[color] = sq
    }

    this._updateSetup(this.fen())

    return true
  }

  remove(square: Square) {
    const piece = this.get(square)
    delete this._board[Ox88[square]]
    if (piece && piece.type === KING) {
      this._kings[piece.color] = EMPTY
    }

    this._updateSetup(this.fen())

    return piece
  }

  _attacked(color: Color, square: number) {
    for (let i = Ox88.a8; i <= Ox88.h1; i++) {
      // did we run off the end of the board
      if (i & 0x88) {
        i += 7
        continue
      }

      // if empty square or wrong color
      if (this._board[i] === undefined || this._board[i].color !== color) {
        continue
      }

      const piece = this._board[i]
      const difference = i - square

      // skip - to/from square are the same
      if (difference === 0) {
        continue
      }

      const index = difference + 119

      if (ATTACKS[index] & PIECE_MASKS[piece.type]) {
        if (piece.type === PAWN) {
          if (difference > 0) {
            if (piece.color === WHITE) return true
          } else {
            if (piece.color === BLACK) return true
          }
          continue
        }

        // if the piece is a knight or a king
        if (piece.type === 'n' || piece.type === 'k') return true

        const offset = RAYS[index]
        let j = i + offset

        let blocked = false
        while (j !== square) {
          if (this._board[j] != null) {
            blocked = true
            break
          }
          j += offset
        }

        if (!blocked) return true
      }
    }

    return false
  }

  private _isKingAttacked(color: Color) {
    return this._attacked(swapColor(color), this._kings[color])
  }

  isAttacked(square: Square, attackedBy: Color) {
    return this._attacked(attackedBy, Ox88[square])
  }

  isCheck() {
    return this._isKingAttacked(this._turn)
  }

  inCheck() {
    return this.isCheck()
  }

  isCheckmate() {
    return this.isCheck() && this._moves().length === 0
  }

  isStalemate() {
    return !this.isCheck() && this._moves().length === 0
  }

  isInsufficientMaterial() {
    /*
     * k.b. vs k.b. (of opposite colors) with mate in 1:
     * 8/8/8/8/1b6/8/B1k5/K7 b - - 0 1
     *
     * k.b. vs k.n. with mate in 1:
     * 8/8/8/8/1n6/8/B7/K1k5 b - - 2 1
     */
    const pieces: Record<PieceSymbol, number> = {
      b: 0,
      n: 0,
      r: 0,
      q: 0,
      k: 0,
      p: 0,
    }
    const bishops = []
    let numPieces = 0
    let squareColor = 0

    for (let i = Ox88.a8; i <= Ox88.h1; i++) {
      squareColor = (squareColor + 1) % 2
      if (i & 0x88) {
        i += 7
        continue
      }

      const piece = this._board[i]
      if (piece) {
        pieces[piece.type] = piece.type in pieces ? pieces[piece.type] + 1 : 1
        if (piece.type === BISHOP) {
          bishops.push(squareColor)
        }
        numPieces++
      }
    }

    // k vs. k
    if (numPieces === 2) {
      return true
    } else if (
      // k vs. kn .... or .... k vs. kb
      numPieces === 3 &&
      (pieces[BISHOP] === 1 || pieces[KNIGHT] === 1)
    ) {
      return true
    } else if (numPieces === pieces[BISHOP] + 2) {
      // kb vs. kb where any number of bishops are all on the same color
      let sum = 0
      const len = bishops.length
      for (let i = 0; i < len; i++) {
        sum += bishops[i]
      }
      if (sum === 0 || sum === len) {
        return true
      }
    }

    return false
  }

  isThreefoldRepetition() {
    const moves = []
    const positions: Record<string, number> = {}
    let repetition = false

    while (true) {
      const move = this._undoMove()
      if (!move) break
      moves.push(move)
    }

    while (true) {
      /*
       * remove the last two fields in the FEN string, they're not needed when
       * checking for draw by rep
       */
      const fen = this.fen().split(' ').slice(0, 4).join(' ')

      // has the position occurred three or move times
      positions[fen] = fen in positions ? positions[fen] + 1 : 1
      if (positions[fen] >= 3) {
        repetition = true
      }

      const move = moves.pop()

      if (!move) {
        break
      } else {
        this._makeMove(move)
      }
    }

    return repetition
  }

  isDraw() {
    return (
      this._halfMoves >= 100 || // 50 moves per side = 100 half moves
      this.isStalemate() ||
      this.isInsufficientMaterial() ||
      this.isThreefoldRepetition()
    )
  }

  isGameOver() {
    return this.isCheckmate() || this.isStalemate() || this.isDraw()
  }

  moves(): string[]
  moves({ square }: { square: Square }): string[]
  moves({ piece }: { piece: PieceSymbol }): string[]

  moves({ square, piece }: { square: Square; piece: PieceSymbol }): string[]

  moves({ verbose, square }: { verbose: true; square?: Square }): Move[]
  moves({ verbose, square }: { verbose: false; square?: Square }): string[]
  moves({
    verbose,
    square,
  }: {
    verbose?: boolean
    square?: Square
  }): string[] | Move[]

  moves({ verbose, piece }: { verbose: true; piece?: PieceSymbol }): Move[]
  moves({ verbose, piece }: { verbose: false; piece?: PieceSymbol }): string[]
  moves({
    verbose,
    piece,
  }: {
    verbose?: boolean
    piece?: PieceSymbol
  }): string[] | Move[]

  moves({
    verbose,
    square,
    piece,
  }: {
    verbose: true
    square?: Square
    piece?: PieceSymbol
  }): Move[]
  moves({
    verbose,
    square,
    piece,
  }: {
    verbose: false
    square?: Square
    piece?: PieceSymbol
  }): string[]
  moves({
    verbose,
    square,
    piece,
  }: {
    verbose?: boolean
    square?: Square
    piece?: PieceSymbol
  }): string[] | Move[]

  moves({ square, piece }: { square?: Square; piece?: PieceSymbol }): Move[]

  moves({
    verbose = false,
    square = undefined,
    piece = undefined,
  }: { verbose?: boolean; square?: Square; piece?: PieceSymbol } = {}) {
    const moves = this._moves({ square, piece })

    if (verbose) {
      return moves.map((move) => this._makePretty(move))
    } else {
      return moves.map((move) => this._moveToSan(move, moves))
    }
  }

  _moves({
    legal = true,
    piece = undefined,
    square = undefined,
  }: {
    legal?: boolean
    piece?: PieceSymbol
    square?: Square
  } = {}) {
    const forSquare = square ? (square.toLowerCase() as Square) : undefined
    const forPiece = piece?.toLowerCase()

    const moves: InternalMove[] = []
    const us = this._turn
    const them = swapColor(us)

    let firstSquare = Ox88.a8
    let lastSquare = Ox88.h1
    let singleSquare = false

    // are we generating moves for a single square?
    if (forSquare) {
      // illegal square, return empty moves
      if (!(forSquare in Ox88)) {
        return []
      } else {
        firstSquare = lastSquare = Ox88[forSquare]
        singleSquare = true
      }
    }

    for (let from = firstSquare; from <= lastSquare; from++) {
      // did we run off the end of the board
      if (from & 0x88) {
        from += 7
        continue
      }

      // empty square or opponent, skip
      if (!this._board[from] || this._board[from].color === them) {
        continue
      }
      const { type } = this._board[from]

      let to: number
      if (type === PAWN) {
        if (forPiece && forPiece !== type) continue

        // single square, non-capturing
        to = from + PAWN_OFFSETS[us][0]
        if (!this._board[to]) {
          addMove(moves, us, from, to, PAWN)

          // double square
          to = from + PAWN_OFFSETS[us][1]
          if (SECOND_RANK[us] === rank(from) && !this._board[to]) {
            addMove(moves, us, from, to, PAWN, undefined, BITS.BIG_PAWN)
          }
        }

        // pawn captures
        for (let j = 2; j < 4; j++) {
          to = from + PAWN_OFFSETS[us][j]
          if (to & 0x88) continue

          if (this._board[to]?.color === them) {
            addMove(
              moves,
              us,
              from,
              to,
              PAWN,
              this._board[to].type,
              BITS.CAPTURE
            )
          } else if (to === this._epSquare) {
            addMove(moves, us, from, to, PAWN, PAWN, BITS.EP_CAPTURE)
          }
        }
      } else {
        if (forPiece && forPiece !== type) continue

        for (let j = 0, len = PIECE_OFFSETS[type].length; j < len; j++) {
          const offset = PIECE_OFFSETS[type][j]
          to = from

          while (true) {
            to += offset
            if (to & 0x88) break

            if (!this._board[to]) {
              addMove(moves, us, from, to, type)
            } else {
              // own color, stop loop
              if (this._board[to].color === us) break

              addMove(
                moves,
                us,
                from,
                to,
                type,
                this._board[to].type,
                BITS.CAPTURE
              )
              break
            }

            /* break, if knight or king */
            if (type === KNIGHT || type === KING) break
          }
        }
      }
    }

    /*
     * check for castling if we're:
     *   a) generating all moves, or
     *   b) doing single square move generation on the king's square
     */

    if (forPiece === undefined || forPiece === KING) {
      if (!singleSquare || lastSquare === this._kings[us]) {
        // king-side castling
        if (this._castling[us] & BITS.KSIDE_CASTLE) {
          const castlingFrom = this._kings[us]
          const castlingTo = castlingFrom + 2

          if (
            !this._board[castlingFrom + 1] &&
            !this._board[castlingTo] &&
            !this._attacked(them, this._kings[us]) &&
            !this._attacked(them, castlingFrom + 1) &&
            !this._attacked(them, castlingTo)
          ) {
            addMove(
              moves,
              us,
              this._kings[us],
              castlingTo,
              KING,
              undefined,
              BITS.KSIDE_CASTLE
            )
          }
        }

        // queen-side castling
        if (this._castling[us] & BITS.QSIDE_CASTLE) {
          const castlingFrom = this._kings[us]
          const castlingTo = castlingFrom - 2

          if (
            !this._board[castlingFrom - 1] &&
            !this._board[castlingFrom - 2] &&
            !this._board[castlingFrom - 3] &&
            !this._attacked(them, this._kings[us]) &&
            !this._attacked(them, castlingFrom - 1) &&
            !this._attacked(them, castlingTo)
          ) {
            addMove(
              moves,
              us,
              this._kings[us],
              castlingTo,
              KING,
              undefined,
              BITS.QSIDE_CASTLE
            )
          }
        }
      }
    }

    /*
     * return all pseudo-legal moves (this includes moves that allow the king
     * to be captured)
     */
    if (!legal) {
      return moves
    }

    // filter out illegal moves
    const legalMoves = []

    for (let i = 0, len = moves.length; i < len; i++) {
      this._makeMove(moves[i])
      if (!this._isKingAttacked(us)) {
        legalMoves.push(moves[i])
      }
      this._undoMove()
    }

    return legalMoves
  }

  move(
    move: string | { from: string; to: string; promotion?: string },
    { strict = false }: { strict?: boolean } = {}
  ) {
    /*
     * The move function can be called with in the following parameters:
     *
     * .move('Nxb7')       <- argument is a case-sensitive SAN string
     *
     * .move({ from: 'h7', <- argument is a move object
     *         to :'h8',
     *         promotion: 'q' })
     *
     *
     * An optional strict argument may be supplied to tell chess.js to
     * strictly follow the SAN specification.
     */

    let moveObj = null

    if (typeof move === 'string') {
      moveObj = this._moveFromSan(move, strict)
    } else if (typeof move === 'object') {
      const moves = this._moves()

      // convert the pretty move object to an ugly move object
      for (let i = 0, len = moves.length; i < len; i++) {
        if (
          move.from === algebraic(moves[i].from) &&
          move.to === algebraic(moves[i].to) &&
          (!('promotion' in moves[i]) || move.promotion === moves[i].promotion)
        ) {
          moveObj = moves[i]
          break
        }
      }
    }

    // failed to find move
    if (!moveObj) {
      if (typeof move === 'string') {
        throw new Error(`Invalid move: ${move}`)
      } else {
        throw new Error(`Invalid move: ${JSON.stringify(move)}`)
      }
    }

    /*
     * need to make a copy of move because we can't generate SAN after the move
     * is made
     */
    const prettyMove = this._makePretty(moveObj)

    this._makeMove(moveObj)

    return prettyMove
  }

  _push(move: InternalMove) {
    this._history.push({
      move,
      kings: { b: this._kings.b, w: this._kings.w },
      turn: this._turn,
      castling: { b: this._castling.b, w: this._castling.w },
      epSquare: this._epSquare,
      halfMoves: this._halfMoves,
      moveNumber: this._moveNumber,
    })
  }

  private _makeMove(move: InternalMove) {
    const us = this._turn
    const them = swapColor(us)
    this._push(move)

    this._board[move.to] = this._board[move.from]
    delete this._board[move.from]

    // if ep capture, remove the captured pawn
    if (move.flags & BITS.EP_CAPTURE) {
      if (this._turn === BLACK) {
        delete this._board[move.to - 16]
      } else {
        delete this._board[move.to + 16]
      }
    }

    // if pawn promotion, replace with new piece
    if (move.promotion) {
      this._board[move.to] = { type: move.promotion, color: us }
    }

    // if we moved the king
    if (this._board[move.to].type === KING) {
      this._kings[us] = move.to

      // if we castled, move the rook next to the king
      if (move.flags & BITS.KSIDE_CASTLE) {
        const castlingTo = move.to - 1
        const castlingFrom = move.to + 1
        this._board[castlingTo] = this._board[castlingFrom]
        delete this._board[castlingFrom]
      } else if (move.flags & BITS.QSIDE_CASTLE) {
        const castlingTo = move.to + 1
        const castlingFrom = move.to - 2
        this._board[castlingTo] = this._board[castlingFrom]
        delete this._board[castlingFrom]
      }

      // turn off castling
      this._castling[us] = 0
    }

    // turn off castling if we move a rook
    if (this._castling[us]) {
      for (let i = 0, len = ROOKS[us].length; i < len; i++) {
        if (
          move.from === ROOKS[us][i].square &&
          this._castling[us] & ROOKS[us][i].flag
        ) {
          this._castling[us] ^= ROOKS[us][i].flag
          break
        }
      }
    }

    // turn off castling if we capture a rook
    if (this._castling[them]) {
      for (let i = 0, len = ROOKS[them].length; i < len; i++) {
        if (
          move.to === ROOKS[them][i].square &&
          this._castling[them] & ROOKS[them][i].flag
        ) {
          this._castling[them] ^= ROOKS[them][i].flag
          break
        }
      }
    }

    // if big pawn move, update the en passant square
    if (move.flags & BITS.BIG_PAWN) {
      if (us === BLACK) {
        this._epSquare = move.to - 16
      } else {
        this._epSquare = move.to + 16
      }
    } else {
      this._epSquare = EMPTY
    }

    // reset the 50 move counter if a pawn is moved or a piece is captured
    if (move.piece === PAWN) {
      this._halfMoves = 0
    } else if (move.flags & (BITS.CAPTURE | BITS.EP_CAPTURE)) {
      this._halfMoves = 0
    } else {
      this._halfMoves++
    }

    if (us === BLACK) {
      this._moveNumber++
    }

    this._turn = them
  }

  undo() {
    const move = this._undoMove()
    return move ? this._makePretty(move) : null
  }

  private _undoMove() {
    const old = this._history.pop()
    if (old === undefined) {
      return null
    }

    const move = old.move

    this._kings = old.kings
    this._turn = old.turn
    this._castling = old.castling
    this._epSquare = old.epSquare
    this._halfMoves = old.halfMoves
    this._moveNumber = old.moveNumber

    const us = this._turn
    const them = swapColor(us)

    this._board[move.from] = this._board[move.to]
    this._board[move.from].type = move.piece // to undo any promotions
    delete this._board[move.to]

    if (move.captured) {
      if (move.flags & BITS.EP_CAPTURE) {
        // en passant capture
        let index: number
        if (us === BLACK) {
          index = move.to - 16
        } else {
          index = move.to + 16
        }
        this._board[index] = { type: PAWN, color: them }
      } else {
        // regular capture
        this._board[move.to] = { type: move.captured, color: them }
      }
    }

    if (move.flags & (BITS.KSIDE_CASTLE | BITS.QSIDE_CASTLE)) {
      let castlingTo: number, castlingFrom: number
      if (move.flags & BITS.KSIDE_CASTLE) {
        castlingTo = move.to + 1
        castlingFrom = move.to - 1
      } else {
        castlingTo = move.to - 2
        castlingFrom = move.to + 1
      }

      this._board[castlingTo] = this._board[castlingFrom]
      delete this._board[castlingFrom]
    }

    return move
  }

  pgn({
    newline = '\n',
    maxWidth = 0,
  }: { newline?: string; maxWidth?: number } = {}) {
    /*
     * using the specification from http://www.chessclub.com/help/PGN-spec
     * example for html usage: .pgn({ max_width: 72, newline_char: "<br />" })
     */

    const result: string[] = []
    let headerExists = false

    /* add the PGN header information */
    for (const i in this._header) {
      /*
       * TODO: order of enumerated properties in header object is not
       * guaranteed, see ECMA-262 spec (section 12.6.4)
       */
      result.push('[' + i + ' "' + this._header[i] + '"]' + newline)
      headerExists = true
    }

    if (headerExists && this._history.length) {
      result.push(newline)
    }

    const appendComment = (moveString: string) => {
      const comment = this._comments[this.fen()]
      if (typeof comment !== 'undefined') {
        const delimiter = moveString.length > 0 ? ' ' : ''
        moveString = `${moveString}${delimiter}{${comment}}`
      }
      return moveString
    }

    // pop all of history onto reversed_history
    const reversedHistory = []
    while (this._history.length > 0) {
      reversedHistory.push(this._undoMove())
    }

    const moves = []
    let moveString = ''

    // special case of a commented starting position with no moves
    if (reversedHistory.length === 0) {
      moves.push(appendComment(''))
    }

    // build the list of moves.  a move_string looks like: "3. e3 e6"
    while (reversedHistory.length > 0) {
      moveString = appendComment(moveString)
      const move = reversedHistory.pop()

      // make TypeScript stop complaining about move being undefined
      if (!move) {
        break
      }

      // if the position started with black to move, start PGN with #. ...
      if (!this._history.length && move.color === 'b') {
        const prefix = `${this._moveNumber}. ...`
        // is there a comment preceding the first move?
        moveString = moveString ? `${moveString} ${prefix}` : prefix
      } else if (move.color === 'w') {
        // store the previous generated move_string if we have one
        if (moveString.length) {
          moves.push(moveString)
        }
        moveString = this._moveNumber + '.'
      }

      moveString =
        moveString + ' ' + this._moveToSan(move, this._moves({ legal: true }))
      this._makeMove(move)
    }

    // are there any other leftover moves?
    if (moveString.length) {
      moves.push(appendComment(moveString))
    }

    // is there a result?
    if (typeof this._header.Result !== 'undefined') {
      moves.push(this._header.Result)
    }

    /*
     * history should be back to what it was before we started generating PGN,
     * so join together moves
     */
    if (maxWidth === 0) {
      return result.join('') + moves.join(' ')
    }

    // TODO (jah): huh?
    const strip = function () {
      if (result.length > 0 && result[result.length - 1] === ' ') {
        result.pop()
        return true
      }
      return false
    }

    // NB: this does not preserve comment whitespace.
    const wrapComment = function (width: number, move: string) {
      for (const token of move.split(' ')) {
        if (!token) {
          continue
        }
        if (width + token.length > maxWidth) {
          while (strip()) {
            width--
          }
          result.push(newline)
          width = 0
        }
        result.push(token)
        width += token.length
        result.push(' ')
        width++
      }
      if (strip()) {
        width--
      }
      return width
    }

    // wrap the PGN output at max_width
    let currentWidth = 0
    for (let i = 0; i < moves.length; i++) {
      if (currentWidth + moves[i].length > maxWidth) {
        if (moves[i].includes('{')) {
          currentWidth = wrapComment(currentWidth, moves[i])
          continue
        }
      }
      // if the current move will push past max_width
      if (currentWidth + moves[i].length > maxWidth && i !== 0) {
        // don't end the line with whitespace
        if (result[result.length - 1] === ' ') {
          result.pop()
        }

        result.push(newline)
        currentWidth = 0
      } else if (i !== 0) {
        result.push(' ')
        currentWidth++
      }
      result.push(moves[i])
      currentWidth += moves[i].length
    }

    return result.join('')
  }

  header(...args: string[]) {
    for (let i = 0; i < args.length; i += 2) {
      if (typeof args[i] === 'string' && typeof args[i + 1] === 'string') {
        this._header[args[i]] = args[i + 1]
      }
    }
    return this._header
  }

  loadPgn(
    pgn: string,
    {
      strict = false,
      newlineChar = '\r?\n',
    }: { strict?: boolean; newlineChar?: string } = {}
  ) {
    function mask(str: string): string {
      return str.replace(/\\/g, '\\')
    }

    function parsePgnHeader(header: string): { [key: string]: string } {
      const headerObj: Record<string, string> = {}
      const headers = header.split(new RegExp(mask(newlineChar)))
      let key = ''
      let value = ''

      for (let i = 0; i < headers.length; i++) {
        const regex = /^\s*\[\s*([A-Za-z]+)\s*"(.*)"\s*\]\s*$/
        key = headers[i].replace(regex, '$1')
        value = headers[i].replace(regex, '$2')
        if (key.trim().length > 0) {
          headerObj[key] = value
        }
      }

      return headerObj
    }

    // strip whitespace from head/tail of PGN block
    pgn = pgn.trim()

    /*
     * RegExp to split header. Takes advantage of the fact that header and movetext
     * will always have a blank line between them (ie, two newline_char's). Handles
     * case where movetext is empty by matching newlineChar until end of string is
     * matched - effectively trimming from the end extra newlineChar.
     *
     * With default newline_char, will equal:
     * /^(\[((?:\r?\n)|.)*\])((?:\s*\r?\n){2}|(?:\s*\r?\n)*$)/
     */
    const headerRegex = new RegExp(
      '^(\\[((?:' +
        mask(newlineChar) +
        ')|.)*\\])' +
        '((?:\\s*' +
        mask(newlineChar) +
        '){2}|(?:\\s*' +
        mask(newlineChar) +
        ')*$)'
    )

    // If no header given, begin with moves.
    const headerRegexResults = headerRegex.exec(pgn)
    const headerString = headerRegexResults
      ? headerRegexResults.length >= 2
        ? headerRegexResults[1]
        : ''
      : ''

    // Put the board in the starting position
    this.reset()

    // parse PGN header
    const headers = parsePgnHeader(headerString)
    let fen = ''

    for (const key in headers) {
      // check to see user is including fen (possibly with wrong tag case)
      if (key.toLowerCase() === 'fen') {
        fen = headers[key]
      }

      this.header(key, headers[key])
    }

    /*
     * the permissive parser should attempt to load a fen tag, even if it's the
     * wrong case and doesn't include a corresponding [SetUp "1"] tag
     */
    if (!strict) {
      if (fen) {
        this.load(fen, true)
      }
    } else {
      /*
       * strict parser - load the starting position indicated by [Setup '1']
       * and [FEN position]
       */
      if (headers['SetUp'] === '1') {
        if (!('FEN' in headers)) {
          throw new Error(
            'Invalid PGN: FEN tag must be supplied with SetUp tag'
          )
        }
        // second argument to load: don't clear the headers
        this.load(headers['FEN'], true)
      }
    }

    /*
     * NB: the regexes below that delete move numbers, recursive annotations,
     * and numeric annotation glyphs may also match text in comments. To
     * prevent this, we transform comments by hex-encoding them in place and
     * decoding them again after the other tokens have been deleted.
     *
     * While the spec states that PGN files should be ASCII encoded, we use
     * {en,de}codeURIComponent here to support arbitrary UTF8 as a convenience
     * for modern users
     */

    function toHex(s: string): string {
      return Array.from(s)
        .map(function (c) {
          /*
           * encodeURI doesn't transform most ASCII characters, so we handle
           * these ourselves
           */
          return c.charCodeAt(0) < 128
            ? c.charCodeAt(0).toString(16)
            : encodeURIComponent(c).replace(/%/g, '').toLowerCase()
        })
        .join('')
    }

    function fromHex(s: string): string {
      return s.length == 0
        ? ''
        : decodeURIComponent('%' + (s.match(/.{1,2}/g) || []).join('%'))
    }

    const encodeComment = function (s: string) {
      s = s.replace(new RegExp(mask(newlineChar), 'g'), ' ')
      return `{${toHex(s.slice(1, s.length - 1))}}`
    }

    const decodeComment = function (s: string) {
      if (s.startsWith('{') && s.endsWith('}')) {
        return fromHex(s.slice(1, s.length - 1))
      }
    }

    // delete header to get the moves
    let ms = pgn
      .replace(headerString, '')
      .replace(
        // encode comments so they don't get deleted below
        new RegExp(`({[^}]*})+?|;([^${mask(newlineChar)}]*)`, 'g'),
        function (_match, bracket, semicolon) {
          return bracket !== undefined
            ? encodeComment(bracket)
            : ' ' + encodeComment(`{${semicolon.slice(1)}}`)
        }
      )
      .replace(new RegExp(mask(newlineChar), 'g'), ' ')

    // delete recursive annotation variations
    const ravRegex = /(\([^()]+\))+?/g
    while (ravRegex.test(ms)) {
      ms = ms.replace(ravRegex, '')
    }

    // delete move numbers
    ms = ms.replace(/\d+\.(\.\.)?/g, '')

    // delete ... indicating black to move
    ms = ms.replace(/\.\.\./g, '')

    /* delete numeric annotation glyphs */
    ms = ms.replace(/\$\d+/g, '')

    // trim and get array of moves
    let moves = ms.trim().split(new RegExp(/\s+/))

    // delete empty entries
    moves = moves.filter((move) => move !== '')

    let result = ''

    for (let halfMove = 0; halfMove < moves.length; halfMove++) {
      const comment = decodeComment(moves[halfMove])
      if (comment !== undefined) {
        this._comments[this.fen()] = comment
        continue
      }

      const move = this._moveFromSan(moves[halfMove], strict)

      // invalid move
      if (move == null) {
        // was the move an end of game marker
        if (TERMINATION_MARKERS.indexOf(moves[halfMove]) > -1) {
          result = moves[halfMove]
        } else {
          throw new Error(`Invalid move in PGN: ${moves[halfMove]}`)
        }
      } else {
        // reset the end of game marker if making a valid move
        result = ''
        this._makeMove(move)
      }
    }

    /*
     * Per section 8.2.6 of the PGN spec, the Result tag pair must match match
     * the termination marker. Only do this when headers are present, but the
     * result tag is missing
     */

    if (result && Object.keys(this._header).length && !this._header['Result']) {
      this.header('Result', result)
    }
  }

  /*
   * Convert a move from 0x88 coordinates to Standard Algebraic Notation
   * (SAN)
   *
   * @param {boolean} strict Use the strict SAN parser. It will throw errors
   * on overly disambiguated moves (see below):
   *
   * r1bqkbnr/ppp2ppp/2n5/1B1pP3/4P3/8/PPPP2PP/RNBQK1NR b KQkq - 2 4
   * 4. ... Nge7 is overly disambiguated because the knight on c6 is pinned
   * 4. ... Ne7 is technically the valid SAN
   */

  private _moveToSan(move: InternalMove, moves: InternalMove[]) {
    let output = ''

    if (move.flags & BITS.KSIDE_CASTLE) {
      output = 'O-O'
    } else if (move.flags & BITS.QSIDE_CASTLE) {
      output = 'O-O-O'
    } else {
      if (move.piece !== PAWN) {
        const disambiguator = getDisambiguator(move, moves)
        output += move.piece.toUpperCase() + disambiguator
      }

      if (move.flags & (BITS.CAPTURE | BITS.EP_CAPTURE)) {
        if (move.piece === PAWN) {
          output += algebraic(move.from)[0]
        }
        output += 'x'
      }

      output += algebraic(move.to)

      if (move.promotion) {
        output += '=' + move.promotion.toUpperCase()
      }
    }

    this._makeMove(move)
    if (this.isCheck()) {
      if (this.isCheckmate()) {
        output += '#'
      } else {
        output += '+'
      }
    }
    this._undoMove()

    return output
  }

  // convert a move from Standard Algebraic Notation (SAN) to 0x88 coordinates
  private _moveFromSan(move: string, strict = false): InternalMove | null {
    // strip off any move decorations: e.g Nf3+?! becomes Nf3
    const cleanMove = strippedSan(move)

    let pieceType = inferPieceType(cleanMove)
    let moves = this._moves({ legal: true, piece: pieceType })

    // strict parser
    for (let i = 0, len = moves.length; i < len; i++) {
      if (cleanMove === strippedSan(this._moveToSan(moves[i], moves))) {
        return moves[i]
      }
    }

    // the strict parser failed
    if (strict) {
      return null
    }

    let piece = undefined
    let matches = undefined
    let from = undefined
    let to = undefined
    let promotion = undefined

    /*
     * The default permissive (non-strict) parser allows the user to parse
     * non-standard chess notations. This parser is only run after the strict
     * Standard Algebraic Notation (SAN) parser has failed.
     *
     * When running the permissive parser, we'll run a regex to grab the piece, the
     * to/from square, and an optional promotion piece. This regex will
     * parse common non-standard notation like: Pe2-e4, Rc1c4, Qf3xf7,
     * f7f8q, b1c3
     *
     * NOTE: Some positions and moves may be ambiguous when using the permissive
     * parser. For example, in this position: 6k1/8/8/B7/8/8/8/BN4K1 w - - 0 1,
     * the move b1c3 may be interpreted as Nc3 or B1c3 (a disambiguated bishop
     * move). In these cases, the permissive parser will default to the most
     * basic interpretation (which is b1c3 parsing to Nc3).
     */

    let overlyDisambiguated = false

    matches = cleanMove.match(
      /([pnbrqkPNBRQK])?([a-h][1-8])x?-?([a-h][1-8])([qrbnQRBN])?/
      //     piece         from              to       promotion
    )

    if (matches) {
      piece = matches[1]
      from = matches[2] as Square
      to = matches[3] as Square
      promotion = matches[4]

      if (from.length == 1) {
        overlyDisambiguated = true
      }
    } else {
      /*
       * The [a-h]?[1-8]? portion of the regex below handles moves that may be
       * overly disambiguated (e.g. Nge7 is unnecessary and non-standard when
       * there is one legal knight move to e7). In this case, the value of
       * 'from' variable will be a rank or file, not a square.
       */

      matches = cleanMove.match(
        /([pnbrqkPNBRQK])?([a-h]?[1-8]?)x?-?([a-h][1-8])([qrbnQRBN])?/
      )

      if (matches) {
        piece = matches[1]
        from = matches[2] as Square
        to = matches[3] as Square
        promotion = matches[4]

        if (from.length == 1) {
          overlyDisambiguated = true
        }
      }
    }

    pieceType = inferPieceType(cleanMove)
    moves = this._moves({
      legal: true,
      piece: piece ? (piece as PieceSymbol) : pieceType,
    })

    for (let i = 0, len = moves.length; i < len; i++) {
      if (from && to) {
        // hand-compare move properties with the results from our permissive regex
        if (
          (!piece || piece.toLowerCase() == moves[i].piece) &&
          Ox88[from] == moves[i].from &&
          Ox88[to] == moves[i].to &&
          (!promotion || promotion.toLowerCase() == moves[i].promotion)
        ) {
          return moves[i]
        } else if (overlyDisambiguated) {
          /*
           * SPECIAL CASE: we parsed a move string that may have an unneeded
           * rank/file disambiguator (e.g. Nge7).  The 'from' variable will
           */

          const square = algebraic(moves[i].from)
          if (
            (!piece || piece.toLowerCase() == moves[i].piece) &&
            Ox88[to] == moves[i].to &&
            (from == square[0] || from == square[1]) &&
            (!promotion || promotion.toLowerCase() == moves[i].promotion)
          ) {
            return moves[i]
          }
        }
      }
    }

    return null
  }

  ascii() {
    let s = '   +------------------------+\n'
    for (let i = Ox88.a8; i <= Ox88.h1; i++) {
      // display the rank
      if (file(i) === 0) {
        s += ' ' + '87654321'[rank(i)] + ' |'
      }

      if (this._board[i]) {
        const piece = this._board[i].type
        const color = this._board[i].color
        const symbol =
          color === WHITE ? piece.toUpperCase() : piece.toLowerCase()
        s += ' ' + symbol + ' '
      } else {
        s += ' . '
      }

      if ((i + 1) & 0x88) {
        s += '|\n'
        i += 8
      }
    }
    s += '   +------------------------+\n'
    s += '     a  b  c  d  e  f  g  h'

    return s
  }

  perft(depth: number) {
    const moves = this._moves({ legal: false })
    let nodes = 0
    const color = this._turn

    for (let i = 0, len = moves.length; i < len; i++) {
      this._makeMove(moves[i])
      if (!this._isKingAttacked(color)) {
        if (depth - 1 > 0) {
          nodes += this.perft(depth - 1)
        } else {
          nodes++
        }
      }
      this._undoMove()
    }

    return nodes
  }

  // pretty = external move object
  private _makePretty(uglyMove: InternalMove): Move {
    const { color, piece, from, to, flags, captured, promotion } = uglyMove

    let prettyFlags = ''

    for (const flag in BITS) {
      if (BITS[flag] & flags) {
        prettyFlags += FLAGS[flag]
      }
    }

    const fromAlgebraic = algebraic(from)
    const toAlgebraic = algebraic(to)

    const move: Move = {
      color,
      piece,
      from: fromAlgebraic,
      to: toAlgebraic,
      san: this._moveToSan(uglyMove, this._moves({ legal: true })),
      flags: prettyFlags,
      lan: fromAlgebraic + toAlgebraic,
      before: this.fen(),
      after: '',
    }

    // generate the FEN for the 'after' key
    this._makeMove(uglyMove)
    move.after = this.fen()
    this._undoMove()

    if (captured) {
      move.captured = captured
    }
    if (promotion) {
      move.promotion = promotion
      move.lan += promotion
    }

    return move
  }

  turn() {
    return this._turn
  }

  board() {
    const output = []
    let row = []

    for (let i = Ox88.a8; i <= Ox88.h1; i++) {
      if (this._board[i] == null) {
        row.push(null)
      } else {
        row.push({
          square: algebraic(i),
          type: this._board[i].type,
          color: this._board[i].color,
        })
      }
      if ((i + 1) & 0x88) {
        output.push(row)
        row = []
        i += 8
      }
    }

    return output
  }

  squareColor(square: Square) {
    if (square in Ox88) {
      const sq = Ox88[square]
      return (rank(sq) + file(sq)) % 2 === 0 ? 'light' : 'dark'
    }

    return null
  }

  history(): string[]
  history({ verbose }: { verbose: true }): Move[]
  history({ verbose }: { verbose: false }): string[]
  history({ verbose }: { verbose: boolean }): string[] | Move[]
  history({ verbose = false }: { verbose?: boolean } = {}) {
    const reversedHistory = []
    const moveHistory = []

    while (this._history.length > 0) {
      reversedHistory.push(this._undoMove())
    }

    while (true) {
      const move = reversedHistory.pop()
      if (!move) {
        break
      }

      if (verbose) {
        moveHistory.push(this._makePretty(move))
      } else {
        moveHistory.push(this._moveToSan(move, this._moves()))
      }
      this._makeMove(move)
    }

    return moveHistory
  }

  private _pruneComments() {
    const reversedHistory = []
    const currentComments: Record<string, string> = {}

    const copyComment = (fen: string) => {
      if (fen in this._comments) {
        currentComments[fen] = this._comments[fen]
      }
    }

    while (this._history.length > 0) {
      reversedHistory.push(this._undoMove())
    }

    copyComment(this.fen())

    while (true) {
      const move = reversedHistory.pop()
      if (!move) {
        break
      }
      this._makeMove(move)
      copyComment(this.fen())
    }
    this._comments = currentComments
  }

  getComment() {
    return this._comments[this.fen()]
  }

  setComment(comment: string) {
    this._comments[this.fen()] = comment.replace('{', '[').replace('}', ']')
  }

  deleteComment() {
    const comment = this._comments[this.fen()]
    delete this._comments[this.fen()]
    return comment
  }

  getComments() {
    this._pruneComments()
    return Object.keys(this._comments).map((fen: string) => {
      return { fen: fen, comment: this._comments[fen] }
    })
  }

  deleteComments() {
    this._pruneComments()
    return Object.keys(this._comments).map((fen) => {
      const comment = this._comments[fen]
      delete this._comments[fen]
      return { fen: fen, comment: comment }
    })
  }
}

*/
