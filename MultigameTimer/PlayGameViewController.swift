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

    var clockStoppedOnPause = false

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stopClockButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pauseLabel: UILabel!

    @IBAction func pauseButtonTapped(_ sender: Any) {
        if pauseButton.titleLabel?.text == "Pause" {
            setStateForPause(isPaused: true)
            notifyOthersOfPauseChange(paused: true, exlude: nil)
        } else {
            setStateForPause(isPaused: false)
            notifyOthersOfPauseChange(paused: false, exlude: nil)
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

        pauseLabel.isHidden = true

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

    // exclude is a player we want to exclude, for the case when this method is called by the central after
    // being notified that a peripheral paused the game. We want the central to not notify that peripheral again.
    func notifyOthersOfPauseChange(paused: Bool, exlude: Player?) {
        if isCentral {
            central?.pauseStateChanged(paused: paused, exclude: exlude)
        } else {
            peripheral?.pauseStateChanged(paused: paused)
        }
    }

    // Other device (cental) told this device to disable pause mode (resume play)
    func disablePauseMode() {
        pauseLabel.isHidden = true
        pauseButton.isEnabled = true
        pauseButton.setTitle("Pause", for: .normal)
    }

    // Other device (central) told this device to enable pause mode
    func enablePauseMode() {
        pauseLabel.isHidden = false
        pauseButton.isEnabled = false
        pauseButton.setTitle("Play", for: .normal)
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

    func setStateForPause(isPaused: Bool) {
        if isPaused {
            if clock.isActive {
                clockStoppedOnPause = true
                clock.stopClock()
                stopClockButton.isEnabled = false
            }
            enablePauseMode()
        } else {
            if clockStoppedOnPause {
                clock.startClock()
                clockStoppedOnPause = false
                stopClockButton.isEnabled = true
            }
            disablePauseMode()
        }
    }
}

extension PlayGameViewController: GamePlayCentralDelegate {

    func playerDidExitGame(player: Player) {
        
    }

    func playerTurnDidFinish(player: Player) {
        nextPlayer()
    }

    func playerDidTogglePause(player: Player, isPaused: Bool) {
        // Set my state correctly...
        setStateForPause(isPaused: isPaused)

        // Then notify my peripherals, except the one who paused to begin with
        notifyOthersOfPauseChange(paused: isPaused, exlude: player)
    }
}

extension PlayGameViewController: GamePlayPeripheralDelegate {
    func turnDidStart() {
        clock.startClock()
        stopClockButton.isEnabled = true
    }

    func pauseWasToggled(isPaused: Bool) {
        setStateForPause(isPaused: isPaused)
    }
}
