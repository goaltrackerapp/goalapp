//
//  AchievementsManager.swift
//  goalapp
//  Created by Elliot Cooper
//

import Foundation
import Combine

/// Описание одного достижения
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let points: Int
}

/// Менеджер геймификации: отслеживает прогресс по целям и открывает ачивки.
/// Сохраняет прогресс в UserDefaults.
final class AchievementsManager: ObservableObject {

    // MARK: - Public @Published

    @Published private(set) var unlocked: Set<String> = []
    @Published private(set) var recentlyUnlocked: [Achievement] = []

    // MARK: - Private

    private let store: GoalStore
    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "achievements_unlocked_ids"

    // Все возможные достижения (можно расширять)
    private let catalog: [Achievement] = [
        Achievement(id: "first_goal_created",
                    title: "First Nest",
                    detail: "Create your first savings goal.",
                    systemImage: "egg",
                    points: 10),

        Achievement(id: "first_contribution",
                    title: "First Egg",
                    detail: "Add your first contribution.",
                    systemImage: "egg.fill",
                    points: 10),

        Achievement(id: "progress_25",
                    title: "Quarter Full",
                    detail: "Reach 25% of any goal.",
                    systemImage: "chart.bar.fill",
                    points: 15),

        Achievement(id: "progress_50",
                    title: "Half Full",
                    detail: "Reach 50% of any goal.",
                    systemImage: "chart.bar.xaxis",
                    points: 20),

        Achievement(id: "progress_75",
                    title: "Almost There",
                    detail: "Reach 75% of any goal.",
                    systemImage: "chart.bar.doc.horizontal.fill",
                    points: 25),

        Achievement(id: "goal_completed",
                    title: "Golden Egg",
                    detail: "Complete any goal (100%).",
                    systemImage: "star.circle.fill",
                    points: 40),

        Achievement(id: "three_goals_created",
                    title: "Triple Basket",
                    detail: "Have at least 3 active goals.",
                    systemImage: "tray.full.fill",
                    points: 15),

        Achievement(id: "five_goals_created",
                    title: "Big Coop",
                    detail: "Have at least 5 active goals.",
                    systemImage: "tray.2.fill",
                    points: 25),

        Achievement(id: "saved_1000_total",
                    title: "Thousand Saver",
                    detail: "Save 1,000 total across all goals.",
                    systemImage: "seal.fill",
                    points: 30),

        Achievement(id: "saved_5000_total",
                    title: "Egg Fortune",
                    detail: "Save 5,000 total across all goals.",
                    systemImage: "rosette",
                    points: 60)
    ]

    // MARK: - Init

    init(store: GoalStore) {
        self.store = store
        loadUnlocked()

        // Пересчитываем ачивки при любых изменениях списка целей
        store.$goals
            .sink { [weak self] _ in
                self?.evaluateAll()
            }
            .store(in: &cancellables)

        // Слушаем точечные обновления прогресса
        NotificationCenter.default.publisher(for: .goalProgressUpdated)
            .sink { [weak self] _ in
                self?.evaluateAll()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Возвращает все достижения из каталога
    var allAchievements: [Achievement] {
        catalog
    }

    /// Проверка: ачивка уже открыта?
    func isUnlocked(_ id: String) -> Bool {
        unlocked.contains(id)
    }

    /// Сумма очков за все открытые достижения
    var totalPoints: Int {
        catalog.filter { unlocked.contains($0.id) }.reduce(0) { $0 + $1.points }
    }

    // MARK: - Core Logic

    /// Полная переоценка прогресса и открытие достижений, если условия выполнены.
    func evaluateAll() {
        recentlyUnlocked.removeAll()

        // Глобальные условия
        checkFirstGoalCreated()
        checkGoalsCount()
        checkTotalsSaved()

        // Условия по каждой цели
        for goal in store.goals {
            checkFirstContribution(goal)
            checkProgressMilestones(goal)
            checkGoalCompleted(goal)
        }

        if !recentlyUnlocked.isEmpty {
            saveUnlocked()
            // Можно разослать уведомление для UI (например, чтобы показать тост/баннер)
            NotificationCenter.default.post(name: .achievementsDidUpdate, object: nil)
        }
    }

    // MARK: - Checks

    private func checkFirstGoalCreated() {
        guard !store.goals.isEmpty else { return }
        unlockIfNeeded("first_goal_created")
    }

    private func checkGoalsCount() {
        let count = store.goals.count
        if count >= 3 { unlockIfNeeded("three_goals_created") }
        if count >= 5 { unlockIfNeeded("five_goals_created") }
    }

    private func checkTotalsSaved() {
        let total = store.goals.reduce(0) { $0 + $1.currentAmount }
        if total >= 1000 { unlockIfNeeded("saved_1000_total") }
        if total >= 5000 { unlockIfNeeded("saved_5000_total") }
    }

    private func checkFirstContribution(_ goal: Goal) {
        guard goal.currentAmount > 0 else { return }
        unlockIfNeeded("first_contribution")
    }

    private func checkProgressMilestones(_ goal: Goal) {
        let p = goal.progress
        if p >= 0.25 { unlockIfNeeded("progress_25") }
        if p >= 0.50 { unlockIfNeeded("progress_50") }
        if p >= 0.75 { unlockIfNeeded("progress_75") }
    }

    private func checkGoalCompleted(_ goal: Goal) {
        if goal.progress >= 1.0 {
            unlockIfNeeded("goal_completed")
        }
    }

    // MARK: - Unlock

    private func unlockIfNeeded(_ id: String) {
        guard !unlocked.contains(id) else { return }
        unlocked.insert(id)
        if let ach = catalog.first(where: { $0.id == id }) {
            recentlyUnlocked.append(ach)
        }
    }

    // MARK: - Persistence

    private func loadUnlocked() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            unlocked = []
            return
        }
        unlocked = ids
    }

    private func saveUnlocked() {
        if let data = try? JSONEncoder().encode(unlocked) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let achievementsDidUpdate = Notification.Name("achievementsDidUpdate")
}
