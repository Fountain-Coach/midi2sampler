
// ZoneCrossfader.swift
//
// For adjacent sample zones (key/velocity/articulation). Before blending, ensure:
// - Same target pitch (offline resampling/pitch-shift)
// - DC removed
// - Loudness matched (RMS/LUFS proxy)
// Then equal-power crossfade with a smooth mapping of t along pitch/velocity axes.
//
import Foundation

public struct ZoneCrossfader {
    public var matchLoudness: Bool = true
    public var dcMode: DCMode = .perWindow

    public init(matchLoudness: Bool = true) {
        self.matchLoudness = matchLoudness
    }

    /// Crossfades two time-aligned, pitch-matched frames (A→B) with equal-power ramp `t` ∈ [0,1].
    public func crossfadeFrame(A: [Float], B: [Float], t: Float) -> [Float] {
        precondition(A.count == B.count)
        var a = A, b = B
        if dcMode == .perWindow { removeDCInPlace(&a); removeDCInPlace(&b) }
        if matchLoudness {
            let ra = max(rms(a), 1e-6)
            let rb = max(rms(b), 1e-6)
            let k = ra / rb
            for i in 0..<b.count { b[i] *= k }
        }
        let (gA, gB) = Window.equalPowerScalar(t)
        var out = [Float](repeating: 0, count: a.count)
        for i in 0..<a.count { out[i] = gA*a[i] + gB*b[i] }
        return out
    }

    /// Smooth pitch mapping between zones with centers pA..pB (in semitones).
    public static func tForPitch(p: Float, pA: Float, pB: Float) -> Float {
        let t = (p - pA) / (pB - pA)
        return Window.smoothstep(t)
    }

    /// Smooth velocity mapping between vA..vB (0..1).
    public static func tForVelocity(v: Float, vA: Float, vB: Float) -> Float {
        let t = (v - vA) / (vB - vA)
        return Window.smoothstep(t)
    }
}
