import XCTest
@testable import BeyondNormal

final class AmrapEstimatorTests: XCTestCase {

    // Helper for exact expected Epley (no rounding)
    private func epley(_ w: Double, _ r: Int) -> Double {
        w * (1.0 + Double(r) / 30.0)
    }

    // MARK: - Core rules

    func testOneRepReturnsWorkingWeight() {
        let r = estimate1RM(weight: 315, reps: 1, formula: .epley, roundTo: 5)
        XCTAssertEqual(r.e1RM, 315)                    // rounded to 5s
        XCTAssertEqual(r.note, .none)
    }

    func testNormalRange_2to10_NoNote() {
        let r = estimate1RM(weight: 225, reps: 8, formula: .epley, roundTo: 5)
        let expected = Double(roundToNearest(epley(225, 8), step: 5))
        XCTAssertEqual(r.e1RM, expected)
        XCTAssertEqual(r.note, .none)
    }

    // MARK: - High reps behavior

    func testLowConfidenceAt11to15() {
        // 11 reps
        var r = estimate1RM(weight: 200, reps: 11, softWarnAt: 11, hardCap: 15, roundTo: 5)
        XCTAssertEqual(r.note, .lowConfidence)

        // 14 reps
        r = estimate1RM(weight: 200, reps: 14, softWarnAt: 11, hardCap: 15, roundTo: 5)
        XCTAssertEqual(r.note, .lowConfidence)

        // 15 reps
        r = estimate1RM(weight: 200, reps: 15, softWarnAt: 11, hardCap: 15, roundTo: 5)
        XCTAssertEqual(r.note, .lowConfidence)
    }

    func testRefuseAboveHardCap() {
        let r = estimate1RM(weight: 200, reps: 16, softWarnAt: 11, hardCap: 15, refuseAboveHardCap: true, roundTo: 5)
        XCTAssertEqual(r.e1RM, 0)
        if case .invalidTooManyReps(let actual) = r.note {
            XCTAssertEqual(actual, 16)
        } else {
            XCTFail("Expected invalidTooManyReps note")
        }
    }

    func testCapAboveHardCap_WhenAllowed() {
        let r = estimate1RM(weight: 200, reps: 30, softWarnAt: 11, hardCap: 15, refuseAboveHardCap: false, roundTo: 5)
        // Expect it to use 15 reps in the math
        let expected = Double(roundToNearest(epley(200, 15), step: 5))
        XCTAssertEqual(r.e1RM, expected)
        if case .capped(let cap) = r.note {
            XCTAssertEqual(cap, 15)
        } else {
            XCTFail("Expected capped(at:) note")
        }
    }

    // MARK: - Rounding & invalids

    func testRoundingToNearestStep() {
        // 200 * (1 + 8/30) = 253.33... → nearest 5 = 255
        let r = estimate1RM(weight: 200, reps: 8, roundTo: 5)
        XCTAssertEqual(r.e1RM, 255)
    }

    func testInvalidInputs() {
        var r = estimate1RM(weight: 0, reps: 8, roundTo: 5)
        XCTAssertEqual(r.e1RM, 0)

        r = estimate1RM(weight: 225, reps: 0, roundTo: 5)
        XCTAssertEqual(r.e1RM, 0)
    }
}
