//
//  InterfaceController.swift
//  Coffee for Olga WatchKit Extension
//
//  Created by Olga Reznikova on 20.07.2020.
//  Copyright © 2020 Olga Reznikova. All rights reserved.
//

import WatchKit
import Foundation
import CoreBluetooth


class InterfaceController: WKInterfaceController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var coffeeMaker: CBPeripheral?
    @IBOutlet weak var statusLabel: WKInterfaceLabel!
    @IBOutlet weak var makeCoffeeButton: WKInterfaceButton!
    
    // Core Bluetooth service IDs
    let serviceID = CBUUID(string: "0xFFE0")
    let bluetoothCharacteristicID = CBUUID(string: "0xFFE1")
    let bluetoothID = UUID(uuidString: "C606F2B7-1D37-1E99-7B6B-62981080E81B")

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        makeCoffeeButton.setEnabled(false)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        
        case .unknown:
            print("Bluetooth status is UNKNOWN")
        case .resetting:
            print("Bluetooth status is RESETTING")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            
            centralManager?.scanForPeripherals(withServices: [serviceID], options: nil)
            //centralManager?.retrievePeripherals(withIdentifiers: [bluetoothID!])
        }
    }
    

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Discovered something: " + peripheral.identifier.uuidString)
        if(peripheral.identifier != bluetoothID) {
            return
        }
        
        coffeeMaker = peripheral
        coffeeMaker?.delegate = self
        centralManager?.stopScan()
        centralManager?.connect(coffeeMaker!)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        DispatchQueue.main.async { () -> Void in
            self.makeCoffeeButton.setEnabled(true)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Disconnected!")
        
        DispatchQueue.main.async { () -> Void in
            self.makeCoffeeButton.setEnabled(false)
        }
    }
    
    @IBAction func makeACoffee() {
        statusLabel.setText("Coffee in progress...")
    }
    

}
