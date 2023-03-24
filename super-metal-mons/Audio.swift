// Copyright © 2023 super metal mons. All rights reserved.

import AVFoundation
import AudioToolbox

struct Audio {
    
    static func endTurn() {
        play(id: 1016)
    }
        
    private static func play(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
    
}
