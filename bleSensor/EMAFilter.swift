//
//  EMAFilter.swift
//  bleSensor
//
//  Created by Louis Lew on 12/29/25.
//

final class EMAFilter {
    private let alpha: Double
    private var lastValue: Double?

    init(alpha: Double) {
        precondition(alpha > 0 && alpha <= 1)
        self.alpha = alpha
    }

    func filter(_ newValue: Double) -> Double {
        guard let last = lastValue else {
            lastValue = newValue
            return newValue
        }

        let filtered = alpha * newValue + (1 - alpha) * last
        lastValue = filtered
        return filtered
    }

    func reset() {
        lastValue = nil
    }
}
