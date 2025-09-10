//
//  GoalModel.swift
//  goalapp
//
//  Created by Elliot Cooper
//

import Foundation

struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    
    init(title: String, targetAmount: Double, deadline: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = 0
        self.deadline = deadline
    }
    
    // Прогресс цели в процентах (0.0 – 1.0)
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    // Остаток до цели
    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }
    
    // Добавление взноса
    mutating func addContribution(_ amount: Double) {
        currentAmount += max(amount, 0)
        if currentAmount > targetAmount {
            currentAmount = targetAmount
        }
    }
}
