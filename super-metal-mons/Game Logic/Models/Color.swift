// ∅ 2024 super-metal-mons

import Foundation

enum Color: String, Codable, CaseIterable, Hashable {

    case white, black
    
    var other: Color {
        switch self {
        case .black:
            return .white
        case .white:
            return .black
        }
    }
    
    static var random: Color {
        return allCases.randomElement() ?? .white
    }
    
}
