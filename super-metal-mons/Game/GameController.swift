// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

protocol GameView: AnyObject {
    func didConnect()
    func updateOpponentEmoji()
    func updateEmoji(color: Color)
    func applyEffects(_ effects: [ViewEffect])
    func showMessageAndDismiss(message: String)
    func setNewBoard()
}

extension GameController: ConnectionDelegate {
    
    func enterWatchOnlyMode() {
        isWatchOnly = true
    }
    
    private func setInitiallyProcessedMovesCount(color: Color, count: Int) {
        switch color {
        case .black:
            if !didSetBlackProcessedMovesCount {
                blackProcessedMovesCount = count
                didSetBlackProcessedMovesCount = true
            }
        case .white:
            if !didSetWhiteProcessedMovesCount {
                whiteProcessedMovesCount = count
                didSetWhiteProcessedMovesCount = true
            }
        }
    }
    
    func didUpdate(match: PlayerMatch) {
        guard didConnect else {
            didConnect = true
            
            if isWatchOnly {
                self.playerSideColor = .white
                updateEmoji(color: match.color, id: match.emojiId)
            } else {
                self.playerSideColor = match.color.other
                updateOpponentEmoji(id: match.emojiId)
            }
            
            if isWatchOnly, let game = MonsGame(fen: match.fen) {
                self.game = game
                gameView.setNewBoard()
                setInitiallyProcessedMovesCount(color: match.color, count: match.moves?.count ?? 0)
            }
            
            gameView.didConnect()
            Audio.shared.play(.didConnect)
            
            return
        }
        
        if isWatchOnly, !didSetBlackProcessedMovesCount || !didSetWhiteProcessedMovesCount {
            if let newGame = MonsGame(fen: match.fen), newGame.isLaterThan(game: game) {
                self.game = newGame
                gameView.setNewBoard()
            }
            setInitiallyProcessedMovesCount(color: match.color, count: match.moves?.count ?? 0)
        }
        
        // TODO: do not update stuff that did not actually change
        
        if isWatchOnly {
            updateEmoji(color: match.color, id: match.emojiId)
            gameView.updateEmoji(color: match.color)
        } else {
            updateOpponentEmoji(id: match.emojiId)
            gameView.updateOpponentEmoji()
        }
        
        let processedMoves = processedMovesCount(color: match.color)
        if let moves = match.moves, moves.count > processedMoves {
            for i in processedMoves..<moves.count {
                processRemoteInputs(moves[i])
            }
            
            setProcessedMovesCount(color: match.color, count: moves.count)
            
            if game.fen != match.fen {
                gameView.showMessageAndDismiss(message: Strings.somethingIsBroken)
                connection = nil
                return
            }
        }
        
        if match.status == .surrendered {
            gameView.showMessageAndDismiss(message: Strings.opponentLeft)
            connection = nil
        }
        
        // TODO: should update game statuses as well sometime – after connection as well – or use less statuses
    }
    
}

// TODO: refactor
class GameController {
    
    func setProcessedMovesCount(color: Color, count: Int) {
        switch color {
        case .black: blackProcessedMovesCount = count
        case .white: whiteProcessedMovesCount = count
        }
    }
    
    func processedMovesCount(color: Color) -> Int {
        switch color {
        case .black: return blackProcessedMovesCount
        case .white: return whiteProcessedMovesCount
        }
    }
    
    private var didSetWhiteProcessedMovesCount = false
    private var didSetBlackProcessedMovesCount = false
    
    private var whiteProcessedMovesCount = 0
    private var blackProcessedMovesCount = 0
    
    private var versusComputer = false
    
    private func updateEmoji(color: Color, id: Int) {
        switch color {
        case .white:
            whiteEmojiId = id
        case .black:
            blackEmojiId = id
        }
    }
    
    private func updateOpponentEmoji(id: Int) {
        updateEmoji(color: playerSideColor.other, id: id)
    }
    
    var isWatchOnly = false
    
    enum Mode {
        case localGame
        case createInvite
        case joinGameId(String)
        
        var isRemoteGame: Bool {
            switch self {
            case .createInvite, .joinGameId:
                return true
            case .localGame:
                return false
            }
        }
    }
    
    var didConnect = false
    var playerSideColor: Color
    var whiteEmojiId: Int
    var blackEmojiId: Int
    
    var shouldAutoFlipBoard: Bool {
        if case .localGame = mode, !versusComputer {
            return true
        } else {
            return false
        }
    }
    
    // TODO: refactor, move somewhere
    enum AssistedInputKind {
        case keepSelectionAfterMove
        case findStartLocationsAfterInvalidInput
        case reselectLastInvalidInput
    }
    
    var winnerColor: Color? {
        return game.winnerColor
    }
    
    var activeColor: Color {
        return game.activeColor
    }
    
    var availableMoves: [AvailableMoveKind: Int] {
        return game.availableMoveKinds
    }
    
    var blackScore: Int {
        return game.blackScore
    }
    
    var whiteScore: Int {
        return game.whiteScore
    }
    
    let boardStyle = BoardStyle.pixel
    
    // idk about this one
    // yeah i feel like we should keep it private
    var board: Board {
        return game.board
    }

    let mode: Mode
    private let gameId: String
    private var connection: Connection?
    private let version = 1
    
    private unowned var gameView: GameView!

    var inviteLink: String {
        return URL.forGame(id: gameId)
    }
    
    init(mode: Mode) {
        self.mode = mode
        
        let emojiId = Images.randomEmojiId
        whiteEmojiId = emojiId
        blackEmojiId = emojiId
        
        switch mode {
        case .localGame:
            gameId = ""
            connection = nil
            playerSideColor = .white
            blackEmojiId = Images.randomEmojiId
        case .createInvite:
            let id = String.newGameId
            self.gameId = id
            self.connection = Connection(gameId: id)
            playerSideColor = .random
            connection?.addInvite(id: id, version: version, hostColor: playerSideColor, emojiId: emojiId, fen: game.fen)
        case .joinGameId(let gameId):
            self.gameId = gameId
            self.connection = Connection(gameId: gameId)
            playerSideColor = .random
            connection?.joinGame(id: gameId, emojiId: emojiId)
        }
        
        connection?.setDelegate(self)
    }
    
    // idk about this one
    // TODO: this one can be created immediatelly for local & invite mode
    // TODO: this one might be different when joining
    
    private var game = MonsGame()
    
    func didSelectGameVersusComputer() {
        versusComputer = true
        blackEmojiId = Images.computerEmojiId // TODO: will be different when will play random color vs computer
    }
    
    func setGameView(_ gameView: GameView) {
        self.gameView = gameView
    }
    
    func useDifferentEmoji() -> UIImage {
        guard !isWatchOnly else { return Images.emoji(whiteEmojiId) }
        
        let emojiId = Images.randomEmojiId(except: whiteEmojiId, andExcept: blackEmojiId)
        connection?.updateEmoji(id: emojiId)
        
        switch playerSideColor {
        case .white:
            whiteEmojiId = emojiId
        case .black:
            blackEmojiId = emojiId
        }
        
        if !didConnect && mode.isRemoteGame {
            whiteEmojiId = emojiId
            blackEmojiId = emojiId
        }
        
        return Images.emoji(emojiId)
    }
    
    func endGame() {
        guard !isWatchOnly else { return }
        if winnerColor == nil {
            connection?.updateStatus(.surrendered)
        }
    }
    
    private var inputs = [MonsGame.Input]()
    private var cachedOutput: MonsGame.Output?
    
    // TODO: refactor
    private func processRemoteInputs(_ inputs: [MonsGame.Input]) {
        self.inputs = inputs
        self.inputs.removeLast()
        let viewEffects = processInput(inputs.last, remoteOrComputerInput: true)
        gameView.applyEffects(viewEffects)
    }
    
    private func makeComputerMoveAfterSmallDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
            self?.makeComputerMove()
        }
    }
    
    private func makeComputerMove() {
        let computerColor = activeColor
        
        let viewEffects = processInput(nil, remoteOrComputerInput: true)
        gameView.applyEffects(viewEffects)
        
        if activeColor == computerColor {
            makeComputerMoveAfterSmallDelay()
        }
    }
    
    // TODO: refactor
    func processInput(_ input: MonsGame.Input?, assistedInputKind: AssistedInputKind? = nil, remoteOrComputerInput: Bool = false) -> [ViewEffect] {
        guard !isWatchOnly || remoteOrComputerInput else { return [] }
        
        switch mode {
        case .localGame:
            guard !versusComputer || activeColor == playerSideColor || remoteOrComputerInput else { return [] }
        case .createInvite, .joinGameId:
            guard remoteOrComputerInput || activeColor == playerSideColor else { return [] }
        }
        
        var viewEffects = [ViewEffect]()
        var highlights = [Highlight]()
        var traces = [Trace]()
        
        if let input = input {
            inputs.append(input)
        }
        
        var output: MonsGame.Output
        if inputs.isEmpty, let cachedOutput = cachedOutput {
            output = cachedOutput
        } else {
            output = game.processInput(inputs)
        }
        
        if case .localGame = mode, remoteOrComputerInput {
            switch output {
            case let .locationsToStartFrom(locations):
                guard let start = locations.randomElement() else { return [] }
                inputs.append(.location(start))
                var didMakeMove = false
                while !didMakeMove {
                    output = game.processInput(inputs)
                    switch output {
                    case .invalidInput, .locationsToStartFrom:
                        return []
                    case let .nextInputOptions(nextInputOptions):
                        guard let nextInput = nextInputOptions.randomElement()?.input else { return [] }
                        inputs.append(nextInput)
                    case .events:
                        didMakeMove = true
                    }
                }
                
            default:
                return []
            }
        }
        
        switch output {
        case let .events(events):
            if !remoteOrComputerInput {
                connection?.makeMove(inputs: inputs, newFen: game.fen)
            }
            
            cachedOutput = nil
            inputs = []
            var locationsToUpdate = Set<Location>()
            
            var mightKeepHighlightOnLocation: Location?
            var mustReleaseHighlight = false
            
            var sounds = [Sound]()
            
            for event in events {
                switch event {
                case .monMove(_, let from, let to):
                    sounds.append(.move)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    mightKeepHighlightOnLocation = to
                    traces.append(Trace(from: from, to: to, kind: .monMove))
                case .manaMove(_, let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    traces.append(Trace(from: from, to: to, kind: .manaMove))
                case let .manaScored(mana, at):
                    switch mana {
                    case .regular:
                        sounds.append(.scoreMana)
                    case .supermana:
                        sounds.append(.scoreSupermana)
                    }
                    locationsToUpdate.insert(at)
                    mustReleaseHighlight = true
                case .mysticAction(_, let from, let to):
                    sounds.append(.mysticAbility)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    traces.append(Trace(from: from, to: to, kind: .mysticAction))
                case .demonAction(_, let from, let to):
                    sounds.append(.demonAbility)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    traces.append(Trace(from: from, to: to, kind: .demonAction))
                case .demonAdditionalStep(_, let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    traces.append(Trace(from: from, to: to, kind: .demonAdditionalStep))
                case .spiritTargetMove(_, let from, let to):
                    sounds.append(.spiritAbility)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    traces.append(Trace(from: from, to: to, kind: .spiritTargetMove))
                case .pickupBomb(_, let at):
                    sounds.append(.pickupBomb)
                    locationsToUpdate.insert(at)
                    mustReleaseHighlight = true
                case .pickupPotion(_, let at):
                    sounds.append(.pickupPotion)
                    locationsToUpdate.insert(at)
                    mustReleaseHighlight = true
                case .pickupMana(_, _, let at):
                    sounds.append(.manaPickUp)
                    locationsToUpdate.insert(at)
                case .monFainted(_, let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .manaDropped(_, let at):
                    locationsToUpdate.insert(at)
                case .supermanaBackToBase(let from, let to):
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                case .bombAttack(_, let from, let to):
                    sounds.append(.bomb)
                    locationsToUpdate.insert(from)
                    locationsToUpdate.insert(to)
                    traces.append(Trace(from: from, to: to, kind: .bomb))
                case .monAwake(_, let at):
                    locationsToUpdate.insert(at)
                case .bombExplosion(let at):
                    sounds.append(.bomb)
                    locationsToUpdate.insert(at)
                case .nextTurn(_):
                    sounds.append(.endTurn)
                    viewEffects.append(.nextTurn)
                    if case .localGame = mode, versusComputer && !remoteOrComputerInput {
                        makeComputerMoveAfterSmallDelay()
                    }
                case let .gameOver(winner):
                    if winner == playerSideColor {
                        sounds.append(.victory)
                    } else {
                        sounds.append(.defeat)
                    }
                }
            }
            
            let maxSoundPriority = sounds.max(by: { $0.priority < $1.priority })?.priority
            sounds = sounds.filter { $0.priority == maxSoundPriority || $0 == .endTurn }
            Audio.shared.play(sounds: sounds)
            
            if let to = mightKeepHighlightOnLocation, !mustReleaseHighlight {
                let nextMoveHighlights = processInput(.location(to), assistedInputKind: .keepSelectionAfterMove)
                if !nextMoveHighlights.isEmpty {
                    viewEffects.append(contentsOf: nextMoveHighlights)
                }
            }
            
            viewEffects.append(ViewEffect.updateCells(Array(locationsToUpdate)))
            viewEffects.append(.updateGameStatus)
        case let .nextInputOptions(nextInputOptions):
            for (index, input) in inputs.enumerated() {
                if case let .location(location) = input {
                    let color: Highlight.Color
                    
                    if index > 0 {
                        switch nextInputOptions.last?.kind {
                        case .demonAdditionalStep:
                            color = .attackTarget
                        case .spiritTargetMove:
                            color = .spiritTarget
                        default:
                            color = .selectedStartItem
                        }
                    } else {
                        color = .selectedStartItem
                    }
                    
                    highlights.append(Highlight(location: location, kind: .selected, color: color, isBlink: false))
                }
            }
            
            for nextInputOption in nextInputOptions {
                if nextInputOption.kind == .selectConsumable {
                    viewEffects.append(.selectBombOrPotion)
                }
                
                switch nextInputOption.input {
                case .location(let location):
                    let locationIsEmpty = board.item(at: location) == nil
                    
                    let highlightKind: Highlight.Kind
                    let highlightColor: Highlight.Color
                    let isBase = Config.monsBases.contains(location)
                    let emptySquareHighlight: Highlight.Kind = isBase ? .targetSuggestion : .emptySquare
                    
                    switch nextInputOption.kind {
                    case .monMove, .manaMove, .selectConsumable:
                        highlightKind = locationIsEmpty ? emptySquareHighlight : .targetSuggestion
                        highlightColor = locationIsEmpty ? .emptyStepDestination : .destinationItem
                    case .mysticAction, .demonAction, .bombAttack:
                        highlightKind = .targetSuggestion
                        highlightColor = .attackTarget
                    case .demonAdditionalStep:
                        highlightKind = locationIsEmpty ? emptySquareHighlight : .targetSuggestion
                        highlightColor = .attackTarget
                    case .spiritTargetCapture:
                        highlightKind = .targetSuggestion
                        highlightColor = .spiritTarget
                    case .spiritTargetMove:
                        highlightKind = locationIsEmpty ? emptySquareHighlight : .targetSuggestion
                        highlightColor = .spiritTarget
                    }
                    
                    highlights.append(Highlight(location: location, kind: highlightKind, color: highlightColor, isBlink: false))
                case .modifier:
                    break
                }
            }
            
        case .invalidInput:
            let shouldTryToReselect = assistedInputKind == nil && inputs.count > 1 && inputs.first != input
            let shouldHelpFindOptions = assistedInputKind == nil && inputs.count == 1
            
            inputs = []
            
            if shouldTryToReselect {
                let reselectHighlights = processInput(input, assistedInputKind: .reselectLastInvalidInput)
                if !reselectHighlights.isEmpty {
                    viewEffects.append(contentsOf: reselectHighlights)
                }
            } else if shouldHelpFindOptions {
                let startLocationHighlights = processInput(nil, assistedInputKind: .findStartLocationsAfterInvalidInput)
                viewEffects.append(contentsOf: startLocationHighlights)
            }
        case let .locationsToStartFrom(locations):
            cachedOutput = output
            inputs = []
            highlights = locations.map { Highlight(location: $0, kind: .targetSuggestion, color: .startFrom, isBlink: true) }
        }
        
        if !highlights.isEmpty {
            viewEffects.append(.addHighlights(highlights))
        }
        
        if !traces.isEmpty && remoteOrComputerInput {
            viewEffects.append(.showTraces(traces))
        }
        
        return viewEffects
    }
    
}
