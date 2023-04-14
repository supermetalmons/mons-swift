// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MainMenuViewController: UIViewController {
    
    @IBAction func playButtonTapped(_ sender: Any) {
        let gameViewController = instantiate(MonsboardViewController.self)
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
    }
    
}
