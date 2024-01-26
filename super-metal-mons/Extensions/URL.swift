// ∅ 2024 super-metal-mons

import Foundation

extension URL {
    
    static let monsBaseURLString = "mons.link"
    
    static func forGame(id: String) -> String {
        return monsBaseURLString + "/" + id
    }
    
    var gameId: String? {
        let link: String
        
        if let scheme = scheme {
            link = absoluteString.replacingOccurrences(of: scheme + "://", with: "")
        } else {
            link = absoluteString
        }
        
        let prefix = URL.monsBaseURLString + "/"
        
        if link.hasPrefix(prefix), link.count > prefix.count {
            let id = String(link.dropFirst(prefix.count))
            return id
        } else {
            return nil
        }
    }
    
}
