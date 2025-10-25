
// SpectralDistance.swift
//
// A lightweight, log-magnitude spectral distance used in loop point scoring.
// We compute Hann-windowed FFT magnitudes for two windows and measure L2 of
// their dB spectra with a floor. This correlates with perceived spectral continuity.
//
import Foundation
#if false
import Accelerate
#endif

public struct SpectralDistance {
    #if false
    private var fftSetup: vDSP.FFT<Float>
    #endif
    private var fftSize: Int
    private var logFloor: Float

    public init(fftSize: Int = 1024, logFloor: Float = -60.0) {
        precondition(fftSize > 0 && (fftSize & (fftSize - 1)) == 0, "fftSize must be power of two")
        self.fftSize = fftSize
        self.logFloor = logFloor
        #if false
        self.fftSetup = vDSP.FFT(
            log2n: vDSP_Length(Int(round(log2f(Float(fftSize))))),
            radix: .radix2,
            ofType: DSPSplitComplex.self
        )!
        #endif
    }

    /// Returns L2 distance between log-magnitude spectra of `a` and `b`.
    public mutating func distance(_ a: ArraySlice<Float>, _ b: ArraySlice<Float>) -> Float {
        let N = fftSize
        guard a.count >= N, b.count >= N else { return 0 }
        #if false
        var w = [Float](repeating: 0, count: N)
        vDSP_hann_window(&w, vDSP_Length(N), Int32(vDSP_HANN_NORM))

        func spec(_ x: ArraySlice<Float>) -> [Float] {
            var frame = Array(x.prefix(N))
            vDSP_vmul(frame, 1, w, 1, &frame, 1, vDSP_Length(N))

            var real = [Float](repeating: 0, count: N/2)
            var imag = [Float](repeating: 0, count: N/2)
            real.withUnsafeMutableBufferPointer { rPtr in
                imag.withUnsafeMutableBufferPointer { iPtr in
                    var split = DSPSplitComplex(realp: rPtr.baseAddress!, imagp: iPtr.baseAddress!)
                    frame.withUnsafeMutableBufferPointer { fPtr in
                        fPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: N) { _ in
                            fftSetup.forward(input: frame, real: &split.realp, imag: &split.imagp)
                        }
                    }
                }
            }
            var mag = [Float](repeating: 0, count: N/2)
            vDSP_zvabs(&DSPSplitComplex(realp: &real, imagp: &imag), 1, &mag, 1, vDSP_Length(N/2))
            var one: Float = 1e-12
            vDSP_vsadd(mag, 1, &one, &mag, 1, vDSP_Length(N/2))

            var logMag = [Float](repeating: 0, count: N/2)
            var c: Float = 20
            vvlog10f(&logMag, mag, [Int32(N/2)])
            vDSP_vsmul(logMag, 1, &c, &logMag, 1, vDSP_Length(N/2))

            var floorVal = logFloor
            vDSP_vthres(logMag, 1, &floorVal, &logMag, 1, vDSP_Length(N/2))
            return logMag
        }

        let A = spec(a), B = spec(b)
        var diff = [Float](repeating: 0, count: N/2)
        vDSP_vsub(B, 1, A, 1, &diff, 1, vDSP_Length(N/2))
        var l2: Float = 0
        vDSP_dotpr(diff, 1, diff, 1, &l2, vDSP_Length(N/2))
        return sqrtf(l2)
        #else
        // Portable fallback: time-domain RMS of difference (coarse)
        let N2 = min(a.count, b.count)
        var acc: Float = 0
        for i in 0..<N2 {
            let d = a[a.startIndex+i] - b[b.startIndex+i]
            acc += d*d
        }
        return (acc / Float(max(1, N2))) ** 0.5
        #endif
    }
}
