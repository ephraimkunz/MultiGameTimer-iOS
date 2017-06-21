//
//  GameCentral.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation
import CoreBluetooth

class GameCentral: NSObject {
    fileprivate var centralManager: CBCentralManager!
    fileprivate var gameUuid: CBUUID
    fileprivate var discovered = [CBPeripheral]()
    fileprivate var connected = [CBPeripheral]()
    fileprivate var characteristics = [CBCharacteristic]()
    fileprivate var players = [Player]()
    fileprivate var connectedCallback: (([Player]) -> Void)?
    var playerTurnFinishedCallback: ((Player) -> Void)?

    init(uuid: String, newConnected: @escaping ([Player]) -> Void) {
        gameUuid = CBUUID(string: uuid)
        connectedCallback = newConnected
        super.init()

        let me = Player()
        me.displayName = "Me"
        players.append(me)
        connectedCallback?(players) // Show "Me" right away

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startGame() {
        centralManager.stopScan()
        for char in characteristics {
            if char.uuid == Constants.StartPlayCharacteristic {
                char.service.peripheral.writeValue("true".data(using: .ascii)!, for: char, type: .withResponse)
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
        connectedCallback?(players)
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }
}

extension GameCentral: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connected.append(peripheral)
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
                peripheral.discoverCharacteristics([Constants.PlayerNameCharacteristic, Constants.StartPlayCharacteristic, Constants.IsPlayerTurnCharacteristic], for: service)
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
                playerTurnFinishedCallback?(player)
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
        self.characteristics.append(contentsOf: characteristics)

        for char in characteristics {
            if char.uuid == Constants.IsPlayerTurnCharacteristic {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }
}
