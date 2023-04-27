// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

// TODO: move protocol implementation to the extension
class GameViewController: UIViewController, GameView {
    
    static func with(gameController: GameController) -> GameViewController {
        let new = instantiate(GameViewController.self)
        new.controller = gameController
        return new
    }
    
    private var controller: GameController!
    
    @IBOutlet weak var boardView: BoardView!
    
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
    
    // TODO: keep view models as well — in order to check if an update is needed
    private lazy var squares: [[BoardSquareView?]] = Array(repeating: Array(repeating: nil, count: controller.boardSize), count: controller.boardSize)
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
        for i in 0..<11 { // TODO: DRY
            for j in 0..<11 {
                let square = BoardSquareView()
                square.backgroundColor = Colors.square(controller.squares[i][j], style: controller.boardStyle)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                square.addGestureRecognizer(tapGestureRecognizer)
                square.row = i
                square.col = j
                
                boardView.addArrangedSubview(square)
                squares[i][j] = square
            }
        }
        reloadPieces()
    }
    
    // MARK: - actions
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let squareView = sender.view as? BoardSquareView else { return }
        
        let i = squareView.row // TODO: use location model here as well
        let j = squareView.col
        
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
            let imageView = UIImageView(image: Images.consumable(consumable, style: controller.boardStyle))
            imageView.contentMode = .scaleAspectFit
            squares[i][j]?.addSubviewConstrainedToFrame(imageView)
            monsOnBoard[i][j] = imageView
        case let .mon(mon: mon):
            let imageView = UIImageView(image: Images.mon(mon, style: controller.boardStyle))
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            
            squares[i][j]?.addSubviewConstrainedToFrame(imageView)
            monsOnBoard[i][j] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            let imageView = UIImageView(image: Images.mon(mon, style: controller.boardStyle))
            
            imageView.contentMode = .scaleAspectFit
            squares[i][j]?.addSubviewConstrainedToFrame(imageView)
            
            let manaView = UIImageView(image: Images.mana(mana, picked: true, style: controller.boardStyle))
            manaView.contentMode = .scaleAspectFit
            
            imageView.addSubview(manaView)
            manaView.translatesAutoresizingMaskIntoConstraints = false
            
            switch mana {
            case .regular:
                NSLayoutConstraint.activate([
                    manaView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.93),
                    manaView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.93),
                    NSLayoutConstraint(item: manaView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.61, constant: 0),
                    NSLayoutConstraint(item: manaView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.45, constant: 0)
                ])
            case .superMana:
                NSLayoutConstraint.activate([
                    manaView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.74),
                    manaView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.74),
                    manaView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                    NSLayoutConstraint(item: manaView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 0.5, constant: 0)
                ])
            }
            
            
            monsOnBoard[i][j] = imageView
            
        case let .mana(mana: mana):
            switch mana {
            case .regular:
                let imageView = UIImageView(image: Images.mana(mana, style: controller.boardStyle))
                imageView.contentMode = .scaleAspectFit
                squares[i][j]?.addSubviewConstrainedToFrame(imageView)
                monsOnBoard[i][j] = imageView
            case .superMana:
                let imageView = UIImageView(image: Images.mana(mana, style: controller.boardStyle))
                imageView.contentMode = .scaleAspectFit
                squares[i][j]?.addSubviewConstrainedToFrame(imageView)
                monsOnBoard[i][j] = imageView
            }
        case .none:
            // TODO: refactor
            if let mon = Location.basedMon(i, j), let square = squares[i][j] {
                let imageView = UIImageView(image: Images.mon(mon, style: controller.boardStyle))
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                squares[i][j]?.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalTo: square.widthAnchor, multiplier: 0.6),
                    imageView.heightAnchor.constraint(equalTo: square.heightAnchor, multiplier: 0.6),
                    imageView.centerXAnchor.constraint(equalTo: square.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: square.centerYAnchor)
                ])
                
                imageView.alpha = 0.4
                monsOnBoard[i][j] = imageView // TODO: do not add to mons on board, this is smth different
            }
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
                squares[index.0][index.1]?.addSubviewConstrainedToFrame(effectView)
                squares[index.0][index.1]?.sendSubviewToBack(effectView)
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
                squares[index.0][index.1]?.addSubviewConstrainedToFrame(effectView)
                squares[index.0][index.1]?.sendSubviewToBack(effectView)
                effectsViews.append(effectView)
            }
        }
    }
    
}
