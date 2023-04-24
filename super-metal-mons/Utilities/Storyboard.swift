// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

enum Storyboard: String {
    case main
}

func instantiate<ViewController: UIViewController>(_ type: ViewController.Type, from storyboard: Storyboard = .main) -> ViewController {
    return UIStoryboard(name: storyboard.rawValue.capitalized, bundle: nil).instantiateViewController(withIdentifier: String(describing: type)) as! ViewController
}

