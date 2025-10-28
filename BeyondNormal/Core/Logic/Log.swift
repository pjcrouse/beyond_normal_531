//
//  Log.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/28/25.
//

import Foundation
import os

// Lightweight debug logger. Works like print() in Debug builds, no-op in Release.
#if DEBUG
@inline(__always)
func dlog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let message = items.map { String(describing: $0) }.joined(separator: separator)
    print(message, terminator: terminator)
}
#else
@inline(__always)
func dlog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // no-op in release builds
}
#endif

// Optional: structured logger for production diagnostics.
// Example:
// let logger = AppLogger.general
// logger.error("Failed to export: \(error.localizedDescription)")
enum AppLogger {
    static let general = Logger(subsystem: "com.beyondnormal.app", category: "general")
    static let export  = Logger(subsystem: "com.beyondnormal.app", category: "export")
    static let data    = Logger(subsystem: "com.beyondnormal.app", category: "data")
}
