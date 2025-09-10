//
//  GoalStore.swift
//  goalapp
//
//  Created by Elliot Cooper
//

import Foundation

class GoalStore: ObservableObject {
    @Published var goals: [Goal] = [] {
        didSet {
            saveGoals()
        }
    }
    
    private let storageKey = "saved_goals"
    
    init() {
        loadGoals()
    }
    
    // Добавление новой цели
    func addGoal(title: String, targetAmount: Double, deadline: Date? = nil) {
        let goal = Goal(title: title, targetAmount: targetAmount, deadline: deadline)
        goals.append(goal)
    }
    
    // Удаление цели
    func removeGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
    }
    
    // Сохранение
    private func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // Загрузка
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            self.goals = decoded
        }
    }
}
