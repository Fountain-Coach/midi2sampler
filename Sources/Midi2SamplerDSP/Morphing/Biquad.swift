
// Biquad.swift
// Minimal biquad with coefficient smoothing (to avoid zipper/clicks).

import Foundation

public struct Biquad {
    public enum Kind { case peak(freq: Float, q: Float)
                       case lowShelf(freq: Float, slope: Float) }

    public var b0: Float = 1, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0
    public var z1: Float = 0, z2: Float = 0

    // Target coeffs (for smoothing)
    private var tb0: Float = 1, tb1: Float = 0, tb2: Float = 0, ta1: Float = 0, ta2: Float = 0
    private var smooth: Float = 0.001   // coeff smoothing per sample

    public init() {}

    public mutating func setSmoothing(_ s: Float) { smooth = max(0, min(s, 1)) }

    public mutating func setEQ(kind: Kind, gainDb: Float, sampleRate: Float) {
        let A = powf(10, gainDb/40)
        let pi = Float.pi
        switch kind {
        case .peak(let freq, let q):
            let w0 = 2*pi*freq/sampleRate
            let alpha = sinf(w0)/(2*q)
            let cosw = cosf(w0)
            let b0 = 1 + alpha*A
            let b1 = -2*cosw
            let b2 = 1 - alpha*A
            let a0 = 1 + alpha/A
            let a1 = -2*cosw
            let a2 = 1 - alpha/A
            tb0 = b0/a0; tb1 = b1/a0; tb2 = b2/a0; ta1 = a1/a0; ta2 = a2/a0
        case .lowShelf(let freq, let slope):
            // slope ~ shelf steepness (use 0.5..1.0 typical)
            let w0 = 2*pi*freq/sampleRate
            let cosw = cosf(w0)
            let sinw = sinf(w0)
            let S = max(0.0001, slope)
            let A = A
            let alpha = sinw/2 * sqrtf( (A + 1/A)*(1/S - 1) + 2 )
            let b0 =    A*( (A+1) - (A-1)*cosw + 2*sqrtf(A)*alpha )
            let b1 =  2*A*( (A-1) - (A+1)*cosw )
            let b2 =    A*( (A+1) - (A-1)*cosw - 2*sqrtf(A)*alpha )
            let a0 =        (A+1) + (A-1)*cosw + 2*sqrtf(A)*alpha
            let a1 =   -2*( (A-1) + (A+1)*cosw )
            let a2 =        (A+1) + (A-1)*cosw - 2*sqrtf(A)*alpha
            tb0 = b0/a0; tb1 = b1/a0; tb2 = b2/a0; ta1 = a1/a0; ta2 = a2/a0
        }
    }

    public mutating func tick(_ x: Float) -> Float {
        // Smooth coefficients
        b0 += (tb0 - b0) * smooth
        b1 += (tb1 - b1) * smooth
        b2 += (tb2 - b2) * smooth
        a1 += (ta1 - a1) * smooth
        a2 += (ta2 - a2) * smooth

        // DF1 transposed
        let y = b0*x + z1
        z1 = b1*x - a1*y + z2
        z2 = b2*x - a2*y
        return y
    }

    public mutating func processInPlace(_ x: inout [Float]) {
        for i in 0..<x.count { x[i] = tick(x[i]) }
    }
}
