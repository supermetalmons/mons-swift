// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

struct Images {
    
    static func consumable(_ consumable: Consumable) -> UIImage {
        switch consumable {
        case .potion:
            return named("potion")
        }
    }
    
    static func mon(_ mon: Mon) -> UIImage {
        return named(mon.kind.rawValue + mon.color.imageNameSuffix)
    }
    
    static func mana(_ mana: Mana) -> UIImage {
        switch mana {
        case .regular(let color):
            return named("mana" + color.imageNameSuffix)
        case .superMana:
            return named("super-mana")
        }
    }
    
    static var randomEmoji: UIImage {
        let index = Int.random(in: 1...164)
        return emoji(index)
    }
    
    static func emoji(_ index: Int) -> UIImage {
        return named("emoji-\(index)")
    }
    
    static func move(_ move: MonsGame.Move) -> UIImage {
        return named("move-\(move.rawValue)")
    }
    
    static var soundEnabled: UIImage { systemName("speaker") }
    static var soundDisabled: UIImage { systemName("speaker.slash") }
    
    private static func named(_ name: String) -> UIImage {
        return UIImage(named: name)!
    }
    
    private static func systemName(_ systemName: String, configuration: UIImage.Configuration? = nil) -> UIImage {
        return UIImage(systemName: systemName, withConfiguration: configuration)!
    }
    
}

private extension Color {
    
    var imageNameSuffix: String {
        switch self {
        case .black: return "-black"
        case .white: return ""
        }
    }
    
}
