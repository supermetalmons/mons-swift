// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MainMenuViewController: UIViewController {
    
    private var didAppear = false
    
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(wasOpenedWithLink), name: Notification.Name.wasOpenedWithLink, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didAppear, let url = launchURL {
            launchURL = nil
            connectToURL(url)
        }
        
        didAppear = true
    }
    
    @objc private func wasOpenedWithLink() {
        if let url = launchURL, presentedViewController == nil {
            launchURL = nil
            connectToURL(url)
        }
    }
    
    private func connectToURL(_ url: URL) {
        if let id = url.gameId {
            let controller = GameController(mode: .joinGameId(id))
            presentGameViewController(gameController: controller)
        } else {
            // TODO: communicate failed connection
        }
    }
    
    private func presentGameViewController(gameController: GameController) {
        let gameViewController = GameViewController.with(gameController: gameController)
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
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
        if let input = UIPasteboard.general.string, let url = URL(string: input) {
            connectToURL(url)
            UIPasteboard.general.string = ""
        } else {
            let alert = UIAlertController(title: Strings.thereIsNoLink, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: Strings.ok, style: .default) { _ in }
            alert.addAction(okAction)
            present(alert, animated: true)
        }
    }
    
}
