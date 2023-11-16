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
        NotificationCenter.default.addObserver(self, selector: #selector(didInterruptMusic), name: .didInterruptMusic, object: nil)
    }
    
    @objc private func didInterruptMusic() {
        isPlaying = false
        updatePlayPauseButton()
    }
    
    @IBAction func discButtonTapped(_ sender: Any) {
        Haptic.generate(.selectionChanged)
        audio.play(.click)
        isPlaying = true
        audio.playRandomMusic(doNotResume: true)
        updatePlayPauseButton()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if isPlaying {
            audio.pauseMusic()
        } else {
            audio.play(.click)
            audio.playRandomMusic(doNotResume: false)
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
