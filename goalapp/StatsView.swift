//
//  StatsView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

/// Компактный блок статистики по одной цели.
/// Показывает суммы, проценты и расчёт требуемого темпа при наличии дедлайна.
struct StatsView: View {
    let goal: Goal

    var body: some View {
        VStack(spacing: 12) {
            // Основные показатели
            StatRow(
                leftTitle: "Saved",
                leftValue: num(goal.currentAmount),
                rightTitle: "Target",
                rightValue: num(goal.targetAmount)
            )

            StatRow(
                leftTitle: "Remaining",
                leftValue: num(goal.remaining),
                rightTitle: "Progress",
                rightValue: "\(percent(goal.progress))"
            )

            // Блок темпа при наличии дедлайна
            if let deadline = goal.deadline {
                Divider().padding(.horizontal, 8)

                StatRow(
                    leftTitle: "Deadline",
                    leftValue: dateString(deadline),
                    rightTitle: "Days Left",
                    rightValue: "\(daysLeft(to: deadline))"
                )

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Needed Per Day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(num(neededPerDay(to: deadline)))
                            .font(.headline)
                            .monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Needed Per Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(num(neededPerWeek(to: deadline)))
                            .font(.headline)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func percent(_ p: Double) -> String {
        let v = max(0, min(1, p))
        return "\(Int((v * 100).rounded()))%"
    }

    private func daysLeft(to deadline: Date) -> Int {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: deadline)
        let comp = Calendar.current.dateComponents([.day], from: start, to: end)
        return max(0, comp.day ?? 0)
    }

    private func neededPerDay(to deadline: Date) -> Double {
        let d = daysLeft(to: deadline)
        guard d > 0 else { return goal.remaining }
        return goal.remaining / Double(d)
    }

    private func neededPerWeek(to deadline: Date) -> Double {
        neededPerDay(to: deadline) * 7.0
    }

    private func num(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

// MARK: - Reusable Row

private struct StatRow: View {
    let leftTitle: String
    let leftValue: String
    let rightTitle: String
    let rightValue: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(leftTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(leftValue)
                    .font(.headline)
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(rightTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(rightValue)
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StatsView(goal: Goal(title: "Vacation", targetAmount: 2000, deadline: Calendar.current.date(byAdding: .day, value: 120, to: .now)))
        StatsView(goal: Goal(title: "New iPad", targetAmount: 1200))
    }
    .padding(.vertical)
}
