//
//  GamePeripheral.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

protocol GamePlayPeripheralDelegate {
    func turnDidStart() // This peripheral was notified that they became the active player

    func pauseWasToggled(isPaused: Bool) // This periph is notified that the pause state changed
}

protocol GameSetupPeripheralDelegate {
    func gameDidStart() // This periph was notified that the game began
}

class GamePeripheral: NSObject {
    private var peripheralManager: CBPeripheralManager!
    private var gameStarted = false
    private var gameUuid: String!
    internal var gamePlayDelegate: GamePlayPeripheralDelegate?
    internal var gameSetupDelegate: GameSetupPeripheralDelegate?

    var IsPausedCharacteristic: CBMutableCharacteristic?
    var IsPlayerTurnCharacteristic: CBMutableCharacteristic?

    init(uuid: String) {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        gameUuid = uuid
    }

    func myTurnEnded() {
        // At this point, the central should have already subscribed to the IsPlayerTurn characteristic. We now notify it that we are done.
        guard let isPlayerTurnChar = IsPlayerTurnCharacteristic else {
            return
        }

        peripheralManager.updateValue("false".data(using: .ascii)!, for: isPlayerTurnChar, onSubscribedCentrals: nil)
    }

    // Let central know that this device is trying to pause/resume the game
    func pauseStateChanged(paused: Bool) {
        guard let isPausedChar = IsPausedCharacteristic else {
            return
        }

        let stringValue = paused ? "true" : "false"
        peripheralManager.updateValue(stringValue.data(using: .ascii)!, for: isPausedChar, onSubscribedCentrals: nil)
    }

    func joinGame() {
        let startPlay = CBMutableCharacteristic(type: Constants.StartPlayCharacteristic, properties: .write, value: nil, permissions: .writeable)

        // Save these characteristics so we can update values for them later
        IsPlayerTurnCharacteristic = CBMutableCharacteristic(type: Constants.IsPlayerTurnCharacteristic, properties: [.write, .notify], value: nil, permissions: [.readable, .writeable])
        IsPausedCharacteristic = CBMutableCharacteristic(type: Constants.IsPausedCharacteristic, properties: [.write, .notify], value: nil, permissions: [.readable, .writeable])

        let name = UIDevice.current.name
        let playerName = CBMutableCharacteristic(type: Constants.PlayerNameCharacteristic, properties: .read, value: name.data(using: .ascii), permissions: .readable)

        let gameService = CBMutableService(type: CBUUID(string: gameUuid), primary: true)
        gameService.characteristics = [startPlay, playerName, IsPlayerTurnCharacteristic!, IsPausedCharacteristic!]


        peripheralManager.add(gameService)
        peripheralManager.startAdvertising(
            [CBAdvertisementDataLocalNameKey: UIDevice.current.name,
            CBAdvertisementDataServiceUUIDsKey: [gameService.uuid]]
        )
    }
}

extension GamePeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            joinGame()
        default:
            print("Peripheral is in state \(peripheral.state)")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print(error)
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print(error)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == Constants.StartPlayCharacteristic {
                gameSetupDelegate?.gameDidStart()
            }
            if request.characteristic.uuid == Constants.IsPlayerTurnCharacteristic {
                gamePlayDelegate?.turnDidStart()
            }
            if request.characteristic.uuid == Constants.IsPausedCharacteristic {
                if let value = request.value {
                    let paused = String(data: value, encoding: .ascii) == "true" ? true : false
                    gamePlayDelegate?.pauseWasToggled(isPaused: paused)
                }
            }
        }

        // The only time a write happens is if a central is connected. In this case, we are good to go.
        peripheral.stopAdvertising()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if characteristic.uuid == Constants.IsPlayerTurnCharacteristic {
            print("Central subscribed to me!")
        }
    }
}

