// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SpaceView: UIView {
    var row = 0
    var col = 0
}

class GameViewController: UIViewController {
    
    static func with(gameDataSource: GameDataSource) -> GameViewController {
        let new = instantiate(GameViewController.self)
        new.gameDataSource = gameDataSource
        return new
    }
    
    @IBOutlet weak var playerMovesTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentMovesTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentMovesStackView: UIStackView!
    @IBOutlet weak var playerMovesStackView: UIStackView!
    @IBOutlet weak var topButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var opponentImageView: UIImageView!
    @IBOutlet weak var soundControlButton: UIButton!
    @IBOutlet weak var boardContainerView: UIView!
    @IBOutlet weak var opponentScoreLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    
    private let boardSize = 11
    private var gameDataSource: GameDataSource!
    private var style = BoardStyle.pixel
    
    private lazy var squares: [[SpaceView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    private var effectsViews = [UIView]()
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

    // TODO: remove it from here
    private lazy var game: MonsGame = {
        return MonsGame()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        topButtonTopConstraint.constant = 8
        playerMovesTrailingConstraint.constant = 7
        opponentMovesTrailingConstraint.constant = 7
        #endif
        
        updateSoundButton(isSoundEnabled: !Defaults.isSoundDisabled)
        setupBoard()
        updateGameInfo()
        
        gameDataSource.observe { [weak self] fen in
            DispatchQueue.main.async {
                self?.game = MonsGame(fen: fen)! // TODO: do not force unwrap
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
            setupMovesView(playerMovesStackView, moves: game.availableMoves)
            opponentMovesStackView.isHidden = true
            playerMovesStackView.isHidden = false
            
            opponentScoreLabel.font = light
            playerScoreLabel.font = bold
        case .black:
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
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        switch style {
        case .basic:
            style = .pixel
        case .pixel:
            style = .plastic
        case .plastic:
            style = .basic
        }
        
        setupBoard()
    }
    
    @IBAction func didTapSoundButton(_ sender: Any) {
        let wasDisabled = Defaults.isSoundDisabled
        Defaults.isSoundDisabled = !wasDisabled
        updateSoundButton(isSoundEnabled: wasDisabled)
    }
    
    // TODO: remove this one, this is for development only
    // TODO: separate board setup from pieces reloading
    private func restartBoardForTest() {
        monsOnBoard.forEach { $0.forEach { $0?.removeFromSuperview() } }
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        reloadPieces()
    }
    
    private var squareSize = CGFloat.zero
    
    private func reloadPieces() {
        for i in game.board.indices {
            for j in game.board[i].indices {
                updateCell(i, j)
            }
        }
    }
    
    private func setupBoard() {
        let isFirstSetup = boardContainerView.subviews.isEmpty
        
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
        
        // TODO: move somewhere from here
        let boardSpec: [[Square]] = [
            [.p, .b, .w, .b, .w, .b, .w, .b, .w, .b, .p],
            [.b, .w, .b, .w, .b, .w, .b, .w, .b, .w, .b],
            [.w, .b, .w, .b, .w, .b, .w, .b, .w, .b, .w],
            [.b, .w, .b, .w, .m, .w, .m, .w, .b, .w, .b],
            [.w, .b, .w, .m, .w, .m, .w, .m, .w, .b, .w],
            [.c, .w, .b, .w, .b, .s, .b, .w, .b, .w, .c],
            [.w, .b, .w, .m, .w, .m, .w, .m, .w, .b, .w],
            [.b, .w, .b, .w, .m, .w, .m, .w, .b, .w, .b],
            [.w, .b, .w, .b, .w, .b, .w, .b, .w, .b, .w],
            [.b, .w, .b, .w, .b, .w, .b, .w, .b, .w, .b],
            [.p, .b, .w, .b, .w, .b, .w, .b, .w, .b, .p]
        ]
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let color = Colors.square(boardSpec[row][col], style: style)
                
                guard isFirstSetup else {
                    squares[row][col]?.backgroundColor = color
                    continue
                }
                
                let x = CGFloat(col) * squareSize
                let y = CGFloat(row) * squareSize + yOffset
                
                let square = SpaceView(frame: CGRect(x: x, y: y, width: squareSize, height: squareSize))
                square.backgroundColor = color
                boardContainerView.addSubview(square)
                squares[row][col] = square
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                square.addGestureRecognizer(tapGestureRecognizer)
                square.col = col
                square.row = row
            }
        }
        
        reloadPieces()
    }
    
    private func updateCell(_ i: Int, _ j: Int) {
        let previouslySetImageView = monsOnBoard[i][j]
        // TODO: refactor, make reloading cells strict and clear
        // rn views are removed here and there. should be able to simply reload a cell
        
        let piece = game.board[i][j]
        switch piece {
        case let .consumable(consumable):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
            imageView.image = Images.consumable(consumable, style: style)
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            monsOnBoard[i][j] = imageView
        case let .mon(mon: mon):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
            imageView.image = Images.mon(mon, style: style)
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
            imageView.image = Images.mon(mon, style: style)
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            let manaView: UIImageView
            
            // TODO: refactor
            switch mana {
            case .regular:
                manaView = UIImageView(frame: CGRect(x: 0.36 * squareSize, y: 0.24 * squareSize, width: 0.93 * squareSize, height: 0.93 * squareSize))
            case .superMana:
                manaView = UIImageView(frame: CGRect(x: 0.13 * squareSize, y: -0.15 * squareSize, width: 0.74 * squareSize, height: 0.74 * squareSize))
            }
            
            manaView.image = Images.mana(mana, style: style)
            manaView.contentMode = .scaleAspectFit
            imageView.addSubview(manaView)
            
            monsOnBoard[i][j] = imageView
            
        case let .mana(mana: mana):
            switch mana {
            case .regular:
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
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
        
        previouslySetImageView?.removeFromSuperview()
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
