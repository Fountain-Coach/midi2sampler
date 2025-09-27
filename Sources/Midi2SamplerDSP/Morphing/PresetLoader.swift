
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
            tilt: (vm.tiltRange[0], vm.tiltRange[1]),
            presence: (vm.presenceRange[0], vm.presenceRange[1]),
            transient: (vm.transientRange[0], vm.transientRange[1]),
            noise: (vm.noiseRange[0], vm.noiseRange[1]),
            sat: (vm.satRange[0], vm.satRange[1])
        )
        p.setPositionEQ(lowShelf: preset.positionEQ.lowShelf,
                        presence: preset.positionEQ.presence,
                        air: preset.positionEQ.air)
        return p
    }
}
