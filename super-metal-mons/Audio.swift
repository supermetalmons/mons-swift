// Copyright © 2023 super metal mons. All rights reserved.

import AVFoundation

struct Audio {
    
    enum Sound: String {
        case bomb
        case demonAbility
        case demonMove
        case downBump
        case dropMana
        case manaPickUp
        case move
        case moveMana
        case mysticAbility
        case pickUpPotion
        case scoreMana
        case scoreSuperMana
        case spiritAbility
    }
    
    private static var player: AVAudioPlayer?
    
    static func play(_ sound: Sound) {
        guard let soundFileURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { return }
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        player = try? AVAudioPlayer(contentsOf: soundFileURL)
        player?.play()
    }

}
