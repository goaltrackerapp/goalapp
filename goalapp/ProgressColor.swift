//
//  ProgressColor.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

/// Маппинг прогресса (0.0–1.0) в цвет заливки яйца.
/// От красного (0%) → жёлтый (середина) → зелёный (100%).
enum ProgressColor {
    static func color(for progress: Double) -> Color {
        let p = max(0, min(1, progress))

        switch p {
        case 0.0..<0.25:
            return Color.red.opacity(0.8)
        case 0.25..<0.5:
            return Color.orange.opacity(0.85)
        case 0.5..<0.75:
            return Color.yellow.opacity(0.9)
        case 0.75..<1.0:
            return Color.green.opacity(0.85)
        default:
            return Color.green
        }
    }
}
