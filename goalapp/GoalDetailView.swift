//
//  GoalDetailView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var store: GoalStore
    @Environment(\.dismiss) private var dismiss

    let goal: Goal

    @State private var showingAddContribution = false
    @State private var hapticsEnabled = AppPreferences.shared.hapticsEnabled

    var body: some View {
        VStack(spacing: 16) {
            if let binding = bindingForGoal() {
                header(binding.wrappedValue)

                // EGG PROGRESS (большая иконка)
                EggProgressIcon(progress: binding.wrappedValue.progress)
                    .frame(width: 120, height: 160)
                    .padding(.top, 2)

                // PROGRESS CARD
                ProgressCard(
                    progress: binding.wrappedValue.progress,
                    current: binding.wrappedValue.currentAmount,
                    target: binding.wrappedValue.targetAmount,
                    deadline: binding.wrappedValue.deadline
                )

                // QUICK ADD
                QuickAddRow { amount in
                    withAnimation(.easeOut(duration: 0.2)) {
                        add(amount, to: binding)
                    }
                }

                // STATS (из StatsView.swift)
                StatsView(goal: binding.wrappedValue)

                Spacer(minLength: 8)

                // ADD CONTRIBUTION BUTTON
                Button {
                    showingAddContribution = true
                } label: {
                    Label("Add Contribution", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .accessibilityLabel("Add Contribution")

            } else {
                ContentUnavailableView("Goal not found",
                                       systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddContribution) {
            AddContributionView { amount in
                if let binding = bindingForGoal() {
                    add(amount, to: binding)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .onChange(of: hapticsEnabled) { value in
                            AppPreferences.shared.hapticsEnabled = value
                        }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    /// Возвращает биндинг к текущей цели внутри GoalStore
    private func bindingForGoal() -> Binding<Goal>? {
        guard let idx = store.goals.firstIndex(where: { $0.id == goal.id }) else { return nil }
        return $store.goals[idx]
    }

    private func add(_ amount: Double, to binding: Binding<Goal>) {
        var updated = binding.wrappedValue
        updated.addContribution(amount)
        binding.wrappedValue = updated

        HapticsManager.rigidImpact()

        // Нотификация для AchievementsManager
        NotificationCenter.default.post(name: .goalProgressUpdated, object: updated.id)
    }

    @ViewBuilder
    private func header(_ goal: Goal) -> some View {
        VStack(spacing: 8) {
            Text(goal.title)
                .font(.title2.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let deadline = goal.deadline {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(deadlineFormatted(deadline))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private func deadlineFormatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

// MARK: - Subviews

private struct ProgressCard: View {
    let progress: Double
    let current: Double
    let target: Double
    let deadline: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(.title2, design: .rounded)).bold()
                Spacer()
                if let deadline {
                    Label {
                        Text(dateString(deadline))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            // Линейный прогресс (яйцо — отдельно выше)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(ProgressColor.color(for: progress))

            HStack {
                Text("\(num(current)) / \(num(target))")
                Spacer()
                Text("Left: \(num(max(target - current, 0)))")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }

    private func num(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct QuickAddRow: View {
    var onTap: (Double) -> Void

    private let amounts: [Double] = [10, 25, 50, 100]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(amounts, id: \.self) { value in
                Button {
                    onTap(value)
                } label: {
                    Text("+\(short(value))")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }

    private func short(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(value)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let goalProgressUpdated = Notification.Name("goalProgressUpdated")
}
