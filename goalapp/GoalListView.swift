//
//  GoalListView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

struct GoalListView: View {
    @EnvironmentObject var store: GoalStore
    @State private var showingAddGoal = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if filteredGoals.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(filteredGoals) { goal in
                            NavigationLink(value: goal.id) {
                                GoalRow(goal: goal)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Savings Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Add Goal")
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .sheet(isPresented: $showingAddGoal) {
                AddGoalSheet { title, target, deadline in
                    store.addGoal(title: title, targetAmount: target, deadline: deadline)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let goal = store.goals.first(where: { $0.id == id }) {
                    GoalDetailView(goal: goal)
                        .environmentObject(store)
                } else {
                    Text("Goal not found")
                }
            }
        }
    }

    private var filteredGoals: [Goal] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return store.goals }
        return store.goals.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { filteredGoals[$0].id }.forEach { id in
            if let idx = store.goals.firstIndex(where: { $0.id == id }) {
                store.goals.remove(at: idx)
            }
        }
    }
}

// MARK: - Row

private struct GoalRow: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 12) {
            EggProgressIcon(progress: goal.progress)
                .frame(width: 40, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(formatted(goal.currentAmount)) / \(formatted(goal.targetAmount))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .monospacedDigit()

                    if let date = goal.deadline {
                        Text("· \(deadlineLabel(date))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text("\(Int((goal.progress * 100).rounded()))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }

    private func formatted(_ amount: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func deadlineLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

// MARK: - Add Goal Sheet

private struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var targetText: String = ""
    @State private var deadlineEnabled: Bool = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    var onSave: (String, Double, Date?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                }
                Section("Target") {
                    TextField("Target amount", text: $targetText)
                        .keyboardType(.decimalPad)
                }
                Section("Deadline (optional)") {
                    Toggle("Enable deadline", isOn: $deadlineEnabled.animation())
                    if deadlineEnabled {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let value = Double(targetText.replacingOccurrences(of: ",", with: ".")), value > 0 else { return false }
        return true
    }

    private func save() {
        let value = Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), value, deadlineEnabled ? deadline : nil)
        dismiss()
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            // Иконка вкладки Goals — в том же стиле «яйца»
            EggProgressIcon(progress: 0.25)
                .frame(width: 70, height: 94)
                .opacity(0.9)

            Text("No goals yet")
                .font(.headline)

            Text("Create your first savings goal to start tracking progress.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let store = GoalStore()
    store.goals = [
        {
            var g = Goal(title: "New iPhone", targetAmount: 1200, deadline: Calendar.current.date(byAdding: .month, value: 5, to: .now))
            g.addContribution(480)
            return g
        }(),
        {
            var g = Goal(title: "Vacation", targetAmount: 2000, deadline: Calendar.current.date(byAdding: .month, value: 8, to: .now))
            g.addContribution(950)
            return g
        }()
    ]
    return GoalListView()
        .environmentObject(store)
}
