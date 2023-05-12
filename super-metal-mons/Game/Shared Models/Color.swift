// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

enum Color: String, Codable, CaseIterable {

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
        return allCases.randomElement()!
    }
    
}
