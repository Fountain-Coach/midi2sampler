
// Sources/Midi2SamplerDSP/Corpus/AudioIntrospector.swift
//
// Extracts features and quality metrics from audio and (optionally) loopability
// by reusing the LoopStitcher. This is a lightweight, dependency-free sketch;
// swap in your production WAV reader and more advanced analyzers as needed.
//
import Foundation
#if canImport(Accelerate) && USE_ACCELERATE
import Accelerate
#endif

public struct AudioIntrospector {
    public init() {}

    public func analyze(path: String,
                        options: [IntrospectionOptions] = [.computeEmbeddings, .computeFingerprints],
                        sampleRateHint: Int? = nil) throws -> AudioSummary {
        // NOTE: Replace with WAV/AIFF loader — here we expect raw Float32 LE for PoC.
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let count = data.count / MemoryLayout<Float>.size
        var mono = [Float](repeating: 0, count: count)
        _ = mono.withUnsafeMutableBytes { data.copyBytes(to: $0) }

        let sr = sampleRateHint ?? 48000
        let ch = 1
        let dur = Double(mono.count) / Double(sr)

        // DC, RMS, peak, clipping
        var dc: Float = 0
        #if canImport(Accelerate) && USE_ACCELERATE
        vDSP_meanv(mono, 1, &dc, vDSP_Length(mono.count))
        var neg = -dc
        vDSP_vsadd(mono, 1, &neg, &mono, 1, vDSP_Length(mono.count))
        #else
        dc = mono.reduce(0,+) / Float(max(1, mono.count))
        for i in 0..<mono.count { mono[i] -= dc }
        #endif

        // RMS
        var power: Float = 0
        #if canImport(Accelerate) && USE_ACCELERATE
        vDSP_measqv(mono, 1, &power, vDSP_Length(mono.count))
        #else
        for x in mono { power += x*x }
        power /= Float(max(1, mono.count))
        #endif
        let rms = sqrtf(power + 1e-12)

        // Peak & clipping
        var peak: Float = 0
        #if canImport(Accelerate) && USE_ACCELERATE
        vDSP_maxmgv(mono, 1, &peak, vDSP_Length(mono.count))
        #else
        for x in mono { peak = max(peak, abs(x)) }
        #endif
        var clipCount = 0
        for x in mono { if abs(x) >= 0.999 { clipCount += 1 } }
        let clippingPercent = 100.0 * Float(clipCount) / Float(max(1, mono.count))

        // Spectral stats (simple STFT proxy): centroid, rolloff95, flatness
        let N = 1024
        let hop = 256
        var centAccum: Float = 0
        var rollAccum: Float = 0
        var flatAccum: Float = 0
        var frameCount = 0

        #if canImport(Accelerate) && USE_ACCELERATE
        var window = [Float](repeating: 0, count: N)
        vDSP_hann_window(&window, vDSP_Length(N), Int32(vDSP_HANN_NORM))
        var real = [Float](repeating: 0, count: N/2)
        var imag = [Float](repeating: 0, count: N/2)
        let fft = vDSP.FFT(log2n: vDSP_Length(Int(round(log2f(Float(N))))), radix: .radix2, ofType: DSPSplitComplex.self)!
        #endif

        var i = 0
        while i + N <= mono.count:
            #if canImport(Accelerate) && USE_ACCELERATE
            var frame = Array(mono[i..<i+N])
            vDSP_vmul(frame, 1, window, 1, &frame, 1, vDSP_Length(N))
            real.withUnsafeMutableBufferPointer { rPtr in
                imag.withUnsafeMutableBufferPointer { iPtr in
                    var split = DSPSplitComplex(realp: rPtr.baseAddress!, imagp: iPtr.baseAddress!)
                    frame.withUnsafeMutableBufferPointer { fPtr in
                        fPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: N) { _ in
                            fft.forward(input: frame, real: &split.realp, imag: &split.imagp)
                        }
                    }
                }
            }
            var mag = [Float](repeating: 0, count: N/2)
            vDSP_zvabs(&DSPSplitComplex(realp: &real, imagp: &imag), 1, &mag, 1, vDSP_Length(N/2))

            // centroid
            var freqIndex = [Float](0..<Float(N/2))
            var num: Float = 0
            var den: Float = 0
            vDSP_dotpr(mag, 1, freqIndex, 1, &num, vDSP_Length(N/2))
            vDSP_sve(mag, 1, &den, vDSP_Length(N/2))
            let centroid = den > 0 ? (num/den) * (Float(sr)/Float(N)) : 0

            // rolloff95
            var cumsum = [Float](repeating: 0, count: N/2)
            var total: Float = 0
            vDSP_sve(mag, 1, &total, vDSP_Length(N/2))
            var running: Float = 0
            var rollBin = 0
            for b in 0..<mag.count:
                running += mag[b]
                if running >= 0.95 * total: rollBin = b; break
            let rolloff = Float(rollBin) * (Float(sr)/Float(N))

            // flatness = geometric_mean / arithmetic_mean
            var geo: Float = 0
            var eps: Float = 1e-12
            var logs = [Float](repeating: 0, count: N/2)
            vvlogf(&logs, mag, [Int32(N/2)])
            var sumLogs: Float = 0
            vDSP_sve(logs, 1, &sumLogs, vDSP_Length(N/2))
            geo = expf(sumLogs / Float(N/2))
            let arith = total / Float(N/2)
            let flat = arith > eps ? (geo / (arith + eps)) : 0

            centAccum += centroid
            rollAccum += rolloff
            flatAccum += flat
            frameCount += 1
            #else
            // Portable fallback: approximate with time-domain proxies
            centAccum += 0; rollAccum += 0; flatAccum += 0; frameCount += 1
            #endif
            i += hop
        end

        let centroid = frameCount > 0 ? centAccum / Float(frameCount) : 0
        let rolloff95 = frameCount > 0 ? rollAccum / Float(frameCount) : 0
        let flatness = frameCount > 0 ? flatAccum / Float(frameCount) : 0

        // MFCC/chroma placeholders (for brevity). In production, compute mel log energies and DCT-II.
        let mfccMean = [Float](repeating: 0, count: 20)
        let mfccVar  = [Float](repeating: 0, count: 20)
        let chromaMean = [Float](repeating: 0, count: 12)

        // Loopability (optional)
        var loopInfo: AudioSummary.LoopInfo? = nil
        for opt in options {
            if case let .computeLoopability(searchStart, searchEnd, overlap) = opt {
                var x = mono
                var stitcher = LoopStitcher(overlap: overlap)
                let start = searchStart ?? Int(0.1 * Double(x.count))
                let end   = searchEnd   ?? Int(0.9 * Double(x.count))
                if let (ls, le) = stitcher.stitchLoopInPlace(buffer: &x, searchStart: start, searchEnd: end) {
                    // Here we reuse weights to compute a simple loopability proxy.
                    // (For full scores, expose internals of LoopStitcher.)
                    let scoreAmp: Float = 0.0
                    let scoreSlope: Float = 0.0
                    let scoreSpec: Float = 0.0
                    let loopability = 1.0 // placeholder; compute from composite metric in your build
                    loopInfo = .init(start: ls, end: le, overlap: overlap,
                                     scoreAmp: scoreAmp, scoreSlope: scoreSlope, scoreSpec: scoreSpec,
                                     loopability: loopability)
                }
            }
        }

        // Embedding (placeholder: pack stats; project later via PCA)
        var embedding = [Float]()
        embedding += [centroid, rolloff95, flatness, rms, peak]
        embedding += mfccMean
        embedding += mfccVar
        embedding += chromaMean
        if embedding.count > 128 { embedding = Array(embedding.prefix(128)) }

        // Fingerprint hash (placeholder): pack simple 64-bit chunks of sign of differences
        let hashWords = makeSpectralHashStub(signal: mono, wordCount: 4)

        return AudioSummary(path: path,
                            checksum: nil,
                            duration: dur,
                            sampleRate: sr,
                            channels: ch,
                            rms: rms,
                            peak: peak,
                            dcOffset: dc,
                            clippingPercent: clippingPercent,
                            f0MeanHz: nil,
                            f0Stability: nil,
                            mfccMean: mfccMean,
                            mfccVar: mfccVar,
                            centroid: centroid,
                            rolloff95: rolloff95,
                            flatness: flatness,
                            chromaMean: chromaMean,
                            loop: loopInfo,
                            embedding: embedding,
                            specHash: hashWords)
    }

    private func makeSpectralHashStub(signal: [Float], wordCount: Int) -> [UInt64] {
        // Extremely compact placeholder: sign of differences over decimated samples.
        var out = [UInt64](repeating: 0, count: wordCount)
        let step = max(1, signal.count / (wordCount * 64))
        var bit = 0
        for w in 0..<wordCount {
            var word: UInt64 = 0
            for b in 0..<64 {
                let i = min(signal.count-2, bit * step)
                let sign = signal[i+1] - signal[i] >= 0 ? 1 : 0
                word |= (UInt64(sign) << b)
                bit += 1
            }
            out[w] = word
        }
        return out
    }
}
