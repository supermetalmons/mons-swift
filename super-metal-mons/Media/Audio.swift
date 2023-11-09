// Copyright © 2023 super metal mons. All rights reserved.

import AVFoundation
import MediaPlayer

class Audio: NSObject {
    
    private (set) var musicVolume = Defaults.musicVolume
    
    static let shared = Audio()
    
    private let queue = DispatchQueue.global(qos: .userInitiated)
    private var players = [Sound: AVAudioPlayer]()
    private var musicPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    var isPlayingMusic: Bool { return musicPlayer?.isPlaying == true }
    
    func prepare() {
        queue.async { [weak self] in
            for sound in Sound.allCases {
                guard let url = sound.url, let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.volume = 1
                self?.players[sound] = player
            }
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    func playRandomMusic(doNotResume: Bool) {
        queue.async { [weak self] in
            self?.playMusic(doNotResume: doNotResume)
        }
    }
    
    func pauseMusic() {
        queue.async { [weak self] in
            self?.musicPlayer?.pause()
        }
    }
    
    func stopMusic() {
        queue.async { [weak self] in
            self?.musicPlayer?.stop()
            self?.musicPlayer = nil
        }
    }
    
    func setMusicVolume(_ volume: Float) {
        Defaults.musicVolume = volume
        musicVolume = volume
        queue.async { [weak self] in
            self?.musicPlayer?.volume = volume
        }
    }
    
    func play(_ sound: Sound) {
        play(sounds: [sound])
    }
    
    func play(sounds: [Sound]) {
        // TODO: check for sounds being muted instead
        
        queue.async { [weak self] in
            for sound in sounds {
                let player = self?.players[sound]
                player?.play()
            }
        }
    }
    
    private func playMusic(doNotResume: Bool) {
        if !doNotResume, let player = musicPlayer, !player.isPlaying {
            if player.play() {
                return
            }
        }
        
        guard let url = Music.randomTrack(), let player = try? AVAudioPlayer(contentsOf: url) else { return }
        
        musicPlayer = player
        musicPlayer?.volume = musicVolume
        
        player.delegate = self
        player.play()
    }
    
    // MARK: - Interruptions
    
    private func didInterruptMusic() {
        if isPlayingMusic {
            NotificationCenter.default.post(name: .didInterruptMusic, object: nil)
            queue.async { [weak self] in
                self?.musicPlayer?.pause()
            }
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        #if !targetEnvironment(macCatalyst)
        if case .began = type { didInterruptMusic() }
        #endif
    }
    
    @objc func handleApplicationWillResignActive(notification: Notification) {
        #if !targetEnvironment(macCatalyst)
        didInterruptMusic()
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension Audio: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        playMusic(doNotResume: true)
    }

}
