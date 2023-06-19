// Copyright © 2023 super metal mons. All rights reserved.

import AVFoundation
import MediaPlayer

class Audio: NSObject {
    
    private (set) var soundsVolume = Defaults.soundsVolume
    private (set) var musicVolume = Defaults.musicVolume
    
    static let shared = Audio()
    
    private let queue = DispatchQueue.global(qos: .userInitiated)
    private var players = [Sound: AVAudioPlayer]()
    private var musicPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func prepare() {
        queue.async { [weak self] in
            for sound in Sound.allCases {
                guard let soundFileURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                      let player = try? AVAudioPlayer(contentsOf: soundFileURL) else { continue }
                player.volume = self?.soundsVolume ?? 0
                self?.players[sound] = player
            }
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
            
            self?.playMusic()
        }
    }
    
    func setMusicVolume(_ volume: Float) {
        Defaults.musicVolume = volume
        queue.async { [weak self] in
            self?.musicPlayer?.volume = volume
            
            if self?.musicVolume.isZero == true && !volume.isZero {
                self?.musicVolume = volume
                self?.playMusic()
            } else if volume.isZero && self?.musicVolume.isZero == false {
                self?.musicPlayer?.pause()
            }
            
            self?.musicVolume = volume
        }
    }
    
    func setSoundsVolume(_ volume: Float) {
        Defaults.soundsVolume = volume
        
        queue.async { [weak self] in
            self?.soundsVolume = volume
            guard let players = self?.players.values else { return }
            for player in players {
                player.volume = volume
            }
        }
    }
    
    func play(_ sound: Sound) {
        play(sounds: [sound])
    }
    
    func play(sounds: [Sound]) {
        guard !soundsVolume.isZero else { return }
        
        queue.async { [weak self] in
            for sound in sounds {
                let player = self?.players[sound]
                player?.play()
            }
        }
    }
    
    // MARK: - Interruptions
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        queue.async { [weak self] in
            switch type {
            case .began:
                self?.musicPlayer?.pause()
            case .ended:
                if let shouldResume = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                   AVAudioSession.InterruptionOptions(rawValue: shouldResume).contains(.shouldResume) {
                    self?.musicPlayer?.play()
                }
            default:
                break
            }
        }
    }
    
    @objc func handleApplicationWillResignActive(notification: Notification) {
        queue.async { [weak self] in
            self?.musicPlayer?.pause()
        }
    }

    @objc func handleApplicationDidBecomeActive(notification: Notification) {
        queue.async { [weak self] in
            self?.musicPlayer?.play()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private
    
    private func playMusic() {
        guard !musicVolume.isZero else { return }
        
        // TODO: handle case when there is existing music player already
        
        guard let musicFileURL = Bundle.main.url(forResource: "18whale2", withExtension: "aac"),
              let player = try? AVAudioPlayer(contentsOf: musicFileURL) else { return }
        musicPlayer = player
        musicPlayer?.volume = musicVolume
        player.delegate = self
        player.play()
    }

}

extension Audio: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // TODO: play next track if successfully
    }
    
}
