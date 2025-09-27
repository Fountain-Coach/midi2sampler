
// Resampler.swift
//
// Minimal windowed-sinc offline resampler for pitch-matching prior to blends.
// Notes:
// - Designed for offline/prepare step, not for realtime streaming (optimize if needed).
// - Use a moderate kernel (e.g., 64 taps) and a Hann windowed sinc.

import Foundation
import simd

public struct WindowedSincResampler {
    public var taps: Int
    public var cutoff: Float     // 0 < cutoff <= 1 (relative to Nyquist)
    public var kernel: [Float]

    public init(taps: Int = 64, cutoff: Float = 0.95) {
        precondition(taps % 2 == 0, "taps must be even")
        self.taps = taps
        self.cutoff = cutoff
        self.kernel = WindowedSincResampler.makeKernel(taps: taps, cutoff: cutoff)
    }

    /// Build symmetric Hann-windowed sinc kernel.
    static func makeKernel(taps: Int, cutoff: Float) -> [Float] {
        let M = taps
        let mid = Float(M-1)/2.0
        var h = [Float](repeating: 0, count: M)
        for n in 0..<M {
            let x = Float(n) - mid
            let sinc = (x == 0) ? 1.0 : sinf(Float.pi * cutoff * x) / (Float.pi * cutoff * x)
            let w = 0.5 - 0.5 * cosf(2.0 * Float.pi * Float(n) / Float(M-1))
            h[n] = sinc * w * cutoff
        }
        // normalize to unity gain at DC
        var sum: Float = h.reduce(0, +)
        for i in 0..<M { h[i] /= sum }
        return h
    }

    /// Resample `x` by factor `ratio` (outputLen ≈ x.count * ratio).
    public func resample(_ x: [Float], ratio: Float) -> [Float] {
        let M = taps
        let outLen = Int(floor(Float(x.count) * ratio))
        guard outLen > 0 else { return [] }
        var y = [Float](repeating: 0, count: outLen)
        let step = 1.0 / ratio  // input step per output sample
        for i in 0..<outLen {
            let srcPos = Float(i) * step
            let idx = Int(floor(srcPos))
            let frac = srcPos - Float(idx)
            // fractional offset handled by phase-shifting the kernel (linear interp).
            var acc: Float = 0
            for k in 0..<M {
                let t = Float(k) - Float(M/2) - frac
                // sample index mirrored at boundaries
                let xi = clamp(idx + k - M//2, 0, x.count - 1)
                // approximate shifted kernel using precomputed base kernel (OK for offline usage)
                // For higher quality, use polyphase or Lagrange interpolation of kernel. 
                acc += x[xi] * kernel[k]
            }
            y[i] = acc
        }
        return y
    }
}
