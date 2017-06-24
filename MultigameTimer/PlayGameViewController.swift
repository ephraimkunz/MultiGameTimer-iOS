//
//  PlayGameViewController.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/18/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import UIKit

class PlayGameViewController: UIViewController {
    var central: GameCentral?
    var players: [Player]?
    var peripheral: GamePeripheral?
    var nextPlayerIndex: Int?
    var clock: GameClock!
    var currentPlayer: Player?
    var isCentral: Bool  {
            return central != nil
    }

    var wasLastActiveBeforePause = false

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stopClockButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pauseLabel: UILabel!

    @IBAction func pauseButtonTapped(_ sender: Any) {
        if pauseButton.titleLabel?.text == "Pause" {
            pauseButton.titleLabel?.text = "Play"
            pauseLabel.text = "Paused"
            pauseLabel.isHidden = false
            clock.stopClock()
            notifyOthersOfPauseChange(paused: true)
        } else {
            pauseButton.titleLabel?.text = "Pause"
            pauseLabel.isHidden = true
            notifyOthersOfPauseChange(paused: false)
        }
    }
    
    @IBAction func stopButtonTapped(_ sender: Any) {
        clock.stopClock()
        stopClockButton.isEnabled = false
        if isCentral {
            nextPlayer()
        } else {
            peripheral?.myTurnEnded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        clock = GameClock(initialTime: 60 * 1, increment: 0, clockTickedCallback: { timeString in
            self.timeLabel.text = timeString
        }, clockExpiredCallback: { _ in
            // Handle clock expiration: eject the player from the game
        })


        // Set initial time label, as it may be some time before this player gets to go
        self.timeLabel.text = clock.formattedTimeRemaining()

        central?.gamePlayDelegate = self
        peripheral?.gamePlayDelegate = self

        stopClockButton.isEnabled = false

        if isCentral {
            nextPlayerIndex = 0
            nextPlayer()
        }
    }

    // This device needs to notify other devices that the local pause state changed.
    // If this device is the central, needs to tell periphs. If a periph, needs to tell central
    func notifyOthersOfPauseChange(paused: Bool) {
        if isCentral {
            central?.pauseStateChanged(paused: paused)
        } else {
            peripheral?.pauseStateChanged(paused: paused)
        }
    }

    // Other device (cental) told this device to disable pause mode
    func disablePauseMode() {
        pauseLabel.text = "Someone else paused me"
        pauseLabel.isHidden = false
        pauseButton.isEnabled = false
        stopClockButton.isEnabled = false
    }

    // Other device (central) told this device to enable pause mode
    func enablePauseMode() {
        pauseLabel.isHidden = true
        pauseButton.isEnabled = true
        // Enable stop clock button?
    }

    // Advances the turn to the next player
    func nextPlayer() {
        if let index = nextPlayerIndex, let players = players {
            currentPlayer = players[index]
            startPlayerTurn(player: currentPlayer!)

            // Calculate next player index and update
            if index == players.count - 1 {
                nextPlayerIndex = 0
            } else {
                nextPlayerIndex = index + 1
            }
        }
    }

    func startPlayerTurn(player: Player) {
        if player.peripheral == nil { // My turn
            stopClockButton.isEnabled = true
            clock.startClock()
        } else { // One of my connected peripheral's turns
            central?.startPlayerTurn(player: player)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension PlayGameViewController: GamePlayCentralDelegate {

    func playerDidExitGame(player: Player) {
        
    }

    func playerTurnDidFinish(player: Player) {
        nextPlayer()
    }

    func playerDidTogglePause(player: Player, isPaused: Bool) {
        if isPaused {
            wasLastActiveBeforePause = false
            if clock.isActive {
                wasLastActiveBeforePause = true
                // I am the active player
                clock.stopClock()
            }
            enablePauseMode()
        } else {
            if wasLastActiveBeforePause {
                wasLastActiveBeforePause = false
                clock.startClock()
                stopClockButton.isEnabled = true
            }
            disablePauseMode()
        }

        notifyOthersOfPauseChange(paused: isPaused)
    }
}

extension PlayGameViewController: GamePlayPeripheralDelegate {
    func turnDidStart() {
        clock.startClock()
        stopClockButton.isEnabled = true
    }

    func pauseWasToggled(isPaused: Bool) {
        if isPaused {
            wasLastActiveBeforePause = false
            if clock.isActive {
                wasLastActiveBeforePause = true
                // I am the active player
                clock.stopClock()
            }
            enablePauseMode()
        } else {
            if wasLastActiveBeforePause {
                wasLastActiveBeforePause = false
                clock.startClock()
                stopClockButton.isEnabled = true
            }
            disablePauseMode()
        }
    }
}
