//
//  PRServiceTests.swift
//  BeyondNormalTests
//
//  Test suite for PRService.swift
//  Covers: PR detection, 1RM estimation, data persistence
//

import XCTest
@testable import BeyondNormal

// MARK: - 1RM Formula Tests

final class E1RMFormulaTests: XCTestCase {
    
    // MARK: - Epley Formula Tests
    
    func testEpleyFormulaBasic() {
        // Epley: 1RM = weight * (1 + reps/30)
        // 225 lb × 8 reps = 225 * (1 + 8/30) = 225 * 1.267 = 285 lb
        let result = estimate1RM(weight: 225, reps: 8, using: .epley)
        XCTAssertEqual(result, 285.0, accuracy: 0.1)
    }
    
    func testEpleySingleRep() {
        // Single rep should return the weight itself
        let result = estimate1RM(weight: 315, reps: 1, using: .epley)
        XCTAssertEqual(result, 315.0)
    }
    
    func testEpleyLowReps() {
        // 315 lb × 3 reps
        let result = estimate1RM(weight: 315, reps: 3, using: .epley)
        XCTAssertEqual(result, 346.5, accuracy: 0.1)
    }
    
    func testEpleyHighReps() {
        // 185 lb × 12 reps
        let result = estimate1RM(weight: 185, reps: 12, using: .epley)
        XCTAssertEqual(result, 259.0, accuracy: 0.1)
    }
    
    // MARK: - Brzycki Formula Tests
    
    func testBrzyckiFormulaBasic() {
        // Brzycki: 1RM = weight * (36 / (37 - reps))
        // 225 lb × 8 reps = 225 * (36 / 29) = 279.3 lb
        let result = estimate1RM(weight: 225, reps: 8, using: .brzycki)
        XCTAssertEqual(result, 279.3, accuracy: 0.5)
    }
    
    func testBrzyckiSingleRep() {
        let result = estimate1RM(weight: 315, reps: 1, using: .brzycki)
        XCTAssertEqual(result, 315.0)
    }
    
    func testBrzyckiMoreAggressiveAtHighReps() {
        // Brzycki should be higher than Epley at higher reps
        let epley = estimate1RM(weight: 200, reps: 15, using: .epley)
        let brzycki = estimate1RM(weight: 200, reps: 15, using: .brzycki)
        
        XCTAssertLessThan(epley, brzycki, "Brzycki should be higher")
    }
    
    // MARK: - Lombardi Formula Tests
    
    func testLombardiFormulaBasic() {
        // Lombardi: 1RM = weight * reps^0.10
        let result = estimate1RM(weight: 225, reps: 8, using: .lombardi)
        XCTAssertGreaterThan(result, 225.0)
        XCTAssertLessThan(result, 300.0)
    }
    
    func testLombardiSingleRep() {
        let result = estimate1RM(weight: 315, reps: 1, using: .lombardi)
        XCTAssertEqual(result, 315.0)
    }
    
    // MARK: - Edge Cases
    
    func testZeroReps() {
        // reps <= 1 should return weight
        let result = estimate1RM(weight: 225, reps: 0, using: .epley)
        XCTAssertEqual(result, 225.0)
    }
    
    func testNegativeReps() {
        let result = estimate1RM(weight: 225, reps: -5, using: .epley)
        XCTAssertEqual(result, 225.0)
    }
}

// MARK: - PRService Tests

final class PRServiceTests: XCTestCase {
    
    var service: PRService!
    let testDate = Date()
    
    override func setUp() {
        super.setUp()
        // Create a fresh service instance for each test
        service = PRService()
        
        // Clear any existing PRs from UserDefaults
        UserDefaults.standard.removeObject(forKey: "stored_prs_v1")
        service = PRService() // Reinitialize after clearing
    }
    
    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "stored_prs_v1")
        service = nil
        super.tearDown()
    }
    
    // MARK: - First PR Detection
    
    func testFirstPRIsDetected() {
        // First PR should always be recorded
        let entry = LiftEntry(lift: .deadlift, weightLB: 315, reps: 5, date: testDate)
        let pr = service.updateIfPR(entry: entry, metric: .estimatedOneRM, formula: .epley)
        
        XCTAssertNotNil(pr, "First PR should be detected")
        XCTAssertEqual(pr?.lift, .deadlift)
        XCTAssertEqual(pr?.metric, .estimatedOneRM)
        XCTAssertGreaterThan(pr?.value ?? 0, 315.0)
    }
    
    func testFirstOneRMPR() {
        // Test actual 1RM (single rep)
        let entry = LiftEntry(lift: .bench, weightLB: 225, reps: 1, date: testDate)
        let pr = service.updateIfPR(entry: entry, metric: .oneRM, formula: .epley)
        
        XCTAssertNotNil(pr)
        XCTAssertEqual(pr?.value, 225.0)
        XCTAssertEqual(pr?.metric, .oneRM)
    }
    
    // MARK: - PR Threshold (0.5 lb margin)
    
    func testPRRequiresHalfPoundMargin() {
        // Set initial PR
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .squat, weightLB: 300, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Try to set PR with only 0.4 lb improvement (should fail)
        let notAPR = service.updateIfPR(
            entry: LiftEntry(lift: .squat, weightLB: 300.4, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        XCTAssertNil(notAPR, "Should not be a PR with < 0.5 lb improvement")
    }
    
    func testPRWithExactlyHalfPound() {
        // Set initial PR
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .squat, weightLB: 300, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Try with exactly 0.5 lb improvement (should succeed)
        let pr = service.updateIfPR(
            entry: LiftEntry(lift: .squat, weightLB: 300.5, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        XCTAssertNotNil(pr, "Should be a PR with exactly 0.5 lb improvement")
        XCTAssertEqual(pr?.value, 300.5)
    }
    
    func testPRWithMoreThanHalfPound() {
        // Set initial PR
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .bench, weightLB: 225, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Try with 5 lb improvement
        let pr = service.updateIfPR(
            entry: LiftEntry(lift: .bench, weightLB: 230, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        XCTAssertNotNil(pr)
        XCTAssertEqual(pr?.value, 230.0)
    }
    
    // MARK: - Multiple Lifts Independence
    
    func testDifferentLiftsTrackedIndependently() {
        // Set PR for deadlift
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .deadlift, weightLB: 400, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Set PR for squat (should not interfere)
        let squatPR = service.updateIfPR(
            entry: LiftEntry(lift: .squat, weightLB: 350, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        XCTAssertNotNil(squatPR, "Different lifts should be independent")
        
        // Verify both exist
        let deadliftBest = service.best(for: .deadlift, metric: .oneRM)
        let squatBest = service.best(for: .squat, metric: .oneRM)
        
        XCTAssertEqual(deadliftBest?.value, 400.0)
        XCTAssertEqual(squatBest?.value, 350.0)
    }
    
    // MARK: - Metric Independence (oneRM vs estimatedOneRM)
    
    func testOneRMAndEstimatedOneRMTrackedSeparately() {
        // Set actual 1RM PR
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .bench, weightLB: 225, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Set estimated 1RM PR (from multiple reps)
        let estimatedPR = service.updateIfPR(
            entry: LiftEntry(lift: .bench, weightLB: 205, reps: 8, date: testDate),
            metric: .estimatedOneRM,
            formula: .epley
        )
        
        XCTAssertNotNil(estimatedPR, "Different metrics should be independent")
        
        // Verify both exist
        let oneRMBest = service.best(for: .bench, metric: .oneRM)
        let estimatedBest = service.best(for: .bench, metric: .estimatedOneRM)
        
        XCTAssertEqual(oneRMBest?.value, 225.0)
        XCTAssertGreaterThan(estimatedBest?.value ?? 0, 225.0) // Estimated should be higher
    }
    
    // MARK: - Formula Selection
    
    func testDifferentFormulasGiveDifferentEstimates() {
        let entry = LiftEntry(lift: .deadlift, weightLB: 315, reps: 8, date: testDate)
        
        // Use Epley
        let epleyPR = service.updateIfPR(entry: entry, metric: .estimatedOneRM, formula: .epley)
        let epleyValue = epleyPR?.value ?? 0
        
        // Reset
        UserDefaults.standard.removeObject(forKey: "stored_prs_v1")
        service = PRService()
        
        // Use Brzycki
        let brzyckiPR = service.updateIfPR(entry: entry, metric: .estimatedOneRM, formula: .brzycki)
        let brzyckiValue = brzyckiPR?.value ?? 0
        
        // They should be different
        XCTAssertNotEqual(epleyValue, brzyckiValue, accuracy: 1.0)
    }
    
    // MARK: - Best PR Retrieval
    
    func testBestReturnsHighestValue() {
        // Add multiple PRs for same lift/metric
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .press, weightLB: 135, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .press, weightLB: 140, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .press, weightLB: 145, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        let best = service.best(for: .press, metric: .oneRM)
        XCTAssertEqual(best?.value, 145.0)
    }
    
    func testBestReturnsNilWhenNoPRs() {
        let best = service.best(for: .row, metric: .oneRM)
        XCTAssertNil(best, "Should return nil when no PRs exist")
    }
    
    // MARK: - Data Persistence
    
    func testPRsPersistAcrossInstances() {
        // Add a PR
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .deadlift, weightLB: 500, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Create new service instance (should load from UserDefaults)
        let newService = PRService()
        
        let best = newService.best(for: .deadlift, metric: .oneRM)
        XCTAssertEqual(best?.value, 500.0, "PRs should persist across instances")
    }
    
    func testMultiplePRsPersist() {
        // Add PRs for multiple lifts
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .squat, weightLB: 405, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .bench, weightLB: 315, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        _ = service.updateIfPR(
            entry: LiftEntry(lift: .deadlift, weightLB: 495, reps: 1, date: testDate),
            metric: .oneRM,
            formula: .epley
        )
        
        // Create new instance
        let newService = PRService()
        
        XCTAssertEqual(newService.best(for: .squat, metric: .oneRM)?.value, 405.0)
        XCTAssertEqual(newService.best(for: .bench, metric: .oneRM)?.value, 315.0)
        XCTAssertEqual(newService.best(for: .deadlift, metric: .oneRM)?.value, 495.0)
    }
    
    // MARK: - Date Tracking
    
    func testPRIncludesDate() {
        let specificDate = Date(timeIntervalSince1970: 1700000000) // Nov 2023
        let entry = LiftEntry(lift: .bench, weightLB: 225, reps: 1, date: specificDate)
        
        let pr = service.updateIfPR(entry: entry, metric: .oneRM, formula: .epley)
        
        XCTAssertNotNil(pr)
        if let prDate = pr?.date {
            XCTAssertEqual(prDate.timeIntervalSince1970, specificDate.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("PR should have a date")
        }
    }
    
    // MARK: - Progress Over Time
    
    func testProgressiveOverload() {
        // Simulate progression over multiple sessions
        let dates = [
            Date(timeIntervalSince1970: 1700000000), // Week 1
            Date(timeIntervalSince1970: 1700604800), // Week 2
            Date(timeIntervalSince1970: 1701209600), // Week 3
        ]
        
        // Week 1: 135 lb
        let pr1 = service.updateIfPR(
            entry: LiftEntry(lift: .press, weightLB: 135, reps: 1, date: dates[0]),
            metric: .oneRM,
            formula: .epley
        )
        XCTAssertNotNil(pr1)
        
        // Week 2: 140 lb (should be PR)
        let pr2 = service.updateIfPR(
            entry: LiftEntry(lift: .press, weightLB: 140, reps: 1, date: dates[1]),
            metric: .oneRM,
            formula: .epley
        )
        XCTAssertNotNil(pr2)
        
        // Week 3: 145 lb (should be PR)
        let pr3 = service.updateIfPR(
            entry: LiftEntry(lift: .press, weightLB: 145, reps: 1, date: dates[2]),
            metric: .oneRM,
            formula: .epley
        )
        XCTAssertNotNil(pr3)
        
        // Best should be most recent
        let best = service.best(for: .press, metric: .oneRM)
        XCTAssertEqual(best?.value, 145.0)
    }
    
    // MARK: - All Lift Types
    
    func testAllLiftTypes() {
        let lifts: [LiftType] = [.deadlift, .squat, .bench, .press, .row]
        
        for (index, lift) in lifts.enumerated() {
            let weight = Double(200 + index * 25)
            let pr = service.updateIfPR(
                entry: LiftEntry(lift: lift, weightLB: weight, reps: 1, date: testDate),
                metric: .oneRM,
                formula: .epley
            )
            
            XCTAssertNotNil(pr, "Should track PRs for \(lift)")
            XCTAssertEqual(pr?.value, weight)
        }
    }
    
    // MARK: - Edge Cases
    
    func testVeryHighReps() {
        // Test with 20 reps (high rep set)
        let entry = LiftEntry(lift: .squat, weightLB: 135, reps: 20, date: testDate)
        let pr = service.updateIfPR(entry: entry, metric: .estimatedOneRM, formula: .epley)
        
        XCTAssertNotNil(pr)
        XCTAssertGreaterThan(pr?.value ?? 0, 135.0)
    }
    
    func testZeroWeight() {
        let entry = LiftEntry(lift: .bench, weightLB: 0, reps: 5, date: testDate)
        let pr = service.updateIfPR(entry: entry, metric: .estimatedOneRM, formula: .epley)
        
        // PRs require effort!
        XCTAssertNil(pr)
    }
    
    func testSingleRepWithOneRMMetric() {
        // When metric is oneRM and reps is 1, value should equal weight exactly
        let entry = LiftEntry(lift: .deadlift, weightLB: 405, reps: 1, date: testDate)
        let pr = service.updateIfPR(entry: entry, metric: .oneRM, formula: .epley)
        
        XCTAssertEqual(pr?.value, 405.0, "Single rep with oneRM metric should use weight directly")
    }
    
    func testSingleRepWithEstimatedMetric() {
        // When metric is estimatedOneRM but reps is 1, formula shouldn't be applied
        let entry = LiftEntry(lift: .bench, weightLB: 225, reps: 1, date: testDate)
        let pr = service.updateIfPR(entry: entry, metric: .estimatedOneRM, formula: .epley)
        
        // Single rep still returns weight (guard in estimate1RM)
        XCTAssertEqual(pr?.value, 225.0)
    }
}
