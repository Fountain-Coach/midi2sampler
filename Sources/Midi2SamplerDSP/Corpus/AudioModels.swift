
// Sources/Midi2SamplerDSP/Corpus/AudioModels.swift
//
// Audio corpus models and introspection configuration.
//
import Foundation

public struct AudioSummary: Codable, Equatable {
    public struct LoopInfo: Codable, Equatable {
        public var start: Int
        public var end: Int
        public var overlap: Int
        public var scoreAmp: Float
        public var scoreSlope: Float
        public var scoreSpec: Float
        public var loopability: Float
    }

    public var path: String
    public var checksum: String?
    public var duration: Double
    public var sampleRate: Int
    public var channels: Int
    public var rms: Float
    public var peak: Float
    public var dcOffset: Float
    public var clippingPercent: Float
    public var f0MeanHz: Float?
    public var f0Stability: Float?
    public var mfccMean: [Float]
    public var mfccVar: [Float]
    public var centroid: Float
    public var rolloff95: Float
    public var flatness: Float
    public var chromaMean: [Float]
    public var loop: LoopInfo?
    public var embedding: [Float]
    public var specHash: [UInt64]

    public init(path: String,
                checksum: String? = nil,
                duration: Double,
                sampleRate: Int,
                channels: Int,
                rms: Float,
                peak: Float,
                dcOffset: Float,
                clippingPercent: Float,
                f0MeanHz: Float?,
                f0Stability: Float?,
                mfccMean: [Float],
                mfccVar: [Float],
                centroid: Float,
                rolloff95: Float,
                flatness: Float,
                chromaMean: [Float],
                loop: LoopInfo?,
                embedding: [Float],
                specHash: [UInt64]) {
        self.path = path
        self.checksum = checksum
        self.duration = duration
        self.sampleRate = sampleRate
        self.channels = channels
        self.rms = rms
        self.peak = peak
        self.dcOffset = dcOffset
        self.clippingPercent = clippingPercent
        self.f0MeanHz = f0MeanHz
        self.f0Stability = f0Stability
        self.mfccMean = mfccMean
        self.mfccVar = mfccVar
        self.centroid = centroid
        self.rolloff95 = rolloff95
        self.flatness = flatness
        self.chromaMean = chromaMean
        self.loop = loop
        self.embedding = embedding
        self.specHash = specHash
    }
}

public enum IntrospectionOptions {
    case computeLoopability(searchStart: Int?, searchEnd: Int?, overlap: Int)
    case computeEmbeddings
    case computeFingerprints
}
