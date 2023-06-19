// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SoundViewController: UIViewController {
    
    @IBOutlet weak var songsStackView: UIStackView!
    
    private let audio = Audio.shared
    
    @IBOutlet weak var soundsVolumeSlider: UISlider!
    @IBOutlet weak var musicVolumeSlider: UISlider!
    @IBOutlet weak var playbackModeControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        soundsVolumeSlider.value = audio.soundsVolume
        musicVolumeSlider.value = audio.musicVolume
        setSongButtonSelected(number: audio.songNumber, isSelected: true)
        playbackModeControl.selectedSegmentIndex = audio.playbackMode.rawValue
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
        let didSelect = audio.selectSong(number: number)
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
        } else {
            button?.configuration = .plain()
        }
        
        button?.configuration?.title = String(number)
    }
    
}
