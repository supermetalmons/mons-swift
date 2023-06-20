// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

// TODO: move protocol implementation to the extension
class GameViewController: UIViewController, GameView {
    
    enum Overlay {
        case none, pickupSelection, hostWaiting, guestWaiting, personOrComputer
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
    @IBOutlet weak var personOrComputerOverlay: UIView!
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
        moreButton.isHidden = true
        playerImageView.image = Images.emoji(controller.whiteEmojiId) // TODO: refactor, could break for local when starts with black
        boardView.setup(board: controller.board, style: controller.boardStyle, delegate: self)
        
        controller.setGameView(self)
        Audio.shared.setMusic(on: true)
        
        switch controller.mode {
        case .createInvite:
            setGameInfoHidden(true)
            showOverlay(.hostWaiting)
        case .joinGameId:
            setGameInfoHidden(true)
            showOverlay(.guestWaiting)
        case .localGame:
            boardView.reloadItems()
            updateGameInfo()
            showOverlay(.personOrComputer)
        }
    }
    
    // MARK: - actions
    
    private func showOverlay(_ overlay: Overlay) {
        self.currentOverlay = overlay
        switch overlay {
        case .none:
            boardOverlayView.isHidden = true
        case .personOrComputer:
            personOrComputerOverlay.isHidden = false
            boardOverlayView.isHidden = false
            pickupSelectionOverlay.isHidden = true
            hostWaitingOverlay.isHidden = true
        case .pickupSelection:
            boardOverlayView.isHidden = false
            personOrComputerOverlay.isHidden = true
            pickupSelectionOverlay.isHidden = false
            hostWaitingOverlay.isHidden = true
        case .hostWaiting:
            boardOverlayView.isHidden = false
            pickupSelectionOverlay.isHidden = true
            personOrComputerOverlay.isHidden = true
            hostWaitingOverlay.isHidden = false
            joinActivityIndicator.isHidden = true
            linkButtonsStackView.isHidden = false
            inviteLinkLabel.text = controller.inviteLink
        case .guestWaiting:
            boardOverlayView.isHidden = false
            personOrComputerOverlay.isHidden = true
            pickupSelectionOverlay.isHidden = true
            hostWaitingOverlay.isHidden = false
            joinActivityIndicator.isHidden = false
            joinActivityIndicator.startAnimating()
            linkButtonsStackView.isHidden = true
            inviteLinkLabel.text = controller.inviteLink
        }
    }
    
    private func processInput(_ input: MonsGame.Input) {
        let effects = controller.processInput(input)
        applyEffects(effects)
    }
    
    private func animateAvatar(opponents: Bool, isUserInteraction: Bool) {
        guard !isAnimatingAvatar else { return }
        isAnimatingAvatar = true
        
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
    
    @IBAction func computerButtonTapped(_ sender: Any) {
        showOverlay(.none) // TODO: implement
    }
    
    @IBAction func personButtonTapped(_ sender: Any) {
        showOverlay(.none) // TODO: implement
    }
    
    @IBAction func boardOverlayTapped(_ sender: Any) {
        switch currentOverlay {
        case .pickupSelection:
            processInput(.modifier(.cancel))
            showOverlay(.none)
        case .none, .hostWaiting, .guestWaiting, .personOrComputer:
            break
        }
    }
    
    @IBAction func didTapPlayerAvatar(_ sender: Any) {
        guard !isAnimatingAvatar else { return }
        if !controller.isWatchOnly {
            Audio.shared.play(.click)
        }
        playerImageView.image = controller.useDifferentEmoji()
        animateAvatar(opponents: false, isUserInteraction: true)
    }
    
    @IBAction func didTapOpponentAvatar(_ sender: Any) {
        guard !isAnimatingAvatar else { return }
        animateAvatar(opponents: true, isUserInteraction: true)
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
        let soundViewController = instantiate(SoundViewController.self)
        soundViewController.modalPresentationStyle = .popover
        if let popoverController = soundViewController.popoverPresentationController {
            popoverController.permittedArrowDirections = [.up, .down, .left, .right]
            popoverController.sourceView = soundControlButton
            popoverController.sourceRect = soundControlButton.bounds
            popoverController.delegate = self
        }
        present(soundViewController, animated: true, completion: nil)
    }
    
    private func setPlayerSide(color: Color) {
        boardView.setPlayerSide(color: controller.playerSideColor)
        updateGameInfo()
    }
    
    private func endGame() {
        controller.endGame()
        dismissBoardViewController()
    }
    
    private func dismissBoardViewController() {
        dismiss(animated: false)
        Audio.shared.setMusic(on: false)
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
        opponentImageView.isHidden = hidden
        playerScoreLabel.isHidden = hidden
        opponentScoreLabel.isHidden = hidden
        playerMovesStackView.isHidden = hidden
        opponentMovesStackView.isHidden = hidden
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
        boardView.reloadItems()
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
    
    private func updateForNextTurn(color: Color) {
        let myTurn = controller.activeColor == controller.playerSideColor
        if myTurn || controller.isWatchOnly {
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
                if case .localGame = controller.mode {
                    // TODO: should not be possible when playing vs computer
                   controller.playerSideColor = controller.playerSideColor.other
                   setPlayerSide(color: controller.playerSideColor)
                }
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
