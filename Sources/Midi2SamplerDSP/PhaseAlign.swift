
// PhaseAlign.swift
//
// Micro phase alignment by small circular shifts, minimizing L1 amplitude error.
// This cheaply reduces residual phase mismatch at loop seams or zone transitions.
//
import Foundation

/// Aligns `b` to `a` by testing circular shifts ±maxShift samples. Returns shifted copy of `b`.
public func bestCircularAlign(a: [Float], b: [Float], maxShift: Int = 8) -> [Float] {
    let L = min(a.count, b.count)
    guard L > 0 else { return b }
    var bestShift = 0
    var bestScore = Float.infinity

    func score(_ shift: Int) -> Float {
        var err: Float = 0
        for i in 0..<L {
            let j = (i + shift) % L
            let idx = j < 0 ? j + L : j
            let d = a[i] - b[idx]
            err += abs(d)
        }
        return err / Float(L)
    }

    for k in -maxShift...maxShift {
        let s = score(k)
        if s < bestScore { bestScore = s; bestShift = k }
    }

    if bestShift == 0 { return Array(b.prefix(L)) }
    var out = [Float](repeating: 0, count: L)
    for i in 0..<L {
        var j = i + bestShift
        if j < 0 { j += L }
        if j >= L { j -= L }
        out[i] = b[j]
    }
    return out
}
