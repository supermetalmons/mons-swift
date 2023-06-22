// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SoundViewController: UIViewController {
    
    @IBOutlet weak var songsStackView: UIStackView!
    
    private let audio = Audio.shared
    private var selectedButtonNumber: Int?
    
    @IBOutlet weak var soundsVolumeSlider: UISlider!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    @IBOutlet weak var playbackModeControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        soundsVolumeSlider.value = audio.soundsVolume
        musicVolumeSlider.value = audio.musicVolume
        
        if audio.isPlayingMusic {
            setSongButtonSelected(number: audio.songNumber, isSelected: true)
        }
        
        playbackModeControl.selectedSegmentIndex = audio.playbackMode.rawValue
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayNextTrack), name: Notification.Name.nextTrack, object: nil)
    }
    
    @objc private func didPlayNextTrack() {
        let songNumber = audio.songNumber
        DispatchQueue.main.async { [weak self] in
            if let selectedButtonNumber = self?.selectedButtonNumber {
                self?.setSongButtonSelected(number: selectedButtonNumber, isSelected: false)
                self?.selectedButtonNumber = nil
            }
            self?.setSongButtonSelected(number: songNumber, isSelected: true)
        }
    }
    
    @IBAction func didChangeSoundVolumeSlider(_ sender: Any) {
        audio.setSoundsVolume(soundsVolumeSlider.value)
    }
    
    @IBAction func didChangeMusicVolumeSlider(_ sender: Any) {
        audio.setMusicVolume(musicVolumeSlider.value)
    }
    
    @IBAction func songButtonTapped(_ sender: UIButton) {
        let previouslySelected = audio.songNumber
        guard let numberString = sender.titleLabel?.text, let number = Int(numberString) else { return }
        let didSelect = audio.selectSong(number: number, force: false)
        setSongButtonSelected(number: number, isSelected: didSelect)
        
        if didSelect {
            setSongButtonSelected(number: previouslySelected, isSelected: false)
        }
    }
    
    @IBAction func didChangePlaybackMode(_ sender: Any) {
        audio.selectPlaybackMode(rawValue: playbackModeControl.selectedSegmentIndex)
    }
    
    private func setSongButtonSelected(number: Int, isSelected: Bool) {
        guard number > 0 else { return }
        let index = number - 1
        
        let row = index / 5
        let col = index % 5
        
        let button = (songsStackView.arrangedSubviews[row] as? UIStackView)?.arrangedSubviews[col].subviews.first as? UIButton
        
        if isSelected {
            button?.configuration = .filled()
            selectedButtonNumber = number
        } else {
            button?.configuration = .plain()
        }
        
        button?.configuration?.title = String(number)
    }
    
}
