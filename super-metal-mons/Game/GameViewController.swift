// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

// TODO: call it sqare view, maake it contain all the stuff
// both mon and tile and effects
class SpaceView: UIView {
    var row = 0
    var col = 0
}

// TODO: move protocol implementation to the extension
class GameViewController: UIViewController, GameView {
    
    static func with(gameController: GameController) -> GameViewController {
        let new = instantiate(GameViewController.self)
        new.controller = gameController
        return new
    }
    
    private var controller: GameController!
    
    @IBOutlet weak var boardContainerView: UIView!
    
    @IBOutlet weak var playerMovesTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentMovesTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topButtonTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var opponentMovesStackView: UIStackView!
    @IBOutlet weak var playerMovesStackView: UIStackView!
    
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var opponentImageView: UIImageView!
    
    @IBOutlet weak var soundControlButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var opponentScoreLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    
    private var squareSize = CGFloat.zero
    
    // TODO: keep view models as well — in order to check if an update is needed
    private lazy var squares: [[SpaceView?]] = Array(repeating: Array(repeating: nil, count: controller.boardSize), count: controller.boardSize)
    private var effectsViews = [UIView]()
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: controller.boardSize), count: controller.boardSize)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        topButtonTopConstraint.constant = 8
        playerMovesTrailingConstraint.constant = 7
        opponentMovesTrailingConstraint.constant = 7
        #endif
        
        moreButton.isHidden = true
        updateSoundButton(isSoundEnabled: !Defaults.isSoundDisabled)
        setupBoard()
        updateGameInfo()
        
        controller.setGameView(self)
    }
    
    // MARK: - setup
    
    private func setupBoard() {
        #if targetEnvironment(macCatalyst)
        let screenWidth: CGFloat = macosWidth
        let screenHeight: CGFloat = macosHeight
        #else
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        #endif
        squareSize = screenWidth / CGFloat(controller.boardSize)
        let totalBoardSize = screenWidth
        let yOffset = (screenHeight - totalBoardSize) / 2
        
        for row in 0..<controller.boardSize {
            for col in 0..<controller.boardSize {
                let color = Colors.square(controller.squares[row][col], style: controller.boardStyle)
                
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
    
    // MARK: - actions
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let spaceView = sender.view as? SpaceView else { return }
        
        let i = spaceView.row // TODO: use location model here as well
        let j = spaceView.col
        
        let effects = controller.didTapSpace((i, j))
        applyEffects(effects)
    }
    
    @IBAction func didTapPlayerAvatar(_ sender: Any) {
        playerImageView.image = Images.randomEmoji
    }
    
    @IBAction func didTapOpponentAvatar(_ sender: Any) {
        opponentImageView.image = Images.randomEmoji
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
    
    @IBAction func moreButtonTapped(_ sender: Any) { }
    
    @IBAction func didTapSoundButton(_ sender: Any) {
        let wasDisabled = Defaults.isSoundDisabled
        Defaults.isSoundDisabled = !wasDisabled
        updateSoundButton(isSoundEnabled: wasDisabled)
    }
    
    private func endGame(openMenu: Bool) {
        controller.endGame()
        if openMenu {
            dismiss(animated: false)
        } else {
            updateGameInfo()
            restartBoardForTest()
        }
    }
    
    // MARK: - updates
    
    private func updateSoundButton(isSoundEnabled: Bool) {
        soundControlButton.configuration?.image = isSoundEnabled ? Images.soundEnabled : Images.soundDisabled
    }
    
    private func updateMovesView(_ stackView: UIStackView, moves: [MonsGame.Move: Int]) {
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
    
    func updateGameInfo() {
        // TODO: setup correctly depending on player's color
        let bold = UIFont.systemFont(ofSize: 19, weight: .semibold)
        let light = UIFont.systemFont(ofSize: 19, weight: .medium)
        
        switch controller.activeColor {
        case .white:
            updateMovesView(playerMovesStackView, moves: controller.availableMoves)
            opponentMovesStackView.isHidden = true
            playerMovesStackView.isHidden = false
            
            opponentScoreLabel.font = light
            playerScoreLabel.font = bold
        case .black:
            updateMovesView(opponentMovesStackView, moves: controller.availableMoves)
            opponentMovesStackView.isHidden = false
            playerMovesStackView.isHidden = true
            
            opponentScoreLabel.font = bold
            playerScoreLabel.font = light
        }
        
        opponentScoreLabel.text = String(controller.blackScore)
        playerScoreLabel.text = String(controller.whiteScore)
    }
    
    func didWin(color: Color) {
        let alert = UIAlertController(title: color == .white ? "⚪️" : "⚫️", message: Strings.allDone, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            // TODO: do not restart the game if the opponent has done so already
            // or i guess in these case there should be a new game id exchage
            self?.endGame(openMenu: true)
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // TODO: remove this one, this is for development only
    // TODO: separate board setup from pieces reloading
    func restartBoardForTest() {
        monsOnBoard.forEach { $0.forEach { $0?.removeFromSuperview() } }
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        reloadPieces()
    }
    
    private func reloadPieces() {
        for i in controller.board.indices {
            for j in controller.board[i].indices {
                updateCell(i, j)
            }
        }
    }
    
    private func updateCell(_ i: Int, _ j: Int) {
        let previouslySetImageView = monsOnBoard[i][j]
        // TODO: refactor, make reloading cells strict and clear
        // rn views are removed here and there. should be able to simply reload a cell
        
        let piece = controller.board[i][j]
        switch piece {
        case let .consumable(consumable):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
            imageView.image = Images.consumable(consumable, style: controller.boardStyle)
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            monsOnBoard[i][j] = imageView
        case let .mon(mon: mon):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
            imageView.image = Images.mon(mon, style: controller.boardStyle)
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
            imageView.image = Images.mon(mon, style: controller.boardStyle)
            
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
            
            manaView.image = Images.mana(mana, style: controller.boardStyle)
            manaView.contentMode = .scaleAspectFit
            imageView.addSubview(manaView)
            
            monsOnBoard[i][j] = imageView
            
        case let .mana(mana: mana):
            switch mana {
            case .regular:
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                imageView.image = Images.mana(mana, style: controller.boardStyle)
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                monsOnBoard[i][j] = imageView
            case .superMana:
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                imageView.image = Images.mana(mana, style: controller.boardStyle)
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
                controller.shareGameState()
                
                if let winner = controller.winnerColor {
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
