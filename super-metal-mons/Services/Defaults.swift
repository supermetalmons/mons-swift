// ∅ 2024 super-metal-mons

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
    
    static var musicVolume: Float {
        get {
            return 1 - defaults.float(forKey: #function)
        }
        set {
            defaults.set(1 - newValue, forKey: #function)
        }
    }
    
}
