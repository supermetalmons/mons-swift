// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SoundViewController: UIViewController {
    
    @IBOutlet weak var songsStackView: UIStackView!
    
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
    
    @IBAction func songButtonTapped(_ sender: UIButton) {
        guard let numberString = sender.titleLabel?.text, let number = Int(numberString) else { return }
        let didSelect = audio.selectSong(number: number)
        if didSelect {
            sender.configuration = .filled()
        } else {
            sender.configuration = .plain()
        }
        sender.configuration?.title = numberString
    }
    
}
