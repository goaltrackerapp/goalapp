//
//  AchievementsView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

/// Экран со списком достижений. Показывает, что уже открыто, прогресс и очки.
struct AchievementsView: View {
    @ObservedObject var manager: AchievementsManager

    @State private var selected: Achievement?
    @State private var showToast = false
    @State private var toastText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                header

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(manager.allAchievements) { ach in
                        AchievementCard(
                            achievement: ach,
                            unlocked: manager.isUnlocked(ach.id),
                            totalPoints: manager.totalPoints
                        )
                        .onTapGesture {
                            selected = ach
                        }
                        .contextMenu {
                            if manager.isUnlocked(ach.id) {
                                Label("Unlocked", systemImage: "checkmark.seal.fill")
                            } else {
                                Label("Locked", systemImage: "lock.fill")
                            }
                            Text(ach.detail)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(ach.title), \(manager.isUnlocked(ach.id) ? "unlocked" : "locked")"))
                        .accessibilityHint(Text(ach.detail))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Achievements")
            .onReceive(NotificationCenter.default.publisher(for: .achievementsDidUpdate)) { _ in
                // Покажем краткий тост о новых ачивках
                if let latest = manager.recentlyUnlocked.last {
                    toastText = "Unlocked: \(latest.title)"
                    withAnimation(.spring()) { showToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation(.easeOut) { showToast = false }
                    }
                }
            }
            .overlay(alignment: .top) {
                if showToast {
                    ToastView(text: toastText)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .sheet(item: $selected) { ach in
                AchievementDetailSheet(achievement: ach, unlocked: manager.isUnlocked(ach.id))
                    .presentationDetents([.fraction(0.35), .medium])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Total Points", systemImage: "trophy.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(manager.totalPoints)")
                    .font(.headline)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)

            ProgressSummary(manager: manager)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }
}

// MARK: - Progress Summary

private struct ProgressSummary: View {
    @ObservedObject var manager: AchievementsManager

    var body: some View {
        let total = manager.allAchievements.count
        let unlocked = manager.allAchievements.filter { manager.isUnlocked($0.id) }.count
        let p = total > 0 ? Double(unlocked) / Double(total) : 0

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Unlocked \(unlocked) of \(total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((p * 100).rounded()))%")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: p)
                .progressViewStyle(.linear)
        }
    }
}

// MARK: - Achievement Card

private struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool
    let totalPoints: Int

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(unlocked ? Color.yellow.opacity(0.20) : Color.secondary.opacity(0.10))

                VStack(spacing: 8) {
                    Image(systemName: achievement.systemImage)
                        .font(.system(size: 34, weight: .semibold))
                        .symbolVariant(unlocked ? .fill : .none)
                        .opacity(unlocked ? 1.0 : 0.55)
                        .scaleEffect(unlocked ? 1.04 : 1.0)

                    Text(achievement.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .opacity(unlocked ? 1.0 : 0.7)

                    Text(achievement.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .opacity(unlocked ? 1.0 : 0.7)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .imageScale(.small)
                        Text("\(achievement.points)")
                            .monospacedDigit()
                    }
                    .font(.footnote)
                    .padding(.top, 2)
                    .opacity(unlocked ? 1.0 : 0.7)
                }
                .padding(14)

                if !unlocked {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.25), lineWidth: 1)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                    }
                }
            }
            .frame(height: 150)
            .shadow(color: .black.opacity(unlocked ? 0.12 : 0.06), radius: unlocked ? 8 : 4, x: 0, y: unlocked ? 6 : 3)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(unlocked ? Color.yellow.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Detail Sheet

private struct AchievementDetailSheet: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 16) {
            capsuleHandle

            Image(systemName: achievement.systemImage)
                .font(.system(size: 42, weight: .semibold))
                .symbolVariant(unlocked ? .fill : .none)
                .padding(.top, 4)

            Text(achievement.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(achievement.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                Text("\(achievement.points) pts")
                    .monospacedDigit()
            }
            .font(.footnote)
            .padding(.top, 4)

            Label(unlocked ? "Unlocked" : "Locked",
                  systemImage: unlocked ? "checkmark.seal.fill" : "lock.fill")
            .foregroundStyle(unlocked ? .green : .secondary)

            Spacer()
        }
        .padding(.bottom, 20)
    }

    private var capsuleHandle: some View {
        Capsule()
            .fill(.secondary.opacity(0.25))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }
}

// MARK: - Toast

private struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
            Text(text)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 6, y: 3)
    }
}

// MARK: - Preview

#Preview {
    // Вспомогательные мок-данные для предпросмотра
    let store = GoalStore()
    store.goals = [
        {
            var g = Goal(title: "Vacation", targetAmount: 2000, deadline: Calendar.current.date(byAdding: .day, value: 90, to: .now))
            g.addContribution(250)
            return g
        }(),
        {
            var g = Goal(title: "New iPad", targetAmount: 1200, deadline: Calendar.current.date(byAdding: .day, value: 150, to: .now))
            g.addContribution(600)
            return g
        }()
    ]

    let manager = AchievementsManager(store: store)
    // Форсим первичную оценку
    manager.evaluateAll()

    return AchievementsView(manager: manager)
}
