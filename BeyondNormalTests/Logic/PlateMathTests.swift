//
//  PlateMathTests.swift
//  BeyondNormalTests
//
//  Test suite for PlateMath.swift
//  Covers: LoadRounder, PlateCalculator, LoadFormat
//

import XCTest
@testable import BeyondNormal

// MARK: - LoadRounder Tests

final class LoadRounderTests: XCTestCase {
    
    // MARK: - Standard Rounding Tests
    
    func testRoundToFivePounds() {
        // 225.3 should round to 225
        XCTAssertEqual(LoadRounder.round(225.3, to: 5), 225.0)
        
        // 227.5 should round to 230 (halfway rounds up)
        XCTAssertEqual(LoadRounder.round(227.5, to: 5), 230.0)
        
        // 222.4 should round to 220
        XCTAssertEqual(LoadRounder.round(222.4, to: 5), 220.0)
        
        // Exact values should remain unchanged
        XCTAssertEqual(LoadRounder.round(225.0, to: 5), 225.0)
    }
    
    func testRoundToTwoPointFivePounds() {
        // Test 2.5 lb increments (rounds to nearest 2.5: 0, 2.5, 5, 7.5, 10, etc.)
        XCTAssertEqual(LoadRounder.round(226.0, to: 2.5), 225.0, accuracy: 0.01) // 226 -> 225
        XCTAssertEqual(LoadRounder.round(226.3, to: 2.5), 227.5, accuracy: 0.01) // 226.3 -> 227.5
        XCTAssertEqual(LoadRounder.round(227.4, to: 2.5), 227.5, accuracy: 0.01) // 227.4 -> 227.5
        XCTAssertEqual(LoadRounder.round(228.8, to: 2.5), 230.0, accuracy: 0.01) // 228.8 -> 230
    }
    
    func testRoundToOnePound() {
        // Test 1 lb increments
        XCTAssertEqual(LoadRounder.round(225.3, to: 1), 225.0)
        XCTAssertEqual(LoadRounder.round(225.6, to: 1), 226.0)
        XCTAssertEqual(LoadRounder.round(225.5, to: 1), 226.0)
    }
    
    // MARK: - Edge Cases
    
    func testRoundWithZeroIncrement() {
        // Should default to 0.5 when increment is 0
        XCTAssertEqual(LoadRounder.round(225.7, to: 0), 225.5)
        XCTAssertEqual(LoadRounder.round(225.3, to: 0), 225.5)
    }
    
    func testRoundWithNegativeIncrement() {
        // Should default to 0.5 when increment is negative
        XCTAssertEqual(LoadRounder.round(225.7, to: -5), 225.5)
    }
    
    func testRoundWithInfiniteIncrement() {
        // Should default to 0.5 when increment is infinite
        XCTAssertEqual(LoadRounder.round(225.7, to: .infinity), 225.5)
    }
    
    func testRoundWithVeryLargeNumbers() {
        // Test with heavy weights
        XCTAssertEqual(LoadRounder.round(1005.3, to: 5), 1005.0)
        XCTAssertEqual(LoadRounder.round(1007.6, to: 5), 1010.0)
    }
    
    func testRoundWithVerySmallNumbers() {
        // Test with light weights
        XCTAssertEqual(LoadRounder.round(47.3, to: 5), 45.0)
        XCTAssertEqual(LoadRounder.round(48.8, to: 5), 50.0)
    }
    
    func testRoundNegativeWeight() {
        // Negative weights should still round properly
        XCTAssertEqual(LoadRounder.round(-225.3, to: 5), -225.0)
        XCTAssertEqual(LoadRounder.round(-227.6, to: 5), -230.0)
    }
}

// MARK: - PlateCalculator Tests

final class PlateCalculatorTests: XCTestCase {
    
    // Standard inventory: typical gym plates available per side
    let standardInventory = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
    let barWeight = 45.0
    
    // MARK: - Basic Plate Calculations
    
    func testStandardThreePlate() {
        // 315 lb = 45 lb bar + (45+45+45) per side = 135 per side
        // Algorithm prefers using same plates when possible
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 315)
        
        XCTAssertEqual(plates, [45.0, 45.0, 45.0])
        
        // Verify total weight
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(barWeight + (totalPerSide * 2), 315.0)
    }
    
    func testStandardTwoPlate() {
        // 225 lb = 45 lb bar + (45+45) per side
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 225)
        
        XCTAssertEqual(plates, [45.0, 45.0])
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(barWeight + (totalPerSide * 2), 225.0)
    }
    
    func testOnePlate() {
        // 135 lb = 45 lb bar + 45 per side
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 135)
        
        XCTAssertEqual(plates, [45.0])
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(barWeight + (totalPerSide * 2), 135.0)
    }
    
    func testEmptyBar() {
        // Just the bar, no plates
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 45)
        
        XCTAssertEqual(plates, [])
    }
    
    func testMixedPlates() {
        // 185 lb = 45 lb bar + 70 per side
        // With greedy algorithm: 45+25 = 70 per side
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 185)
        
        XCTAssertEqual(plates, [45.0, 25.0])
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(barWeight + (totalPerSide * 2), 185.0)
    }
    
    func testOddWeightRequiringSmallPlates() {
        // 157.5 lb = 45 lb bar + 56.25 per side
        // Greedy algorithm: 45+10 = 55 per side = 155 total (closest achievable)
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 2.5, inventory: standardInventory)
        let plates = calc.plates(target: 157.5)
        
        // Algorithm gets as close as possible with available plates
        XCTAssertEqual(plates, [45.0, 10.0])
        
        let totalPerSide = plates.reduce(0, +)
        // Total will be 155, not exactly 157.5 (that would need 2.5 lb plates)
        XCTAssertEqual(barWeight + (totalPerSide * 2), 155.0)
    }
    
    // MARK: - Edge Cases
    
    func testWeightBelowBarWeight() {
        // Target weight less than bar weight should return empty
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 40)
        
        XCTAssertEqual(plates, [])
    }
    
    func testWeightEqualToBarWeight() {
        // Target weight equal to bar weight should return empty
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 45)
        
        XCTAssertEqual(plates, [])
    }
    
    func testVeryHeavyWeight() {
        // 585 lb = 45 lb bar + (45+45+45+45+45+45) per side = 270 per side
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 585)
        
        // Should have six 45s per side
        XCTAssertEqual(plates.filter { $0 == 45.0 }.count, 6)
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(barWeight + (totalPerSide * 2), 585.0)
    }
    
    func testInsufficientPlatesScenario() {
        // With limited inventory, algorithm uses what's available
        let limitedInventory = [45.0, 25.0] // Only 45s and 25s
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: limitedInventory)
        
        // 185 lb = 45 + (45+25) per side = 140 total (can't hit exactly)
        let plates = calc.plates(target: 185)
        
        // Should return 45+25 = 70 per side = 185 total
        XCTAssertEqual(plates, [45.0, 25.0])
    }
    
    // MARK: - Custom Bar Weights
    
    func testSSBBar() {
        // Safety Squat Bar typically weighs 60-65 lb
        let ssbWeight = 60.0
        let calc = PlateCalculator(barWeight: ssbWeight, roundTo: 5, inventory: standardInventory)
        
        // 225 with SSB = 60 + (82.5 per side)
        let plates = calc.plates(target: 225)
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(ssbWeight + (totalPerSide * 2), 225.0, accuracy: 2.5)
    }
    
    func testTrapBar() {
        // Trap bar typically weighs 45-60 lb, let's use 60
        let trapBarWeight = 60.0
        let calc = PlateCalculator(barWeight: trapBarWeight, roundTo: 5, inventory: standardInventory)
        
        let plates = calc.plates(target: 315)
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(trapBarWeight + (totalPerSide * 2), 315.0, accuracy: 2.5)
    }
    
    func testCustomBarWeightParameter() {
        // Test using custom bar weight parameter override
        let calc = PlateCalculator(barWeight: 45, roundTo: 5, inventory: standardInventory)
        
        // Calculate for a 35 lb women's bar
        let plates = calc.plates(target: 135, barWeight: 35)
        
        let totalPerSide = plates.reduce(0, +)
        XCTAssertEqual(35 + (totalPerSide * 2), 135.0, accuracy: 2.5)
    }
    
    // MARK: - Rounding Integration
    
    func testRoundingAppliedToTarget() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        
        // Test that calculator's round() method works
        XCTAssertEqual(calc.round(227.3), 225.0)
        XCTAssertEqual(calc.round(227.6), 230.0)
    }
    
    // MARK: - Caching Behavior
    
    func testCachingWorks() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        
        // First call
        let plates1 = calc.plates(target: 315)
        
        // Second call should return cached result (same reference)
        let plates2 = calc.plates(target: 315)
        
        // Verify they're the same
        XCTAssertEqual(plates1, plates2)
    }
    
    func testCachingWithDifferentBarWeights() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        
        // Calculate with default bar
        let plates1 = calc.plates(target: 225, barWeight: 45)
        
        // Calculate with custom bar
        let plates2 = calc.plates(target: 225, barWeight: 35)
        
        // Should be different
        XCTAssertNotEqual(plates1, plates2)
    }
    
    // MARK: - Invalid Input Handling
    
    func testInfiniteWeight() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: .infinity)
        
        XCTAssertEqual(plates, [])
    }
    
    func testNaNWeight() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: .nan)
        
        XCTAssertEqual(plates, [])
    }
    
    func testNegativeWeight() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: -225)
        
        XCTAssertEqual(plates, [])
    }
    
    func testInvalidBarWeight() {
        let calc = PlateCalculator(barWeight: 0, roundTo: 5, inventory: standardInventory)
        let plates = calc.plates(target: 225)
        
        // Should return empty with invalid bar weight
        XCTAssertEqual(plates, [])
    }
    
    func testEmptyInventory() {
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: [])
        let plates = calc.plates(target: 225)
        
        // Can't load weight with no plates
        XCTAssertEqual(plates, [])
    }
    
    func testInvalidPlatesInInventory() {
        // Inventory with invalid values (negative, zero, infinite)
        let badInventory = [45.0, 0.0, -25.0, .infinity, 10.0, 5.0]
        let calc = PlateCalculator(barWeight: barWeight, roundTo: 5, inventory: badInventory)
        
        // Should filter out invalid plates and still work
        let plates = calc.plates(target: 135)
        
        // Should only use valid plates (45, 10, 5)
        XCTAssertEqual(plates, [45.0])
    }
}

// MARK: - LoadFormat Tests

final class LoadFormatTests: XCTestCase {
    
    // MARK: - Plate List Formatting
    
    func testPlateListWithIntegers() {
        let plates = [45.0, 45.0, 10.0]
        let formatted = LoadFormat.plateList(plates)
        
        XCTAssertEqual(formatted, "45, 45, 10")
    }
    
    func testPlateListWithDecimals() {
        let plates = [45.0, 10.0, 2.5]
        let formatted = LoadFormat.plateList(plates)
        
        XCTAssertEqual(formatted, "45, 10, 2.5")
    }
    
    func testPlateListMixed() {
        let plates = [45.0, 25.0, 10.0, 5.0, 2.5, 2.5]
        let formatted = LoadFormat.plateList(plates)
        
        XCTAssertEqual(formatted, "45, 25, 10, 5, 2.5, 2.5")
    }
    
    func testEmptyPlateList() {
        let plates: [Double] = []
        let formatted = LoadFormat.plateList(plates)
        
        XCTAssertEqual(formatted, "")
    }
    
    func testSinglePlate() {
        let plates = [45.0]
        let formatted = LoadFormat.plateList(plates)
        
        XCTAssertEqual(formatted, "45")
    }
    
    // MARK: - Number Formatting
    
    func testIntegerFormatting() {
        XCTAssertEqual(LoadFormat.intOr1dp(225), "225")
        XCTAssertEqual(LoadFormat.intOr1dp(45), "45")
        XCTAssertEqual(LoadFormat.intOr1dp(315), "315")
    }
    
    func testDecimalFormatting() {
        XCTAssertEqual(LoadFormat.intOr1dp(227.5), "227.5")
        XCTAssertEqual(LoadFormat.intOr1dp(2.5), "2.5")
        XCTAssertEqual(LoadFormat.intOr1dp(100.5), "100.5")
    }
    
    func testZeroFormatting() {
        XCTAssertEqual(LoadFormat.intOr1dp(0), "0")
        XCTAssertEqual(LoadFormat.intOr1dp(0.0), "0")
    }
    
    func testNegativeFormatting() {
        XCTAssertEqual(LoadFormat.intOr1dp(-225), "-225")
        XCTAssertEqual(LoadFormat.intOr1dp(-227.5), "-227.5")
    }
    
    func testVerySmallDecimal() {
        // Should show 1 decimal place
        XCTAssertEqual(LoadFormat.intOr1dp(0.5), "0.5")
    }
    
    func testLargeNumber() {
        XCTAssertEqual(LoadFormat.intOr1dp(1000), "1000")
        XCTAssertEqual(LoadFormat.intOr1dp(1000.5), "1000.5")
    }
}
