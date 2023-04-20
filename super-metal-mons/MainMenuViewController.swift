// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MainMenuViewController: UIViewController {
    
    var fisrtTime = true
    
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(wasOpenedWithLink), name: NSNotification.Name("link"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if fisrtTime, let url = launchURL {
            launchURL = nil
            connectToURL(url)
        }
        
        fisrtTime = false
    }
    
    @objc private func wasOpenedWithLink() {
        if let url = launchURL, presentedViewController == nil {
            launchURL = nil
            connectToURL(url)
        }
    }
    
    private func connectToURL(_ url: URL) {
        let link: String
        
        if let scheme = url.scheme {
            link = url.absoluteString.replacingOccurrences(of: scheme + "://", with: "")
        } else {
            link = url.absoluteString
        }
        
        let prefix = "lil.org/mons?"
        
        if link.hasPrefix(prefix) {
            let id = String(link.dropFirst(prefix.count))
            
            let gameViewController = MonsboardViewController.with(gameDataSource: RemoteGameDataSource(gameId: id))
            gameViewController.modalPresentationStyle = .overFullScreen
            present(gameViewController, animated: false)
        }
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let id = String((0..<10).map { _ in letters.randomElement()! })
        
        let gameViewController = MonsboardViewController.with(gameDataSource: RemoteGameDataSource(gameId: id))
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
        
        let link = "lil.org/mons?\(id)"
        let alert = UIAlertController(title: "invite link", message: link, preferredStyle: .alert)
        let copyAction = UIAlertAction(title: "copy", style: .default) { _ in
            UIPasteboard.general.string = link
        }
        alert.addAction(copyAction)
        gameViewController.present(alert, animated: true)
    }
    
    @IBAction func localGameButtonTapped(_ sender: Any) {
        let gameViewController = MonsboardViewController.with(gameDataSource: LocalGameDataSource(gameId: ""))
        gameViewController.modalPresentationStyle = .overFullScreen
        present(gameViewController, animated: false)
    }
    
    @IBAction func joinButtonTapped(_ sender: Any) {
        if let input = UIPasteboard.general.string, let url = URL(string: input) {
            connectToURL(url)
            UIPasteboard.general.string = ""
        } else {
            let alert = UIAlertController(title: "there is no link", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: Strings.ok, style: .default) { _ in }
            alert.addAction(okAction)
            present(alert, animated: true)
        }
    }
    
}
