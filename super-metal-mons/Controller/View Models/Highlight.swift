// ∅ 2024 super-metal-mons

import Foundation

struct Highlight {
    
    enum Kind {
        case selected
        case emptySquare
        case targetSuggestion
    }
    
    enum Color: String {
        case selectedStartItem
        case emptyStepDestination
        case startFrom
        case attackTarget
        case destinationItem
        case spiritTarget
    }
    
    let location: Location
    let kind: Kind
    let color: Color
    let isBlink: Bool
    
}
