//
//  GameCentral.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol GameSetupCentralDelegate {
    func connectedPlayersDidChange(players: [Player]) // New players connected, returns full list connected so far
}

protocol GamePlayCentralDelegate {
    func playerTurnDidFinish(player: Player) // Notified that a player has finished their turn, time to transisiton

    func playerDidTogglePause(player: Player, isPaused: Bool) // Notified that a player (periph) has toggled pause

    func playerDidExitGame(player: Player) // Notified that a player just exited the game
}

class GameCentral: NSObject {
    fileprivate var centralManager: CBCentralManager!
    fileprivate var gameUuid: CBUUID
    internal var gameSetupDelegate: GameSetupCentralDelegate?  // Should delegate be weak?
    internal var gamePlayDelegate: GamePlayCentralDelegate?

    fileprivate var players = [Player]()

    init(uuid: String) {
        gameUuid = CBUUID(string: uuid)
        super.init()

        let me = Player()
        me.displayName = "Me"
        players.append(me)

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func pauseStateChanged(paused: Bool, exclude: Player?) {
        let writeValue = paused ? "true" : "false"
        
        // Tell all the players that I'm trying to pause/resume the game
        for player in players {
            if let exclude = exclude {
                if exclude === player {
                    continue
                }
            }
            if let periph = player.peripheral { // Don't tell myself
                let service = periph.services!.first(where: { $0.uuid == gameUuid })
                let char = service!.characteristics!.first(where: { $0.uuid == Constants.IsPausedCharacteristic })
                periph.writeValue(writeValue.data(using: .ascii)!, for: char!, type: .withResponse)

            }
        }
    }

    func startGame() {
        centralManager.stopScan()
        for player in players {
            if let periph = player.peripheral { // Don't tell myself
                let service = periph.services!.first(where: { $0.uuid == gameUuid })
                let pauseChar = service!.characteristics?.first(where: { $0.uuid == Constants.IsPausedCharacteristic})
                periph.setNotifyValue(true, for: pauseChar!) // Set up so game players can notify me later when they pause / resume

                let startPlayChar = service!.characteristics?.first(where: { $0.uuid == Constants.StartPlayCharacteristic})
                periph.writeValue("true".data(using: .ascii)!, for: startPlayChar!, type: .withResponse)
            }
        }
    }

    func startPlayerTurn(player: Player) {
        guard let periph = player.peripheral else {
            return
        }

        let service = periph.services!.first(where: { $0.uuid == gameUuid })
        let char = service!.characteristics?.first(where: { $0.uuid == Constants.IsPlayerTurnCharacteristic })
        periph.writeValue("true".data(using: .ascii)!, for: char!, type: .withResponse)
    }
}

extension GameCentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [gameUuid], options: nil)
        default:
            print("Central is in state \(central.state)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }

        let player = Player()
        player.displayName = name
        player.peripheral = peripheral
        players.append(player)
        gameSetupDelegate?.connectedPlayersDidChange(players: players) // Technically we haven't connected yet, but we need to get the name here.
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }
}

extension GameCentral: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([gameUuid])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print(error)
            return
        }

        let service = peripheral.services!.first(where: { $0.uuid == gameUuid })
        peripheral.discoverCharacteristics([Constants.PlayerNameCharacteristic, Constants.StartPlayCharacteristic, Constants.IsPlayerTurnCharacteristic, Constants.IsPausedCharacteristic], for: service!)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error)
            return
        }

        if characteristic.uuid == Constants.IsPlayerTurnCharacteristic {
            let player = players.first(where: { peripheral == $0.peripheral })

            if let player = player {
                gamePlayDelegate?.playerTurnDidFinish(player: player)
            }
        } else if characteristic.uuid == Constants.IsPausedCharacteristic {
            let player = players.first(where: { $0.peripheral?.identifier == peripheral.identifier })
            if let data = characteristic.value, let value = String(data: data, encoding: .ascii), let player = player {
                let isPaused = value == "true"
                gamePlayDelegate?.playerDidTogglePause(player: player, isPaused: isPaused)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print(error)
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        let char = characteristics.first(where: { $0.uuid == Constants.IsPlayerTurnCharacteristic })
        peripheral.setNotifyValue(true, for: char!)
    }
}
