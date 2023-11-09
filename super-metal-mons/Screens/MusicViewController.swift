// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MusicViewController: UIViewController {
    
    private let audio = Audio.shared
    private lazy var isPlaying = audio.isPlayingMusic
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var discButton: UIButton!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musicVolumeSlider.value = audio.musicVolume
        updatePlayPauseButton()
    }
    
    @IBAction func discButtonTapped(_ sender: Any) {
        isPlaying = true
        audio.playRandomMusic()
        updatePlayPauseButton()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if isPlaying {
            audio.stopMusic()
        } else {
            audio.playRandomMusic()
        }
        isPlaying.toggle()
        updatePlayPauseButton()
    }
    
    @IBAction func didChangeMusicVolumeSlider(_ sender: Any) {
        audio.setMusicVolume(musicVolumeSlider.value)
    }
    
    private func updatePlayPauseButton() {
        if isPlaying {
            playButton.configuration?.image = Images.pause
        } else {
            playButton.configuration?.image = Images.play
        }
    }
    
}
