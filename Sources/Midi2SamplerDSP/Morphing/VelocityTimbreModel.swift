
// VelocityTimbreModel.swift
// Parametric morphing across velocity using simple, controllable curves.
//
// MIDI 2 velocity (0..16383) is normalized to v ∈ [0,1] and mapped into
// tilt EQ, presence EQ, transient emphasis, noise gain, and saturation drive.

import Foundation

public struct VelocityTimbreModel: Codable, Equatable {
    public var tiltRange: (Float, Float)      // dB/Oct (low→high v)
    public var presenceRange: (Float, Float)  // dB at ~3 kHz
    public var transientRange: (Float, Float) // 0..1
    public var noiseRange: (Float, Float)     // 0..1
    public var satRange: (Float, Float)       // 0..1

    public init(tilt: (Float,Float),
                presence: (Float,Float),
                transient: (Float,Float),
                noise: (Float,Float),
                sat: (Float,Float)) {
        self.tiltRange = tilt
        self.presenceRange = presence
        self.transientRange = transient
        self.noiseRange = noise
        self.satRange = sat
    }

    @inlinable func curve(_ t: Float, _ r: (Float,Float)) -> Float {
        let tt = Window.smoothstep(clamp(t, 0, 1))
        return r.0 + (r.1 - r.0) * tt
    }

    /// v2 is MIDI 2 velocity 0..16383
    public func params(v2: UInt16) -> (tilt: Float, presence: Float, trans: Float, noise: Float, sat: Float) {
        let v = Float(v2) / 16383.0
        return (
            curve(v, tiltRange),
            curve(v, presenceRange),
            curve(v, transientRange),
            curve(v, noiseRange),
            curve(v, satRange)
        )
    }
}
