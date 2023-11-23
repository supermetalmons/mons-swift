// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

extension MonsGame {
    
    var availableMoveKinds: [AvailableMoveKind: Int] {
        var moves: [AvailableMoveKind: Int] = [
            .monMove: Config.monsMovesPerTurn - monsMovesCount,
            .action: 0,
            .potion: 0,
            .manaMove: 0
        ]

        if turnNumber == 1 {
            return moves
        }
        
        moves[.action] = (Config.actionsPerTurn - actionsUsedCount)
        moves[.potion] = playerPotionsCount
        moves[.manaMove] = Config.manaMovesPerTurn - manaMovesCount
        
        return moves
    }
    
    var winnerColor: Color? {
        if whiteScore >= Config.targetScore {
            return .white
        } else if blackScore >= Config.targetScore {
            return .black
        } else {
            return nil
        }
    }
    
    func isLaterThan(game: MonsGame) -> Bool {
        if turnNumber > game.turnNumber {
            return true
        } else if turnNumber == game.turnNumber {
            return playerPotionsCount < game.playerPotionsCount ||
            actionsUsedCount > game.actionsUsedCount ||
            manaMovesCount > game.manaMovesCount ||
            monsMovesCount > game.monsMovesCount ||
            board.faintedMonsLocations(color: activeColor.other).count > game.board.faintedMonsLocations(color: activeColor.other).count
        } else {
            return false
        }
    }
    
    var isFirstTurn: Bool { turnNumber == 1 }
    var playerPotionsCount: Int { activeColor == .white ? whitePotionsCount : blackPotionsCount }
    var playerCanMoveMon: Bool { monsMovesCount < Config.monsMovesPerTurn }
    var playerCanMoveMana: Bool { !isFirstTurn && manaMovesCount < Config.manaMovesPerTurn }
    var playerCanUseAction: Bool { !isFirstTurn && (playerPotionsCount > 0 || actionsUsedCount < Config.actionsPerTurn) }
    
    var protectedByOpponentsAngel: Set<Location> {
        if let location = board.findAwakeAngel(color: activeColor.other) {
            let protected = location.nearbyLocations
            return Set(protected)
        } else {
            return Set()
        }
    }
    
}
