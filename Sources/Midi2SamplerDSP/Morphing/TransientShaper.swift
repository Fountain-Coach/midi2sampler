
// TransientShaper.swift
// Simple attack emphasis using envelope follower and difference boost.

import Foundation

public struct TransientShaper {
    public var amount: Float = 0.0        // 0..1
    public var attackMs: Float = 5.0
    public var releaseMs: Float = 50.0
    public var sampleRate: Float = 48000

    private var env: Float = 0

    public init() {}

    public mutating func processInPlace(_ x: inout [Float]) {
        let aA = expf(-1.0 / (sampleRate * max(0.001, attackMs/1000)))
        let aR = expf(-1.0 / (sampleRate * max(0.001, releaseMs/1000)))
        let k = amount
        for i in 0..<x.count {
            let rect = abs(x[i])
            let coeff = rect > env ? aA : aR
            env = coeff * env + (1 - coeff) * rect
            let boosted = x[i] + k * (rect - env) * (x[i] >= 0 ? 1 : -1)
            x[i] = boosted
        }
    }
}
