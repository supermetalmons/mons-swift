// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SoundViewController: UIViewController {
    
    @IBOutlet weak var soundsVolumeSlider: UISlider!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        soundsVolumeSlider.value = Audio.soundsVolume
        musicVolumeSlider.value = Audio.musicVolume
    }
    
    @IBAction func didChangeSoundVolumeSlider(_ sender: Any) {
        Audio.setSoundsVolume(soundsVolumeSlider.value)
    }
    
    @IBAction func didChangeMusicVolumeSlider(_ sender: Any) {
        Audio.setMusicVolume(musicVolumeSlider.value)
    }
    
}
