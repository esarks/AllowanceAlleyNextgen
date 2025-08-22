//
//  Chore+Compat.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/21/25.
//
import Foundation

// Back-compat shim: map UI's `description` to the model's actual field.
extension Chore {
    /// Returns the chore’s human description. Works whether the model names it
    /// `description` or `choreDescription`.
    var description: String? {
        // If the model already has `description`, prefer it (no crash/clash).
        if let existing = (Mirror(reflecting: self).children.first { $0.label == "description" }?.value as? String) {
            return existing
        }
        // Otherwise fall back to a commonly-used name in this codebase.
        return Mirror(reflecting: self).children.first { $0.label == "choreDescription" }?.value as? String
    }
}

