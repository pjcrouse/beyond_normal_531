//
//  WarmupPlannerTests.swift
//  BeyondNormalTests
//
//  Test suite for WarmupPlanner.swift
//  Covers: Warmup set generation, movement suggestions, rep schemes
//

import XCTest
@testable import BeyondNormal

// MARK: - Movement Suggestion Tests

final class MovementSuggestionTests: XCTestCase {
    
    func testSquatMovementSuggestion() {
        let suggestion = suggestedMovement(for: .squat)
        XCTAssertTrue(suggestion.contains("squat") || suggestion.contains("hip"))
        XCTAssertFalse(suggestion.isEmpty)
    }
    
    func testDeadliftMovementSuggestion() {
        let suggestion = suggestedMovement(for: .deadlift)
        XCTAssertTrue(suggestion.contains("swing") || suggestion.contains("RDL"))
        XCTAssertFalse(suggestion.isEmpty)
    }
    
    func testBenchMovementSuggestion() {
        let suggestion = suggestedMovement(for: .bench)
        XCTAssertTrue(suggestion.contains("pushup") || suggestion.contains("push"))
        XCTAssertFalse(suggestion.isEmpty)
    }
    
    func testRowMovementSuggestion() {
        let suggestion = suggestedMovement(for: .row)
        XCTAssertTrue(suggestion.contains("row") || suggestion.contains("scap"))
        XCTAssertFalse(suggestion.isEmpty)
    }
    
    func testPressMovementSuggestion() {
        let suggestion = suggestedMovement(for: .press)
        XCTAssertTrue(suggestion.contains("shoulder") || suggestion.contains("press"))
        XCTAssertFalse(suggestion.isEmpty)
    }
}

// MARK: - Warmup Plan Generation Tests

final class WarmupPlannerTests: XCTestCase {
    
    let standardBar: Double = 45.0
    let roundTo: Double = 5.0
    
    // MARK: - Basic Plan Generation
    
    func testAlwaysStartsWithBar() {
        // Every warmup plan should start with just the bar
        let plans = [
            buildWarmupPlan(target: 135, bar: standardBar, roundTo: roundTo, lift: .squat),
            buildWarmupPlan(target: 225, bar: standardBar, roundTo: roundTo, lift: .squat),
            buildWarmupPlan(target: 315, bar: standardBar, roundTo: roundTo, lift: .squat),
            buildWarmupPlan(target: 405, bar: standardBar, roundTo: roundTo, lift: .squat)
        ]
        
        for plan in plans {
            XCTAssertEqual(plan.first?.weight, standardBar, "First set should always be the bar")
            XCTAssertEqual(plan.first?.reps, 10, "First set should be 10 reps")
        }
    }
    
    func testSmallJump_OnePlate() {
        // 135 lb (one plate) - small jump from bar
        // Span: 135 - 45 = 90 lb
        // Should give: bar + 1-2 warmup sets
        let plan = buildWarmupPlan(target: 135, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertGreaterThanOrEqual(plan.count, 2, "Should have at least bar + 1 warmup")
        XCTAssertLessThanOrEqual(plan.count, 4, "Should never exceed 4 total sets")
        
        // All weights should be strictly less than target
        for step in plan {
            XCTAssertLessThan(step.weight, 135.0)
        }
        
        // Should be sorted
        let weights = plan.map { $0.weight }
        XCTAssertEqual(weights, weights.sorted(), "Weights should be in ascending order")
    }
    
    func testMediumJump_TwoPlate() {
        // 225 lb (two plate) - medium jump
        // Span: 225 - 45 = 180 lb
        // Should give: bar + 2-3 warmup sets
        let plan = buildWarmupPlan(target: 225, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertGreaterThanOrEqual(plan.count, 3, "Medium jump should have 3+ sets")
        XCTAssertLessThanOrEqual(plan.count, 4, "Should never exceed 4 total sets")
        
        // Verify all intermediate weights
        for step in plan {
            XCTAssertLessThan(step.weight, 225.0)
            XCTAssertGreaterThanOrEqual(step.weight, standardBar)
        }
    }
    
    func testLargeJump_ThreePlate() {
        // 315 lb (three plate) - large jump
        // Span: 315 - 45 = 270 lb
        // Should give: bar + 3 warmup sets (max)
        let plan = buildWarmupPlan(target: 315, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertGreaterThanOrEqual(plan.count, 3, "Large jump should have multiple sets")
        XCTAssertLessThanOrEqual(plan.count, 4, "Should cap at 4 total sets")
        
        // Verify progression is reasonable
        for step in plan {
            XCTAssertLessThan(step.weight, 315.0)
        }
    }
    
    func testVeryLargeJump() {
        // 495 lb - very large jump
        // Should still cap at 4 total sets
        let plan = buildWarmupPlan(target: 495, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertLessThanOrEqual(plan.count, 4, "Should cap at 4 sets even for huge jumps")
        
        // Should have reasonable spacing
        let weights = plan.map { $0.weight }
        XCTAssertEqual(weights.first, standardBar)
        XCTAssertLessThan(weights.last!, 495.0)
    }
    
    // MARK: - Rep Scheme Tests
    
    func testRepSchemeBasedOnPercentage() {
        let target: Double = 315
        let plan = buildWarmupPlan(target: target, bar: standardBar, roundTo: roundTo, lift: .squat)

        // Sanity
        XCTAssertFalse(plan.isEmpty, "Plan should not be empty")

        var prevWeight = -Double.infinity
        var prevReps = Int.max

        for (idx, step) in plan.enumerated() {
            // Weights must strictly increase and remain < target (exclusive ramp)
            XCTAssertGreaterThan(step.weight, prevWeight, "Weights should increase monotonically")
            XCTAssertLessThan(step.weight, target, "Warmup step must be < target")

            if idx == 0 {
                // First set is always the bar ×10
                XCTAssertEqual(step.weight, standardBar, accuracy: roundTo, "First set should be the bar")
                XCTAssertEqual(step.reps, 10, "First (bar) set should be 10 reps")
            } else {
                // Reps should not increase as weight rises
                XCTAssertLessThanOrEqual(step.reps, prevReps, "Reps should not increase with weight")

                // Band mapping for *non-bar* warmups:
                // <60% → 8, 60–75% → 5, 75–87% → 3, ≥87% → 1
                let pct = step.weight / target
                switch pct {
                case ..<0.60:
                    XCTAssertEqual(step.reps, 8, "Light (<60%) should be 8 reps")
                case 0.60..<0.75:
                    XCTAssertEqual(step.reps, 5, "Medium (60–75%) should be 5 reps")
                case 0.75..<0.87:
                    XCTAssertEqual(step.reps, 3, "Heavy (75–87%) should be 3 reps")
                default:
                    XCTAssertEqual(step.reps, 1, "Very heavy (≥87%) should be 1 rep")
                }
            }

            prevWeight = step.weight
            prevReps = step.reps
        }
    }
    
    func testRepSchemesDecrease() {
        // Generally, reps should decrease or stay same as weight increases
        let plan = buildWarmupPlan(target: 315, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        for i in 1..<plan.count {
            // Weight increases
            XCTAssertGreaterThan(plan[i].weight, plan[i-1].weight)
            
            // Reps decrease or stay same
            XCTAssertLessThanOrEqual(plan[i].reps, plan[i-1].reps)
        }
    }
    
    // MARK: - Rounding Tests
    
    func testWeightsRoundedToIncrement() {
        let plan = buildWarmupPlan(target: 315, bar: standardBar, roundTo: 5.0, lift: .squat)
        
        for step in plan {
            // Check if weight is a multiple of 5
            let remainder = step.weight.truncatingRemainder(dividingBy: 5.0)
            XCTAssertEqual(remainder, 0.0, accuracy: 0.01, "Weight should be rounded to 5 lb")
        }
    }
    
    func testRoundingWithHalfIncrements() {
        // Test with 2.5 lb rounding
        let plan = buildWarmupPlan(target: 315, bar: standardBar, roundTo: 2.5, lift: .squat)
        
        for step in plan {
            // Check if weight is a multiple of 2.5
            let remainder = step.weight.truncatingRemainder(dividingBy: 2.5)
            XCTAssertEqual(remainder, 0.0, accuracy: 0.01, "Weight should be rounded to 2.5 lb")
        }
    }
    
    func testNoDuplicateWeightsAfterRounding() {
        // After rounding, there should be no duplicate weights
        let plan = buildWarmupPlan(target: 315, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        let weights = plan.map { $0.weight }
        let uniqueWeights = Set(weights)
        
        XCTAssertEqual(weights.count, uniqueWeights.count, "Should have no duplicate weights")
    }
    
    // MARK: - Edge Cases
    
    func testTargetEqualToBar() {
        // If target equals bar, should return just the bar
        let plan = buildWarmupPlan(target: standardBar, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.weight, standardBar)
        XCTAssertEqual(plan.first?.reps, 10)
    }
    
    func testTargetLessThanBar() {
        // If target is less than bar (invalid), should return just the bar
        let plan = buildWarmupPlan(target: 30, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.weight, standardBar)
    }
    
    func testVerySmallJump() {
        // Target just slightly above bar
        // Span: 55 - 45 = 10 lb (very small)
        let plan = buildWarmupPlan(target: 55, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        // Should handle gracefully - probably just bar
        XCTAssertGreaterThanOrEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.weight, standardBar)
        
        // All weights should be valid
        for step in plan {
            XCTAssertLessThan(step.weight, 55.0)
            XCTAssertGreaterThanOrEqual(step.weight, standardBar)
        }
    }
    
    func testInfiniteTarget() {
        // Invalid target should return safe default (bar)
        let plan = buildWarmupPlan(target: .infinity, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.weight, standardBar)
    }
    
    func testNaNTarget() {
        // NaN target should return safe default (bar)
        let plan = buildWarmupPlan(target: .nan, bar: standardBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.weight, standardBar)
    }
    
    func testInfiniteBar() {
        // Invalid bar should return safe default
        let plan = buildWarmupPlan(target: 225, bar: .infinity, roundTo: roundTo, lift: .squat)
        
        // Should handle gracefully and return something safe
        XCTAssertGreaterThanOrEqual(plan.count, 1)
    }
    
    // MARK: - Custom Bar Weights
    
    func testWomensBar() {
        // Women's bar is 35 lb
        let womensBar: Double = 35.0
        let plan = buildWarmupPlan(target: 135, bar: womensBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.first?.weight, womensBar)
        
        for step in plan {
            XCTAssertLessThan(step.weight, 135.0)
            XCTAssertGreaterThanOrEqual(step.weight, womensBar)
        }
    }
    
    func testSSBBar() {
        // Safety Squat Bar is typically 60-65 lb
        let ssbBar: Double = 60.0
        let plan = buildWarmupPlan(target: 315, bar: ssbBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.first?.weight, ssbBar)
        
        for step in plan {
            XCTAssertLessThan(step.weight, 315.0)
            XCTAssertGreaterThanOrEqual(step.weight, ssbBar)
        }
    }
    
    func testTrapBar() {
        // Trap bar is typically 45-60 lb
        let trapBar: Double = 55.0
        let plan = buildWarmupPlan(target: 405, bar: trapBar, roundTo: roundTo, lift: .squat)
        
        XCTAssertEqual(plan.first?.weight, trapBar)
        XCTAssertLessThanOrEqual(plan.count, 4)
    }
    
    // MARK: - Real-World Scenarios
    
    func testBeginnerOnePlateSquat() {
        // Beginner working up to 135 lb squat
        let plan = buildWarmupPlan(target: 135, bar: 45, roundTo: 5, lift: .squat)
        
        // Should have bar + warmups
        XCTAssertGreaterThanOrEqual(plan.count, 2)
        
        // First is bar
        XCTAssertEqual(plan.first?.weight, 45)
        XCTAssertEqual(plan.first?.reps, 10)
        
        // All should be < 135
        XCTAssertTrue(plan.allSatisfy { $0.weight < 135 })
    }
    
    func testIntermediateTwoPlateSquat() {
        // Intermediate working up to 225 lb
        let plan = buildWarmupPlan(target: 225, bar: 45, roundTo: 5, lift: .squat)
        
        XCTAssertGreaterThanOrEqual(plan.count, 3)
        XCTAssertLessThanOrEqual(plan.count, 4)
        
        // Should have good progression
        let weights = plan.map { $0.weight }
        XCTAssertEqual(weights.first, 45)
        XCTAssertLessThan(weights.last!, 225)
    }
    
    func testAdvancedFourPlateDeadlift() {
        // Advanced lifter working up to 405 lb deadlift
        // Should start at 135 for proper bar height, not 45
        let plan = buildWarmupPlan(target: 405, bar: 45, roundTo: 5, lift: .deadlift)
        
        // Should use maximum warmup sets (4)
        XCTAssertLessThanOrEqual(plan.count, 4)
        
        // Deadlifts with heavy target should start at 135, not 45
        XCTAssertEqual(plan.first?.weight, 135, "Heavy deadlifts should start at 135 for proper bar height")
        
        // Verify progression makes sense
        for i in 1..<plan.count {
            let jump = plan[i].weight - plan[i-1].weight
            XCTAssertGreaterThan(jump, 0, "Weight should increase")
            XCTAssertLessThan(jump, 150, "Jumps should be reasonable")
        }
    }
    
    func testEliteFivePlateDeadlift() {
        // Elite lifter working up to 495 lb deadlift
        let plan = buildWarmupPlan(target: 495, bar: 45, roundTo: 5, lift: .deadlift)
        
        // Should cap at 4 sets
        XCTAssertLessThanOrEqual(plan.count, 4)
        
        // Should start at 135 for heavy deadlifts
        XCTAssertEqual(plan.first?.weight, 135)
        
        // All should be less than target
        XCTAssertTrue(plan.allSatisfy { $0.weight < 495 })
    }
    
    // MARK: - Deadlift-Specific Behavior
    
    func testDeadliftStartsAt135ForHeavyLifters() {
        // Deadlifts need proper bar height - 45 lb plates
        // For targets >= 225, should start at 135 minimum
        let heavyTargets = [225.0, 315.0, 405.0, 495.0]
        
        for target in heavyTargets {
            let plan = buildWarmupPlan(target: target, bar: 45, roundTo: 5, lift: .deadlift)
            XCTAssertEqual(plan.first?.weight, 135,
                         "Deadlift with target \(target) should start at 135, not 45")
        }
    }
    
    func testDeadliftStartsAtBarForLightLifters() {
        // For beginners (target < 225), still start at bar
        let plan = buildWarmupPlan(target: 185, bar: 45, roundTo: 5, lift: .deadlift)
        XCTAssertEqual(plan.first?.weight, 45,
                     "Light deadlifts (<225 lb) should still start at bar")
    }
    
    func testOtherLiftsNotAffectedByDeadliftLogic() {
        // Squat, bench, etc. should still start at bar even for heavy weights
        let lifts: [Lift] = [.squat, .bench, .press, .row]
        
        for lift in lifts {
            let plan = buildWarmupPlan(target: 405, bar: 45, roundTo: 5, lift: lift)
            XCTAssertEqual(plan.first?.weight, 45,
                         "\(lift) should start at bar, not 135")
        }
    }
    
    // MARK: - Consistency Tests
    
    func testConsistentOutputForSameInputs() {
        // Same inputs should always give same output
        let plan1 = buildWarmupPlan(target: 315, bar: 45, roundTo: 5, lift: .squat)
        let plan2 = buildWarmupPlan(target: 315, bar: 45, roundTo: 5, lift: .squat)
        
        XCTAssertEqual(plan1.count, plan2.count)
        
        for (step1, step2) in zip(plan1, plan2) {
            XCTAssertEqual(step1.weight, step2.weight)
            XCTAssertEqual(step1.reps, step2.reps)
        }
    }
    
    func testStrictlyIncreasing() {
        // All plans should have strictly increasing weights
        let targets = [135.0, 225.0, 315.0, 405.0, 495.0]
        
        for target in targets {
            let plan = buildWarmupPlan(target: target, bar: 45, roundTo: 5, lift: .squat)
            
            for i in 1..<plan.count {
                XCTAssertGreaterThan(plan[i].weight, plan[i-1].weight,
                                   "Weights must strictly increase for target \(target)")
            }
        }
    }
    
    // MARK: - WarmupStep Tests
    
    func testWarmupStepEquality() {
        let step1 = WarmupStep(weight: 135, reps: 5)
        let step2 = WarmupStep(weight: 135, reps: 5)
        
        // Same weight and reps should be equal (ignoring UUID)
        XCTAssertEqual(step1.weight, step2.weight)
        XCTAssertEqual(step1.reps, step2.reps)
    }
    
    func testWarmupStepHasUniqueID() {
        let step1 = WarmupStep(weight: 135, reps: 5)
        let step2 = WarmupStep(weight: 135, reps: 5)
        
        // IDs should be different even for same weight/reps
        XCTAssertNotEqual(step1.id, step2.id)
    }
}
