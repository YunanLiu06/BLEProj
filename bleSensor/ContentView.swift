//
//  ContentView.swift
//  bleSensor
//
//  Created by Louis Lew on 12/22/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var ble = BLEManager()
    
    var pressureValues: [Double] {
        ble.receivedText
            .split(separator: ",")          // Split the string by commas
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) } // Convert each part to Double
    }
    // MARK: - Recording State
    @State private var isRecording = false
    @State private var startTime: Date?
    @State private var timer: Timer?
    @State private var samples: [PressureSample] = []
    @State private var lastCSVURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            
            if case .failed = ble.step {
                Button(action: {
                    ble.retry()
                }) {
                    Text("BLE failed — Tap to Retry")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                }
            } else if case .disconnected = ble.step {
                Button(action: {
                    ble.retry()
                }) {
                    Text("BLE disconnected, retrying")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                }
            } else {
                Text("BLE: \(ble.step.description)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(statusColor)
                    .foregroundColor(.white)
            }
            
            
            Spacer()
            
            HStack(spacing: 16) {
                ValueBar(
                    label: "Pressure",
                    unit: "psi",
                    currentValue: pressureValues.count > 1 ? pressureValues[1] : 0.0,
                    minValue: 0,
                    maxValue: 120
                )
                
                ValueBar(
                    label: "Temperature",
                    unit: "F",
                    currentValue: pressureValues.count > 0 ? pressureValues[0] : 0.0,
                    minValue: 0,
                    maxValue: 300
                )
            }
            
            Spacer()
            
            VStack {
                Button(action: isRecording ? stopRecording : startRecording) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                // Share button shows after CSV is created
                if let fileURL = lastCSVURL {
                    ShareLink(item: fileURL) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
    }
    
    private var statusColor: Color {
        switch ble.step {
        case .subscribed: return .green
        case .failed: return .red
        default: return .gray
        }
    }
    
    // MARK: - Recording Logic
    
    private func startRecording() {
        print("Recording started")
        samples.removeAll()
        startTime = Date()
        isRecording = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let startTime else { return }
            
            let now = Date()
            let elapsed = now.timeIntervalSince(startTime)
            let utcTimestamp = Int(now.timeIntervalSince1970)
            
            let sample = PressureSample(
                elapsedTime: elapsed,
                utcTimestamp: utcTimestamp,
                pressure: pressureValues.count > 1 ? pressureValues[1] : 0.0,
                temperature: pressureValues.count > 0 ? pressureValues[0] : 0.0
            )
            
            samples.append(sample)
        }
    }
    
    private func stopRecording() {
        print("Recording stopped")
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        do {
            lastCSVURL = try CSVExporter.savePressureSamples(samples)
            print("CSV saved:", lastCSVURL!)
        } catch {
            print("Failed to save CSV:", error)
        }
    }
}

#Preview { ContentView() }
