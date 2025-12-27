//
//  PressureBar.swift
//  bleSensor
//
//  Created by Louis Lew on 12/24/25.
//

import SwiftUI

struct ValueBar: View {

    let label: String
    let unit: String

    let currentValue: Double
    let minValue: Double
    let maxValue: Double

    // MARK: - Threshold (per bar)
    @AppStorage private var threshold: Double

    @State private var showThresholdPrompt = false
    @State private var thresholdInput = ""

    var height: CGFloat = 250
    var width: CGFloat = 60

    init(
        label: String,
        unit: String,
        currentValue: Double,
        minValue: Double,
        maxValue: Double
    ) {
        self.label = label
        self.unit = unit
        self.currentValue = currentValue
        self.minValue = minValue
        self.maxValue = maxValue

        // individual key per bar
        _threshold = AppStorage(wrappedValue: 50, "threshold_\(label)")
    }

    // MARK: - Computed values
    private var clampedValue: Double {
        min(max(currentValue, minValue), maxValue)
    }

    private var fillRatio: CGFloat {
        CGFloat((clampedValue - minValue) / (maxValue - minValue))
    }

    private var barColor: Color {
        currentValue > threshold ? .red : .blue
    }

    var body: some View {
        VStack(spacing: 12) {

            Text(String(format: "%.1f %@", clampedValue, unit))
                .font(.system(size: 28, weight: .bold))
                .monospacedDigit()

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 12)
                    .fill(barColor)
                    .frame(height: height * fillRatio)
            }
            .frame(width: width, height: height)
            .animation(.easeOut(duration: 0.2), value: fillRatio)
            .animation(.easeInOut(duration: 0.2), value: barColor)

            Text("\(label) (\(unit))")
                .font(.headline)
                .foregroundColor(.secondary)

            Button {
                thresholdInput = String(Int(threshold))
                showThresholdPrompt = true
            } label: {
                Text("Set Warning")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .alert("Set Threshold", isPresented: $showThresholdPrompt) {

            TextField("Enter integer", text: $thresholdInput)
                .keyboardType(.numberPad)
                .onChange(of: thresholdInput) { _, newValue in
                    thresholdInput = newValue.filter(\.isNumber)
                }

            Button("OK") {
                if let value = Double(thresholdInput) {
                    threshold = value
                }
            }

            Button("Cancel", role: .cancel) { }
        }
    }
}
