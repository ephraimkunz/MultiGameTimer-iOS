//
//  JoinGameViewController.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import UIKit

let GAME_ID_LENGTH = 3

class JoinGameViewController: UIViewController {

    @IBOutlet weak var gameIdField: UITextField!
    @IBOutlet weak var joinGameButton: UIButton!

    @IBAction func joinGameTapped(_ sender: Any) {
        guard let string = gameIdField.text, let index = Int(string) else {
            return // Must have text if the button was enabled to be tapped
        }

        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WaitForGameStartViewController") as! WaitForGameStartViewController

        let uuid = Constants.gameIds[index - 100]
        vc.peripheral = GamePeripheral(uuid: uuid)
        navigationController?.pushViewController(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gameIdField.addTarget(self, action: #selector(gameIdChanged), for: .editingChanged)
        joinGameButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func gameIdChanged(_ textField: UITextField) {
        joinGameButton.isEnabled = textField.text?.characters.count == GAME_ID_LENGTH
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

