// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SpaceView: UIView {
    var row = 0
    var col = 0
}

class GameViewController: UIViewController {
    
    private var gameDataSource: GameDataSource!
    
    static func with(gameDataSource: GameDataSource) -> GameViewController {
        let new = instantiate(GameViewController.self)
        new.gameDataSource = gameDataSource
        return new
    }
    
    private var effectsViews = [UIView]()
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    
    private var didSetupBoard = false
    
    @IBOutlet weak var playerMovesTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentMovesTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentMovesStackView: UIStackView!
    @IBOutlet weak var playerMovesStackView: UIStackView!
    
    @IBOutlet weak var topButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var opponentImageView: UIImageView!
    
    @IBOutlet weak var opponentHighlightView: UIImageView!
    @IBOutlet weak var playerHighlightView: UIImageView!
    
    @IBOutlet weak var soundControlButton: UIButton! {
        didSet {
            updateSoundButton(isSoundEnabled: !Defaults.isSoundDisabled)
        }
    }
    @IBOutlet weak var boardContainerView: UIView!
    @IBOutlet weak var opponentScoreLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    
    private let boardSize = 11
    private lazy var squares: [[SpaceView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

    // TODO: mb it should be in a game data source
    private lazy var game: MonsGame = {
        return MonsGame() // TODO: load the last game if there is one
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        topButtonTopConstraint.constant = 8
        playerMovesTrailingConstraint.constant = 7
        opponentMovesTrailingConstraint.constant = 7
        #endif
        
        setupMonsboard()
        updateGameInfo()
        
        gameDataSource.observe { [weak self] fen in
            DispatchQueue.main.async {
                self?.game = MonsGame(fen: fen)!
                self?.restartBoardForTest()
                self?.updateGameInfo()
                if let winner = self?.game.winnerColor {
                    self?.didWin(color: winner)
                }
            }
        }
    }
    
    private func setupMovesView(_ stackView: UIStackView, moves: [MonsGame.Move: Int]) {
        let steps = moves[.step] ?? 0
        let mana = moves[.mana] ?? 0
        let actions = moves[.action] ?? 0
        
        for (i, moveView) in stackView.arrangedSubviews.enumerated() {
            switch i {
            case 0...4:
                moveView.isHidden = i >= steps
            case 5...7:
                moveView.isHidden = (i - 5) >= actions
            default:
                moveView.isHidden = mana == 0
            }
        }
    }
    
    private func updateGameInfo() {
        // TODO: setup correctly depending on player's color
        let bold = UIFont.systemFont(ofSize: 19, weight: .semibold)
        let light = UIFont.systemFont(ofSize: 19, weight: .medium)
        
        switch game.activeColor {
        case .white:
            opponentHighlightView.isHidden = true
            playerHighlightView.isHidden = false
            
            setupMovesView(playerMovesStackView, moves: game.availableMoves)
            opponentMovesStackView.isHidden = true
            playerMovesStackView.isHidden = false
            
            opponentScoreLabel.font = light
            playerScoreLabel.font = bold
        case .black:
            opponentHighlightView.isHidden = false
            playerHighlightView.isHidden = true
            
            setupMovesView(opponentMovesStackView, moves: game.availableMoves)
            opponentMovesStackView.isHidden = false
            playerMovesStackView.isHidden = true
            
            opponentScoreLabel.font = bold
            playerScoreLabel.font = light
        }
        
        opponentScoreLabel.text = String(game.blackScore)
        playerScoreLabel.text = String(game.whiteScore)
    }
    
    @IBAction func didTapPlayerAvatar(_ sender: Any) {
        playerImageView.image = Images.randomEmoji
    }
    
    @IBAction func didTapOpponentAvatar(_ sender: Any) {
        opponentImageView.image = Images.randomEmoji
    }
    
    private func didWin(color: Color) {
        let alert = UIAlertController(title: color == .white ? "⚪️" : "⚫️", message: Strings.allDone, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            // TODO: do not restart the game if the opponent has done so already
            // or i guess in these case there should be a new game id exchage
            self?.endGame(openMenu: true)
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func sendFen(_ fen: String) {
        gameDataSource.update(fen: fen)
    }
    
    private func endGame(openMenu: Bool) {
        game = MonsGame()
        sendFen(game.fen)
        if openMenu {
            dismiss(animated: false)
        } else {
            updateGameInfo()
            restartBoardForTest()
        }
    }
    
    @IBAction func escapeButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: Strings.endTheGameConfirmation, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .destructive) { [weak self] _ in
            self?.endGame(openMenu: true)
        }
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel) { _ in }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    private func updateSoundButton(isSoundEnabled: Bool) {
        soundControlButton.configuration?.image = isSoundEnabled ? Images.soundEnabled : Images.soundDisabled
    }
    
    @IBAction func didTapSoundButton(_ sender: Any) {
        let wasDisabled = Defaults.isSoundDisabled
        Defaults.isSoundDisabled = !wasDisabled
        updateSoundButton(isSoundEnabled: wasDisabled)
    }
    
    // TODO: remove this one, this is for development only
    private func restartBoardForTest() {
        monsOnBoard.forEach { $0.forEach { $0?.removeFromSuperview() } }
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        setupMonsboard()
    }
    
    private var squareSize = CGFloat.zero
    
    private func setupMonsboard() {
        #if targetEnvironment(macCatalyst)
        let screenWidth: CGFloat = macosWidth
        let screenHeight: CGFloat = macosHeight
        #else
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        #endif
        squareSize = screenWidth / CGFloat(boardSize)
        let totalBoardSize = screenWidth
        let yOffset = (screenHeight - totalBoardSize) / 2

        if !didSetupBoard {
            for row in 0..<boardSize {
                for col in 0..<boardSize {
                    let x = CGFloat(col) * squareSize
                    let y = CGFloat(row) * squareSize + yOffset

                    let square = SpaceView(frame: CGRect(x: x, y: y, width: squareSize, height: squareSize))
                    square.backgroundColor = (row + col) % 2 == 0 ? Colors.squareLight : Colors.squareDark
                    boardContainerView.addSubview(square)
                    squares[row][col] = square
                    
                    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                    square.addGestureRecognizer(tapGestureRecognizer)
                    square.col = col
                    square.row = row
                }
            }
            
            for (i, j) in [(0, 0), (5, 5), (10, 10), (0, 10), (10, 0)] {
                squares[i][j]?.backgroundColor = Colors.squareSpecial
            }
        }
        
        // TODO: move to board class
        for i in game.board.indices {
            for j in game.board[i].indices {
                updateCell(i, j)
            }
        }
        didSetupBoard = true
    }
    
    private func updateCell(_ i: Int, _ j: Int) {
        let piece = game.board[i][j]
        let style = BoardStyle.basic
        switch piece {
        case let .consumable(consumable):
            if !didSetupBoard {
                // TODO: this would brake when we start with the ongoing game
                squares[i][j]?.backgroundColor = Colors.squareConsumable
            }
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.8, height: squareSize * 0.8))
            imageView.image = Images.consumable(consumable, style: style)
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            monsOnBoard[i][j] = imageView
        case let .mon(mon: mon):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
            imageView.image = Images.mon(mon, style: style)
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
            imageView.image = Images.mon(mon, style: style)
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            let manaView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
            manaView.image = Images.mana(mana, style: style)
            manaView.contentMode = .scaleAspectFit
            imageView.addSubview(manaView)
            
            monsOnBoard[i][j] = imageView
            
        case let .mana(mana: mana):
            switch mana {
            case .regular:
                if !didSetupBoard {
                    squares[i][j]?.backgroundColor = Colors.squareMana
                }
                
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
                imageView.image = Images.mana(mana, style: style)
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                monsOnBoard[i][j] = imageView
            case .superMana:
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                imageView.image = Images.mana(mana, style: style)
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                monsOnBoard[i][j] = imageView
            }
        case .none:
            break
        }
    }
    
    // TODO: act differently when i click spaces while opponent makes his turns
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let spaceView = sender.view as? SpaceView else { return }
        
        let i = spaceView.row // TODO: use location model here as well
        let j = spaceView.col
        
        let effects = game.didTapSpace((i, j))
        applyEffects(effects)
    }
    
    private func applyEffects(_ effects: [Effect]) {
        for effectView in effectsViews {
            effectView.removeFromSuperview()
        }
        effectsViews = []
        
        for effect in effects {
            switch effect {
            case .updateCell(let index):
                monsOnBoard[index.0][index.1]?.removeFromSuperview()
                monsOnBoard[index.0][index.1] = nil
                updateCell(index.0, index.1)
            case .setSelected(let index):
                let effectView = UIView()
                effectView.backgroundColor = .clear
                effectView.layer.borderWidth = 3
                effectView.layer.borderColor = UIColor.green.cgColor
                effectView.frame = CGRect(origin: .zero, size: CGSize(width: squareSize, height: squareSize))
                squares[index.0][index.1]?.addSubview(effectView)
                effectsViews.append(effectView)
            case .updateGameStatus:
                updateGameInfo()
                sendFen(game.fen)
                
                if let winner = game.winnerColor {
                    didWin(color: winner)
                }
            case .availableForStep(let index):
                // TODO: use dot for an empty field
                let effectView = UIView()
                effectView.backgroundColor = .clear
                effectView.layer.borderWidth = 5
                effectView.layer.borderColor = UIColor.yellow.cgColor
                effectView.frame = CGRect(origin: .zero, size: CGSize(width: squareSize, height: squareSize))
                squares[index.0][index.1]?.addSubview(effectView)
                effectsViews.append(effectView)
            }
        }
    }
    
}
