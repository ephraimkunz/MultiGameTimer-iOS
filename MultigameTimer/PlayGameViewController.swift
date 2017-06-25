//
//  PlayGameViewController.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/18/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import UIKit

fileprivate let buttonDisabledColor = UIColor(red: (99.0 / 255), green: (93.0 / 255), blue: (87.0 / 255), alpha: 1)

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

    var startTime: Int!
    var incrementTime: Int!
    var clockStoppedOnPause = false

    @IBOutlet weak var stopClockButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pauseLabel: UILabel!

    @IBAction func pauseButtonTapped(_ sender: Any) {
        if pauseButton.currentImage == UIImage(named: "pauseIcon") {
            setStateForPause(isPaused: true)
            // Above call hides pause button, but we want it to show. So fix that below
            pauseButton.isEnabled = true
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

        clock = GameClock(initialTime: TimeInterval(startTime), increment: TimeInterval(incrementTime), clockTickedCallback: { timeString in
            self.stopClockButton.setTitle(timeString, for: .normal)
        }, clockExpiredCallback: { _ in
            // Handle clock expiration: eject the player from the game
            if self.isCentral {
                // Not really sure how to handle this. Transfer all players to a new central?
            } else {
                self.peripheral?.myTimeExpired()
            }
        })

        // Set initial time label, as it may be some time before this player gets to go
        self.stopClockButton.setTitle(clock.formattedTimeRemaining(), for: .normal)

        central?.gamePlayDelegate = self
        peripheral?.gamePlayDelegate = self

        stopClockButton.isEnabled = false
        stopClockButton.setBackgroundColor(color: buttonDisabledColor, forState: UIControlState.disabled)
        stopClockButton.layer.cornerRadius = 5
        stopClockButton.layer.masksToBounds = true // Corner radius persists when disabled as well
        stopClockButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 45, weight: UIFontWeightBold)

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
        pauseButton.setImage(UIImage(named: "pauseIcon"), for: .normal)
    }

    // Other device (central) told this device to enable pause mode
    func enablePauseMode() {
        pauseLabel.isHidden = false
        pauseButton.isEnabled = false
        pauseButton.setImage(UIImage(named: "playIcon"), for: .normal)
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
            clock.startClock(shouldIncrement: true)
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
                clock.startClock(shouldIncrement: false)
                clockStoppedOnPause = false
                stopClockButton.isEnabled = true
            }
            disablePauseMode()
        }
    }
}

extension PlayGameViewController: GamePlayCentralDelegate {

    func playerDidExitGame(player: Player) {
        // First remove from our local list of players
        let index = players?.index(where: { $0 === player })
        players?.remove(at: index!)

        // Check for the case where nextPlayerIndex is now too large (this was second to last before wrap around to front)
        if nextPlayerIndex! > players!.count - 1 {
            nextPlayerIndex = 0
        }
        nextPlayer()
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
        clock.startClock(shouldIncrement: true)
        stopClockButton.isEnabled = true
    }

    func pauseWasToggled(isPaused: Bool) {
        setStateForPause(isPaused: isPaused)
    }
}
