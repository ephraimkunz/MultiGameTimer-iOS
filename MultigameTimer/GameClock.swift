//
//  GameClock.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/19/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation

let timerInterval = 1.0 // How often we run the timerFired method. Lower = better timer accuracy / worse battery life / dealing with fractions of a second

class GameClock {
    let initialTime: TimeInterval
    let increment: TimeInterval
    let clockTickedCallback: (String) -> Void
    let clockExpiredCallback: (Void) -> Void
    var timer = Timer()
    var isActive: Bool {
        return timer.isValid
    }

    var time: TimeInterval

    init(initialTime: TimeInterval, increment: TimeInterval, clockTickedCallback: @escaping (String) -> Void, clockExpiredCallback: @escaping (Void) -> Void) {
        self.increment = increment
        self.initialTime = initialTime
        self.clockTickedCallback = clockTickedCallback
        self.clockExpiredCallback = clockExpiredCallback
        time = initialTime
    }

    @objc private func timerFired(timer: Timer) {
        time -= timerInterval
        clockTickedCallback(formattedTimeRemaining())
    }

    func startClock() {
        time += increment
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }

    func stopClock() {
        timer.invalidate()
    }

    func resetClock() {
        time = initialTime
    }

    func formattedTimeRemaining() -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}
