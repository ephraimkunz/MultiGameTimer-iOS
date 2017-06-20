//
//  GameClock.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/19/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation

let timerInterval = 1.0

class GameClock {
    let initialTime: TimeInterval
    let increment: TimeInterval
    let callback: ((String) -> Void)
    var timer = Timer()

    var time: TimeInterval

    init(initialTime: TimeInterval, increment: TimeInterval, callback: @escaping (String) -> Void) {
        self.increment = increment
        self.initialTime = initialTime
        self.callback = callback
        time = initialTime
    }

    @objc private func timerFired(timer: Timer) {
        time -= timerInterval
        callback(formattedTimeRemaining())
    }

    func startClock() {
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
