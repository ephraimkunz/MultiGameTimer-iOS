//
//  Constants.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/17/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Constants {
    static let gameIds = ["1b4f7e10-536b-11e7-9598-0800200c9a66"]

    // Central notifies peripherals that game is starting
    static let StartPlayCharacteristic = CBUUID(string: "B4F9CD98-8484-47B8-AED8-014018816A19")
    // Name of player that shows up in Central's list. Is this needed if advertised by default?
    static let PlayerNameCharacteristic = CBUUID(string: "ECDFEC0A-817F-4FAB-AFD6-A618B4ADD70E")
}
