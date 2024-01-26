// ∅ 2024 super-metal-mons

import Foundation

extension String {

    static var newGameId: String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let id = String((0..<10).map { _ in letters.randomElement()! })
        return id
    }
    
    var withHttpsSchema: String {
        let prefix = "https://"
        guard !hasPrefix(prefix) else { return self }
        return prefix + self
    }
    
}
