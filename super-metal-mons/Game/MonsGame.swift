// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: do not play audio from the game logic code

class MonsGame {
    
    private let boardSize = 11 // TODO: use it when creating a board as well
    
    enum Move: String {
        case step, action, mana
    }
    
    var availableMoves: [Move: Int] {
        var moves: [Move: Int] = [
            .step: 5 - monsMovesCount,
            .action: 0,
            .mana: 0
        ]
        
        if isFirstTurn {
            return moves
        }
        
        moves[.action] = (actionUsed ? 0 : 1) + potionsCount
        
        if !manaMoved {
            moves[.mana] = 1
        }
        
        return moves
    }
    
    let version: Int
    
    var whiteScore: Int
    var blackScore: Int
    
    var activeColor: Color
    var actionUsed: Bool // TODO: use int here to make game more configurable
    var manaMoved: Bool // TODO: use int here to make game more configurable
    var monsMovesCount: Int
    
    var whitePotionsCount: Int
    var blackPotionsCount: Int
    
    var turnNumber: Int
    var board: [[Piece]]
    
    var isFirstTurn: Bool { return turnNumber == 1 }
    
    init() {
        self.version = 1
        self.whiteScore = 0
        self.blackScore = 0
        self.activeColor = .white
        self.actionUsed = false
        self.manaMoved = false
        self.monsMovesCount = 0
        self.whitePotionsCount = 0
        self.blackPotionsCount = 0
        self.turnNumber = 1
        self.board = [
            [.none, .none, .none,
             .mon(mon: Mon(kind: .mystic, color: .black)), // 3
             .mon(mon: Mon(kind: .spirit, color: .black)), // 4
             .mon(mon: Mon(kind: .drainer, color: .black)), // 5
             .mon(mon: Mon(kind: .angel, color: .black)), // 6
             .mon(mon: Mon(kind: .demon, color: .black)), // 7
             .none, .none, .none],
            
            [.none, .none,  .none, .none, .none, .none, .none, .none, .none, .none, .none],
            [.none, .none,  .none, .none, .none, .none, .none, .none, .none, .none, .none],
            
            [.none, .none,  .none, .none,
             .mana(mana: .regular(color: .black)),
             .none,
             .mana(mana: .regular(color: .black)),
             .none, .none, .none, .none],
            
            [.none, .none,  .none,
             .mana(mana: .regular(color: .black)),
             .none,
             .mana(mana: .regular(color: .black)),
             .none,
             .mana(mana: .regular(color: .black)),
             .none, .none, .none],
            
            [.consumable(consumable: .potion),
             .none,  .none, .none, .none,
             .mana(mana: .superMana),
             .none, .none, .none, .none,
             .consumable(consumable: .potion)],
            
            [.none, .none,  .none,
             .mana(mana: .regular(color: .white)),
             .none,
             .mana(mana: .regular(color: .white)),
             .none,
             .mana(mana: .regular(color: .white)),
             .none, .none, .none],
            
            [.none, .none,  .none, .none,
             .mana(mana: .regular(color: .white)),
             .none,
             .mana(mana: .regular(color: .white)),
             .none, .none, .none, .none],
            
            [.none, .none,  .none, .none, .none, .none, .none, .none, .none, .none, .none],
            [.none, .none,  .none, .none, .none, .none, .none, .none, .none, .none, .none],
            
            [.none, .none, .none,
             .mon(mon: Mon(kind: .demon, color: .white)), // 3
             .mon(mon: Mon(kind: .angel, color: .white)), // 4
             .mon(mon: Mon(kind: .drainer, color: .white)), // 5
             .mon(mon: Mon(kind: .spirit, color: .white)), // 6
             .mon(mon: Mon(kind: .mystic, color: .white)), // 7
             .none, .none, .none],
        ]
    }
    
    init?(fen: String) {
        let fields = fen.split(separator: " ")
        guard fields.count == 11,
              let version = Int(fields[0]),
              let whiteScore = Int(fields[1]),
              let blackScore = Int(fields[2]),
              let activeColor = Color(fen: String(fields[3])),
              let actionUsed = Bool(fen: String(fields[4])),
              let manaMoved = Bool(fen: String(fields[5])),
              let monsMovesCount = Int(fields[6]),
              let whitePotionsCount = Int(fields[7]),
              let blackPotionsCount = Int(fields[8]),
              let turnNumber = Int(fields[9]),
              let board = [[Piece]](fen: String(fields[10]))
        else { return nil }
        
        self.version = version
        self.whiteScore = whiteScore
        self.blackScore = blackScore
        self.activeColor = activeColor
        self.actionUsed = actionUsed
        self.manaMoved = manaMoved
        self.monsMovesCount = monsMovesCount
        self.whitePotionsCount = whitePotionsCount
        self.blackPotionsCount = blackPotionsCount
        self.turnNumber = turnNumber
        self.board = board
    }
    
    
    private var potionsCount: Int {
        return activeColor == .white ? whitePotionsCount : blackPotionsCount
    }
    
    private var canUseAction: Bool {
        return !isFirstTurn && (!actionUsed || potionsCount > 0)
    }
    
    // TODO: optimize mana search the same way as mons iteration
    private var hasFreeMana: Bool {
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                let piece = board[i][j]
                if case let .mana(.regular(color: color)) = piece, color == activeColor {
                    return true
                }
            }
        }
        return false
    }
    
    private var canMoveMana: Bool {
        return !isFirstTurn && !manaMoved
    }
    
    private func didUseAction() {
        if !actionUsed {
            actionUsed = true
        } else {
            switch activeColor {
            case .white:
                whitePotionsCount -= 1
            case .black:
                blackPotionsCount -= 1
            }
        }
    }
    
    private func isProtectedByAngel(_ index: (Int, Int)) -> Bool {
        // TODO: keep set of mons to avoid iterating so much
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                let piece = board[i][j]
                if case let .mon(mon) = piece, mon.kind == .angel, mon.color != activeColor {
                    if !mon.isFainted && max(abs(index.0 - i), abs(index.1 - j)) == 1 {
                        return true
                    } else {
                        return false
                    }
                }
            }
        }
        
        return false
    }
    
    func didTapSpace(_ index: (Int, Int)) -> [Effect] {
        inputSequence.append(index)
        return processInput()
    }
    
    private var inputSequence = [(Int, Int)]()
    
    private func nearbySpaces(from: (Int, Int)) -> [(Int, Int)] {
        var nearby = [(Int, Int)]()
        for i in (from.0 - 1)...(from.0 + 1) {
            for j in (from.1 - 1)...(from.1 + 1) {
                if isValidLocation(i, j), i != from.0 || j != from.1 {
                    nearby.append((i, j))
                }
            }
        }
        return nearby
    }
    
    // TODO: move into location model
    // though if i move it to the location model, why how would it know about the current board size
    private func isValidLocation(_ i: Int, _ j: Int) -> Bool {
        return i >= 0 && j >= 0 && i < boardSize && j < boardSize
    }
    
    // TODO: извлечить код тестирования конкретного поля, чтобы его можно было переиспользовать, когда получили два или три инпута
    // TODO: да вот не нравится вот этот инпут bySpiritMagic. сверху мудрый коммент про то, что надо это поле разбить.
    private func availableForStep(from: (Int, Int), bySpiritMagic: Bool = false) -> [(Int, Int)] {
        let piece = board[from.0][from.1]
        switch piece {
        case .none:
            return []
        case .consumable:
            if bySpiritMagic {
                let available = nearbySpaces(from: from).filter { (i, j) -> Bool in
                    let destination = board[i][j]
                    
                    switch destination {
                    case .none:
                        return !Location.isMonsBase(i, j) && !Location.isSuperManaBase(i, j)
                    case .monWithMana, .mon:
                        return true
                    case .mana, .consumable:
                        return false
                    }
                }
                return available
            } else {
                return []
            }
        case let .mana(mana: mana):
            switch mana {
            case .superMana:
                if bySpiritMagic {
                    let available = nearbySpaces(from: from).filter { (i, j) -> Bool in
                        let destination = board[i][j]
                        
                        switch destination {
                        case .none:
                            return !Location.isMonsBase(i, j)
                        case .mana, .monWithMana, .consumable:
                            return false
                        case let .mon(mon: mon):
                            if mon.kind == .drainer {
                                return !Location.isMonsBase(i, j)
                            } else {
                                return false
                            }
                        }
                    }
                    return available
                } else {
                    return []
                }
            case .regular:
                let available = nearbySpaces(from: from).filter { (i, j) -> Bool in
                    let destination = board[i][j]
                    
                    switch destination {
                    case .none:
                        return !Location.isMonsBase(i, j) && !Location.isSuperManaBase(i, j)
                    case .mana, .monWithMana, .consumable:
                        return false
                    case let .mon(mon: mon):
                        if mon.kind == .drainer {
                            return !Location.isMonsBase(i, j) && !Location.isSuperManaBase(i, j)
                        } else {
                            return false
                        }
                    }
                }
                return available
            }
        case let .monWithMana(mon: mon, mana: mana):
            let available = nearbySpaces(from: from).filter { (i, j) -> Bool in
                let destination = board[i][j]
                
                switch destination {
                case .consumable, .none:
                    if Location.isMonsBase(i, j) {
                        let ownBase = mon.base
                        return ownBase.i == i && ownBase.j == j // TODO: implement getting home while leaving mana
                    } else if Location.isSuperManaBase(i, j) {
                        if case .superMana = mana {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        return true
                    }
                case .mana:
                    return true // TODO: implement jumping from mana to mana
                case .mon, .monWithMana:
                    return false
                }
            }
            return available
        case let .mon(mon: mon):
            let available = nearbySpaces(from: from).filter { (i, j) -> Bool in
                let destination = board[i][j]
                
                switch destination {
                case .consumable, .none:
                    if Location.isMonsBase(i, j) {
                        let ownBase = mon.base
                        return ownBase.i == i && ownBase.j == j
                    } else {
                        return !Location.isSuperManaBase(i, j)
                    }
                case .mana:
                    return mon.kind == .drainer
                case .mon, .monWithMana:
                    return false
                }
            }
            return available
        }
    }
    
    private func availableForAction(from: (Int, Int)) -> [(Int, Int)] {
        let piece = board[from.0][from.1]
        
        guard !Location.isMonsBase(from.0, from.1) else { return [] }
        
        switch piece {
        case .monWithMana, .mana, .none, .consumable:
            return []
        case let .mon(mon: mon):
            let i = from.0
            let j = from.1
            
            switch mon.kind {
            case .drainer, .angel:
                return []
            case .demon:
                let valid = [(i - 2, j), (i + 2, j), (i, j - 2), (i, j + 2)].filter { (a, b) -> Bool in
                    guard isValidLocation(a, b), !Location.isMonsBase(a, b) else { return false }
                    let validTarget: Bool
                    let destination = board[a][b]
                    switch destination {
                    case .monWithMana(mon: let targetMon, mana: _):
                        validTarget = mon.color != targetMon.color
                    case .mon(mon: let targetMon):
                        validTarget = mon.color != targetMon.color
                    case .consumable, .mana, .none:
                        return false
                    }
                    
                    guard case .none = board[(i + a) / 2][(j + b) / 2] else { return false }
                    return validTarget && !isProtectedByAngel((a, b)) // TODO: implement jumping out of super mana base
                }
                return valid
            case .mystic:
                let valid = [(i - 2, j - 2), (i + 2, j + 2), (i - 2, j + 2), (i + 2, j - 2)].filter { (i, j) -> Bool in
                    guard isValidLocation(i, j), !Location.isMonsBase(i, j) else { return false }
                    let validTarget: Bool
                    let destination = board[i][j]
                    switch destination {
                    case .monWithMana(mon: let targetMon, mana: _):
                        validTarget = mon.color != targetMon.color
                    case .mon(mon: let targetMon):
                        validTarget = mon.color != targetMon.color
                    case .consumable, .mana, .none:
                        return false
                    }
                    return validTarget && !isProtectedByAngel((i, j))
                }
                return valid
            case .spirit:
                var valid = [(Int, Int)]()
                for x in -2...2 {
                    for y in -2...2 {
                        guard max(abs(x), abs(y)) == 2 else { continue }
                        let a = i + x
                        let b = j + y
                        guard isValidLocation(a, b) else { continue }
                        
                        let destination = board[a][b]
                        switch destination {
                        case .consumable, .mana, .monWithMana:
                            valid.append((a, b))
                        case let .mon(mon):
                            if mon.isFainted {
                                continue
                            } else {
                                valid.append((a, b))
                            }
                        case .none:
                            continue
                        }
                    }
                }
                return valid
            }
        }
    }
    
    private func processInput() -> [Effect] {
        var effects = [Effect]()
        
        switch inputSequence.count {
        case 1:
            let index = inputSequence[0]
            
            var canSelect: Bool
            var forNextStep = [(Int, Int)]()
            var forAction = [(Int, Int)]()
            
            let piece = board[index.0][index.1]
            switch piece {
            case .none, .consumable:
                canSelect = false
            case let .mon(mon: mon):
                canSelect = mon.color == activeColor && !mon.isFainted
                forNextStep = canMoveMon ? availableForStep(from: index) : []
                forAction = canUseAction ? availableForAction(from: index) : []
                canSelect = canSelect && !(forNextStep.isEmpty && forAction.isEmpty)
            case let .mana(mana: mana):
                switch mana {
                case .superMana:
                    canSelect = false
                case let .regular(color: color):
                    canSelect = color == activeColor && canMoveMana
                    forNextStep = availableForStep(from: index)
                    canSelect = canSelect && !forNextStep.isEmpty
                }
            case let .monWithMana(mon: mon, mana: _):
                canSelect = mon.color == activeColor && !mon.isFainted
                forNextStep = canMoveMon ? availableForStep(from: index) : []
                canSelect = canSelect && !forNextStep.isEmpty
            }
            
            if canSelect {
                effects.append(.setSelected(index))
                
                let nextStepsEffects = forNextStep.map { Effect.availableForStep($0) }
                effects.append(contentsOf: nextStepsEffects)
                
                let nextActionEffects = forAction.map { Effect.availableForStep($0) }
                effects.append(contentsOf: nextActionEffects)
            } else {
                inputSequence = []
            }
            
            return effects
        case 2:
            let from = inputSequence[0]
            let to = inputSequence[1]
            
            // TODO: тут же понимаю, удобно ли по итогам хода оставить какую-то из клеток подсвеченной
            var (effects, didMove) = move(from: from, to: to)
            
            if didMove || effects.isEmpty {
                inputSequence = []
            }
            
            if !effects.isEmpty && didMove {
                effects += endTurnIfNeeded()
                effects += [.updateGameStatus]
            }
            
            return effects
        case 3:
            let spiritLocation = inputSequence[0]
            let targetLocation = inputSequence[1]
            let destinationLocation = inputSequence[2]
            
            inputSequence = []
            
            let spirit = board[spiritLocation.0][spiritLocation.1]
            let target = board[targetLocation.0][targetLocation.1]
            let destination = board[destinationLocation.0][destinationLocation.1]
            
            guard canUseAction, case let .mon(mon) = spirit, mon.kind == .spirit, !mon.isFainted else {
                return effects
            }
            
            guard max(abs(spiritLocation.0 - targetLocation.0), abs(spiritLocation.1 - targetLocation.1)) == 2 else {
                return effects
            }
            
            guard availableForStep(from: targetLocation, bySpiritMagic: true).contains(where: { $0.0 == destinationLocation.0 && $0.1 == destinationLocation.1 }) else {
                return effects
            }
            
            switch target {
            case .none:
                return effects
            case let .mana(mana):
                board[targetLocation.0][targetLocation.1] = .none
                if case let .mon(mon) = destination {
                    board[destinationLocation.0][destinationLocation.1] = Piece.monWithMana(mon: mon, mana: mana)
                } else {
                    board[destinationLocation.0][destinationLocation.1] = target
                }
            case .consumable:
                board[targetLocation.0][targetLocation.1] = .none
                if case let .mon(mon) = destination {
                    switch mon.color {
                    case .black:
                        blackPotionsCount += 1
                    case .white:
                        whitePotionsCount += 1
                    }
                } else if case let .monWithMana(mon, _) = destination {
                    switch mon.color {
                    case .black:
                        blackPotionsCount += 1
                    case .white:
                        whitePotionsCount += 1
                    }
                } else {
                    board[destinationLocation.0][destinationLocation.1] = target
                }
            case let .mon(mon):
                board[targetLocation.0][targetLocation.1] = .none
                if case .consumable = destination {
                    switch mon.color {
                    case .black:
                        blackPotionsCount += 1
                    case .white:
                        whitePotionsCount += 1
                    }
                    board[destinationLocation.0][destinationLocation.1] = target
                } else if case let .mana(mana) = destination {
                    board[destinationLocation.0][destinationLocation.1] = Piece.monWithMana(mon: mon, mana: mana)
                } else {
                    board[destinationLocation.0][destinationLocation.1] = target
                }
            case let .monWithMana(mon, _):
                if case .consumable = destination {
                    switch mon.color {
                    case .black:
                        blackPotionsCount += 1
                    case .white:
                        whitePotionsCount += 1
                    }
                }
                board[targetLocation.0][targetLocation.1] = .none
                board[destinationLocation.0][destinationLocation.1] = target
                // TODO: should be able to go to mana (later)
            }
            
            didUseAction()
            Audio.play(.spiritAbility) // tmp
            
            effects = [targetLocation, destinationLocation].map { Effect.updateCell($0) }
            effects += endTurnIfNeeded()
            effects += [.updateGameStatus]
            
            return effects
        default:
            return []
        }
    }
    
    var canMoveMon: Bool {
        monsMovesCount < 5 // TODO: add to game config
    }
    
    // TODO: flag is needed when moving drainer with mana. spirit can also move drainer with mana in a three ways
    private func move(from: (Int, Int), to: (Int, Int)) -> ([Effect], Bool) {
        let source = board[from.0][from.1]
        let destination = board[to.0][to.1]
        
        let xDistance = abs(to.1 - from.1)
        let yDistance = abs(to.0 - from.0)
        let distance = max(xDistance, yDistance)
        
        let isSpiritAction: Bool // TODO: there should be a better way to implement this
        switch source {
        case let .mon(mon: mon):
            isSpiritAction = mon.kind == .spirit && distance > 1 && !Location.isMonsBase(from.0, from.1)
        default:
            isSpiritAction = false
        }
        
        if Location.isMonsBase(to.0, to.1) && !isSpiritAction {
            switch source {
            case let .mon(mon: mon):
                let base = mon.base
                if base.i != to.0 || base.j != to.1 {
                    return ([], false)
                }
            case .none, .mana, .monWithMana, .consumable:
                return ([], false)
            }
        } else if Location.isSuperManaBase(to.0, to.1), distance == 1 { // TODO: remove implicit move / action disambiguation by checking distance
            switch source {
            case let .mon(mon: mon):
                guard mon.kind == .drainer, case let .mana(mana) = destination, case .superMana = mana else { return ([], false) }
            case let .monWithMana(mon: mon, mana: mana):
                guard mon.kind == .drainer, case .superMana = mana else { return ([], false) }
            case .consumable, .mana, .none:
                return ([], false)
            }
        }
        
        switch source {
        case .mon(let mon):
            guard !mon.isFainted && mon.color == activeColor else { return ([], false) }
            
            if distance == 1 {
                guard canMoveMon else { return ([], false) }
                
                switch destination {
                case .mon, .monWithMana:
                    return ([], false)
                case .mana(let mana):
                    guard mon.kind == .drainer else { return ([], false) }
                    board[from.0][from.1] = .none
                    board[to.0][to.1] = Piece.monWithMana(mon: mon, mana: mana)
                    Audio.play(.manaPickUp)
                    monsMovesCount += 1
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .consumable(let consumable):
                    switch consumable {
                    case .potion:
                        switch activeColor {
                        case .white:
                            whitePotionsCount += 1
                        case .black:
                            blackPotionsCount += 1
                        }
                    }
                    board[from.0][from.1] = .none
                    board[to.0][to.1] = source
                    monsMovesCount += 1
                    Audio.play(.pickUpPotion)
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .none:
                    // TODO: move this boilerplate moving into a separate function
                    board[from.0][from.1] = .none
                    board[to.0][to.1] = source
                    monsMovesCount += 1
                    switch mon.kind {
                    case .demon:
                        Audio.play(.demonMove)
                    default:
                        Audio.play(.move)
                    }
                    return ([from, to].map { Effect.updateCell($0) }, true)
                }
            } else {
                guard canUseAction else { return ([], false) }
                
                switch mon.kind {
                case .mystic:
                    guard xDistance == 2 && yDistance == 2, !isProtectedByAngel(to) else { return ([], false) }
                    
                    switch destination {
                    case .none, .mana, .consumable:
                        return ([], false)
                    case .mon(mon: var targetMon):
                        guard targetMon.color != mon.color else { return ([], false) }
                        board[to.0][to.1] = .none
                        didUseAction()
                        
                        let faintIndex = targetMon.base
                        targetMon.faint()
                        board[faintIndex.0][faintIndex.1] = .mon(mon: targetMon)
                        Audio.play(.mysticAbility)
                        return ([faintIndex, to].map { Effect.updateCell($0) }, true)
                    case .monWithMana(mon: var targetMon, mana: let mana):
                        guard targetMon.color != mon.color else { return ([], false) }
                        
                        let manaIndex: (Int, Int)
                        switch mana {
                        case .regular:
                            manaIndex = to
                            board[to.0][to.1] = .mana(mana: mana)
                        case .superMana:
                            manaIndex = (5, 5) // TODO: move to the config
                            board[to.0][to.1] = .none
                            board[manaIndex.0][manaIndex.1] = .mana(mana: mana)
                        }
                        
                        didUseAction()
                        Audio.play(.mysticAbility)
                        
                        let faintIndex = targetMon.base
                        targetMon.faint()
                        board[faintIndex.0][faintIndex.1] = .mon(mon: targetMon)
                        
                        // TODO: in regular mana case manaIndex == to
                        // TODO: do not add repeating indices in the first place
                        return ([manaIndex, faintIndex, to].map { Effect.updateCell($0) }, true)
                    }
                case .demon:
                    guard !isProtectedByAngel(to), xDistance == 2 && yDistance == 0 || xDistance == 0 && yDistance == 2 else { return ([], false) }
                    
                    let between = ((from.0 + to.0) / 2, (from.1 + to.1) / 2)
                    guard case .none = board[between.0][between.1] else { return ([], false) }
                    
                    switch destination {
                    case .none, .mana, .consumable:
                        return ([], false)
                    case .mon(mon: var targetMon):
                        guard targetMon.color != mon.color else { return ([], false) }
                        
                        board[from.0][from.1] = .none
                        board[to.0][to.1] = source
                        didUseAction()
                        Audio.play(.demonAbility)
                        // TODO: move fainting to the separate function. these three lines repeat in each fainting case
                        let faintIndex = targetMon.base
                        targetMon.faint()
                        board[faintIndex.0][faintIndex.1] = .mon(mon: targetMon)
                        
                        return ([faintIndex, from, to].map { Effect.updateCell($0) }, true)
                    case .monWithMana(mon: var targetMon, mana: let mana):
                        guard targetMon.color != mon.color else { return ([], false) }
                        let manaIndex: (Int, Int)
                        var also = (0, 0) // TODO: just add it to the list when needed
                        switch mana {
                        case .regular:
                            manaIndex = to
                            board[to.0][to.1] = .mana(mana: mana)
                            let additionalStep = nearbySpaces(from: to).first(where: { (i, j) -> Bool in
                                let destination = board[i][j]
                                switch destination {
                                case .none:
                                    return !Location.isMonsBase(i, j) && !Location.isSuperManaBase(i, j)
                                case .mana, .consumable, .monWithMana, .mon:
                                    // TODO: should be able to pick up a potion
                                    return false
                                }
                            })
                            if let additionalStep = additionalStep {
                                board[additionalStep.0][additionalStep.1] = source
                                also = additionalStep
                            }
                        case .superMana:
                            manaIndex = (5, 5) // TODO: move to the config
                            board[manaIndex.0][manaIndex.1] = .mana(mana: mana)
                            board[to.0][to.1] = source
                        }
                        
                        board[from.0][from.1] = .none
                        
                        let faintIndex = targetMon.base
                        targetMon.faint()
                        board[faintIndex.0][faintIndex.1] = .mon(mon: targetMon)
                        
                        didUseAction()
                        Audio.play(.demonAbility)
                        // TODO: in regular mana case manaIndex == to
                        // TODO: do not add repeating indices in the first place
                        return ([manaIndex, faintIndex, from, to, also].map { Effect.updateCell($0) }, true)
                    }
                case .spirit:
                    guard max(abs(from.0 - to.0), abs(from.1 - to.1)) == 2 else { return ([], false) }
                    switch board[to.0][to.1] {
                    case .none:
                        return ([], false)
                    case let .mon(mon):
                        if mon.isFainted {
                            return ([], false)
                        }
                    case .mana, .consumable, .monWithMana:
                        break
                    }
                    
                    let nextStep = availableForStep(from: to, bySpiritMagic: true).map { Effect.availableForStep($0) }
                    
                    return ([Effect.setSelected(from), Effect.setSelected(to)] + nextStep, false)
                case .angel, .drainer:
                    return ([], false)
                }
            }
        case let .mana(mana):
            if distance == 1 {
                guard case let .regular(color) = mana, color == activeColor && canMoveMana else { return ([], false) }
                switch destination {
                case .none:
                    if let poolColor = poolColor(to.0, to.1) {
                        board[from.0][from.1] = .none
                        board[to.0][to.1] = .none
                        switch poolColor {
                        case .white:
                            whiteScore += 1
                        case .black:
                            blackScore += 1
                        }
                        Audio.play(.scoreMana)
                    } else {
                        board[from.0][from.1] = .none
                        board[to.0][to.1] = source
                        Audio.play(.moveMana)
                    }
                    manaMoved = true
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case let .mon(mon: mon):
                    guard mon.kind == .drainer else { return ([], false) }
                    board[from.0][from.1] = .none
                    board[to.0][to.1] = Piece.monWithMana(mon: mon, mana: mana)
                    Audio.play(.manaPickUp)
                    manaMoved = true
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .mana, .monWithMana, .consumable:
                    return ([], false)
                }
            } else {
                return ([], false)
            }
        case let .monWithMana(mon, mana):
            if distance == 1 {
                guard canMoveMon && !mon.isFainted && mon.color == activeColor else { return ([], false) }
                switch destination {
                case .mon, .monWithMana, .mana:
                    return ([], false)
                case .consumable(let consumable):
                    switch consumable {
                    case .potion:
                        switch activeColor {
                        case .white:
                            whitePotionsCount += 1
                        case .black:
                            blackPotionsCount += 1
                        }
                    }
                    Audio.play(.pickUpPotion)
                    board[from.0][from.1] = .none
                    board[to.0][to.1] = source
                    monsMovesCount += 1
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .none:
                    if let poolColor = poolColor(to.0, to.1) {
                        board[from.0][from.1] = .none
                        board[to.0][to.1] = .mon(mon: mon)
                        
                        let delta: Int
                        switch mana {
                        case .superMana:
                            delta = 2
                            Audio.play(.scoreSuperMana)
                        case .regular:
                            delta = 1
                            Audio.play(.scoreMana)
                        }
                        
                        switch poolColor {
                        case .white:
                            whiteScore += delta
                        case .black:
                            blackScore += delta
                        }
                    } else {
                        board[from.0][from.1] = .none
                        board[to.0][to.1] = source
                        Audio.play(.move)
                    }
                    
                    monsMovesCount += 1
                    return ([from, to].map { Effect.updateCell($0) }, true)
                }
            } else {
                return ([], false)
            }
        case .consumable, .none:
            return ([], false)
        }
    }
    
    func poolColor(_ i: Int, _ j: Int) -> Color? {
        let endIndex = boardSize - 1
        switch (i, j) {
        case (0, 0), (0, endIndex):
            return .black
        case (endIndex, 0), (endIndex, endIndex):
            return .white
        default:
            return nil
        }
    }
    
    private func endTurn() -> [Effect] {
        activeColor = activeColor == .white ? .black : .white
        actionUsed = false
        manaMoved = false
        monsMovesCount = 0
        
        // TODO: keep set of mons to avoid iterating so much
        var indicesToUpdate = [(Int, Int)]()
        for i in [0, boardSize - 1] {
            for j in 0..<boardSize {
                let piece = board[i][j]
                if case var .mon(mon) = piece, mon.color == activeColor, mon.isFainted {
                    mon.decreaseCooldown()
                    board[i][j] = .mon(mon: mon)
                    if !mon.isFainted {
                        indicesToUpdate.append((i, j))
                    }
                }
            }
        }
       
        turnNumber += 1
        
        let effects = indicesToUpdate.map { Effect.updateCell($0) }
        
        inputSequence = []
        
        return effects
    }
    
    private func endTurnIfNeeded() -> [Effect] {
        guard winnerColor == nil else { return [] }
        
        if isFirstTurn && !canMoveMon ||
            !isFirstTurn && !canMoveMana ||
            !isFirstTurn && !canMoveMon && !hasFreeMana {
            return endTurn()
        } else {
            return []
        }
    }
    
    // TODO: move target score to the game config
    var winnerColor: Color? {
        if whiteScore >= 5 {
            return .white
        } else if blackScore >= 5 {
            return .black
        } else {
            return nil
        }
    }
    
    var fen: String {
        let fields = [
            String(version),
            String(whiteScore),
            String(blackScore),
            activeColor.fen,
            actionUsed.fen,
            manaMoved.fen,
            String(monsMovesCount),
            String(whitePotionsCount),
            String(blackPotionsCount),
            String(turnNumber),
            board.fen
        ]
        return fields.joined(separator: " ")
    }
    
    // TODO: keep it or remove it
    func moves() -> [String] {
        // Returns a list of legal moves from the current position.
        // Optionally takes previous input / selected piece / square as an argument
        return []
    }
    
    func squareColor() {
        // TODO: use for board setup
        // should know color types, not the exact colors
    }
    
}
