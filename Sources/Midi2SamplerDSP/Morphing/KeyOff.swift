
// KeyOff.swift
// Scaffolding for key-off micro samples scaled by release velocity.

import Foundation

public struct KeyOff {
    public var sample: [Float] = []     // short sample (mono)
    public var gain: Float = 0.2        // base gain
    public init(sample: [Float] = [], gain: Float = 0.2) { self.sample = sample; self.gain = gain }

    /// Mix the key-off sample into `buffer` starting at index 0.
    public mutating func mix(into buffer: inout [Float], releaseVelocity: Float) {
        let g = gain * clamp(releaseVelocity, 0, 1)
        let L = min(sample.count, buffer.count)
        for i in 0..<L { buffer[i] += g * sample[i] }
    }
}
