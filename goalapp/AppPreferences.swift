//
//  AppPreferences.swift
//  goalapp
//  Created by Elliot Cooper
//

import Foundation
import Combine

/// Централизованные настройки приложения (например, Haptics).
/// Хранит значения в UserDefaults и транслирует изменения через @Published.
final class AppPreferences: ObservableObject {

    // MARK: - Singleton

    static let shared = AppPreferences()

    // MARK: - Keys

    private struct Keys {
        static let hapticsEnabled = "prefs.hapticsEnabled"
        static let firstLaunch    = "prefs.firstLaunchDone"
    }

    // MARK: - Published

    /// Включены ли вибро-отклики в приложении.
    @Published var hapticsEnabled: Bool = true {
        didSet { saveHapticsEnabled() }
    }

    // MARK: - Init

    private init() {
        loadPreferences()
        performFirstLaunchIfNeeded()
    }

    // MARK: - Public API

    /// Быстрое переключение тумблера Haptics.
    func toggleHaptics() {
        hapticsEnabled.toggle()
    }

    /// Версия приложения (Marketing Version) + Build.
    var appVersionString: String {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(ver) (\(build))"
    }

    // MARK: - Persistence

    private func loadPreferences() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.hapticsEnabled) == nil {
            // Значение по умолчанию: true
            hapticsEnabled = true
            saveHapticsEnabled()
        } else {
            hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        }
    }

    private func saveHapticsEnabled() {
        let defaults = UserDefaults.standard
        defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
    }

    private func performFirstLaunchIfNeeded() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Keys.firstLaunch) {
            // Точка для первичной инициализации настроек при самом первом запуске
            if defaults.object(forKey: Keys.hapticsEnabled) == nil {
                defaults.set(true, forKey: Keys.hapticsEnabled)
            }
            defaults.set(true, forKey: Keys.firstLaunch)
        }
    }

    // MARK: - Utilities

    /// Сброс к значениям по умолчанию (не используется автоматически).
    func resetToDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.hapticsEnabled)
        defaults.removeObject(forKey: Keys.firstLaunch)
        loadPreferences()
    }
}
