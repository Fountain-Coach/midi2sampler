
// LoopStitcher.swift
//
// Algorithm:
// 1) Search candidate loop points in a steady-state region.
// 2) Score with composite metric: amplitude L2, slope mismatch, spectral distance.
// 3) Fine phase-align the chosen windows with micro circular shifts.
// 4) Write an equal-power crossfaded seam of overlap `L` at loop entry.
//
import Foundation

public enum DCMode { case none, perWindow }

public struct LoopStitcher {
    public var overlap: Int                  // L samples; choose 2–3 periods of lowest partial
    public var weights: (amp: Float, slope: Float, spec: Float)
    public var dcMode: DCMode
    public var specDist: SpectralDistance

    public init(overlap: Int,
                weights: (Float, Float, Float) = (1.0, 0.5, 0.3),
                dcMode: DCMode = .perWindow,
                specFFT: Int = 1024) {
        self.overlap = overlap
        self.weights = weights
        self.dcMode = dcMode
        self.specDist = SpectralDistance(fftSize: specFFT)
    }

    /// Search in [searchStart, searchEnd). Writes seam in-place and returns chosen (loopStart, loopEnd).
    public mutating func stitchLoopInPlace(buffer x: inout [Float],
                                           searchStart: Int,
                                           searchEnd: Int,
                                           window: CrossfadeWindow = .equalPower) -> (start: Int, end: Int)? {
        let L = overlap
        guard searchEnd - searchStart >= 4*L else { return nil }

        var best: (score: Float, s: Int, e: Int)?
        let low = max(0, searchStart)
        let high = min(x.count, searchEnd)

        // 1) Candidate scan (coarse step on e for speed)
        for s in stride(from: low, to: high - 3*L, by: 1) {
            for e in stride(from: s + 2*L, to: high - L, by: max(1, L/8)) {
                let a = x[s..<(s+L)]
                let b = x[(e-L)..<e]
                var aa = Array(a), bb = Array(b)
                if dcMode == .perWindow { removeDCInPlace(&aa); removeDCInPlace(&bb) }

                // Amplitude error (L2)
                var ampErr: Float = 0
                for i in 0..<L { let d = aa[i] - bb[i]; ampErr += d*d }
                ampErr = (ampErr ** 0.5) / Float(L)

                // Slope error (L1 of first-difference mismatch)
                var slopeErr: Float = 0
                for i in 1..<L {
                    let da = aa[i] - aa[i-1]
                    let db = bb[i] - bb[i-1]
                    slopeErr += abs(da - db)
                }
                slopeErr /= Float(L-1)

                // Spectral distance (FFT)
                let spec = specDist.distance(a, b)

                let J = weights.amp * ampErr + weights.slope * slopeErr + weights.spec * spec
                if best == nil || J < best!.score { best = (J, s, e) }
            }
        }
        guard let chosen = best else { return nil }
        let s = chosen.s, e = chosen.e

        // 2) Fine phase alignment
        var A = Array(x[s..<(s+L)])
        var B = Array(x[(e-L)..<e])
        if dcMode == .perWindow { removeDCInPlace(&A); removeDCInPlace(&B) }
        B = bestCircularAlign(a: A, b: B, maxShift: 8)

        // 3) Equal-power crossfade seam
        let (gA, gB) = Window.crossfadeGains(length: L, kind: window)
        var Y = [Float](repeating: 0, count: L)
        for i in 0..<L { Y[i] = gA[i]*A[i] + gB[i]*B[i] }

        // Write seam back
        x.replaceSubrange(s..<(s+L), with: Y)
        return (s, e)
    }
}
