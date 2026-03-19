//
//  TimerViewModel.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import Foundation
import Combine

final class TimerViewModel: ObservableObject {
    
    enum SessionState {
        case idle
        case focusRunning
        case waitingForBreakConfirmation
        case breakRunning
        case waitingForWorkConfirmation
        case overdueBreak
        case overdueWork
    }
    
    @Published var state: SessionState = .idle
    @Published var timeRemaining: Int = 25 * 60
    
    private var timer: Timer?
    private var overdueTimer: Timer?
    
    @Published var focusMinutes: Int = 25
    @Published var breakMinutes: Int = 5

    var focusDuration: Int {
        max(1, focusMinutes) * 60
    }

    var breakDuration: Int {
        max(1, breakMinutes) * 60
    }
    private var cancellables = Set<AnyCancellable>()

    init() {
        $focusMinutes
            .sink { [weak self] _ in
                self?.resetIfIdle()
            }
            .store(in: &cancellables)

        $breakMinutes
            .sink { [weak self] _ in
                self?.resetIfIdle()
            }
            .store(in: &cancellables)
    }

    private func resetIfIdle() {
        if state == .idle {
            timeRemaining = focusDuration
        }
    }

    func startWork() {
        stopAllSounds()
        overdueTimer?.invalidate()
        stopTimer()
        
        state = .focusRunning
        timeRemaining = focusDuration
        
        SoundManager.shared.playOneShot(name: "well_start_timer")
        
        startTimer()
    }
    
    func startBreak() {
        stopAllSounds()
        overdueTimer?.invalidate()
        stopTimer()
        
        state = .breakRunning
        timeRemaining = breakDuration
        
        startTimer()
    }
    
    func resumeWork() {
        stopAllSounds()
        overdueTimer?.invalidate()
        stopTimer()
        
        state = .focusRunning
        timeRemaining = focusDuration
        
        SoundManager.shared.playOneShot(name: "well_start_timer")
        
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            handleTimerFinished()
            return
        }
        
        timeRemaining -= 1
    }
    
    private func handleTimerFinished() {
        stopTimer()
        
        switch state {
        case .focusRunning:
            state = .waitingForBreakConfirmation
            
            SoundManager.shared.playOneShot(name: "well_focus_done")
            
            NotificationManager.shared.send(
                title: "good job! time for a break!",
                body: "stand up, move a little, drink water"
            )
            
            overdueTimer?.invalidate()
            overdueTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { _ in
                DispatchQueue.main.async {
                    if self.state == .waitingForBreakConfirmation {
                        self.state = .overdueBreak
                        
                        SoundManager.shared.playLoop(name: "well_angry")
                        
                        NotificationManager.shared.send(
                            title: "hey? it's really time for your break!",
                            body: "you’re still working..."
                        )
                    }
                }
            }
            
        case .breakRunning:
            state = .waitingForWorkConfirmation
            
            SoundManager.shared.playOneShot(name: "well_break")
            
            NotificationManager.shared.send(
                title: "break's over",
                body: "ready to get back to work?"
            )
            
            overdueTimer?.invalidate()
            overdueTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { _ in
                DispatchQueue.main.async {
                    if self.state == .waitingForWorkConfirmation {
                        self.state = .overdueWork
                        
                        SoundManager.shared.playLoop(name: "well_back_to_work")
                        
                        NotificationManager.shared.send(
                            title: "you still on break?",
                            body: "let’s get moving again"
                        )
                    }
                }
            }
            
        default:
            break
        }
    }
    
    private func stopAllSounds() {
        SoundManager.shared.stop()
    }
    
    func formattedTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
