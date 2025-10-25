
// VelocityTimbreModel.swift
// Parametric morphing across velocity using simple, controllable curves.
//
// MIDI 2 velocity (0..16383) is normalized to v ∈ [0,1] and mapped into
// tilt EQ, presence EQ, transient emphasis, noise gain, and saturation drive.

import Foundation

public struct VelocityTimbreModel: Codable, Equatable {
    public struct Pair: Codable, Equatable { public var min: Float; public var max: Float }
    public var tiltRange: Pair      // dB/Oct (low→high v)
    public var presenceRange: Pair  // dB at ~3 kHz
    public var transientRange: Pair // 0..1
    public var noiseRange: Pair     // 0..1
    public var satRange: Pair       // 0..1

    public init(tilt: Pair,
                presence: Pair,
                transient: Pair,
                noise: Pair,
                sat: Pair) {
        self.tiltRange = tilt
        self.presenceRange = presence
        self.transientRange = transient
        self.noiseRange = noise
        self.satRange = sat
    }

    @inlinable func curve(_ t: Float, _ r: Pair) -> Float {
        let tt = Window.smoothstep(clamp(t, 0, 1))
        return r.min + (r.max - r.min) * tt
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
