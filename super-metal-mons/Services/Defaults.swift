// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Defaults {
    
    private static let defaults = UserDefaults.standard
    
    static var isSoundDisabled: Bool {
        get {
            return defaults.bool(forKey: #function)
        }
        set {
            defaults.set(newValue, forKey: #function)
        }
    }
    
    static var songNumber: Int {
        get {
            return defaults.integer(forKey: #function)
        }
        set {
            defaults.set(newValue, forKey: #function)
        }
    }
    
    static var playbackMode: Int {
        get {
            return defaults.integer(forKey: #function)
        }
        set {
            defaults.set(newValue, forKey: #function)
        }
    }
    
    static var musicVolume: Float {
        get {
            return 1 - defaults.float(forKey: #function)
        }
        set {
            defaults.set(1 - newValue, forKey: #function)
        }
    }
    
}
