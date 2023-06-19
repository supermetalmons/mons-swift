// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Defaults {
    
    private static let defaults = UserDefaults.standard
    
    static var songNumber: Int {
        get {
            return defaults.integer(forKey: #function) + 1
        }
        set {
            defaults.set(newValue - 1, forKey: #function)
        }
    }
    
    static var musicVolume: Float {
        get {
            return defaults.float(forKey: #function)
        }
        set {
            defaults.set(newValue, forKey: #function)
        }
    }
    
    static var soundsVolume: Float {
        get {
            return 1 - defaults.float(forKey: #function)
        }
        set {
            defaults.set(1 - newValue, forKey: #function)
        }
    }
    
}
