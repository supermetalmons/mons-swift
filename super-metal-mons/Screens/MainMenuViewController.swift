// ∅ 2024 super-metal-mons

import UIKit

class MainMenuViewController: UIViewController {
    
    private func presentGameViewController(gameController: GameController) {
        Haptic.generate(.selectionChanged)
        let gameViewController = GameViewController.with(gameController: gameController)
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
    }
    
    @IBAction func pvpButtonTapped(_ sender: Any) {
        let controller = GameController()
        presentGameViewController(gameController: controller)
    }
    
    @IBAction func pvcButtonTapped(_ sender: Any) {
        let controller = GameController()
        controller.didSelectGameVersusComputer(.person)
        presentGameViewController(gameController: controller)
    }
    
    @IBAction func cvcButtonTapped(_ sender: Any) {
        let controller = GameController()
        controller.didSelectGameVersusComputer(.computer)
        presentGameViewController(gameController: controller)
    }
    
}
