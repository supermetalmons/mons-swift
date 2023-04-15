// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MainMenuViewController: UIViewController {
    
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    @IBAction func playButtonTapped(_ sender: Any) {
        let gameViewController = instantiate(MonsboardViewController.self)
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
    }
    
    @IBAction func joinButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "there is no link", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { _ in }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
}
