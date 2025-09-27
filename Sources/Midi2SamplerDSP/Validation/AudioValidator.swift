
// Sources/Midi2SamplerDSP/Validation/AudioValidator.swift
//
// AudioSummary validation: quick gates for quality and continuity.

import Foundation

public struct AudioValidator: Validatable {
    public init() {}

    public func validate(_ subject: AudioSummary) -> ValidationReport {
        var issues: [ValidationIssue] = []

        // HARD: basic fields
        if subject.sampleRate <= 0 {
            issues.append(.init(.hard, "sampleRate", "sampleRate must be positive"))
        }
        if subject.channels <= 0 {
            issues.append(.init(.hard, "channels", "channels must be positive"))
        }
        if subject.duration <= 0 {
            issues.append(.init(.hard, "duration", "duration must be positive"))
        }

        // SOFT: DC
        if abs(subject.dcOffset) > 0.01 {
            issues.append(.init(.soft, "dcOffset", "non-trivial DC offset",
                                suggestion: "apply high-pass or mean subtraction per window"))
        }

        // SOFT: clipping
        if subject.clippingPercent > 0.1 {
            issues.append(.init(.soft, "clippingPercent", "signal appears clipped",
                                suggestion: "re-record or reduce gain; consider declipping"))
        }

        // SOFT: loop continuity threshold
        if let loop = subject.loop {
            if loop.loopability < 0.5 {
                issues.append(.init(.soft, "loop.loopability", "low loopability score",
                                    suggestion: "increase overlap or re-pick loop points"))
            }
        }

        let ok = !issues.contains { $0.severity == .hard }
        return ValidationReport(ok: ok, issues: issues)
    }
}
