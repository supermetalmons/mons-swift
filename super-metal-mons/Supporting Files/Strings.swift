// ∅ 2024 super-metal-mons

import Foundation

struct Strings {
    
    static let ok = loc("ok")
    static let endTheGameConfirmation = loc("end the game?")
    static let say = loc("say")
    static let rematch = loc("rematch")
    
    private static func loc(_ string: String.LocalizationValue) -> String {
        return String(localized: string)
    }
    
}
