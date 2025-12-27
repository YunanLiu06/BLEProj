//
//  BleSteps.swift
//  bleSensor
//
//  Created by Louis Lew on 12/26/25.
//

enum BLEStep: Equatable {
    case idle
    case scanning
    case connecting
    case discoveringServices
    case discoveringCharacteristics
    case subscribed
    case failed(String)
    case disconnected(String)
    
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .discoveringServices: return "Discovering services"
        case .discoveringCharacteristics: return "Discovering characteristics"
        case .subscribed: return "Subscribed"
        case .failed(let msg): return msg
        case .disconnected(let msg): return msg
        }
    }
}
