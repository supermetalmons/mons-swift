// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: do not play audio from the game logic code

// TODO: do not pass index tuples, instead use locations everywhere
struct Location: Equatable, Hashable {
    let i: Int
    let j: Int
    
    init(_ i: Int, _ j: Int) {
        self.i = i
        self.j = j
    }
    
    // TODO: DRY
    private static let monsBases: Set<Location> = {
        let coordinates = [(10, 5), (0, 5), (10, 4), (0, 6), (10, 6), (0, 4), (10, 3), (0, 7), (10, 7), (0, 3)]
        return Set(coordinates.map { Location($0.0, $0.1) })
    }()
    
    static func isMonsBase(_ i: Int, _ j: Int) -> Bool {
        return monsBases.contains(Location(i, j))
    }
    
    static func isSuperManaBase(_ i: Int, _ j: Int) -> Bool {
        // TODO: DRY
        return i == 5 && j == 5
    }
    
}

enum Effect {
    case availableForStep((Int, Int))
    case updateCell((Int, Int)) // TODO: use Location here as well
    case setSelected((Int, Int))
    case updateGameStatus
}

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
    
    var redScore: Int
    var blueScore: Int
    
    var activeColor: Color
    var actionUsed: Bool // TODO: use int here to make game more configurable
    var manaMoved: Bool // TODO: use int here to make game more configurable
    var monsMovesCount: Int
    
    var redPotionsCount: Int
    var bluePotionsCount: Int
    
    var turnNumber: Int
    var board: [[Space]]
    
    var isFirstTurn: Bool { return turnNumber == 1 }
    
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
             .mon(mon: Mon(kind: .mystic, color: .blue)), // 3
             .mon(mon: Mon(kind: .spirit, color: .blue)), // 4
             .mon(mon: Mon(kind: .drainer, color: .blue)), // 5
             .mon(mon: Mon(kind: .angel, color: .blue)), // 6
             .mon(mon: Mon(kind: .demon, color: .blue)), // 7
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
             .mon(mon: Mon(kind: .demon, color: .red)), // 3
             .mon(mon: Mon(kind: .angel, color: .red)), // 4
             .mon(mon: Mon(kind: .drainer, color: .red)), // 5
             .mon(mon: Mon(kind: .spirit, color: .red)), // 6
             .mon(mon: Mon(kind: .mystic, color: .red)), // 7
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
    
    
    private var potionsCount: Int {
        return activeColor == .red ? redPotionsCount : bluePotionsCount
    }
    
    private var canUseAction: Bool {
        return !isFirstTurn && (!actionUsed || potionsCount > 0)
    }
    
    private var canMoveMana: Bool {
        return !isFirstTurn && !manaMoved
    }
    
    private func didUseAction() {
        if !actionUsed {
            actionUsed = true
        } else {
            switch activeColor {
            case .red:
                redPotionsCount -= 1
            case .blue:
                bluePotionsCount -= 1
            }
        }
    }
    
    private func isProtectedByAngel(_ index: (Int, Int)) -> Bool {
        // TODO: keep set of mons to avoid iterating so much
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                let space = board[i][j]
                if case let .mon(mon) = space, mon.kind == .angel, mon.color != activeColor {
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
        let space = board[from.0][from.1]
        switch space {
        case .empty:
            return []
        case .consumable:
            if bySpiritMagic {
                let available = nearbySpaces(from: from).filter { (i, j) -> Bool in
                    let destination = board[i][j]
                    
                    switch destination {
                    case .empty:
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
                        case .empty:
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
                    case .empty:
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
                case .consumable, .empty:
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
                case .consumable, .empty:
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
        let space = board[from.0][from.1]
        
        switch space {
        case .monWithMana, .mana, .empty, .consumable:
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
                    case .consumable, .mana, .empty:
                        return false
                    }
                    
                    guard case .empty = board[(i + a) / 2][(j + b) / 2] else { return false }
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
                    case .consumable, .mana, .empty:
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
                        case .empty:
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
            
            let space = board[index.0][index.1]
            switch space {
            case .empty, .consumable:
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
            case .empty:
                return effects
            case let .mana(mana):
                board[targetLocation.0][targetLocation.1] = .empty
                if case let .mon(mon) = destination {
                    board[destinationLocation.0][destinationLocation.1] = Space.monWithMana(mon: mon, mana: mana)
                } else {
                    board[destinationLocation.0][destinationLocation.1] = target
                }
            case .consumable:
                board[targetLocation.0][targetLocation.1] = .empty
                if case let .mon(mon) = destination {
                    switch mon.color {
                    case .blue:
                        bluePotionsCount += 1
                    case .red:
                        redPotionsCount += 1
                    }
                } else if case let .monWithMana(mon, _) = destination {
                    switch mon.color {
                    case .blue:
                        bluePotionsCount += 1
                    case .red:
                        redPotionsCount += 1
                    }
                } else {
                    board[destinationLocation.0][destinationLocation.1] = target
                }
            case let .mon(mon):
                board[targetLocation.0][targetLocation.1] = .empty
                if case .consumable = destination {
                    switch mon.color {
                    case .blue:
                        bluePotionsCount += 1
                    case .red:
                        redPotionsCount += 1
                    }
                    board[destinationLocation.0][destinationLocation.1] = target
                } else if case let .mana(mana) = destination {
                    board[destinationLocation.0][destinationLocation.1] = Space.monWithMana(mon: mon, mana: mana)
                } else {
                    board[destinationLocation.0][destinationLocation.1] = target
                }
            case let .monWithMana(mon, _):
                if case .consumable = destination {
                    switch mon.color {
                    case .blue:
                        bluePotionsCount += 1
                    case .red:
                        redPotionsCount += 1
                    }
                }
                board[targetLocation.0][targetLocation.1] = .empty
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
            isSpiritAction = mon.kind == .spirit && distance > 1
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
            case .empty, .mana, .monWithMana, .consumable:
                return ([], false)
            }
        } else if Location.isSuperManaBase(to.0, to.1), distance == 1 { // TODO: remove implicit move / action disambiguation by checking distance
            switch source {
            case let .mon(mon: mon):
                guard mon.kind == .drainer, case let .mana(mana) = destination, case .superMana = mana else { return ([], false) }
            case let .monWithMana(mon: mon, mana: mana):
                guard mon.kind == .drainer, case .superMana = mana else { return ([], false) }
            case .consumable, .mana, .empty:
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
                    board[from.0][from.1] = .empty
                    board[to.0][to.1] = Space.monWithMana(mon: mon, mana: mana)
                    Audio.play(.manaPickUp)
                    monsMovesCount += 1
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .consumable(let consumable):
                    switch consumable {
                    case .potion:
                        switch activeColor {
                        case .red:
                            redPotionsCount += 1
                        case .blue:
                            bluePotionsCount += 1
                        }
                    }
                    board[from.0][from.1] = .empty
                    board[to.0][to.1] = source
                    monsMovesCount += 1
                    Audio.play(.pickUpPotion)
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .empty:
                    // TODO: move this boilerplate moving into a separate function
                    board[from.0][from.1] = .empty
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
                    case .empty, .mana, .consumable:
                        return ([], false)
                    case .mon(mon: var targetMon):
                        guard targetMon.color != mon.color else { return ([], false) }
                        board[to.0][to.1] = .empty
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
                            board[to.0][to.1] = .empty
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
                    guard case .empty = board[between.0][between.1] else { return ([], false) }
                    
                    switch destination {
                    case .empty, .mana, .consumable:
                        return ([], false)
                    case .mon(mon: var targetMon):
                        guard targetMon.color != mon.color else { return ([], false) }
                        
                        board[from.0][from.1] = .empty
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
                                case .empty:
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
                        
                        board[from.0][from.1] = .empty
                        
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
                    case .empty:
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
                case .empty:
                    if let poolColor = poolColor(to.0, to.1) {
                        board[from.0][from.1] = .empty
                        board[to.0][to.1] = .empty
                        switch poolColor {
                        case .red:
                            redScore += 1
                        case .blue:
                            blueScore += 1
                        }
                        Audio.play(.scoreMana)
                    } else {
                        board[from.0][from.1] = .empty
                        board[to.0][to.1] = source
                        Audio.play(.moveMana)
                    }
                    manaMoved = true
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case let .mon(mon: mon):
                    guard mon.kind == .drainer else { return ([], false) }
                    board[from.0][from.1] = .empty
                    board[to.0][to.1] = Space.monWithMana(mon: mon, mana: mana)
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
                        case .red:
                            redPotionsCount += 1
                        case .blue:
                            bluePotionsCount += 1
                        }
                    }
                    Audio.play(.pickUpPotion)
                    board[from.0][from.1] = .empty
                    board[to.0][to.1] = source
                    monsMovesCount += 1
                    return ([from, to].map { Effect.updateCell($0) }, true)
                case .empty:
                    if let poolColor = poolColor(to.0, to.1) {
                        board[from.0][from.1] = .empty
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
                        case .red:
                            redScore += delta
                        case .blue:
                            blueScore += delta
                        }
                    } else {
                        board[from.0][from.1] = .empty
                        board[to.0][to.1] = source
                        Audio.play(.move)
                    }
                    
                    monsMovesCount += 1
                    return ([from, to].map { Effect.updateCell($0) }, true)
                }
            } else {
                return ([], false)
            }
        case .consumable, .empty:
            return ([], false)
        }
    }
    
    func poolColor(_ i: Int, _ j: Int) -> Color? {
        let endIndex = boardSize - 1
        switch (i, j) {
        case (0, 0), (0, endIndex):
            return .blue
        case (endIndex, 0), (endIndex, endIndex):
            return .red
        default:
            return nil
        }
    }
    
    private func endTurn() -> [Effect] {
        activeColor = activeColor == .red ? .blue : .red
        actionUsed = false
        manaMoved = false
        monsMovesCount = 0
        
        // TODO: keep set of mons to avoid iterating so much
        var indicesToUpdate = [(Int, Int)]()
        for i in [0, boardSize - 1] {
            for j in 0..<boardSize {
                let space = board[i][j]
                if case var .mon(mon) = space, mon.color == activeColor, mon.isFainted {
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
        guard winnerColor == nil,
              (isFirstTurn && !canMoveMon) ||
                (!isFirstTurn && !canMoveMana) else { return [] }
        return endTurn()
    }
    
    // TODO: move target score to the game config
    var winnerColor: Color? {
        if redScore >= 5 {
            return .red
        } else if blueScore >= 5 {
            return .blue
        } else {
            return nil
        }
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
