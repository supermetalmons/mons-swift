// ∅ 2024 super-metal-mons

import GameplayKit

class Computer {
    
    private let strategist: GKStrategist
    private let queue = DispatchQueue.global(qos: .userInitiated)
    
    init(gameModel: MonsGame) {
        computerPlayers = [ComputerPlayer(color: .black), ComputerPlayer(color: .white)]
        let minMaxStrategist = GKMinmaxStrategist()
        minMaxStrategist.randomSource = GKLinearCongruentialRandomSource()
        minMaxStrategist.maxLookAheadDepth = 3
        minMaxStrategist.gameModel = gameModel
        strategist = minMaxStrategist
    }
    
    func bestMoveForActivePlayer(completion: @escaping (([Input]) -> Void)) {
        queue.async { [weak self] in
            let inputs = (self?.strategist.bestMoveForActivePlayer() as? ComputerMove)?.resultingInputs ?? []
            completion(inputs)
        }
    }
    
}

fileprivate var computerPlayers: [GKGameModelPlayer]?

fileprivate class ComputerPlayer: NSObject, GKGameModelPlayer {
    
    let playerId: Int
    let color: Color
    
    init(color: Color) {
        self.color = color
        playerId = color == .white ? 0 : 1
    }
    
}

fileprivate class ComputerMove: NSObject, GKGameModelUpdate {
    
    var value: Int = 0
    
    let resultingInputs: [Input]
    
    init(resultingInputs: [Input]) {
        self.resultingInputs = resultingInputs
    }
    
}

extension MonsGame: GKGameModel {
    
    var players: [GKGameModelPlayer]? {
        return computerPlayers
    }
    
    var activePlayer: GKGameModelPlayer? {
        return computerPlayers?.first(where: { ($0 as? ComputerPlayer)?.color == activeColor })
    }
    
    func setGameModel(_ gameModel: GKGameModel) {
        guard let otherGame = gameModel as? MonsGame else { return }
        updateWith(otherGame: otherGame)
    }
        
    private func allNextMoves(inputs: [Input]) -> [ComputerMove] {
        var moves = [ComputerMove]()
        let output = processInput(inputs, doNotApplyEvents: true)
        switch output {
        case .invalidInput:
            break
        case let .locationsToStartFrom(locations):
            for location in locations {
                let locationInput = Input.location(location)
                moves += allNextMoves(inputs: [locationInput])
            }
        case .events:
            moves.append(ComputerMove(resultingInputs: inputs))
        case let .nextInputOptions(nextInputOptions):
            for inputOption in nextInputOptions {
                moves += allNextMoves(inputs: inputs + [inputOption.input])
            }
        }
        return moves
    }
    
    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard (player as? ComputerPlayer)?.color == activeColor else { return nil }
        return allNextMoves(inputs: [])
    }
    
    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        guard let resultingInputs = (gameModelUpdate as? ComputerMove)?.resultingInputs else { return }
        _ = processInput(resultingInputs, doNotApplyEvents: false)
    }
    
    func isWin(for player: GKGameModelPlayer) -> Bool {
        guard let color = (player as? ComputerPlayer)?.color else { return false }
        return color == winnerColor
    }
    
    func score(for player: GKGameModelPlayer) -> Int {
        guard let color = (player as? ComputerPlayer)?.color else { return 0 }
        return evaluateFor(color: color)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = MonsGame(board: Board(items: board.items),
                            whiteScore: whiteScore,
                            blackScore: blackScore,
                            activeColor: activeColor,
                            actionsUsedCount: actionsUsedCount,
                            manaMovesCount: manaMovesCount,
                            monsMovesCount: monsMovesCount,
                            whitePotionsCount: whitePotionsCount,
                            blackPotionsCount: blackPotionsCount,
                            turnNumber: turnNumber)
        return copy as Any
    }
    
}
