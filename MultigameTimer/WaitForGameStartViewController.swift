//
//  WaitForGameStartViewController.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/18/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import UIKit

class WaitForGameStartViewController: UIViewController {
    var peripheral: GamePeripheral!

    @IBOutlet weak var activitiyIndicator: UIActivityIndicatorView!
    @IBOutlet weak var startedLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        activitiyIndicator.startAnimating()
        startedLabel.text = "Waiting for game to start"
        peripheral.gameSetupDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WaitForGameStartViewController: GameSetupPeripheralDelegate {
    func gameDidStart() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayGameViewController") as! PlayGameViewController
        vc.peripheral = peripheral
        navigationController?.pushViewController(vc, animated: true)
    }
}
