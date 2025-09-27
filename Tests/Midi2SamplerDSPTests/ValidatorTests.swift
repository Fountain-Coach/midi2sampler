
import XCTest
@testable import Midi2SamplerDSP

final class ValidatorTests: XCTestCase {

    func testPackValidator() throws {
        var pack = SamplerPack(
            instrument: Instrument(
                name: "Test",
                sampleRate: 48000,
                zones: [
                    Zone(id: "z1",
                         pitchCenter: 60,
                         pitchRange: [57, 63],
                         velocityRange: [0.5, 0.7],
                         file: "Audio/z1.wav",
                         loop: Loop(start: 1000, end: 8000, overlap: 512),
                         normRMS: nil)
                ]
            )
        )

        let v = PackValidator()
        let report = v.validate(pack)
        XCTAssertTrue(report.ok)  // only soft issues expected
        XCTAssertTrue(report.issues.contains { $0.severity == .soft })

        let (fixed, fixes) = v.autoCorrect(pack)
        XCTAssertNotNil(fixed.instrument.zones.first!.normRMS)
        XCTAssertEqual(fixed.instrument.zones.first!.loop!.overlap, ValidatorDefaults.loopOverlapFloor)
        XCTAssertFalse(fixes.isEmpty)
    }

    func testAudioValidator() throws {
        let summary = AudioSummary(
            path: "Audio/a.rawf32",
            duration: 1.0,
            sampleRate: 48000,
            channels: 1,
            rms: 0.3, peak: 0.99, dcOffset: 0.02, clippingPercent: 0.2,
            f0MeanHz: nil, f0Stability: nil,
            mfccMean: .init(repeating: 0, count: 20),
            mfccVar: .init(repeating: 0, count: 20),
            centroid: 1000, rolloff95: 5000, flatness: 0.4,
            chromaMean: .init(repeating: 0, count: 12),
            loop: .init(start: 1000, end: 8000, overlap: 2048, scoreAmp: 0, scoreSlope: 0, scoreSpec: 0, loopability: 0.4),
            embedding: .init(repeating: 0, count: 64),
            specHash: [0,1,2,3]
        )
        let v = AudioValidator()
        let rep = v.validate(summary)
        XCTAssertTrue(rep.ok)  // only soft issues expected here
        XCTAssertTrue(rep.issues.contains { $0.path == "dcOffset" })
        XCTAssertTrue(rep.issues.contains { $0.path == "clippingPercent" })
        XCTAssertTrue(rep.issues.contains { $0.path == "loop.loopability" })
    }
}
