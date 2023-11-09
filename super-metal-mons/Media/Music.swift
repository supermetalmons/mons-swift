// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Music {
    
    static func randomTrack() -> URL? {
        if let name = songNames.randomElement(),
           let url = Bundle.main.url(forResource: name, withExtension: "aac") {
            return url
        } else {
            return nil
        }
    }
    
    private static let songNames = [
        "cloud propeller", "bell glide", "bell dance", "organwhawha", "chimes photography_going home", "ping", "clock tower", "melodine", "cloud propeller 2", "jelly jam", "bubble jam", "spirit track", "bounce", "gilded", "mana pool", "honkshoooo memememeee zzzZZZ", "arploop", "whale2", "gustofwind", "ewejam", "change", "melodine", "driver", "object", "runner", "band", "crumbs", "buzz", "drreams", "super"
    ]
    
}
