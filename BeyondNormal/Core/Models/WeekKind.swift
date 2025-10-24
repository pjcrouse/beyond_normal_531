//
//  WeekKind.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/24/25.
//

// Core/Models/WeekKind.swift
import Foundation

/// Represents the core 5/3/1 week scheme.
public enum WeekKind: String, Codable, CaseIterable {
    case five
    case three
    case one
}
