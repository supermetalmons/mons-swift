// ∅ 2024 super-metal-mons

import UIKit

struct Colors {
    
    static func square(_ square: SquareColor, style: BoardStyle) -> UIColor {
        return named("board/\(style.namespace)\(square.rawValue)")
    }
    
    static func traces(style: BoardStyle) -> [UIColor] {
        return (1...7).map { named("board/\(style.namespace)trace/\($0)") }
    }
    
    static func ripple(style: BoardStyle) -> UIColor {
        return named("board/\(style.namespace)ripple")
    }
    
    static func highlight(_ color: Highlight.Color, style: BoardStyle) -> UIColor {
        return named("board/\(style.namespace)highlights/\(color.rawValue)")
    }
    
    private static func named(_ name: String) -> UIColor {
        return UIColor(named: name)!
    }
    
}
