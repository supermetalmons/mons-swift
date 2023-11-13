// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Reaction {
    
    enum Kind: String, CaseIterable {
        case yo, gm, gg
        
        var text: String {
            return rawValue
        }
        
    }
    
    let kind: Kind
    let variation: Int
    
    static func random(of kind: Kind) -> Reaction {
        let variation = 0
        return Reaction(kind: kind, variation: variation)
    }
    
    var url: URL? { return Bundle.main.url(forResource: "\(kind.rawValue)-\(variation)", withExtension: "m4a") }
    
}
