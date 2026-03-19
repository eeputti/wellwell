//
//  SoundManager.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?

    func playOneShot(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("\(name).wav not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = 0
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("error playing one-shot sound: \(error.localizedDescription)")
        }
    }

    func playLoop(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("\(name).wav not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("error playing loop sound: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
