// ∅ 2024 super-metal-mons

import UIKit

class MainMenuViewController: UIViewController {
    
    @IBOutlet weak var searchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
#if !targetEnvironment(macCatalyst)
        searchButton.isHidden = false
#endif
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
