//
//  CreateGameViewController.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import UIKit

fileprivate let START_TIMES_PICKER = 1
fileprivate let INCREMENT_TIMES_PICKER = 2

class CreateGameViewController: UIViewController {
    let gameShortId = arc4random_uniform(899) + 100
    var gameId: String {
        let index = Int(gameShortId - 100)
        return Constants.gameIds[index]
    }
    var central: GameCentral!
    var players = [Player]()

    let startTimes = ["00:00:15", "00:00:30", "00:00:45", "00:01:00", "00:02:00", "00:03:00", "00:05:00", "00:10:00", "00:30:00", "00:45:00", "01:00:00", "01:30:00", "02:00:00", "02:30:00", "03:00:00"]
    var incrementTimes = ["00:00:00", "00:00:05", "00:00:10", "00:00:15", "00:00:30", "00:00:45", "00:01:00", "00:01:30", "00:02:00", "00:03:00", "00:05:00", "00:10:00"]

    @IBOutlet weak var gameShortIdLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startTimePickerView: UIPickerView!
    @IBOutlet weak var incrementPickerView: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        central = GameCentral(uuid: gameId)
        central.gameSetupDelegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Begin", style: .plain, target: self, action: #selector(beginTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false

        tableView.delegate = self
        tableView.dataSource = self
        tableView.isEditing = true

        gameShortIdLabel.text = "Game Id: \(gameShortId)"

        // Generate data for picker views and set them up
        startTimePickerView.dataSource = self
        incrementPickerView.dataSource = self
        startTimePickerView.delegate = self
        incrementPickerView.delegate = self
        startTimePickerView.selectRow(startTimes.count / 2, inComponent: 0, animated: false) // In the middle
        incrementPickerView.selectRow(incrementTimes.count / 2, inComponent: 0, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        central.stopScanning()
    }

    func convertStringToTimeInSeconds(_ string: String) -> Int {
        let components = string.components(separatedBy: ":")
        if let hours = Int(components[0]), let minutes = Int(components[1]), let seconds = Int(components[2]) {
            return (hours * 3600) + (minutes * 60) + seconds
        }

        return 0
    }

    func beginTapped(_ button: UIBarButtonItem) {
        print("beginTapped")
        let startTimeSeconds = convertStringToTimeInSeconds(startTimes[startTimePickerView.selectedRow(inComponent: 0)])
        let incrementTimeSeconds = convertStringToTimeInSeconds(incrementTimes[incrementPickerView.selectedRow(inComponent: 0)])
        central.startGame(startTime: startTimeSeconds, incrementTime: incrementTimeSeconds)

        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayGameViewController") as! PlayGameViewController
        vc.central = self.central
        vc.players = self.players
        vc.startTime = startTimeSeconds
        vc.incrementTime = incrementTimeSeconds
        self.navigationController?.pushViewController(vc, animated: true)

    }
}

extension CreateGameViewController: GameSetupCentralDelegate {
    func connectedPlayersDidChange(players: [Player]) {
        self.players = players
        tableView.reloadData()

        if players.count > 1 { // Wait until there's more than just me
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}

extension CreateGameViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let player = players[sourceIndexPath.row]
        players.remove(at: sourceIndexPath.row)
        players.insert(player, at: destinationIndexPath.row)

    }
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

extension CreateGameViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case START_TIMES_PICKER:
            return startTimes[row]
        case INCREMENT_TIMES_PICKER:
            fallthrough
        default:
            return incrementTimes[row]
        }
    }
}

extension CreateGameViewController: UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case START_TIMES_PICKER:
            return startTimes.count
        case INCREMENT_TIMES_PICKER:
            fallthrough
        default:
            return incrementTimes.count
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
}
