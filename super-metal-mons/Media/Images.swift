// ∅ 2024 super-metal-mons

import UIKit

struct Images {
    
    static var play: UIImage { systemName("play.fill") }
    static var pause: UIImage { systemName("pause.fill") }
    static var muteSounds: UIImage { systemName("speaker") }
    static var unmuteSounds: UIImage { systemName("speaker.slash") }
    static var rematch: UIImage { systemName("arrow.clockwise") }
    
    static func monsBase(mon: Mon, style: BoardStyle) -> UIImage {
        return named(style.namespace + "base-" + mon.kind.rawValue)
    }

    static func sparkle(style: BoardStyle) -> UIImage {
        return named(style.namespace + "sparkle")
    }
    
    static func consumable(_ consumable: Consumable, style: BoardStyle) -> UIImage {
        return named(style.namespace + consumable.rawValue)
    }
    
    static func mon(_ mon: Mon, style: BoardStyle) -> UIImage {
        return named(style.namespace + mon.kind.rawValue + mon.color.imageNameSuffix)
    }
    
    static func mana(_ mana: Mana, picked: Bool = false, style: BoardStyle) -> UIImage {
        switch mana {
        case .regular(let color):
            return named(style.namespace + "mana" + color.imageNameSuffix)
        case .supermana:
            return named(style.namespace + "supermana" + (picked ? "-simple" : ""))
        }
    }
    
    static func randomEmojiId(except: Int, andExcept: Int) -> Int {
        var newRandom = randomEmojiId
        while newRandom == except || newRandom == andExcept {
            newRandom = randomEmojiId
        }
        return newRandom
    }
    
    static let computerEmojiId = totalEmojiCount + 1
    static let totalEmojiCount = 155
    
    static var randomEmojiId: Int {
        let index = Int.random(in: 1...totalEmojiCount)
        return index
    }
    
    static func emoji(_ index: Int) -> UIImage {
        guard index <= computerEmojiId else { return emoji(randomEmojiId) }
        return named("emoji-\(index)")
    }
    
    static func moveEmoji(_ move: AvailableMoveKind) -> UIImage {
        return named("move-\(move.rawValue)")
    }
    
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
