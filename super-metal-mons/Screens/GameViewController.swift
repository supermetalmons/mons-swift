// ∅ 2024 super-metal-mons

import UIKit

class GameViewController: UIViewController, GameView {
    
    enum Overlay {
        case none, pickupSelection
    }
    
    static func with(gameController: GameController) -> GameViewController {
        let new = instantiate(GameViewController.self)
        new.controller = gameController
        return new
    }
    
    private var controller: GameController!
    private var isAnimatingPlayersAvatar = false
    private var isAnimatingOpponentsAvatar = false
    private var currentOverlay = Overlay.none
    private var latestOpponentReactionDate = Date.distantPast
    
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var pickupSelectionOverlay: UIView!
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
    @IBOutlet weak var opponentReactionLabel: UILabel!
    @IBOutlet weak var playerReactionLabel: UILabel!
    @IBOutlet weak var soundControlButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var voiceChatButton: UIButton!
    @IBOutlet weak var escapeButton: UIButton! {
        didSet {
            escapeButton.addTarget(self, action: #selector(endGame), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var opponentScoreLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    
    func setNewBoard() {
        boardView.setNewBoard(controller.board)
        updateGameInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        topButtonTopConstraint.constant = 8
        playerMovesTrailingConstraint.constant = 7
        opponentMovesTrailingConstraint.constant = 7
        #endif
        playerImageView.image = Images.emoji(controller.whiteEmojiId)
        boardView.setup(board: controller.board, style: controller.boardStyle, delegate: self)
        updateSoundControlButton()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSoundControlButton), name: .didEnableSounds, object: nil)
        
        controller.setGameView(self)
        setupVoiceChatButton()
        
        setGameInfoHidden(true)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSomewhere))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        didConnect()
    }
    
    private func setupVoiceChatButton() {
        let items: [UIAction] = Reaction.Kind.allCases.map { kind in
            return UIAction(title: kind.text, handler: { [weak self] _ in self?.react(Reaction.random(of: kind), byOpponent: false) })
        }
        
        #if targetEnvironment(macCatalyst)
        let children: [UIAction] = items
        #else
        let children: [UIAction] = items.reversed()
        #endif
        
        let menu = UIMenu(title: Strings.say, children: children)
        voiceChatButton.menu = menu
        voiceChatButton.showsMenuAsPrimaryAction = true
    }
    
    private func rematch() {
        let versusComputer = controller.versusComputer
        let newController = GameController()
        self.controller = newController
        controller.setGameView(self)
        if let versusComputer = versusComputer {
            controller.didSelectGameVersusComputer(versusComputer)
        }
        boardView.removeHighlights()
        setNewBoard()
        didConnect()        
    }
    
    private func setupEscapeButtonToRequireConfirmation() {
        guard escapeButton.menu == nil else { return }
        var items: [UIAction] = [
            UIAction(title: Strings.ok, handler: { [weak self] _ in
                self?.endGame()
                Haptic.generate(.error)
            })
        ]
        
        items.append(
            UIAction(title: Strings.rematch, image: Images.rematch, handler: { [weak self] _ in
                self?.rematch()
            })
        )
        
        let menu = UIMenu(title: Strings.endTheGameConfirmation, options: .destructive, children: items)
        escapeButton.menu = menu
        escapeButton.showsMenuAsPrimaryAction = true
    }
    
    func isAnimatingAvatar(opponents: Bool) -> Bool {
        return opponents ? isAnimatingOpponentsAvatar : isAnimatingPlayersAvatar
    }
    
    func setIsAnimatingAvatar(_ isAnimatingAvatar: Bool, opponents: Bool) {
        if opponents {
            isAnimatingOpponentsAvatar = isAnimatingAvatar
        } else {
            isAnimatingPlayersAvatar = isAnimatingAvatar
        }
    }
    
    // MARK: - actions
    
    @objc private func didTapSomewhere() {
        switch currentOverlay {
        case .none:
            processInput(.modifier(.cancel))
        case .pickupSelection:
            processInput(.modifier(.cancel))
            showOverlay(.none)
        }
    }
    
    func react(_ reaction: Reaction, byOpponent: Bool) {
        if !byOpponent {
            if controller.personVersusComputer {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
                    self?.react(Reaction.random(of: [.yo, .drop, .slurp]), byOpponent: true)
                }
            } else {
                voiceChatButton.isEnabled = false
                voiceChatButton.alpha = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak voiceChatButton] in
                    voiceChatButton?.isEnabled = true
                    voiceChatButton?.alpha = 1
                }
            }
        } else if !controller.personVersusComputer {
            let delta = Date().timeIntervalSince(latestOpponentReactionDate)
            guard delta > 5 else { return }
            latestOpponentReactionDate = Date()
        }
        
        Audio.shared.play(reaction: reaction, byOpponent: byOpponent)
        let label = byOpponent ? opponentReactionLabel : playerReactionLabel
        label?.text = reaction.kind.text
        label?.isHidden = false
        label?.alpha = 1
        label?.layer.removeAllAnimations()
        UIView.animate(withDuration: 3, animations: { [weak label] in label?.alpha = 0 }) { [weak label] completed in
            guard completed else { return }
            label?.isHidden = true
            label?.alpha = 1
        }
    }
    
    private func showOverlay(_ overlay: Overlay) {
        self.currentOverlay = overlay
        switch overlay {
        case .none:
            boardOverlayView.isHidden = true
            setupEscapeButtonToRequireConfirmation()
        case .pickupSelection:
            boardOverlayView.isHidden = false
            pickupSelectionOverlay.isHidden = false
        }
    }
    
    private func processInput(_ input: Input) {
        let effects = controller.processInput(input)
        applyEffects(effects)
    }
    
    private func animateAvatar(opponents: Bool, isUserInteraction: Bool) {
        guard !isAnimatingAvatar(opponents: opponents) && (isUserInteraction || !controller.isWatchOnly) else { return }
        setIsAnimatingAvatar(true, opponents: opponents)
        
        let animatedImageView: UIImageView! = opponents ? opponentImageView : playerImageView
        
        if let parent = animatedImageView.superview {
            view.bringSubviewToFront(parent)
        }
        
        let originalTransform = animatedImageView.transform
        let xDelta: CGFloat
        let yDelta: CGFloat
        var scaleFactor = CGFloat(boardView.bounds.width / animatedImageView.bounds.width * 0.45)
        if !isUserInteraction {
            scaleFactor = max(scaleFactor / 2.8, 2.2)
            xDelta = 12
            yDelta = 10
        } else {
            xDelta = 14
            yDelta = 14
        }
        let scaledTransform = originalTransform.scaledBy(x: scaleFactor, y: scaleFactor)
        let translatedAndScaledTransform = scaledTransform.translatedBy(x: xDelta, y: opponents ? yDelta : -yDelta)
                
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, animations: { [weak animatedImageView] in
            animatedImageView?.transform = translatedAndScaledTransform
        }) { [weak self, weak animatedImageView] _ in
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, animations: {
                animatedImageView?.transform = originalTransform
            }) { _ in
                self?.setIsAnimatingAvatar(false, opponents: opponents)
            }
        }
    }
    
    @IBAction func didTapMusicButton(_ sender: Any) {
        let musicViewController = instantiate(MusicViewController.self)
        musicViewController.modalPresentationStyle = .popover
        musicViewController.preferredContentSize = CGSize(width: 230, height: 302)

        if let popoverController = musicViewController.popoverPresentationController {
            popoverController.permittedArrowDirections = [.up, .down, .left, .right]
            popoverController.sourceView = musicButton
            popoverController.sourceRect = musicButton.bounds
            popoverController.delegate = self
        }
        present(musicViewController, animated: true, completion: nil)
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
        case .none:
            break
        }
    }
    
    @IBAction func didTapPlayerAvatar(_ sender: Any) {
        guard !isAnimatingPlayersAvatar else { return }
        if controller.versusComputer != nil || controller.activeColor == .white {
            Audio.shared.play(.click)
            playerImageView.image = controller.useDifferentEmoji()
        }
        animateAvatar(opponents: false, isUserInteraction: true)
    }
    
    @IBAction func didTapOpponentAvatar(_ sender: Any) {
        guard !isAnimatingOpponentsAvatar else { return }
        if controller.versusComputer == nil && controller.activeColor == .black {
            Audio.shared.play(.click)
            opponentImageView.image = controller.useDifferentEmoji()
        }
        animateAvatar(opponents: true, isUserInteraction: true)
    }
    
    @objc private func updateSoundControlButton() {
        soundControlButton.configuration?.image = Audio.shared.isSoundDisabled ? Images.unmuteSounds : Images.muteSounds
    }
    
    @IBAction func didTapSoundButton(_ sender: Any) {
        Audio.shared.toggleIsSoundDisabled()
        updateSoundControlButton()
    }
    
    private func setPlayerSide(color: Color) {
        boardView.setPlayerSide(color: controller.playerSideColor)
        updateGameInfo()
    }
    
    @objc private func endGame() {
        dismissBoardViewController()
    }
    
    private func dismissBoardViewController() {
        dismiss(animated: false)
        Audio.shared.stopMusic()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - updates
    
    func showMessageAndDismiss(message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            self?.dismissBoardViewController()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
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
        playerImageView.isHidden = hidden
        opponentImageView.isHidden = hidden
        playerScoreLabel.isHidden = hidden
        opponentScoreLabel.isHidden = hidden
        playerMovesStackView.isHidden = hidden
        opponentMovesStackView.isHidden = hidden
        let mightHaveVoiceChat = controller.personVersusComputer && !controller.isWatchOnly
        voiceChatButton.isHidden = hidden || !mightHaveVoiceChat
    }
    
    func updateEmoji(color: Color) {
        let imageViewToUpdate = color == controller.playerSideColor ? playerImageView : opponentImageView
        switch color {
        case .white:
            imageViewToUpdate?.image = Images.emoji(controller.whiteEmojiId)
        case .black:
            imageViewToUpdate?.image = Images.emoji(controller.blackEmojiId)
        }
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
        Haptic.generate(.success)        
        Audio.shared.play(.didConnect)
        boardView.reloadItems()
        setGameInfoHidden(false)
        setPlayerSide(color: controller.playerSideColor)
        showOverlay(.none)
        updateOpponentEmoji()
    }
    
    func didWin(color: Color) {
        let alert = UIAlertController(title: (color == .white ? "⚪️" : "⚫️") + "🏅", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            self?.endGame()
        }
        let rematchAction = UIAlertAction(title: "🔄 " + Strings.rematch, style: .default) { [weak self] _ in
            self?.rematch()
        }
#if targetEnvironment(macCatalyst)
        alert.addAction(rematchAction)
        alert.addAction(okAction)
#else
        alert.addAction(okAction)
        alert.addAction(rematchAction)
#endif
        present(alert, animated: true)
    }
    
    private func updateForNextTurn(color: Color) {
        let myTurn = controller.activeColor == controller.playerSideColor
        if controller.versusComputer != nil && myTurn || controller.isWatchOnly {
            animateAvatar(opponents: myTurn, isUserInteraction: false)
        }
    }
    
    func applyEffects(_ effects: [ViewEffect]) {
        boardView.removeHighlights()
        
        for effect in effects {
            switch effect {
            case .updateGameStatus:
                updateGameInfo()
                if let winner = controller.winnerColor {
                    didWin(color: winner)
                }
            case .nextTurn:
                if controller.winnerColor == nil {
                    updateForNextTurn(color: controller.activeColor)
                }
            case .selectBombOrPotion:
                showOverlay(.pickupSelection)
                Audio.shared.play(.choosePickup)
            case let .updateCells(locations):
                boardView.updateCells(locations)
            case let .addHighlights(highlights):
                boardView.addHighlights(highlights)
            case let .showTraces(traces):
                boardView.showTraces(traces)
            }
        }
    }
    
}

extension GameViewController: BoardViewDelegate {
    
    func didTapSquare(location: Location) {
        processInput(.location(location))
    }
    
}

extension GameViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
}
