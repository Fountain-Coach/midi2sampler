
import XCTest
@testable import Midi2SamplerDSP

final class Midi2SamplerDSPTests: XCTestCase {

    func testEqualPowerScalar() {
        let (a0,b0) = Window.equalPowerScalar(0)
        XCTAssertEqual(a0, 1, accuracy: 1e-6)
        XCTAssertEqual(b0, 0, accuracy: 1e-6)

        let (a1,b1) = Window.equalPowerScalar(1)
        XCTAssertEqual(a1, 0, accuracy: 1e-6)
        XCTAssertEqual(b1, 1, accuracy: 1e-6)
    }

    func testPhaseAlignNoop() {
        let a: [Float] = [0, 1, 0, -1]
        let b = a
        let out = bestCircularAlign(a: a, b: b, maxShift: 4)
        XCTAssertEqual(out, b)
    }

    func testLoopStitcherBasic() {
        // A quasi-sine with a loopable region.
        let sr: Float = 48000
        let f: Float = 220
        let N = 48000
        var x = (0..<N).map { i in sinf(2 * .pi * f * Float(i)/sr) }
        var st = LoopStitcher(overlap: 1024)
        let res = st.stitchLoopInPlace(buffer: &x, searchStart: 2000, searchEnd: N-2000)
        XCTAssertNotNil(res)
    }
}
