import Combine
import CoreBluetooth
import AsyncBluetooth
import BoostBLEKit

private let serviceUuid = CBUUID(string: GATT.serviceUuid)
private let characteristicUuid = CBUUID(string: GATT.characteristicUuid)

enum Port: UInt8 {
    case A
    case B
    case C
    case D
}

@MainActor
class ViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var peripheral: Peripheral?
    @Published var power: Int = 0
    
    private let centralManager = CentralManager()
    private var characteristic: Characteristic?
    
    func connect() {
        Task {
            do {
                self.isScanning = true
                try await centralManager.waitUntilReady()
                let scanDataStream = try await centralManager.scanForPeripherals(withServices: [serviceUuid], options: nil)
                for await scanData in scanDataStream {
                    print("Found", scanData.peripheral.name ?? "Unknown")
                    
                    do {
                        self.peripheral = scanData.peripheral
                        try await centralManager.connect(scanData.peripheral, options: nil)
                        print("Connected")
                        
                        self.characteristic = try await scanData.peripheral.discoverCharacteristic()
                        print("Ready!")
                        
                        break
                    } catch {
                        print(error)
                        self.peripheral = nil
                        try await centralManager.cancelPeripheralConnection(scanData.peripheral)
                    }
                }
            } catch {
                print(error)
            }
            
            await centralManager.stopScan()
            self.isScanning = false
        }
    }
    
    func cancel() {
        Task {
            if let peripheral = self.peripheral {
                self.peripheral = nil
                try await centralManager.cancelPeripheralConnection(peripheral)
            }
            await centralManager.stopScan()
            self.isScanning = false
        }
    }
    
    func disconnect() {
        Task {
            do {
                power = 0
                if let peripheral = peripheral {
                    self.peripheral = nil
                    try await centralManager.cancelPeripheralConnection(peripheral)
                }
            } catch {
                print(error)
            }
        }
    }
    
    func increment() {
        setPower(min(100, power + 10))
    }
    
    func decrement() {
        setPower(max(-100, power - 10))
    }
    
    func stop() {
        setPower(0)
    }
    
    func setPower(_ power: Int) {
        self.power = power
        let power = Int8(clamping: power)
        sendCommand(MotorStartPowerCommand(portId: Port.A.rawValue, power: power))
        sendCommand(MotorStartPowerCommand(portId: Port.B.rawValue, power: power))
    }
    
    func sendCommand(_ command: Command) {
        Task {
            do {
                if let characteristic = characteristic {
                    try await peripheral?.writeValue(command.data, for: characteristic, type: .withoutResponse)
                }
            } catch {
                print(error)
            }
        }
    }
}

enum PeripheralError: Error {
    case serviceNotFound
    case characteristicNotFound
}

private extension Peripheral {
    
    func discoverCharacteristic() async throws -> Characteristic {
        try await discoverServices([serviceUuid])
        guard let service = discoveredServices?.first else {
            throw PeripheralError.serviceNotFound
        }
        print("Discovered a service")
        
        try await discoverCharacteristics([characteristicUuid], for: service)
        guard let characteristic = service.discoveredCharacteristics?.first else {
            throw PeripheralError.characteristicNotFound
        }
        print("Discovered a characteristic")
        
        return characteristic
    }
}
