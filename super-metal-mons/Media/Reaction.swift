// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Reaction: Codable {
    
    enum Kind: String, CaseIterable, Codable {
        case yo, wahoo, gg, slurp
        
        var text: String {
            switch self {
            case .yo, .wahoo, .gg:
                return rawValue
            case .slurp:
                return "*\(rawValue)*"
            }
        }
        
        var variationsCount: Int {
            switch self {
            case .yo:
                return 4
            case .gg:
                return 2
            case .wahoo:
                return 1
            case .slurp:
                return 1
            }
        }
        
    }
    
    let uuid: String
    let kind: Kind
    let variation: Int
    
    static func random(of kind: Kind) -> Reaction {
        let variation = Int.random(in: 1...kind.variationsCount)
        return Reaction(uuid: UUID().uuidString, kind: kind, variation: variation)
    }
    
    var url: URL? { return Bundle.main.url(forResource: "\(kind.rawValue)\(variation)", withExtension: "wav") }
    
}
