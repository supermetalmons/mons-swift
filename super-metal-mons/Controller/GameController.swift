// ∅ 2024 super-metal-mons

import UIKit

let monsGameControllerVersion = 2

protocol GameView: AnyObject {
    func didConnect()
    func updateOpponentEmoji()
    func updateEmoji(color: Color)
    func applyEffects(_ effects: [ViewEffect])
    func showMessageAndDismiss(message: String)
    func setNewBoard()
    func react(_ reaction: Reaction, byOpponent: Bool)
}


class GameController {
    
    enum VersusComputer {
        case person, computer
    }
    
    var versusComputer: VersusComputer?
    
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
    var personVersusComputer: Bool {
        if case .person = versusComputer {
            return true
        } else {
            return false
        }
    }
    
    var didConnect = false
    var playerSideColor: Color
    var whiteEmojiId: Int
    var blackEmojiId: Int
    
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
    
    var board: Board {
        return game.board
    }

    private var game = MonsGame()
    private let gameId: String
    private weak var gameView: GameView?
    
    init() {
        let emojiId = Images.randomEmojiId
        whiteEmojiId = emojiId
        blackEmojiId = emojiId
        gameId = ""
        playerSideColor = .white
        blackEmojiId = Images.randomEmojiId
    }
    
    func didSelectGameVersusComputer(_ versusComputer: VersusComputer) {
        lastComputerMoveDate = Date()
        self.versusComputer = versusComputer
        playerSideColor = .random
        updateOpponentEmoji(id: Images.computerEmojiId)
        
        switch versusComputer {
        case .computer:
            isWatchOnly = true
            updateEmoji(color: playerSideColor, id: Images.computerEmojiId)
            makeComputerMove()
        case .person:
            if activeColor != playerSideColor {
                makeComputerMove()
            }
        }
    }
    
    func setGameView(_ gameView: GameView) {
        self.gameView = gameView
    }
    
    func useDifferentEmoji() -> UIImage {
        guard !isWatchOnly else { return Images.emoji(whiteEmojiId) }
        let emojiId = Images.randomEmojiId(except: whiteEmojiId, andExcept: blackEmojiId)
        switch versusComputer != nil ? playerSideColor : activeColor {
        case .white:
            whiteEmojiId = emojiId
        case .black:
            blackEmojiId = emojiId
        }
        return Images.emoji(emojiId)
    }
    
    private var inputs = [Input]()
    private var cachedOutput: Output?
    
    private func processRemoteInputs(_ inputs: [Input]) {
        self.inputs = inputs
        self.inputs.removeLast()
        let viewEffects = processInput(inputs.last, remoteOrComputerInput: true)
        gameView?.applyEffects(viewEffects)
    }
    
    var lastComputerMoveDate = Date()
    private func makeComputerMove() {
        let sinceLast = Date().timeIntervalSince(lastComputerMoveDate)
        let delta: Double = 1
        guard sinceLast > delta else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(delta) * 1000 - Int(1000 * sinceLast))) { [weak self] in
                self?.makeComputerMove()
            }
            return
        }
        lastComputerMoveDate = Date()
        guard winnerColor == nil else { return }
        _ = processInput(nil, remoteOrComputerInput: true)
    }
    
    private var computer: Computer?
    
    // TODO: refactor
    func processInput(_ input: Input?, assistedInputKind: AssistedInputKind? = nil, remoteOrComputerInput: Bool = false) -> [ViewEffect] {
        guard !isWatchOnly || remoteOrComputerInput else { return [] }
        
        guard versusComputer == nil || activeColor == playerSideColor || remoteOrComputerInput else { return [] }
        
        var viewEffects = [ViewEffect]()
        var highlights = [Highlight]()
        var traces = [Trace]()
        
        if let input = input {
            inputs.append(input)
        }
        
        var output: Output
        
        if remoteOrComputerInput, inputs.isEmpty {
            if computer == nil { computer = Computer(gameModel: game) }
            let computerColor = activeColor
            computer?.bestMoveForActivePlayer { [weak self] inputs in
                guard !inputs.isEmpty else { return }
                DispatchQueue.main.async {
                    self?.processRemoteInputs(inputs)
                    if self?.game.activeColor == computerColor {
                        self?.makeComputerMove()
                    }
                }
            }
            return []
        } else if inputs.isEmpty, let cachedOutput = cachedOutput {
            output = cachedOutput
        } else {
            output = game.processInput(inputs, doNotApplyEvents: false, oneOptionEnough: false)
        }
                
        switch output {
        case let .events(events):
            cachedOutput = nil
            inputs = []
            var locationsToUpdate = Set<Location>()
            
            var mightKeepHighlightOnLocation: Location?
            var mustReleaseHighlight = remoteOrComputerInput
            
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
                    if !remoteOrComputerInput && !isWatchOnly { Haptic.generate(.success) }
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
                    if !isWatchOnly { Haptic.generate(.selectionChanged) }
                    if  let versusComputer = versusComputer {
                        switch versusComputer {
                        case .computer:
                            makeComputerMove()
                        case .person:
                            if !remoteOrComputerInput { makeComputerMove() }
                        }
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
