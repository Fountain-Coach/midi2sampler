
// RealTimeNoteProcessor.swift
// Applies velocity-timbre morphing and nice-to-haves per note in-place.
// Assumes the input buffer is the current audio block for the active note voice.

import Foundation

public final class RealTimeNoteProcessor {
    public var sampleRate: Float = 48000
    public var model = VelocityTimbreModel(tilt: (-1.5, 2.5),
                                           presence: (0, 4),
                                           transient: (0.05, 0.5),
                                           noise: (0.0, 0.3),
                                           sat: (0.0, 0.4))

    private var ls = Biquad()
    private var pr = Biquad()
    private var shaper = TransientShaper()
    private var sat = SoftSaturator()
    private var posEQ = PositionEQ()
    private var pedal = PedalResonance()
    private var keyOff = KeyOff()

    private var slewTilt = SlewLimiter(initial: 0, maxDeltaPerSample: 1e-4)
    private var slewPresence = SlewLimiter(initial: 0, maxDeltaPerSample: 1e-4)
    private var slewTrans = SlewLimiter(initial: 0, maxDeltaPerSample: 1e-4)
    private var slewSat = SlewLimiter(initial: 0, maxDeltaPerSample: 1e-4)

    public init() {
        ls.setSmoothing(0.001); pr.setSmoothing(0.001)
        shaper.sampleRate = sampleRate
        posEQ.sampleRate = sampleRate
        posEQ.updateCoeffs()
    }

    /// Update per-note processing based on MIDI 2 velocity and timbre/pressure.
    public func setControls(velocity2: UInt16, timbre: Float?, pressure: Float?) {
        let p = model.params(v2: velocity2)
        let tilt = slewTilt.process(target: p.tilt)
        let pres = slewPresence.process(target: p.presence)
        let trans = slewTrans.process(target: p.trans)
        let drive = slewSat.process(target: p.sat)

        // Map per-note timbre/pressure (if present)
        let tAdj = timbre.map { ($0 * 2 - 1) * 2 } ?? 0     // -2..+2 dB
        let pAdj = pressure.map { ($0) * 0.2 } ?? 0         // +drive up to +0.2

        ls.setEQ(kind: .lowShelf(freq: 150, slope: 0.8), gainDb: tilt, sampleRate: sampleRate)
        pr.setEQ(kind: .peak(freq: 3000, q: 1.0), gainDb: pres + tAdj, sampleRate: sampleRate)
        shaper.amount = max(0, min(1, trans + (pressure ?? 0) * 0.2))
        sat.drive = max(0, min(1, drive + pAdj))
    }

    /// Process audio block in-place; call after setControls()
    public func processBlock(_ x: inout [Float]) {
        ls.processInPlace(&x)
        pr.processInPlace(&x)
        shaper.processInPlace(&x)
        sat.processInPlace(&x)
        // Position EQ and pedal resonance are global-ish; apply here for simplicity.
        posEQ.processInPlace(&x)
        pedal.processInPlace(&x)
    }

    public func setPositionEQ(lowShelf: Float, presence: Float, air: Float) {
        posEQ.lowShelfGain = lowShelf
        posEQ.presenceGain = presence
        posEQ.airGain = air
        posEQ.updateCoeffs()
    }

    public func setPedalIR(_ ir: [Float]) { pedal = PedalResonance(ir: ir) }
    public func setKeyOffSample(_ s: [Float], gain: Float) { keyOff = KeyOff(sample: s, gain: gain) }
    public func onKeyOff(releaseVelocity: Float, mixInto buffer: inout [Float]) { keyOff.mix(into: &buffer, releaseVelocity: releaseVelocity) }
}
