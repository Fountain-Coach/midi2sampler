
// PositionEQ.swift
// Chain a few biquads to mimic mic perspective / position.

import Foundation

public struct PositionEQ {
    public var lowShelfGain: Float = 0      // dB at ~150 Hz
    public var presenceGain: Float = 0      // dB at ~3 kHz
    public var airGain: Float = 0           // dB at ~10 kHz

    private var ls = Biquad()
    private var pr = Biquad()
    private var air = Biquad()
    public var sampleRate: Float = 48000

    public init() {}

    public mutating func updateCoeffs() {
        ls.setEQ(kind: .lowShelf(freq: 150, slope: 0.8), gainDb: lowShelfGain, sampleRate: sampleRate)
        pr.setEQ(kind: .peak(freq: 3000, q: 1.0), gainDb: presenceGain, sampleRate: sampleRate)
        air.setEQ(kind: .peak(freq: 10000, q: 0.7), gainDb: airGain, sampleRate: sampleRate)
    }

    public mutating func processInPlace(_ x: inout [Float]) {
        ls.processInPlace(&x)
        pr.processInPlace(&x)
        air.processInPlace(&x)
    }
}
