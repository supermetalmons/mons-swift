// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class MusicViewController: UIViewController {
    
    private let audio = Audio.shared
    private var selectedButtonNumber: Int?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    @IBOutlet weak var playbackModeControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musicVolumeSlider.value = audio.musicVolume
        
        if audio.isPlayingMusic {
            // TODO: display what's being played
        }
        
        playbackModeControl.selectedSegmentIndex = audio.playbackMode.rawValue
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayNextTrack), name: Notification.Name.nextTrack, object: nil)
    }
    
    @objc private func didPlayNextTrack() {
        // TODO: update what's being played
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        audio.selectSong(number: Int.random(in: 1...30), force: true)
    }
    
    @IBAction func didChangeMusicVolumeSlider(_ sender: Any) {
        audio.setMusicVolume(musicVolumeSlider.value)
    }
    
    @IBAction func didChangePlaybackMode(_ sender: Any) {
        audio.selectPlaybackMode(rawValue: playbackModeControl.selectedSegmentIndex)
    }
    
}
