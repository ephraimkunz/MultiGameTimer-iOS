//
//  ButtonExtensions.swift
//  MultigameTimer
//
//  Created by Ephraim Kunz on 6/24/17.
//  Copyright © 2017 Ephraim Kunz. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {

    func setBackgroundColor(color: UIColor, forState: UIControlState) {

        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, for: forState)
    }
}
