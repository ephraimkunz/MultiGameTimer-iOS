//
//  CreateGameViewController.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import UIKit

class CreateGameViewController: UIViewController {
    let gameShortId = arc4random_uniform(899) + 100
    var gameId: String {
        let index = Int(gameShortId - 100)
        return Constants.gameIds[index]
    }
    var central: GameCentral!
    var players = [Player]()

    @IBOutlet weak var gameShortIdLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        central = GameCentral(uuid: gameId, newConnected: { allPlayers in
            self.players = allPlayers
            self.tableView.reloadData()
        })
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Begin", style: .plain, target: self, action: #selector(beginTapped))
        tableView.delegate = self
        tableView.dataSource = self
        gameShortIdLabel.text = "Game Id: \(gameShortId)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func beginTapped(_ button: UIBarButtonItem) {
        print("beginTapped")
        central.startGame()
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayGameViewController") as! PlayGameViewController
        vc.central = self.central
        vc.players = self.players
        self.navigationController?.pushViewController(vc, animated: true)

    }
}

extension CreateGameViewController: UITableViewDelegate {

}

extension CreateGameViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath)
        cell.textLabel?.text = players[indexPath.row].displayName
        return cell
    }
}
