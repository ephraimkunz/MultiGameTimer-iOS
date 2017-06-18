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
        
        peripheral.gameStartedCallback = { started in
            if started {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayGameViewController") as! PlayGameViewController
                vc.peripheral = self.peripheral
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
