// Copyright © 2023 super metal mons. All rights reserved.

import AVFoundation
import MediaPlayer

class Audio: NSObject {
    
    private (set) var musicVolume = Defaults.musicVolume
    private (set) var songNumber = 1
    
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
    
    var isPlayingMusic: Bool { return musicPlayer?.isPlaying == true }
    
    func prepare() {
        queue.async { [weak self] in
            for sound in Sound.allCases {
                guard let soundFileURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                      let player = try? AVAudioPlayer(contentsOf: soundFileURL) else { continue }
                player.volume = 1
                self?.players[sound] = player
            }
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    func playRandomMusic() {
        queue.async { [weak self] in
            self?.playMusic()
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
    
    private func playMusic() {
        guard let name = songNames[Int.random(in: 1...30)] else { return }
        
        guard let musicFileURL = Bundle.main.url(forResource: name, withExtension: "aac"),
              let player = try? AVAudioPlayer(contentsOf: musicFileURL) else { return }
        
        musicPlayer = player
        musicPlayer?.volume = musicVolume
        
        player.delegate = self
        player.play()
    }
    
    // MARK: - Interruptions
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        #if !targetEnvironment(macCatalyst)
        queue.async { [weak self] in
            switch type {
            case .began:
                self?.musicPlayer?.pause()
            case .ended:
                if let shouldResume = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                   AVAudioSession.InterruptionOptions(rawValue: shouldResume).contains(.shouldResume),
                    self?.songNumber != 0 {
                    self?.musicPlayer?.play()
                }
            default:
                break
            }
        }
        #endif
    }
    
    @objc func handleApplicationWillResignActive(notification: Notification) {
        #if !targetEnvironment(macCatalyst)
        queue.async { [weak self] in
            self?.musicPlayer?.pause()
        }
        #endif
    }

    @objc func handleApplicationDidBecomeActive(notification: Notification) {
        #if !targetEnvironment(macCatalyst)
        queue.async { [weak self] in
            if self?.songNumber != 0 {
                self?.musicPlayer?.play()
            }
        }
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension Audio: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        playMusic()
    }

}

// TODO: move to a separate file
private let songNames: [Int: String] = [
    1: "cloud propeller",
    2: "bell glide",
    3: "bell dance",
    4: "organwhawha",
    5: "chimes photography_going home",
    6: "ping",
    7: "clock tower",
    8: "melodine",
    9: "cloud propeller 2",
    10: "jelly jam",
    11: "bubble jam",
    12: "spirit track",
    13: "bounce",
    14: "gilded",
    15: "mana pool",
    16: "honkshoooo memememeee zzzZZZ",
    17: "arploop",
    18: "whale2",
    19: "gustofwind",
    20: "ewejam",
    21: "change",
    22: "melodine",
    23: "driver",
    24: "object",
    25: "runner",
    26: "band",
    27: "crumbs",
    28: "buzz",
    29: "drreams",
    30: "super"
]
