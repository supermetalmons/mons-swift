// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

protocol GameView: AnyObject {
    
}

class GameController {
    
//    общается с view в терминах view
//    общается с game в терминах game
//    издает звуки
//    ходит в сеть
    
    private var gameDataSource: GameDataSource!
    
    private lazy var game: MonsGame = {
        return MonsGame()
    }()
    
    enum GameViewEffect {
        
    }
    
    private weak var gameView: GameView?
    
    func didTapSquare() -> [GameViewEffect] {
        return []
    }
    
}
