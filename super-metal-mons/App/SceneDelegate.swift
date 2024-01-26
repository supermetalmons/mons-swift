// ∅ 2024 super-metal-mons

import UIKit

var launchURL: URL?

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        scene.sizeRestrictions?.minimumSize = CGSize(width: 420, height: 420)
        if let url = connectionOptions.userActivities.first?.webpageURL ?? connectionOptions.urlContexts.first?.url {
            wasOpenedWithURL(url, onStart: true)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL {
            wasOpenedWithURL(url, onStart: false)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            wasOpenedWithURL(url, onStart: false)
        }
    }
    
    private func wasOpenedWithURL(_ url: URL, onStart: Bool) {
        launchURL = url
        NotificationCenter.default.post(name: Notification.Name.wasOpenedWithLink, object: nil)
    }

}
