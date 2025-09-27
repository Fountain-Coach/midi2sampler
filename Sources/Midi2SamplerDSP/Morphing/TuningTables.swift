
// TuningTables.swift
// Per-note detune and inharmonicity scaffolding (for pianos).

import Foundation

public struct TuningTables: Codable, Equatable {
    /// cents offset per MIDI note (0..127)
    public var detuneCents: [Float]   // length 128
    /// inharmonicity factor per note (B coefficient for stretched partials)
    public var inharmonicity: [Float] // length 128

    public init(detuneCents: [Float] = .init(repeating: 0, count: 128),
                inharmonicity: [Float] = .init(repeating: 0.0001, count: 128)) {
        self.detuneCents = detuneCents
        self.inharmonicity = inharmonicity
    }
}
