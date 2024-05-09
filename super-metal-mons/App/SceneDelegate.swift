// ∅ 2024 super-metal-mons

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        scene.sizeRestrictions?.minimumSize = CGSize(width: 420, height: 420)
    }

}
