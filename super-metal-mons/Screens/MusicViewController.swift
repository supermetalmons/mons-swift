// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MusicViewController: UIViewController {
    
    private let audio = Audio.shared
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var discButton: UIButton!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musicVolumeSlider.value = audio.musicVolume
        
        if audio.isPlayingMusic {
            // TODO: display what's being played
        }
    }
    
    @IBAction func discButtonTapped(_ sender: Any) {
        audio.selectSong(number: Int.random(in: 1...30), force: true)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        // TODO: play / pause
        audio.selectSong(number: Int.random(in: 1...30), force: true)
    }
    
    @IBAction func didChangeMusicVolumeSlider(_ sender: Any) {
        audio.setMusicVolume(musicVolumeSlider.value)
    }
    
}
