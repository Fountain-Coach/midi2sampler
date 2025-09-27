
// PedalResonance.swift
// Very short convolution IR bank scaffold for damper up resonance.
// (For production, use partitioned convolution or Metal compute.)

import Foundation

public struct PedalResonance {
    public var ir: [Float] = []  // mono IR, short (e.g., 2048 samples)
    private var tail: [Float] = []
    private var idx: Int = 0

    public init(ir: [Float] = []) {
        self.ir = ir
        self.tail = [Float](repeating: 0, count: max(1, ir.count-1))
    }

    public mutating func processInPlace(_ x: inout [Float]) {
        guard !ir.isEmpty else { return }
        var y = [Float](repeating: 0, count: x.count + ir.count - 1)

        // naive FIR (optimize later)
        for n in 0..<x.count {
            let xn = x[n]
            for k in 0..<ir.count { y[n+k] += xn * ir[k] }
        }

        // overlap-add tail
        for i in 0..<tail.count { y[i] += tail[i] }
        // write back in-place the input length portion
        for i in 0..<x.count { x[i] = y[i] }
        // save new tail
        tail = Array(y[x.count:])
    }
}
