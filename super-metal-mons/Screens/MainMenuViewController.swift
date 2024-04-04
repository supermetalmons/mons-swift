// ∅ 2024 super-metal-mons

import UIKit

class MainMenuViewController: UIViewController {
    
    private var didAppear = false
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var localGameButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(wasOpenedWithLink), name: Notification.Name.wasOpenedWithLink, object: nil)
        let attributes: [NSAttributedString.Key : Any] = [.font: UIFont.systemFont(ofSize: 32, weight: .bold)]
        newGameButton.setAttributedTitle(NSAttributedString(string: Strings.newLink, attributes: attributes), for: .normal)
        joinButton.setAttributedTitle(NSAttributedString(string: Strings.enterLink, attributes: attributes), for: .normal)
        localGameButton.setAttributedTitle(NSAttributedString(string: Strings.playHere, attributes: attributes), for: .normal)
#if !targetEnvironment(macCatalyst)
        searchButton.isHidden = false
#endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didAppear, let url = launchURL {
            launchURL = nil
            processUrl(url)
        }
        
        didAppear = true
    }
    
    @objc private func wasOpenedWithLink() {
        if let url = launchURL {
            launchURL = nil
            processUrl(url)
        }
    }
    
    private func processUrl(_ url: URL) {
        if let gameId = url.gameId, presentedViewController == nil {
            connectToGame(id: gameId)
        } else if let secretAppRequest = url.secretAppRequest {
            switch secretAppRequest {
            case .createSecretInvite:
                showProcessingAlert() // TODO: implement
            case .recoverSecretInvite(id: let id):
                showProcessingAlert() // TODO: implement
            case .acceptSecretInvite(id: let id, password: let password):
                showProcessingAlert() // TODO: implement
            case .getSecretGameResult(id: let id, signature: let signature):
                showProcessingAlert() // TODO: implement
            }
        }
    }
    
    private func showProcessingAlert() {
        let alert = UIAlertController(title: Strings.loading, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel) { _ in
            
        }
        alert.addAction(cancelAction)
        topmost.present(alert, animated: true)
    }
    
    private func connectToGame(id: String) {
        let controller = GameController(mode: .joinGameId(id))
        presentGameViewController(gameController: controller)
    }
    
    private func presentGameViewController(gameController: GameController) {
        Haptic.generate(.selectionChanged)
        let gameViewController = GameViewController.with(gameController: gameController)
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
#if !targetEnvironment(macCatalyst)
        present(instantiate(MapViewController.self).inNavigationController, animated: true)
#endif
    }
    
    @IBAction func newGameLinkButtonTapped(_ sender: Any) {
        let controller = GameController(mode: .createInvite)
        presentGameViewController(gameController: controller)
    }
    
    @IBAction func localGameButtonTapped(_ sender: Any) {
        let controller = GameController(mode: .localGame)
        presentGameViewController(gameController: controller)
    }
    
    @IBAction func joinButtonTapped(_ sender: Any) {
        if let input = UIPasteboard.general.string, let gameId = URL(string: input)?.gameId {
            connectToGame(id: gameId)
        } else {
            let alert = UIAlertController(title: Strings.thereIsNoLink, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: Strings.ok, style: .default) { _ in }
            alert.addAction(okAction)
            present(alert, animated: true)
            Haptic.generate(.error)
            return
        }
    }
    
}
