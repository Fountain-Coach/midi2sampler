
// PresetLoader.swift
// Loads a simple JSON preset for the morphing model and position EQ.

import Foundation

public struct MorphingPreset: Codable, Equatable {
    public struct VelocityModelRange: Codable, Equatable { public var tiltRange: [Float]; public var presenceRange: [Float]; public var transientRange: [Float]; public var noiseRange: [Float]; public var satRange: [Float] }
    public struct PositionEQCfg: Codable, Equatable { public var lowShelf: Float; public var presence: Float; public var air: Float }
    public var name: String
    public var velocityModel: VelocityModelRange
    public var positionEQ: PositionEQCfg
}

public enum PresetLoader {
    public static func load(path: String) throws -> MorphingPreset {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(MorphingPreset.self, from: data)
    }

    public static func apply(_ preset: MorphingPreset, to proc: RealTimeNoteProcessor) -> RealTimeNoteProcessor {
        var p = proc
        let vm = preset.velocityModel
        p.model = VelocityTimbreModel(
            tilt: .init(min: vm.tiltRange[0], max: vm.tiltRange[1]),
            presence: .init(min: vm.presenceRange[0], max: vm.presenceRange[1]),
            transient: .init(min: vm.transientRange[0], max: vm.transientRange[1]),
            noise: .init(min: vm.noiseRange[0], max: vm.noiseRange[1]),
            sat: .init(min: vm.satRange[0], max: vm.satRange[1])
        )
        p.setPositionEQ(lowShelf: preset.positionEQ.lowShelf,
                        presence: preset.positionEQ.presence,
                        air: preset.positionEQ.air)
        return p
    }
}
