//
//  soundEffectManager.swift
//  small-chess
//
//  Created by Nazwa Sapta Pradana on 05/05/26.
//

import AVFoundation

class AudioService {
    
    private var isMuted: Bool = false
    var backgroundAudioPlayer: AVAudioPlayer?
    var soundEffectPlayer: AVAudioPlayer?
    
    static let shared: AudioService = AudioService()
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }
    
    func playBackgorundMusic() {
        if isMuted {
            return
        }
        
        if let sound = Bundle.main.path(forResource: "background", ofType: "mp3") {
          do {
            self.backgroundAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
              self.backgroundAudioPlayer?.numberOfLoops = -1
              self.backgroundAudioPlayer?.prepareToPlay()
              self.backgroundAudioPlayer?.play()
          } catch {
            print("AVAudioPlayer can't be instantiated.")
          }
        } else {
          print("Audio file not found.")
        }
    }
    
    func playSoundEffect(audio: AudioEffect) {
        if isMuted {
            return
        }
        
        let audioData = splitFileName(audio.rawValue)
        
        if audioData == nil {
            print("Invalid audio name")
            return
        }
        
        if let sound = Bundle.main.path(forResource: audioData!.name, ofType: audioData!.type) {
          do {
            self.soundEffectPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
              self.soundEffectPlayer?.prepareToPlay()
              self.soundEffectPlayer?.play()
          } catch {
            print("AVAudioPlayer can't be instantiated.")
          }
        } else {
          print("Audio file not found.")
        }
    }
    
    func changeAudioState(isMuted: Bool) {
        self.isMuted = isMuted
        
        if (isMuted) {
            self.backgroundAudioPlayer?.stop()
        }
    }
    
    func getAudioState() -> Bool {
        return isMuted
    }
    
    func splitFileName(_ fileName: String) -> (name: String, type: String)? {
        let url = URL(fileURLWithPath: fileName)
        let name = url.deletingPathExtension().lastPathComponent
        let type = url.pathExtension
        
        guard !name.isEmpty, !type.isEmpty else { return nil }
        return (name, type)
    }
    
}

enum AudioEffect: String {
    case checkMate = "checkmate.mp3"
    case nextLevel = "nextlevel.wav"
    case moveself = "moveself.mp3"
    case bestmove = "bestmove.mp3"
    case blunder = "blunder.mp3"
    case brilliant = "brilliant.mp3"
    case mistake = "mistake.mp3"
}
