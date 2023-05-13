// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

// TODO: move protocol implementation to the extension
class GameViewController: UIViewController, GameView {
    
    enum Overlay {
        case none, pickupSelection, hostWaiting, guestWaiting
    }
    
    static func with(gameController: GameController) -> GameViewController {
        let new = instantiate(GameViewController.self)
        new.controller = gameController
        return new
    }
    
    private var controller: GameController!
    private var isAnimatingAvatar = false
    private var currentOverlay = Overlay.none
    
    @IBOutlet weak var boardView: BoardView!
    
    @IBOutlet weak var monEducationImageView: UIImageView!
    @IBOutlet weak var shareLinkButton: UIButton!
    @IBOutlet weak var inviteLinkLabel: UILabel!
    @IBOutlet weak var pickupSelectionOverlay: UIView!
    @IBOutlet weak var hostWaitingOverlay: UIView!
    @IBOutlet weak var joinActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var linkButtonsStackView: UIStackView!
    
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
    private lazy var monsOnBoard = [Location: UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        topButtonTopConstraint.constant = 8
        playerMovesTrailingConstraint.constant = 7
        opponentMovesTrailingConstraint.constant = 7
        #endif
        
        updateSoundButton(isSoundEnabled: !Defaults.isSoundDisabled)
        moreButton.isHidden = controller.mode.isOnline
        playerImageView.image = Images.emoji(controller.whiteEmojiId) // TODO: refactor, could break for local when starts with black
        setupBoard()
        
        controller.setGameView(self)
        
        switch controller.mode {
        case .createInvite:
            setGameInfoHidden(true)
            showOverlay(.hostWaiting)
        case .joinGameId:
            setGameInfoHidden(true)
            showOverlay(.guestWaiting)
        case .localGame:
            reloadItems()
            updateGameInfo()
        }
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
    }
    
    // MARK: - actions
    
    private func showOverlay(_ overlay: Overlay) {
        self.currentOverlay = overlay
        switch overlay {
        case .none:
            boardOverlayView.isHidden = true
        case .pickupSelection:
            boardOverlayView.isHidden = false
            pickupSelectionOverlay.isHidden = false
            hostWaitingOverlay.isHidden = true
        case .hostWaiting:
            boardOverlayView.isHidden = false
            pickupSelectionOverlay.isHidden = true
            hostWaitingOverlay.isHidden = false
            joinActivityIndicator.isHidden = true
            linkButtonsStackView.isHidden = false
            inviteLinkLabel.text = controller.inviteLink
        case .guestWaiting:
            boardOverlayView.isHidden = false
            pickupSelectionOverlay.isHidden = true
            hostWaitingOverlay.isHidden = false
            joinActivityIndicator.isHidden = false
            joinActivityIndicator.startAnimating()
            linkButtonsStackView.isHidden = true
            inviteLinkLabel.text = controller.inviteLink
        }
    }
    
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
    
    @IBAction func shareLinkButtonTapped(_ sender: Any) {
        let shareViewController = UIActivityViewController(activityItems: [controller.inviteLink], applicationActivities: nil)
        shareViewController.popoverPresentationController?.sourceView = shareLinkButton
        shareViewController.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .openInIBooks, .postToFlickr, .postToVimeo, .markupAsPDF]
        present(shareViewController, animated: true)
    }
    
    @IBAction func copyLinkButtonTapped(_ sender: Any) {
        UIPasteboard.general.string = controller.inviteLink
    }
    
    @IBAction func bombButtonTapped(_ sender: Any) {
        processInput(.modifier(.selectBomb))
        showOverlay(.none)
    }
    
    @IBAction func potionButtonTapped(_ sender: Any) {
        processInput(.modifier(.selectPotion))
        showOverlay(.none)
    }
    
    @IBAction func boardOverlayTapped(_ sender: Any) {
        switch currentOverlay {
        case .pickupSelection:
            processInput(.modifier(.cancel))
            showOverlay(.none)
        case .none, .hostWaiting, .guestWaiting:
            break
        }
    }
    
    @IBAction func didTapPlayerAvatar(_ sender: Any) {
        guard !isAnimatingAvatar else { return }
        Audio.play(.click)
        playerImageView.image = controller.useDifferentEmoji()
        animateAvatar(opponents: false)
    }
    
    @IBAction func didTapOpponentAvatar(_ sender: Any) {
        guard !isAnimatingAvatar else { return }
        animateAvatar(opponents: true)
    }
    
    @IBAction func escapeButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: Strings.endTheGameConfirmation, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .destructive) { [weak self] _ in
            self?.endGame()
        }
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel) { _ in }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        guard case .localGame = controller.mode else { return } // TODO: should not be possible when playing vs computer
        controller.playerSideColor = controller.playerSideColor.other
        setPlayerSide(color: controller.playerSideColor)
    }
    
    @IBAction func didTapSoundButton(_ sender: Any) {
        let wasDisabled = Defaults.isSoundDisabled
        Defaults.isSoundDisabled = !wasDisabled
        updateSoundButton(isSoundEnabled: wasDisabled)
    }
    
    private func setPlayerSide(color: Color) {
        boardView.setPlayerSide(color: controller.playerSideColor)
        updateGameInfo()
    }
    
    private func endGame() {
        controller.endGame()
        dismiss(animated: false)
    }
    
    // MARK: - updates
    
    func showMessageAndDismiss(message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            self?.dismiss(animated: false)
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
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
        
        let myTurn = controller.playerSideColor == controller.activeColor
        let myScore: Int
        let opponentScore: Int
        switch controller.playerSideColor {
        case .white:
            playerImageView.image = Images.emoji(controller.whiteEmojiId)
            opponentImageView.image = Images.emoji(controller.blackEmojiId)
            myScore = controller.whiteScore
            opponentScore = controller.blackScore
        case .black:
            playerImageView.image = Images.emoji(controller.blackEmojiId)
            opponentImageView.image = Images.emoji(controller.whiteEmojiId)
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
    
    func setGameInfoHidden(_ hidden: Bool) {
        opponentImageView.isHidden = hidden
        playerScoreLabel.isHidden = hidden
        opponentScoreLabel.isHidden = hidden
        playerMovesStackView.isHidden = hidden
        opponentMovesStackView.isHidden = hidden
    }
    
    func updateOpponentEmoji() {
        switch controller.playerSideColor {
        case .white:
            opponentImageView.image = Images.emoji(controller.blackEmojiId)
        case .black:
            opponentImageView.image = Images.emoji(controller.whiteEmojiId)
        }
    }
    
    func didConnect() {
        reloadItems()
        setGameInfoHidden(false)
        setPlayerSide(color: controller.playerSideColor)
        showOverlay(.none)
        updateOpponentEmoji()
    }
    
    func didWin(color: Color) {
        let alert = UIAlertController(title: color == .white ? "⚪️" : "⚫️", message: Strings.allDone, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            self?.endGame()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
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
            guard let square = squares[location] else { break }
            
            let sparklingView = SparklingView(frame: square.bounds, style: controller.boardStyle)
            square.addSubviewConstrainedToFrame(sparklingView)
            
            let imageView = UIImageView(image: Images.consumable(consumable, style: controller.boardStyle))
            imageView.contentMode = .scaleAspectFit
            sparklingView.addSubviewConstrainedToFrame(imageView)
            
            monsOnBoard[location] = sparklingView
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
    
    func applyEffects(_ effects: [ViewEffect]) {
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
                
            case let .highlight(highlight):
                guard let square = squares[highlight.location] else { continue }
                let color = highlight.color
                switch highlight.kind {
                case .selected:
                    let effectView = CircleCutoutView(color: Colors.highlight(color, style: style), inverted: true)
                    square.addSubviewConstrainedToFrame(effectView)
                    square.sendSubviewToBack(effectView)
                    effectsViews.append(effectView)
                    
                case .emptySquare:
                    let effectView = CircleView()
                    effectView.backgroundColor = Colors.highlight(color, style: style)
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
                case .targetSuggestion:
                    let effectView = CircleCutoutView(color: Colors.highlight(color, style: style), inverted: false)
                    square.addSubviewConstrainedToFrame(effectView)
                    square.sendSubviewToBack(effectView)
                    effectsViews.append(effectView)
                    
                    if highlight.isBlink {
                        blinkingViews.append(effectView)
                    }
                }
            case .updateGameStatus:
                updateGameInfo()
                if let winner = controller.winnerColor {
                    didWin(color: winner)
                }
            case .selectBombOrPotion:
                showOverlay(.pickupSelection)
                Audio.play(.choosePickup)
            case .trace(from: let from, to: let to):
                boardView.showTrace(from: from, to: to)
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
