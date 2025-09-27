
// SoftSaturator.swift
// Lightweight tanh-like soft clipping; drive 0..1

import Foundation

public struct SoftSaturator {
    public var drive: Float = 0.0  // 0..1
    public init() {}
    @inlinable public mutating func tick(_ x: Float) -> Float {
        let g = 1 + 9*drive          // map 0..1 → 1..10
        return tanhf(g * x) / tanhf(g)  // normalized
    }
    public mutating func processInPlace(_ x: inout [Float]) {
        for i in 0..<x.count { x[i] = tick(x[i]) }
    }
}
