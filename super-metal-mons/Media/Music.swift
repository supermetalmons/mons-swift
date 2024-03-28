// ∅ 2024 super-metal-mons

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
        "organwhawha", "jelly jam", "whale2", "driver"
    ]
    
}
