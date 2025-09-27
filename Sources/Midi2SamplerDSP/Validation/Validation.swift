
// Sources/Midi2SamplerDSP/Validation/Validation.swift
//
// Generic validation types for packs and audio summaries.

import Foundation

public enum ValidationSeverity: String, Codable {
    case hard     // must fix; fails gate
    case soft     // recommended; can auto-correct or set defaults
    case info     // informational
}

public struct ValidationIssue: Codable, Equatable {
    public var severity: ValidationSeverity
    public var path: String           // JSONPath-like (e.g., "instrument.zones[0].loop.start")
    public var message: String
    public var suggestion: String?

    public init(_ severity: ValidationSeverity, _ path: String, _ message: String, suggestion: String? = nil) {
        self.severity = severity
        self.path = path
        self.message = message
        self.suggestion = suggestion
    }
}

public struct ValidationReport: Codable, Equatable {
    public var ok: Bool
    public var issues: [ValidationIssue]

    public init(ok: Bool, issues: [ValidationIssue]) {
        self.ok = ok
        self.issues = issues
    }
}

public protocol Validatable {
    associatedtype Subject
    func validate(_ subject: Subject) -> ValidationReport
}

public enum ValidatorDefaults {
    // Conservative defaults for crossfades & overlaps
    public static let minOverlapSamples = 256
    public static let recommendedOverlapSamples = 2048

    // Loop overlap: at least ~2 periods at 44.1kHz for 100Hz tone ≈ 882 samples; we use 1024+
    public static let loopOverlapFloor = 1024

    // Loudness target for zone normalization (RMS proxy, in dBFS)
    public static let targetRMSdBFS: Float = -18.0

    // Spectral continuity threshold (heuristic, log-mag L2)
    public static let spectralSeamMax: Float = 18.0
}
