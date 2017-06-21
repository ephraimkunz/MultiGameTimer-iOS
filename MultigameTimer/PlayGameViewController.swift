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

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stopClockButton: UIButton!
    
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

        clock = GameClock(initialTime: 60 * 1, increment: 0, callback: { timeString in
            self.timeLabel.text = timeString
        })

        // Set initial time label, as it may be some time before this player gets to go
        self.timeLabel.text = clock.formattedTimeRemaining()

        central?.playerTurnFinishedCallback = { player in
            self.nextPlayer()
        }

        peripheral?.myTurnStartedCallback = { _ in
            self.clock.startClock()
            self.stopClockButton.isEnabled = true
        }

        stopClockButton.isEnabled = false

        if isCentral {
            nextPlayerIndex = 0
            nextPlayer()
        }
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
