// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SoundViewController: UIViewController {
    
    private let audio = Audio.shared
    
    @IBOutlet weak var soundsVolumeSlider: UISlider!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        soundsVolumeSlider.value = audio.soundsVolume
        musicVolumeSlider.value = audio.musicVolume
    }
    
    @IBAction func didChangeSoundVolumeSlider(_ sender: Any) {
        audio.setSoundsVolume(soundsVolumeSlider.value)
    }
    
    @IBAction func didChangeMusicVolumeSlider(_ sender: Any) {
        audio.setMusicVolume(musicVolumeSlider.value)
    }
    
}
