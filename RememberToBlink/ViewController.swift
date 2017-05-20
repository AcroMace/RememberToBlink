//
//  ViewController.swift
//  RememberToBlink
//
//  Created by Andy Cho on 2017-05-19.
//  Copyright © 2017 AcroMace. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MuseBlinkDelegate {

    let museManager = MuseManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        museManager.delegate = self
    }

    func didConnectToMuse() {
        print("Connected to Muse")
    }

    func museBlinkReceived() {
        print("Blink detected")
    }

}
