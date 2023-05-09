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
    private var playerSideColor = Color.white
    private var whiteEmoji = Images.randomEmoji // TODO: get from controller
    private var blackEmoji = Images.randomEmoji

    private var isAnimatingAvatar = false
    
    @IBOutlet weak var boardView: BoardView!
    
    @IBOutlet weak var boardOverlayView: UIVisualEffectView!
    @IBOutlet weak var bombButton: UIButton!
    @IBOutlet weak var potionButton: UIButton!
    
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
    private lazy var squares = [Location: BoardSquareView]()
    private var effectsViews = [UIView]()
    private lazy var monsOnBoard = [Location: UIImageView]()
    
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
        
        controller.setGameView(self)
    }
    
    // MARK: - setup
    
    private func setupBoard() {
        for i in 0..<11 { // TODO: DRY
            for j in 0..<11 {
                let location = Location(i, j)
                let square = BoardSquareView(location: location)
                square.backgroundColor = Colors.square(controller.board.square(at: location).color(location: location), style: controller.boardStyle)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                square.addGestureRecognizer(tapGestureRecognizer)
                
                boardView.addArrangedSubview(square)
                squares[location] = square
            }
        }
        reloadItems()
    }
    
    // MARK: - actions
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let squareView = sender.view as? BoardSquareView else { return }
        processInput(.location(squareView.location))
    }
    
    private func processInput(_ input: MonsGame.Input) {
        let effects = controller.processInput(input)
        applyEffects(effects)
    }
    
    private func animateAvatar(opponents: Bool) {
        guard !isAnimatingAvatar else { return }
        isAnimatingAvatar = true
        
        let animatedImageView: UIImageView! = opponents ? opponentImageView : playerImageView
        
        if let parent = animatedImageView.superview {
            view.bringSubviewToFront(parent)
        }
        
        let originalTransform = animatedImageView.transform
        let scaleFactor = CGFloat(boardView.bounds.width / animatedImageView.bounds.width * 0.45)
        let scaledTransform = originalTransform.scaledBy(x: scaleFactor, y: scaleFactor)
        let translatedAndScaledTransform = scaledTransform.translatedBy(x: 14, y: opponents ? 14 : -14)
                
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, animations: { [weak animatedImageView] in
            animatedImageView?.transform = translatedAndScaledTransform
        }) { [weak self, weak animatedImageView] _ in
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, animations: {
                animatedImageView?.transform = originalTransform
            }) { _ in
                self?.isAnimatingAvatar = false
            }
        }
    }
    
    @IBAction func bombButtonTapped(_ sender: Any) {
        processInput(.modifier(.selectBomb))
        boardOverlayView.isHidden = true
    }
    
    @IBAction func potionButtonTapped(_ sender: Any) {
        processInput(.modifier(.selectPotion))
        boardOverlayView.isHidden = true
    }
    
    @IBAction func boardOverlayTapped(_ sender: Any) {
        processInput(.modifier(.cancel))
        boardOverlayView.isHidden = true
    }
    
    @IBAction func didTapPlayerAvatar(_ sender: Any) {
        guard !isAnimatingAvatar else { return }
        Audio.play(.click)
        let newRandom = Images.randomEmoji
        switch playerSideColor {
        case .white:
            whiteEmoji = newRandom
        case .black:
            blackEmoji = newRandom
        }
        playerImageView.image = newRandom
        animateAvatar(opponents: false)
    }
    
    @IBAction func didTapOpponentAvatar(_ sender: Any) {
        guard !isAnimatingAvatar else { return }
        animateAvatar(opponents: true)
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
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        flipBoard()
    }
    
    @IBAction func didTapSoundButton(_ sender: Any) {
        let wasDisabled = Defaults.isSoundDisabled
        Defaults.isSoundDisabled = !wasDisabled
        updateSoundButton(isSoundEnabled: wasDisabled)
    }
    
    private func flipBoard() {
        playerSideColor = playerSideColor.other
        boardView.setPlayerSide(color: playerSideColor)
        updateGameInfo()
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
    
    private func updateMovesView(_ stackView: UIStackView, moves: [AvailableMoveKind: Int]) {
        let steps = moves[.monMove] ?? 0
        let actions = moves[.action] ?? 0
        let potions = moves[.potion] ?? 0
        let mana = moves[.manaMove] ?? 0
        
        for (i, moveView) in stackView.arrangedSubviews.enumerated() {
            switch i {
            case 0...4:
                moveView.isHidden = i >= steps
            case 5:
                moveView.isHidden = (i - 5) >= actions
            case 6...7:
                moveView.isHidden = (i - 6) >= potions
            default:
                moveView.isHidden = mana == 0
            }
        }
    }
    
    func updateGameInfo() {
        let boldFont = UIFont.systemFont(ofSize: 19, weight: .semibold)
        let lightFont = UIFont.systemFont(ofSize: 19, weight: .medium)
        
        let myTurn = playerSideColor == controller.activeColor
        let myScore: Int
        let opponentScore: Int
        switch playerSideColor {
        case .white:
            playerImageView.image = whiteEmoji
            opponentImageView.image = blackEmoji
            myScore = controller.whiteScore
            opponentScore = controller.blackScore
        case .black:
            playerImageView.image = blackEmoji
            opponentImageView.image = whiteEmoji
            myScore = controller.blackScore
            opponentScore = controller.whiteScore
        }
        
        updateMovesView(myTurn ? playerMovesStackView : opponentMovesStackView, moves: controller.availableMoves)
        opponentMovesStackView.isHidden = myTurn
        playerMovesStackView.isHidden = !myTurn
        opponentScoreLabel.font = myTurn ? lightFont : boldFont
        playerScoreLabel.font = myTurn ?  boldFont : lightFont
        
        opponentScoreLabel.text = String(opponentScore)
        playerScoreLabel.text = String(myScore)
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
    // TODO: separate board setup from items reloading
    func restartBoardForTest() {
        monsOnBoard.forEach { $0.value.removeFromSuperview() }
        monsOnBoard.removeAll()
        reloadItems()
    }
    
    private func reloadItems() {
        for i in 0..<11 { // TODO: DRY
            for j in 0..<11 {
                let location = Location(i, j)
                updateCell(location)
            }
        }
    }
    
    // TODO: remake
    private func updateCell(_ location: Location) {
        let previouslySetImageView = monsOnBoard[location]
        // TODO: refactor, make reloading cells strict and clear
        // rn views are removed here and there. should be able to simply reload a cell
        
        let item = controller.board.item(at: location)
        switch item {
        case let .consumable(consumable):
            let imageView = UIImageView(image: Images.consumable(consumable, style: controller.boardStyle))
            imageView.contentMode = .scaleAspectFit
            squares[location]?.addSubviewConstrainedToFrame(imageView)
            
            // TODO: show under the image view
//            let sparklingView = SparklingView(frame: imageView.bounds)
//            imageView.addSubviewConstrainedToFrame(sparklingView)
            
            monsOnBoard[location] = imageView
        case let .mon(mon: mon):
            let imageView = UIImageView(image: Images.mon(mon, style: controller.boardStyle))
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            
            squares[location]?.addSubviewConstrainedToFrame(imageView)
            monsOnBoard[location] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            let imageView = UIImageView(image: Images.mon(mon, style: controller.boardStyle))
            
            imageView.contentMode = .scaleAspectFit
            squares[location]?.addSubviewConstrainedToFrame(imageView)
            
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
            case .supermana:
                NSLayoutConstraint.activate([
                    manaView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.74),
                    manaView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.74),
                    manaView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                    NSLayoutConstraint(item: manaView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 0.5, constant: 0)
                ])
            }
            
            
            monsOnBoard[location] = imageView
            
        case let .mana(mana: mana):
            switch mana {
            case .regular:
                let imageView = UIImageView(image: Images.mana(mana, style: controller.boardStyle))
                imageView.contentMode = .scaleAspectFit
                squares[location]?.addSubviewConstrainedToFrame(imageView)
                monsOnBoard[location] = imageView
            case .supermana:
                let imageView = UIImageView(image: Images.mana(mana, style: controller.boardStyle))
                imageView.contentMode = .scaleAspectFit
                squares[location]?.addSubviewConstrainedToFrame(imageView)
                monsOnBoard[location] = imageView
            }
        case .none:
            // TODO: refactor
            if case let .monBase(kind: kind, color: color) = controller.board.square(at: location), let square = squares[location] {
                let imageView = UIImageView(image: Images.mon(Mon(kind: kind, color: color), style: controller.boardStyle))
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                squares[location]?.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalTo: square.widthAnchor, multiplier: 0.6),
                    imageView.heightAnchor.constraint(equalTo: square.heightAnchor, multiplier: 0.6),
                    imageView.centerXAnchor.constraint(equalTo: square.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: square.centerYAnchor)
                ])
                
                imageView.alpha = 0.4
                monsOnBoard[location] = imageView // TODO: do not add to mons on board, this is smth different
            }
            
        case .monWithConsumable(mon: let mon, consumable: let consumable):
            let imageView = UIImageView(image: Images.mon(mon, style: controller.boardStyle))
            
            imageView.contentMode = .scaleAspectFit
            squares[location]?.addSubviewConstrainedToFrame(imageView)
            
            let consumableView = UIImageView(image: Images.consumable(consumable, style: controller.boardStyle))
            consumableView.contentMode = .scaleAspectFit
            
            imageView.addSubview(consumableView)
            consumableView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                consumableView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.54),
                consumableView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.54),
                NSLayoutConstraint(item: consumableView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.60, constant: 0),
                NSLayoutConstraint(item: consumableView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.50, constant: 0)
            ])
            
            monsOnBoard[location] = imageView
        }
        
        previouslySetImageView?.removeFromSuperview()
    }
    
    private func applyEffects(_ effects: [ViewEffect]) {
        for effectView in effectsViews {
            effectView.removeFromSuperview()
        }
        effectsViews = []
        
        var blinkingViews = [UIView]()
        let style = controller.boardStyle
        
        // TODO: refactor
        for effect in effects {
            switch effect {
            case .updateCell(let location):
                monsOnBoard[location]?.removeFromSuperview()
                monsOnBoard[location] = nil
                updateCell(location)
            case .setSelected(let location):
                let effectView = CircleCutoutView(color: Colors.highlight(.selectedItem, style: style), inverted: true)
                // TODO: different selection styles for different situations
                squares[location]?.addSubviewConstrainedToFrame(effectView)
                squares[location]?.sendSubviewToBack(effectView)
                effectsViews.append(effectView)
            case .updateGameStatus:
                updateGameInfo()
                controller.shareGameState()
                
                if let winner = controller.winnerColor {
                    didWin(color: winner)
                }
            case .availableForStep(let location):
                if controller.board.item(at: location) == nil, let square = squares[location] {
                    let effectView = CircleView()
                    effectView.backgroundColor = Colors.highlight(.destinationItem, style: style)
                    effectView.translatesAutoresizingMaskIntoConstraints = false
                    
                    square.addSubview(effectView)
                    square.sendSubviewToBack(effectView)
                    effectsViews.append(effectView)
                    
                    NSLayoutConstraint.activate([
                        effectView.widthAnchor.constraint(equalTo: square.widthAnchor, multiplier: 0.3),
                        effectView.heightAnchor.constraint(equalTo: square.heightAnchor, multiplier: 0.3),
                        effectView.centerXAnchor.constraint(equalTo: square.centerXAnchor),
                        effectView.centerYAnchor.constraint(equalTo: square.centerYAnchor)
                    ])
                    
                } else {
                    let effectView = CircleCutoutView(color: Colors.highlight(.emptyDestination, style: style))
                    squares[location]?.addSubviewConstrainedToFrame(effectView)
                    squares[location]?.sendSubviewToBack(effectView)
                    effectsViews.append(effectView)
                }
            case .availableForAction(let location):
                let effectView = CircleCutoutView(color: Colors.highlight(.attackTarget, style: style))
                squares[location]?.addSubviewConstrainedToFrame(effectView)
                squares[location]?.sendSubviewToBack(effectView)
                effectsViews.append(effectView)
            case .availableForSpiritAction(let location):
                
                // TODO: update
                // TODO: use dot for an empty field
                let effectView = UIView()
                effectView.backgroundColor = .clear
                effectView.layer.borderWidth = 5
                effectView.layer.borderColor = UIColor.cyan.cgColor
                squares[location]?.addSubviewConstrainedToFrame(effectView)
                squares[location]?.sendSubviewToBack(effectView)
                effectsViews.append(effectView)
            case .availableToStartFrom(let location):
                let effectView = CircleCutoutView(color: Colors.highlight(.startFrom, style: style), inverted: true)
                squares[location]?.addSubviewConstrainedToFrame(effectView)
                squares[location]?.sendSubviewToBack(effectView)
                effectsViews.append(effectView)
                blinkingViews.append(effectView)
            case .selectBombOrPotion:
                boardOverlayView.isHidden = false
            }
        }
        
        if !blinkingViews.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                for blinkingView in blinkingViews {
                    blinkingView.removeFromSuperview()
                }
                blinkingViews = []
            }
        }
    }
    
}
