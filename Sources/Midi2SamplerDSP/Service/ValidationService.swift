
// Sources/Midi2SamplerDSP/Service/ValidationService.swift
//
// Lightweight adapter functions you can call from your HTTP server to service
// the OpenAPI endpoints (/packs:validate, /corpus/audio:validate).

import Foundation

public struct ValidationService {
    public init() {}

    public func validatePack(_ pack: SamplerPack) -> ValidationReport {
        PackValidator().validate(pack)
    }

    public func validateAudio(_ summary: AudioSummary) -> ValidationReport {
        AudioValidator().validate(summary)
    }
}
