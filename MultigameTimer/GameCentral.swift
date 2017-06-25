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

    let charsToDiscover = [Constants.PlayerNameCharacteristic, Constants.StartPlayCharacteristic, Constants.IsPlayerTurnCharacteristic, Constants.IsPausedCharacteristic, Constants.IsPlayerTimeExpiredCharacteristic]

    fileprivate var players = [Player]()

    init(uuid: String) {
        gameUuid = CBUUID(string: uuid)
        super.init()

        let me = Player()
        me.displayName = "Me"
        players.append(me)

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
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

    func startGame(startTime: Int, incrementTime: Int) {
        centralManager.stopScan()
        for player in players {
            if let periph = player.peripheral { // Don't tell myself
                let service = periph.services!.first(where: { $0.uuid == gameUuid })

                let pauseChar = service!.characteristics?.first(where: { $0.uuid == Constants.IsPausedCharacteristic})
                periph.setNotifyValue(true, for: pauseChar!) // Set up so game players can notify me later when they pause / resume

                let startPlayChar = service!.characteristics?.first(where: { $0.uuid == Constants.StartPlayCharacteristic})
                periph.writeValue("\(startTime):\(incrementTime)".data(using: .ascii)!, for: startPlayChar!, type: .withResponse)

                let timeExpiredChar = service!.characteristics?.first(where: { $0.uuid == Constants.IsPlayerTimeExpiredCharacteristic })
                periph.setNotifyValue(true, for: timeExpiredChar!)

                let char = service!.characteristics?.first(where: { $0.uuid == Constants.IsPlayerTurnCharacteristic })
                periph.setNotifyValue(true, for: char!)
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
        // We will notify the delegate of new players when we detect that they connect
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
        peripheral.discoverCharacteristics(charsToDiscover, for: service!)
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
        } else if characteristic.uuid == Constants.IsPlayerTimeExpiredCharacteristic {
            let index = players.index(where: { $0.peripheral === peripheral })
            let player = players[index!]
            players.remove(at: index!)
            centralManager.cancelPeripheralConnection(peripheral)
            gamePlayDelegate?.playerDidExitGame(player: player)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print(error)
        }

        // Make sure we have discovered all of the necessary characteristics before showing this as a connected player. Otherwise, we have a race condition where they start the game before we have discovered and subscribed to the right characteristics.
        let connectedPlayers = players.filter { player in
            if let periph = player.peripheral {
                if let service = periph.services?[0], let chars = service.characteristics {
                    for needToFind in charsToDiscover {
                        let index = chars.index { $0.uuid == needToFind }
                        if index == nil {
                            return false
                        }
                    }
                    return true
                }

                return false // No service or not all characteristics discovered yet
            } else {
                // Should be the "Me" player
                return true
            }
        }
        gameSetupDelegate?.connectedPlayersDidChange(players: connectedPlayers)
    }
}
