//
//  HapticsManager.swift
//  goalapp
//  Created by Elliot Cooper
//

import Foundation
import UIKit

/// Отвечает за воспроизведение виброоткликов (haptics) в приложении.
/// Перед каждым вызовом проверяет, включены ли Haptics в AppPreferences.
enum HapticsManager {

    /// Лёгкий отклик (например, нажатие кнопки).
    static func lightImpact() {
        guard AppPreferences.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Жёсткий отклик (например, успешное действие).
    static func rigidImpact() {
        guard AppPreferences.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// Средний отклик (универсальный).
    static func mediumImpact() {
        guard AppPreferences.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Отклик при успехе (уведомление).
    static func success() {
        guard AppPreferences.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Отклик при ошибке (уведомление).
    static func error() {
        guard AppPreferences.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Отклик при предупреждении.
    static func warning() {
        guard AppPreferences.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
