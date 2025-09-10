//
//  AddContributionView.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI

struct AddContributionView: View {
    @Environment(\.dismiss) private var dismiss

    // Возврат суммы во внешнюю логику (обновление цели выполняется снаружи)
    var onSave: (Double) -> Void

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var showInvalidAlert = false

    // Быстрые суммы
    private let presets: [Double] = [10, 25, 50, 100]

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .onChange(of: amountText) { _ in
                                // Мягкая фильтрация ввода
                                amountText = sanitized(amountText)
                            }

                        Button("Clear") {
                            amountText = ""
                        }
                        .buttonStyle(.borderless)
                    }

                    // Быстрые кнопки
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(presets, id: \.self) { value in
                            Button("+\(short(value))") {
                                bump(by: value)
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 4)
                }

                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Note (optional)") {
                    TextField("Short note", text: $note)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("Add Contribution")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("Enter numbers only", isPresented: $showInvalidAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Amount should be a positive number.")
            }
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        guard let value = parsedAmount(), value > 0 else { return false }
        return true
    }

    private func save() {
        guard let value = parsedAmount(), value > 0 else {
            showInvalidAlert = true
            return
        }
        onSave(value)
        dismiss()
    }

    private func parsedAmount() -> Double? {
        // Разрешаем точку и запятую
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        if let number = Double(cleaned) {
            return number.rounded(toPlaces: 2)
        }
        return nil
    }

    private func sanitized(_ raw: String) -> String {
        // Оставляем только цифры и один разделитель
        var result = ""
        var hasSeparator = false
        for ch in raw {
            if ch.isNumber {
                result.append(ch)
            } else if ch == "." || ch == "," {
                if !hasSeparator {
                    result.append(".")
                    hasSeparator = true
                }
            }
        }
        return result
    }

    private func bump(by value: Double) {
        let current = parsedAmount() ?? 0
        let newValue = (current + value).rounded(toPlaces: 2)
        amountText = shortString(newValue)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func short(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(value)
        }
    }

    private func shortString(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Preview

#Preview {
    AddContributionView { _ in }
}

// MARK: - Utilities

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        guard places >= 0 else { return self }
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
