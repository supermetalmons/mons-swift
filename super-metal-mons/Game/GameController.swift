// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

protocol GameView: AnyObject {
    func restartBoardForTest() // TODO: deprecate
    func updateGameInfo() // TODO: refactor
    func didWin(color: Color) // TODO: refactor
}

enum GameViewEffect {
    
}

// TODO: talk to view in view terms
// TODO: talk to game in game terms
// TODO: make sounds
// TODO: manage networking

// TODO: refactor
class GameController {
    
    var winnerColor: Color? {
        return game.winnerColor
    }
    
    var activeColor: Color {
        return game.activeColor
    }
    
    var availableMoves: [Move: Int] {
        return game.availableMoves
    }
    
    var blackScore: Int {
        return game.blackScore
    }
    
    var whiteScore: Int {
        return game.whiteScore
    }
    
    let boardStyle = BoardStyle.pixel
    
    // idk about this one
    var board: Board {
        return game.board
    }
    
    private unowned var gameView: GameView!
    private var gameDataSource: GameDataSource
    
    init() {
        gameDataSource = LocalGameDataSource()
    }
    
    init(gameId: String) {
        gameDataSource = RemoteGameDataSource(gameId: gameId)
    }
    
    // idk about this one
    private lazy var game: MonsGame = {
        return MonsGame()
    }()
    
    func setGameView(_ gameView: GameView) {
        self.gameView = gameView
        
        gameDataSource.observe { [weak self] fen in
            DispatchQueue.main.async {
                self?.game = MonsGame(fen: fen)! // TODO: do not force unwrap
                self?.gameView.restartBoardForTest()
                self?.gameView.updateGameInfo()
                if let winner = self?.game.winnerColor {
                    self?.gameView.didWin(color: winner)
                }
            }
        }
    }
    
    // TODO: deprecate. should not be called from gameviewcontroller. should happen internally here.
    func shareGameState() {
        sendFen(game.fen)
    }
    
    private func sendFen(_ fen: String) {
        gameDataSource.update(fen: fen)
    }
    
    func endGame() {
        game = MonsGame()
        sendFen(game.fen)
    }
    
    private var inputs = [MonsGame.Input]()
    
    // TODO: refactor
    func processInput(_ input: MonsGame.Input) -> [ViewEffect] {
        // TODO: act differently when i click spaces while opponent makes his turns
        
        var viewEffects = [ViewEffect]() // TODO: tmp
        
        inputs.append(input)
        
        let output = game.processInput(inputs)
        
        switch output {
        case let .events(events):
            inputs = []
            var locationsToUpdate = [Location]()
            for event in events {
                switch event {
                case .monMove(_, let from, let to):
                    Audio.play(.move)
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .manaMove(_, let from, let to):
                    Audio.play(.moveMana)
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case let .manaScored(mana, at, _):
                    switch mana {
                    case .regular:
                        Audio.play(.scoreMana)
                    case .supermana:
                        Audio.play(.scoreSupermana)
                    }
                    locationsToUpdate.append(at)
                case .mysticAction(_, let from, let to):
                    Audio.play(.mysticAbility)
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .demonAction(_, let from, let to):
                    Audio.play(.demonAbility)
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .demonAdditionalStep(_, let from, let to):
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .spiritTargetMove(_, let from, let to):
                    Audio.play(.spiritAbility)
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .pickupBomb(_, let at):
                    Audio.play(.pickUpPotion)
                    locationsToUpdate.append(at)
                case .pickupPotion(_, let at):
                    Audio.play(.pickUpPotion)
                    locationsToUpdate.append(at)
                case .pickupMana(_, _, let at):
                    Audio.play(.manaPickUp)
                    locationsToUpdate.append(at)
                case .monFainted(_, let from, let to):
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .manaDropped(_, let at):
                    locationsToUpdate.append(at)
                case .supermanaBackToBase(let from, let to):
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .bombAttack(_, let from, let to):
                    Audio.play(.bomb)
                    locationsToUpdate.append(from)
                    locationsToUpdate.append(to)
                case .monAwake(_, let at):
                    locationsToUpdate.append(at)
                case .bombExplosion(let at):
                    Audio.play(.bomb)
                    locationsToUpdate.append(at)
                case .nextTurn(_):
                    break
                case .gameOver(_):
                    break
                }
            }
            
            viewEffects.append(contentsOf: locationsToUpdate.map { ViewEffect.updateCell($0) })
            viewEffects.append(.updateGameStatus)
        case let .nextInputOptions(nextInputOptions):
            for input in inputs {
                if case let .location(location) = input {
                    viewEffects.append(.setSelected(location))
                }
            }
            
            for nextInputOption in nextInputOptions {
                if nextInputOption.kind == .selectConsumable {
                    viewEffects.append(.selectBombOrPotion)
                }
                
                switch nextInputOption.input {
                case .location(let location):
                    viewEffects.append(.availableForStep(location))
                case .modifier:
                    break
                }
            }
            
        case .invalidInput:
            inputs = []
        }
        
        return viewEffects
    }
    
}
