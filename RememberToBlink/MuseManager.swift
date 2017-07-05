//
//  MuseManager.swift
//  RememberToBlink
//
//  Created by Andy Cho on 2017-05-19.
//  Copyright © 2017 AcroMace. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol MuseBlinkDelegate: class {
    func didConnectToMuse()
    func didDisconnectFromMuse()
    func museBlinkReceived()
}

class MuseManager: NSObject {

    var muse: IXNMuse?
    let museManager: IXNMuseManagerIos
    var bluetoothManager: CBCentralManager?
    var bluetoothEnabled = false
    var lastBlink = false
    weak var delegate: MuseBlinkDelegate?

    override init() {
        museManager = IXNMuseManagerIos.sharedManager()
        super.init()

        museManager.museListener = self
        IXNLogManager.instance()?.setLogListener(self)

        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        museManager.startListening()
    }

    func connectToMuse() {
        guard let muse = museManager.getMuses().first else {
            print("No Muses detected")
            return
        }

        self.muse = muse
        muse.register(self)
        muse.register(self, type: .artifacts) // Blinking
        muse.runAsynchronously()

        muse.connect()
    }

}

// MARK: CBCentralManagerDelegate

extension MuseManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothEnabled = bluetoothManager?.state == CBManagerState.poweredOn
    }

    func isBluetoothEnabled() -> Bool {
        return bluetoothEnabled
    }

}

// MARK: IXNMuseConnectionListener

extension MuseManager: IXNMuseConnectionListener {

    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {
        switch packet.currentConnectionState {
        case .connected:
            delegate?.didConnectToMuse()
            break
        case .connecting:
            print("Connecting to Muse")
            break
        case .disconnected:
            print("Disconnected from Muse")
            break
        case .needsUpdate:
            print("Muse needs to update")
            break
        case .unknown:
            print("Muse state unknown")
            break
        }
    }

}

// MARK: IXNMuseListener

extension MuseManager: IXNMuseListener {

    func museListChanged() {
        // We don't actually care since we just connect to the first Muse
        print("List of muses changed: \(museManager.getMuses())")
        connectToMuse()
    }

}

// MARK: IXNMuseDataListener

extension MuseManager: IXNMuseDataListener {

    func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
        // This is for receiving EEG data - not applicable here
    }

    func receive(_ packet: IXNMuseArtifactPacket, muse: IXNMuse?) {
        if packet.blink && packet.blink != self.lastBlink {
            delegate?.museBlinkReceived()
        }
        self.lastBlink = packet.blink
    }

}

// MARK: IXNLogListener

extension MuseManager: IXNLogListener {

    func receiveLog(_ log: IXNLogPacket) {
        print("\(log.tag): \(log.timestamp) \(log.raw) \(log.message)")
    }

}
