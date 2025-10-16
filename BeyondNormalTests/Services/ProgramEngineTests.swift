//
//  ProgramEngineTests.swift
//  BeyondNormalTests
//
//  Test suite for ProgramEngine.swift
//  Covers: 5/3/1 week schemes, training max progression
//

import XCTest
@testable import BeyondNormal

// MARK: - Week Scheme Tests

final class WeekSchemeTests: XCTestCase {
    
    let engine = ProgramEngine()
    
    // MARK: - Week 1 Tests (Default: 85% × 5+)
    
    func testWeek1Scheme() {
        let scheme = engine.weekScheme(for: 1)
        
        // Week 1: 65%, 75%, 85%
        XCTAssertEqual(scheme.main.count, 3)
        
        XCTAssertEqual(scheme.main[0].pct, 0.65)
        XCTAssertEqual(scheme.main[0].reps, 5)
        XCTAssertFalse(scheme.main[0].amrap)
        
        XCTAssertEqual(scheme.main[1].pct, 0.75)
        XCTAssertEqual(scheme.main[1].reps, 5)
        XCTAssertFalse(scheme.main[1].amrap)
        
        XCTAssertEqual(scheme.main[2].pct, 0.85)
        XCTAssertEqual(scheme.main[2].reps, 5)
        XCTAssertTrue(scheme.main[2].amrap, "Last set should be AMRAP")
        
        XCTAssertTrue(scheme.showBBB, "Week 1 should show BBB")
        XCTAssertEqual(scheme.topLine, "85% × 5+")
    }
    
    func testWeek1IsDefault() {
        // Week 1 and any invalid week number should use the same scheme
        let week1 = engine.weekScheme(for: 1)
        let week0 = engine.weekScheme(for: 0)
        let week5 = engine.weekScheme(for: 5)
        let weekNegative = engine.weekScheme(for: -1)
        let week100 = engine.weekScheme(for: 100)
        
        // All should have same percentages
        XCTAssertEqual(week1.main[0].pct, week0.main[0].pct)
        XCTAssertEqual(week1.main[0].pct, week5.main[0].pct)
        XCTAssertEqual(week1.main[0].pct, weekNegative.main[0].pct)
        XCTAssertEqual(week1.main[0].pct, week100.main[0].pct)
        
        // All should show BBB
        XCTAssertTrue(week0.showBBB)
        XCTAssertTrue(week5.showBBB)
        XCTAssertTrue(weekNegative.showBBB)
    }
    
    // MARK: - Week 2 Tests (90% × 3+)
    
    func testWeek2Scheme() {
        let scheme = engine.weekScheme(for: 2)
        
        // Week 2: 70%, 80%, 90%
        XCTAssertEqual(scheme.main.count, 3)
        
        XCTAssertEqual(scheme.main[0].pct, 0.70)
        XCTAssertEqual(scheme.main[0].reps, 3)
        XCTAssertFalse(scheme.main[0].amrap)
        
        XCTAssertEqual(scheme.main[1].pct, 0.80)
        XCTAssertEqual(scheme.main[1].reps, 3)
        XCTAssertFalse(scheme.main[1].amrap)
        
        XCTAssertEqual(scheme.main[2].pct, 0.90)
        XCTAssertEqual(scheme.main[2].reps, 3)
        XCTAssertTrue(scheme.main[2].amrap, "Last set should be AMRAP")
        
        XCTAssertTrue(scheme.showBBB, "Week 2 should show BBB")
        XCTAssertEqual(scheme.topLine, "90% × 3+")
    }
    
    // MARK: - Week 3 Tests (95% × 1+)
    
    func testWeek3Scheme() {
        let scheme = engine.weekScheme(for: 3)
        
        // Week 3: 75%, 85%, 95%
        XCTAssertEqual(scheme.main.count, 3)
        
        XCTAssertEqual(scheme.main[0].pct, 0.75)
        XCTAssertEqual(scheme.main[0].reps, 5)
        XCTAssertFalse(scheme.main[0].amrap)
        
        XCTAssertEqual(scheme.main[1].pct, 0.85)
        XCTAssertEqual(scheme.main[1].reps, 3)
        XCTAssertFalse(scheme.main[1].amrap)
        
        XCTAssertEqual(scheme.main[2].pct, 0.95)
        XCTAssertEqual(scheme.main[2].reps, 1)
        XCTAssertTrue(scheme.main[2].amrap, "Last set should be AMRAP")
        
        XCTAssertTrue(scheme.showBBB, "Week 3 should show BBB")
        XCTAssertEqual(scheme.topLine, "95% × 1+")
    }
    
    // MARK: - Week 4 Tests (Deload: 60% × 5)
    
    func testWeek4DeloadScheme() {
        let scheme = engine.weekScheme(for: 4)
        
        // Week 4: Deload - 40%, 50%, 60%
        XCTAssertEqual(scheme.main.count, 3)
        
        XCTAssertEqual(scheme.main[0].pct, 0.40)
        XCTAssertEqual(scheme.main[0].reps, 5)
        XCTAssertFalse(scheme.main[0].amrap)
        
        XCTAssertEqual(scheme.main[1].pct, 0.50)
        XCTAssertEqual(scheme.main[1].reps, 5)
        XCTAssertFalse(scheme.main[1].amrap)
        
        XCTAssertEqual(scheme.main[2].pct, 0.60)
        XCTAssertEqual(scheme.main[2].reps, 5)
        XCTAssertFalse(scheme.main[2].amrap, "Deload has no AMRAP")
        
        XCTAssertFalse(scheme.showBBB, "Week 4 deload should NOT show BBB")
        XCTAssertEqual(scheme.topLine, "Deload: 60% × 5")
    }
    
    // MARK: - Progressive Difficulty
    
    func testProgressiveDifficulty() {
        // Week 1: 85% × 5+
        // Week 2: 90% × 3+
        // Week 3: 95% × 1+
        // Week 4: 60% × 5 (deload)
        
        let week1 = engine.weekScheme(for: 1)
        let week2 = engine.weekScheme(for: 2)
        let week3 = engine.weekScheme(for: 3)
        let week4 = engine.weekScheme(for: 4)
        
        // Top set percentages should increase weeks 1-3
        XCTAssertLessThan(week1.main.last!.pct, week2.main.last!.pct)
        XCTAssertLessThan(week2.main.last!.pct, week3.main.last!.pct)
        
        // Week 4 deload is much lighter
        XCTAssertLessThan(week4.main.last!.pct, week1.main.last!.pct)
    }
    
    func testRepsDecreaseAsWeightIncreases() {
        // Week 1: 5 reps top set
        // Week 2: 3 reps top set
        // Week 3: 1 rep top set
        
        let week1 = engine.weekScheme(for: 1)
        let week2 = engine.weekScheme(for: 2)
        let week3 = engine.weekScheme(for: 3)
        
        XCTAssertGreaterThan(week1.main.last!.reps, week2.main.last!.reps)
        XCTAssertGreaterThan(week2.main.last!.reps, week3.main.last!.reps)
    }
    
    // MARK: - AMRAP Logic
    
    func testOnlyLastSetIsAMRAP() {
        let weeks = [1, 2, 3]
        
        for week in weeks {
            let scheme = engine.weekScheme(for: week)
            
            // First two sets should not be AMRAP
            XCTAssertFalse(scheme.main[0].amrap, "Week \(week) first set should not be AMRAP")
            XCTAssertFalse(scheme.main[1].amrap, "Week \(week) second set should not be AMRAP")
            
            // Last set should be AMRAP
            XCTAssertTrue(scheme.main[2].amrap, "Week \(week) last set should be AMRAP")
        }
    }
    
    func testDeloadHasNoAMRAP() {
        let scheme = engine.weekScheme(for: 4)
        
        // Deload should have no AMRAP sets
        for set in scheme.main {
            XCTAssertFalse(set.amrap, "Deload sets should not be AMRAP")
        }
    }
    
    // MARK: - BBB Flag
    
    func testBBBFlagCorrect() {
        XCTAssertTrue(engine.weekScheme(for: 1).showBBB, "Week 1 shows BBB")
        XCTAssertTrue(engine.weekScheme(for: 2).showBBB, "Week 2 shows BBB")
        XCTAssertTrue(engine.weekScheme(for: 3).showBBB, "Week 3 shows BBB")
        XCTAssertFalse(engine.weekScheme(for: 4).showBBB, "Week 4 deload hides BBB")
    }
    
    // MARK: - All Weeks Have 3 Sets
    
    func testAllWeeksHaveThreeSets() {
        for week in -5...10 {
            let scheme = engine.weekScheme(for: week)
            XCTAssertEqual(scheme.main.count, 3, "Week \(week) should have 3 main sets")
        }
    }
}

// MARK: - Training Max Progression Tests

final class TrainingMaxProgressionTests: XCTestCase {
    
    let engine = ProgramEngine()
    
    // MARK: - Classic Progression Tests
    
    func testClassicProgressionUpperBody() {
        // Classic: +5 for upper body
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: nil,
            style: .classic,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 230.0, "Upper body classic progression adds 5 lb")
    }
    
    func testClassicProgressionLowerBody() {
        // Classic: +10 for lower body
        let current: Double = 315
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: nil,
            style: .classic,
            isUpperBody: false
        )
        
        XCTAssertEqual(next, 325.0, "Lower body classic progression adds 10 lb")
    }
    
    func testClassicIgnoresAMRAP() {
        // Classic progression ignores AMRAP data
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: 300.0,  // Should be ignored
            style: .classic,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 230.0, "Classic adds fixed 5 lb regardless of AMRAP")
    }
    
    // MARK: - Auto Progression Tests
    
    func testAutoProgressionBasic() {
        // Auto: 90% of latest AMRAP 1RM
        // Latest AMRAP: 300 lb → TM should be 270
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: 300.0,
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 235.0, "Auto can't increase more than +10 for upper (capped)")
    }
    
    func testAutoProgressionWithinCap() {
        // AMRAP suggests 240, current 225, cap is +10
        // 90% of 260 = 234, which is +9, within cap
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: 260.0,  // 90% = 234
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 234.0, "Should use 90% when within +10 cap")
    }
    
    func testAutoProgressionUpperBodyCap() {
        // Upper body cap: +10 max per cycle
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: 400.0,  // 90% = 360, way above current
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 235.0, "Upper body capped at +10")
    }
    
    func testAutoProgressionLowerBodyCap() {
        // Lower body cap: +20 max per cycle
        let current: Double = 315
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: 500.0,  // 90% = 450, way above current
            style: .auto,
            isUpperBody: false
        )
        
        XCTAssertEqual(next, 335.0, "Lower body capped at +20")
    }
    
    func testAutoProgressionNoAMRAPData() {
        // If no AMRAP data, keep current TM
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: nil,
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 225.0, "No AMRAP data means no change")
    }
    
    func testAutoProgressionZeroAMRAP() {
        // If AMRAP is zero, keep current TM
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: 0.0,
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 225.0, "Zero AMRAP means no change")
    }
    
    func testAutoProgressionNegativeAMRAP() {
        // If AMRAP is negative (shouldn't happen but guard against it)
        let current: Double = 225
        let next = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: -100.0,
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 225.0, "Negative AMRAP means no change")
    }
    
    // MARK: - Real-World Scenarios
    
    func testBenchProgressionScenario() {
        // Bench (upper body): 225 TM, hit 235×8 on AMRAP
        // Estimated 1RM: ~295 lb
        // Next TM: 90% of 295 = 265.5
        // But capped at 225+10 = 235
        
        let current: Double = 225
        let amrap1RM: Double = 295
        
        let classicNext = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: amrap1RM,
            style: .classic,
            isUpperBody: true
        )
        
        let autoNext = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: amrap1RM,
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(classicNext, 230.0, "Classic: +5")
        XCTAssertEqual(autoNext, 235.0, "Auto: capped at +10")
    }
    
    func testSquatProgressionScenario() {
        // Squat (lower body): 315 TM, hit 335×5 on AMRAP
        // Estimated 1RM: ~370 lb
        // Next TM: 90% of 370 = 333
        // Within cap of 315+20 = 335
        
        let current: Double = 315
        let amrap1RM: Double = 370
        
        let classicNext = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: amrap1RM,
            style: .classic,
            isUpperBody: false
        )
        
        let autoNext = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: amrap1RM,
            style: .auto,
            isUpperBody: false
        )
        
        XCTAssertEqual(classicNext, 325.0, "Classic: +10")
        XCTAssertEqual(autoNext, 333.0, "Auto: 90% of 370")
    }
    
    func testPressStallScenario() {
        // Press struggling: 135 TM, barely hit 145×3 on AMRAP
        // Estimated 1RM: ~154 lb
        // Next TM: 90% of 154 = 138.6
        // Only +3.6, which is fine
        
        let current: Double = 135
        let amrap1RM: Double = 154
        
        let autoNext = engine.nextTrainingMax(
            current: current,
            latestAMRAP1RM: amrap1RM,
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(autoNext, 138.6, accuracy: 0.1, "Auto adjusts for stall")
    }
    
    // MARK: - Edge Cases
    
    func testZeroCurrentTM() {
        let next = engine.nextTrainingMax(
            current: 0,
            latestAMRAP1RM: 200,
            style: .auto,
            isUpperBody: true
        )
        
        // 90% of 200 = 180, but capped at 0+10 = 10
        XCTAssertEqual(next, 10.0)
    }
    
    func testVeryLowCurrentTM() {
        let next = engine.nextTrainingMax(
            current: 45,  // Just the bar
            latestAMRAP1RM: 100,
            style: .auto,
            isUpperBody: true
        )
        
        // 90% of 100 = 90, but capped at 45+10 = 55
        XCTAssertEqual(next, 55.0)
    }
    
    func testVeryHighAMRAP() {
        let next = engine.nextTrainingMax(
            current: 225,
            latestAMRAP1RM: 1000,  // Unrealistic but test the cap
            style: .auto,
            isUpperBody: true
        )
        
        XCTAssertEqual(next, 235.0, "Should cap at +10")
    }
}

// MARK: - Model Tests

final class ProgramEngineModelTests: XCTestCase {
    
    func testSetSchemeModel() {
        let set = SetScheme(pct: 0.85, reps: 5, amrap: true)
        
        XCTAssertEqual(set.pct, 0.85)
        XCTAssertEqual(set.reps, 5)
        XCTAssertTrue(set.amrap)
    }
    
    func testWeekSchemeResultModel() {
        let sets = [
            SetScheme(pct: 0.65, reps: 5, amrap: false),
            SetScheme(pct: 0.75, reps: 5, amrap: false),
            SetScheme(pct: 0.85, reps: 5, amrap: true)
        ]
        
        let result = WeekSchemeResult(
            main: sets,
            showBBB: true,
            topLine: "85% × 5+"
        )
        
        XCTAssertEqual(result.main.count, 3)
        XCTAssertTrue(result.showBBB)
        XCTAssertEqual(result.topLine, "85% × 5+")
    }
    
    func testProgressionStyleEnum() {
        XCTAssertEqual(ProgressionStyle.classic.rawValue, "classic")
        XCTAssertEqual(ProgressionStyle.auto.rawValue, "auto")
    }
}
