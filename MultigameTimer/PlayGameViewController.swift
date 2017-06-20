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
    var clock: GameClock!
    var isCentral: Bool  {
            return central != nil
    }

    @IBOutlet weak var timeLabel: UILabel!
    
    @IBAction func stopButtonTapped(_ sender: Any) {
        clock.stopClock()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        clock = GameClock(initialTime: 60 * 1, increment: 0, callback: { timeString in
            self.timeLabel.text = timeString
        })

        clock.startClock()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
