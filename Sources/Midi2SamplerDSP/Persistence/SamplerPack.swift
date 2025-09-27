
// Persistence/SamplerPack.swift
//
// JSON models for the MIDI 2–native Sampler Pack.
// Designed to be stable, diffable, and easy to validate.
//
import Foundation

public struct SamplerPack: Codable, Equatable {
    public var format: String
    public var version: String
    public var instrument: Instrument
    public var controllers: Controllers
    public var profiles: [String]
    public var propertyExchange: PropertyExchange?

    public init(format: String = "Midi2SamplerPack",
                version: String = "0.1.0",
                instrument: Instrument,
                controllers: Controllers = .defaults(),
                profiles: [String] = [],
                propertyExchange: PropertyExchange? = nil) {
        self.format = format
        self.version = version
        self.instrument = instrument
        self.controllers = controllers
        self.profiles = profiles
        self.propertyExchange = propertyExchange
    }
}

public struct Instrument: Codable, Equatable {
    public var name: String
    public var sampleRate: Int
    public var zones: [Zone]
    public var xfade: XFade

    public init(name: String,
                sampleRate: Int,
                zones: [Zone],
                xfade: XFade = .init(timeMs: 30, curve: .equalPower, spectralMorph: false)) {
        self.name = name
        self.sampleRate = sampleRate
        self.zones = zones
        self.xfade = xfade
    }
}

public struct Zone: Codable, Equatable {
    public var id: String
    public var pitchCenter: Int
    public var pitchRange: [Int]   // [low, high] in MIDI notes
    public var velocityRange: [Float] // [low, high] in 0..1
    public var file: String        // relative path to audio
    public var loop: Loop?
    public var normRMS: Float?
    public var phaseAlignHint: Int?

    public init(id: String,
                pitchCenter: Int,
                pitchRange: [Int],
                velocityRange: [Float],
                file: String,
                loop: Loop? = nil,
                normRMS: Float? = nil,
                phaseAlignHint: Int? = nil) {
        self.id = id
        self.pitchCenter = pitchCenter
        self.pitchRange = pitchRange
        self.velocityRange = velocityRange
        self.file = file
        self.loop = loop
        self.normRMS = normRMS
        self.phaseAlignHint = phaseAlignHint
    }
}

public struct Loop: Codable, Equatable {
    public var start: Int
    public var end: Int
    public var overlap: Int
    public var window: CrossfadeCurve

    public init(start: Int, end: Int, overlap: Int, window: CrossfadeCurve = .equalPower) {
        self.start = start
        self.end = end
        self.overlap = overlap
        self.window = window
    }
}

public struct XFade: Codable, Equatable {
    public var timeMs: Int
    public var curve: CrossfadeCurve
    public var spectralMorph: Bool
    public init(timeMs: Int, curve: CrossfadeCurve, spectralMorph: Bool) {
        self.timeMs = timeMs
        self.curve = curve
        self.spectralMorph = spectralMorph
    }
}

public enum CrossfadeCurve: String, Codable { case equalPower, smoothstep, hann }

public struct Controllers: Codable, Equatable {
    public var perNote: PerNote
    public var global: Global
    public static func defaults() -> Controllers {
        .init(perNote: .init(pitchBend: true, timbre: "CC74", pressure: true),
              global: .init(sustain: 64, pedalResonance: true))
    }
    public struct PerNote: Codable, Equatable {
        public var pitchBend: Bool
        public var timbre: String?
        public var pressure: Bool
    }
    public struct Global: Codable, Equatable {
        public var sustain: Int
        public var pedalResonance: Bool
    }
}

public struct PropertyExchange: Codable, Equatable {
    public var uri: String
    public var params: [String: Bool]
}
