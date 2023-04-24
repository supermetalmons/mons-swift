// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

var launchURL: URL?

var macosHeight: CGFloat = 900
var macosWidth: CGFloat = 600

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        scene.sizeRestrictions?.minimumSize = CGSize(width: macosWidth, height: macosHeight)
        scene.sizeRestrictions?.maximumSize = CGSize(width: macosWidth, height: macosHeight)
        
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