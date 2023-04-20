// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Defaults {
    
    private static let defaults = UserDefaults.standard
    
    static var isSoundEnabled: Bool {
        get {
            return defaults.bool(forKey: #function)
        }
        set {
            defaults.set(newValue, forKey: #function)
        }
    }
    
}
