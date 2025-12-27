//
//  BLEManager.swift
//  bleSensor
//
//  Created by Louis Lew on 12/23/25.
//

import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {
    
    // MARK: - Published (SwiftUI)
    @Published var step: BLEStep = .idle
    @Published var receivedText: String = ""
    
    private var timeoutTimer: Timer?
    private let stepTimeout: TimeInterval = 5
    
    
    // MARK: - BLE
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    
    private var notifyCharacteristic: CBCharacteristic?
    
    // MARK: - UUIDs
    private let serviceUUID = CBUUID(string: "9ECADC24-0EE5-A9E0-93F3-A3B50100406E")
    private let notifyUUID  = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    private let uartUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    private var retryCount = 0
    private let maxRetries = 5
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func autoRetry(after delay: TimeInterval = 2) {
        print("retry count: ",retryCount)
        guard retryCount < maxRetries else {
            print("Max retries reached")
            return
        }
        retryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.startScanning()
        }
    }
    
    private func startScanning() {
        guard central.state == .poweredOn else { return }
        step = .scanning
        startTimeout(for: .scanning)
        central.scanForPeripherals(withServices: nil)
    }
    
    func retry() {
        timeoutTimer?.invalidate()
        if let peripheral = peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        notifyCharacteristic = nil
        receivedText = "---"
        step = .idle
        
        // Restart scanning
        centralManagerDidUpdateState(central)
    }
    
    private func startTimeout(for step: BLEStep) {
        timeoutTimer?.invalidate()
        
        guard step != .idle, step != .subscribed else { return }
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: stepTimeout, repeats: false) { [weak self] _ in
            self?.failStep("Timeout during \(step.description)")
        }
    }
    
    private func completeStep(_ next: BLEStep) {
        timeoutTimer?.invalidate()
        step = next
    }
    
    private func failStep(_ message: String) {
        timeoutTimer?.invalidate()
        step = .failed(message)
        // disconnect and cleanup BLE
        if let peripheral = peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            step = .failed("Bluetooth unavailable")
            return
        }
        
        step = .scanning
        startTimeout(for: .scanning)
        central.scanForPeripherals(withServices: nil)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        if peripheral.name == "MPY ESP32" {
            self.peripheral = peripheral
            central.stopScan()
            step = .connecting
            startTimeout(for: .connecting)
            central.connect(peripheral)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        peripheral.delegate = self
        step = .discoveringServices
        startTimeout(for: .discoveringServices)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        failStep("Failed to connect")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("Peripheral disconnected:", peripheral.name ?? "unknown", error?.localizedDescription ?? "")
        
        // Update step to failed or idle
        if let error = error {
            step = .disconnected("Disconnected: \(error.localizedDescription)")
        } else {
            step = .disconnected("Disconnected, retrying")
        }
        
        autoRetry(after: 1)
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else {
            print("No services found")
            return
        }
        
        for service in services {
            step = .discoveringCharacteristics
            startTimeout(for: .discoveringCharacteristics)
            if service.uuid == uartUUID {
                peripheral.discoverCharacteristics([notifyUUID], for: service)
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        
        for char in characteristics where char.uuid == notifyUUID {
            notifyCharacteristic = char
            peripheral.setNotifyValue(true, for: char)
            completeStep(.subscribed)
            retryCount = 0
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == notifyUUID,
              let data = characteristic.value else { return }
        
        receivedText = String(decoding: data, as: UTF8.self)
    }
}
