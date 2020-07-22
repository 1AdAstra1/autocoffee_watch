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
    var coffeeCharacteristic: CBCharacteristic?
    
    @IBOutlet weak var statusLabel: WKInterfaceLabel!
    @IBOutlet weak var makeCoffeeButton: WKInterfaceButton!
    
    // Core Bluetooth service IDs
    let serviceID = CBUUID(string: "0xFFE0")
    let bluetoothCharacteristicID = CBUUID(string: "0xFFE1")
    let bluetoothID = UUID(uuidString: "C606F2B7-1D37-1E99-7B6B-62981080E81B")
    
    // Custom status protocol, ASCII chars for Bluetooth transmission
    let READY = 0
    let NO_WATER = 1;
    let IN_PROGRESS = 2;
    let statusMessages = ["Ready", "No water", "In progress"]
    
    let commandMakeCoffee = "0";
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        makeCoffeeButton.setEnabled(false)
        statusLabel.setHorizontalAlignment(WKInterfaceObjectHorizontalAlignment.center)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
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
        
        coffeeMaker?.discoverServices([serviceID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Disconnected!")
        
        DispatchQueue.main.async { () -> Void in
            self.makeCoffeeButton.setEnabled(false)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid == serviceID {
                print("Service: \(service) found!")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            print(characteristic)
            
            if characteristic.uuid == bluetoothCharacteristicID {
                peripheral.setNotifyValue(true, for: characteristic)
                coffeeCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == bluetoothCharacteristicID {
            let statusString = String(data: characteristic.value!, encoding: String.Encoding.utf8)!
            let status = Int(statusString)!
            print("Coffee machine status: \(status)")
            DispatchQueue.main.async { () -> Void in
                self.statusLabel.setText(self.statusMessages[status])
                self.makeCoffeeButton.setEnabled(status != self.IN_PROGRESS)
            }
        }
    }
    
    @IBAction func makeACoffee() {
        let valueString = (commandMakeCoffee as NSString).data(using: String.Encoding.utf8.rawValue)
        coffeeMaker?.writeValue(valueString!, for: coffeeCharacteristic!,type: CBCharacteristicWriteType.withoutResponse)
    }
    
}
