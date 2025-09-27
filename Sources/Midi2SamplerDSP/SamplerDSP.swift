
// SamplerDSP.swift
//
// Core utilities used across the sampler DSP:
// - clamp, smoothing (SlewLimiter)
// - crossfade windows (equal-power, hann), scalar equal-power
// - DC removal and RMS
//
// Rationale
// ---------
// Clicks at seams arise from discontinuities in amplitude or slope.
// Equal-power crossfades keep perceived loudness stable, while DC removal
// and loudness matching prevent residual offsets that create steps.
//
import Foundation
#if canImport(Accelerate) && USE_ACCELERATE
import Accelerate
#endif

/// Clamp `x` to [a, b].
@inlinable public func clamp<T: Comparable>(_ x: T, _ a: T, _ b: T) -> T {
    return min(max(x, a), b)
}

/// Click-proof smoothing for parameters (gains, cutoff, per-note bends).
public struct SlewLimiter {
    private var y: Float
    public var maxDeltaPerSample: Float
    public init(initial: Float = 0, maxDeltaPerSample: Float = 1e-3) {
        self.y = initial
        self.maxDeltaPerSample = maxDeltaPerSample
    }
    /// Returns the smoothed value after applying a bounded step towards `target`.
    @inlinable public mutating func process(target: Float) -> Float {
        let d = target - y
        let step = clamp(d, -maxDeltaPerSample, maxDeltaPerSample)
        y += step
        return y
    }
}

public enum CrossfadeWindow {
    /// Equal-power (cos^2/sin^2) to avoid dips/peaks in perceived loudness.
    case equalPower
    /// Hann/Hann for amplitude-linear fades or analysis contexts.
    case hann
}

public enum Window {
    /// Returns (gA, gB) crossfade gains of length `L` for A→B.
    public static func crossfadeGains(length L: Int, kind: CrossfadeWindow = .equalPower) -> ([Float], [Float]) {
        precondition(L >= 2)
        var gA = [Float](repeating: 0, count: L)
        var gB = [Float](repeating: 0, count: L)
        switch kind {
        case .equalPower:
            for n in 0..<L {
                let t = Float.pi * Float(n) / (2.0 * Float(L - 1))
                let c = cosf(t), s = sinf(t)
                gA[n] = c * c
                gB[n] = s * s
            }
        case .hann:
            for n in 0..<L {
                let t = Float(n) / Float(L - 1)
                gB[n] = 0.5 - 0.5 * cosf(Float.pi * 2 * t)
                gA[n] = 1 - gB[n]
            }
        }
        return (gA, gB)
    }

    /// Scalar equal-power pair for realtime crossfades with `t` ∈ [0, 1].
    @inlinable public static func equalPowerScalar(_ t: Float) -> (Float, Float) {
        let tt = clamp(t, 0, 1)
        let a = cosf(0.5 * Float.pi * tt)
        let b = sinf(0.5 * Float.pi * tt)
        return (a * a, b * b)
    }

    /// Smoothstep curve t^2(3−2t) for smooth zone weight mapping.
    @inlinable public static func smoothstep(_ t: Float) -> Float {
        let tt = clamp(t, 0, 1)
        return tt * tt * (3 - 2 * tt)
    }
}

/// In-place DC removal (mean subtraction) to avoid offset steps at seams.
@inlinable public func removeDCInPlace(_ x: inout [Float]) {
    #if canImport(Accelerate) && USE_ACCELERATE
    var mean: Float = 0
    vDSP_meanv(x, 1, &mean, vDSP_Length(x.count))
    var neg = -mean
    vDSP_vsadd(x, 1, &neg, &x, 1, vDSP_Length(x.count))
    #else
    guard !x.isEmpty else { return }
    let m = x.reduce(0, +) / Float(x.count)
    for i in 0..<x.count { x[i] -= m }
    #endif
}

/// Short-window RMS used for loudness matching prior to blending.
public func rms(_ x: [Float]) -> Float {
    #if canImport(Accelerate) && USE_ACCELERATE
    var p: Float = 0
    vDSP_measqv(x, 1, &p, vDSP_Length(x.count))
    return sqrtf(p + 1e-12)
    #else
    guard !x.isEmpty else { return 0 }
    var acc: Float = 0
    for v in x { acc += v*v }
    return (acc / Float(x.count)) ** 0.5
    #endif
}
