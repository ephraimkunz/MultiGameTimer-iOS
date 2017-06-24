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
    internal var gameSetupDelegate: GameSetupCentralDelegate? { // Should delegate be weak?
        willSet {
            gameSetupDelegate?.connectedPlayersDidChange(players: players) // Call delegate as soon as it is set to show player "Me" right away
        }
    }

    internal var gamePlayDelegate: GamePlayCentralDelegate?

    fileprivate var discovered = [CBPeripheral]()
    fileprivate var players = [Player]()

    init(uuid: String) {
        gameUuid = CBUUID(string: uuid)
        super.init()

        let me = Player()
        me.displayName = "Me"
        players.append(me)

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func pauseStateChanged(paused: Bool) {
        let writeValue = paused ? "true" : "false"
        for player in players {
            if let periph = player.peripheral {
                let service = periph.services!.first(where: { $0.uuid == gameUuid })
                let char = service!.characteristics!.first(where: { $0.uuid == Constants.IsPausedCharacteristic })
                periph.writeValue(writeValue.data(using: .ascii)!, for: char!, type: .withResponse)

            }
        }
    }

    func startGame() {
        centralManager.stopScan()
        for player in players {
            if let periph = player.peripheral {
                let service = periph.services!.first(where: { service in
                    return service.uuid == gameUuid
                })
                let pauseChar = service!.characteristics?.first(where: { $0.uuid == Constants.IsPausedCharacteristic})
                periph.setNotifyValue(true, for: pauseChar!)

                let startPlayChar = service!.characteristics?.first(where: { $0.uuid == Constants.StartPlayCharacteristic})
                periph.writeValue("true".data(using: .ascii)!, for: startPlayChar!, type: .withResponse)
            }
        }
    }

    func startPlayerTurn(player: Player) {
        guard let periph = player.peripheral, let services = periph.services else {
            return
        }

        for service in services {
            guard let characteristics = service.characteristics else {
                return
            }

            for char in characteristics {
                if char.uuid == Constants.IsPlayerTurnCharacteristic {
                    // Write a value to the characteristic to start the turn
                    periph.writeValue("true".data(using: .ascii)!, for: char, type: .withResponse)
                }
            }
        }
    }
}

extension GameCentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [gameUuid], options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }

        discovered.append(peripheral)
        let player = Player()
        player.displayName = name
        player.peripheral = peripheral
        players.append(player)
        gameSetupDelegate?.connectedPlayersDidChange(players: players)
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

        guard let services = peripheral.services else {
            return
        }

        for service in services {
            if service.uuid == gameUuid {
                peripheral.discoverCharacteristics([Constants.PlayerNameCharacteristic, Constants.StartPlayCharacteristic, Constants.IsPlayerTurnCharacteristic, Constants.IsPausedCharacteristic], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error)
            return
        }

        if characteristic.uuid == Constants.IsPlayerTurnCharacteristic {
            let player = players.first(where: { player in
                return peripheral == player.peripheral
            })

            if let player = player {
                gamePlayDelegate?.playerTurnDidFinish(player: player)
            }
        } else if characteristic.uuid == Constants.IsPausedCharacteristic {
            
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

        for char in characteristics {
            if char.uuid == Constants.IsPlayerTurnCharacteristic {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }
}
