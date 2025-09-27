
// Sources/Midi2SamplerDSP/Validation/PackValidator.swift
//
// SamplerPack validator with Hard / Soft / Info rules and simple auto-corrections.

import Foundation

public struct PackValidator: Validatable {
    public init() {}

    public func validate(_ subject: SamplerPack) -> ValidationReport {
        var issues: [ValidationIssue] = []

        // HARD: format and version present
        if subject.format.isEmpty {
            issues.append(.init(.hard, "format", "format is required", suggestion: "set to 'Midi2SamplerPack'"))
        }
        if subject.instrument.name.isEmpty {
            issues.append(.init(.hard, "instrument.name", "instrument.name is required"))
        }
        if subject.instrument.sampleRate <= 0 {
            issues.append(.init(.hard, "instrument.sampleRate", "sampleRate must be positive"))
        }

        // HARD: zones non-empty
        if subject.instrument.zones.isEmpty {
            issues.append(.init(.hard, "instrument.zones", "instrument must have at least one zone"))
        }

        // ZONE rules
        for (i, z) in subject.instrument.zones.enumerated() {
            let base = "instrument.zones[\(i)]"

            // HARD: file non-empty
            if z.file.isEmpty {
                issues.append(.init(.hard, "\(base).file", "zone file is required"))
            }

            // HARD: pitch/velocity ranges
            if z.pitchRange.count != 2 || z.pitchRange[0] > z.pitchRange[1] {
                issues.append(.init(.hard, "\(base).pitchRange", "pitchRange must be [low, high] and low<=high"))
            }
            if z.velocityRange.count != 2 || z.velocityRange[0] > z.velocityRange[1] {
                issues.append(.init(.hard, "\(base).velocityRange", "velocityRange must be [low, high] and low<=high"))
            }

            // SOFT: loop overlap recommendation
            if let loop = z.loop {
                if loop.start >= loop.end {
                    issues.append(.init(.hard, "\(base).loop", "loop.start must be < loop.end"))
                }
                if loop.overlap < ValidatorDefaults.loopOverlapFloor {
                    issues.append(.init(.soft, "\(base).loop.overlap",
                                        "overlap is small; may click for low fundamentals",
                                        suggestion: "use ≥ \(ValidatorDefaults.loopOverlapFloor) samples"))
                }
            } else {
                issues.append(.init(.soft, "\(base).loop", "zone has no loop; long sustains may fade unnaturally"))
            }

            // SOFT: RMS normalization hint
            if let norm = z.normRMS {
                if norm > -8.0 {
                    issues.append(.init(.soft, "\(base).normRMS", "zone is quite hot (>−8 dBFS RMS)",
                                        suggestion: "aim around \(ValidatorDefaults.targetRMSdBFS) dBFS"))
                }
            } else {
                issues.append(.init(.soft, "\(base).normRMS", "missing RMS target; normalization recommended",
                                    suggestion: "set to ~\(ValidatorDefaults.targetRMSdBFS) dBFS"))
            }
        }

        // XFade defaults
        if subject.instrument.xfade.timeMs < 10 || subject.instrument.xfade.timeMs > 200 {
            issues.append(.init(.soft, "instrument.xfade.timeMs",
                                "xfade time is unusual (recommended 20–60 ms)",
                                suggestion: "set timeMs ~30"))
        }

        let ok = !issues.contains { $0.severity == .hard }
        return ValidationReport(ok: ok, issues: issues)
    }

    /// Auto-correct soft issues: fill defaults and nudge toward recommended values.
    public func autoCorrect(_ pack: SamplerPack) -> (corrected: SamplerPack, fixes: [ValidationIssue]) {
        var p = pack
        var fixes: [ValidationIssue] = []

        if p.format.isEmpty {
            p.format = "Midi2SamplerPack"
            fixes.append(.init(.soft, "format", "filled default format", suggestion: "Midi2SamplerPack"))
        }
        if p.version.isEmpty {
            p.version = "0.1.0"
            fixes.append(.init(.soft, "version", "filled default version", suggestion: "0.1.0"))
        }
        if p.instrument.xfade.timeMs < 10 || p.instrument.xfade.timeMs > 200 {
            p.instrument.xfade.timeMs = 30
            fixes.append(.init(.soft, "instrument.xfade.timeMs", "set default crossfade time to 30 ms"))
        }
        // Zone defaults
        for i in 0..<p.instrument.zones.count {
            if p.instrument.zones[i].normRMS == nil {
                p.instrument.zones[i].normRMS = ValidatorDefaults.targetRMSdBFS
                fixes.append(.init(.soft, "instrument.zones[\(i)].normRMS",
                                   "set default RMS to \(ValidatorDefaults.targetRMSdBFS) dBFS"))
            }
            if var lp = p.instrument.zones[i].loop, lp.overlap < ValidatorDefaults.loopOverlapFloor {
                lp.overlap = ValidatorDefaults.loopOverlapFloor
                p.instrument.zones[i].loop = lp
                fixes.append(.init(.soft, "instrument.zones[\(i)].loop.overlap",
                                   "raised overlap to \(ValidatorDefaults.loopOverlapFloor) samples"))
            }
        }
        return (p, fixes)
    }
}
