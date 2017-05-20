//
//  ViewController.swift
//  RememberToBlink
//
//  Created by Andy Cho on 2017-05-19.
//  Copyright © 2017 AcroMace. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController, MuseBlinkDelegate {

    @IBOutlet weak var statusLabel: UILabel!

    // An alarm will sound if you haven't blinked for this amount of time (in seconds)
    let minimumBlinkInterval: Double = 10
    let alertColourForeground = UIColor.red
    let alertColourBackground = UIColor.white

    let museManager = MuseManager()
    var connectedToMuse = false
    var countdownTimer: Timer? // Timer that updates the background to see if you need to blink
    var lastBlink: Date? // Time of the last blink
    var lastAlertBackgroundWasRed = true // True if the background for the last tick was red (see countdownTime)

    override func viewDidLoad() {
        super.viewDidLoad()
        museManager.delegate = self

        updateConnectionState(connected: false)
    }

    func updateConnectionState(connected: Bool) {
        // Check that there weren't any previous timers
        countdownTimer?.invalidate()
        countdownTimer = nil

        if connected {
            print("Connected to Muse")
            statusLabel.text = ""
            view.backgroundColor = UIColor.black

            // Start the timer updates
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: countdownTime)
        } else {
            print("Disconnected from Muse")

            statusLabel.text = "Disconnected from Muse"
            statusLabel.textColor = UIColor.white
            view.backgroundColor = UIColor.red
        }
    }

    // This is called on the main thread
    func countdownTime(_: Timer) {
        guard let `lastBlink` = lastBlink else {
            // If the user hasn't blinked since connecting, start counting from the connection time
            self.lastBlink = Date()
            return
        }

        let timeSinceLastBlink = Date().timeIntervalSince(lastBlink)

        // Turn the background colour from black to red as the user runs
        // out of time to blink
        let rednessPercentage = Float(min(timeSinceLastBlink / minimumBlinkInterval, 1.0))
        view.backgroundColor = UIColor(colorLiteralRed: rednessPercentage, green: 0, blue: 0, alpha: 1)

        // Tell the user to blink if they already ran out of time
        if timeSinceLastBlink > minimumBlinkInterval {
            sendBlinkNotification()
        } else {
            statusLabel.text = ""
        }
    }

    func didConnectToMuse() {
        updateConnectionState(connected: true)
    }

    func didDisconnectFromMuse() {
        updateConnectionState(connected: false)
    }

    func museBlinkReceived() {
        print("Blink detected")
        lastBlink = Date()
    }

    func sendBlinkNotification() {
        // Flash the screen
        statusLabel.text = "BLINK"
        statusLabel.textColor = lastAlertBackgroundWasRed ? alertColourBackground : alertColourForeground
        view.backgroundColor = lastAlertBackgroundWasRed ? alertColourForeground : alertColourBackground
        lastAlertBackgroundWasRed = !lastAlertBackgroundWasRed

        // Vibrate the phone
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Play the power low sound
        AudioServicesPlayAlertSound(SystemSoundID(1006))

        print("Blink!")
    }

}
