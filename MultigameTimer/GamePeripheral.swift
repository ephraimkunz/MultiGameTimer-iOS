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

class GamePeripheral: NSObject {
    private var peripheralManager: CBPeripheralManager!
    private var gameStarted = false
    private var gameUuid: String!
    var gameStartedCallback: ((Bool) -> Void)?
    var myTurnStartedCallback: ((Void) -> Void)?
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

    func joinGame() {
        let startPlay = CBMutableCharacteristic(type: Constants.StartPlayCharacteristic, properties: .write, value: nil, permissions: .writeable)
        // Save this characteristic so we can update values for it later
        IsPlayerTurnCharacteristic = CBMutableCharacteristic(type: Constants.IsPlayerTurnCharacteristic, properties: .notify, value: nil, permissions: .writeable)

        let name = UIDevice.current.name
        let playerName = CBMutableCharacteristic(type: Constants.PlayerNameCharacteristic, properties: .read, value: name.data(using: .ascii), permissions: .readable)

        let gameService = CBMutableService(type: CBUUID(string: gameUuid), primary: true)
        gameService.characteristics = [startPlay, playerName, IsPlayerTurnCharacteristic!]


        peripheralManager.add(gameService)
        peripheralManager.startAdvertising(
            [CBAdvertisementDataLocalNameKey: UIDevice.current.name,
            CBAdvertisementDataServiceUUIDsKey: [gameService.uuid]]
        )
    }
}

extension GamePeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print(peripheral.state.rawValue)
        if peripheral.state == .poweredOn {
            joinGame()
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

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == Constants.StartPlayCharacteristic {
                gameStartedCallback?(true)
            }
            if request.characteristic.uuid == Constants.IsPlayerTurnCharacteristic {
                myTurnStartedCallback?()
            }
        }
        peripheral.stopAdvertising()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if characteristic.uuid == Constants.IsPlayerTurnCharacteristic {
            print("Central subscribed to me!")
        }
    }
}

