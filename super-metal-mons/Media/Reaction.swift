// ∅ 2024 super-metal-mons

import Foundation

struct Reaction: Codable {
    
    enum Kind: String, CaseIterable, Codable {
        case yo, wahoo, drop, slurp, gg
        
        var text: String {
            switch self {
            case .yo, .wahoo, .gg, .drop, .slurp:
                return rawValue
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
            case .drop:
                return 1
            case .slurp:
                return 1
            }
        }
        
    }
    
    let uuid: String
    let kind: Kind
    let variation: Int
    
    static func random(of kinds: [Kind]) -> Reaction {
        let kind = kinds.randomElement() ?? .gg
        return random(of: kind)
    }
    
    static func random(of kind: Kind) -> Reaction {
        let variation = Int.random(in: 1...kind.variationsCount)
        return Reaction(uuid: UUID().uuidString, kind: kind, variation: variation)
    }
    
    var url: URL? { return Bundle.main.url(forResource: "\(kind.rawValue)\(variation)", withExtension: "wav") }
    
}
