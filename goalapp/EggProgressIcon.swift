//
//  EggProgressIcon.swift
//  goalapp
//  Created by Elliot Cooper
//

import SwiftUI


/// Иконка яйца, которая заполняется цветом в зависимости от прогресса.
/// Используется как маленькая (в списке целей) и как крупная (в деталях).
struct EggProgressIcon: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Контур яйца
                EggShape()
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 2)

                // Заполнение по прогрессу (маска прямоугольником по высоте прогресса)
                EggShape()
                    .fill(fillColor)
                    .mask(
                        Rectangle()
                            .frame(height: geo.size.height * CGFloat(progressClamped))
                            .offset(y: geo.size.height * (1 - CGFloat(progressClamped)))
                    )
                    .animation(.easeInOut(duration: 0.4), value: progressClamped)
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
    }

    // MARK: - Helpers

    private var progressClamped: Double {
        max(0, min(1, progress))
    }

    private var fillColor: Color {
        ProgressColor.color(for: progressClamped)
    }
}

/// Форма яйца
struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Примерная форма яйца через кривые Безье
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.7),
                      control1: CGPoint(x: w * 0.85, y: h * 0.05),
                      control2: CGPoint(x: w, y: h * 0.4))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.7),
                      control1: CGPoint(x: w, y: h),
                      control2: CGPoint(x: 0, y: h))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                      control1: CGPoint(x: 0, y: h * 0.4),
                      control2: CGPoint(x: w * 0.15, y: h * 0.05))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        EggProgressIcon(progress: 0.1)
            .frame(width: 60, height: 80)

        EggProgressIcon(progress: 0.5)
            .frame(width: 60, height: 80)

        EggProgressIcon(progress: 0.9)
            .frame(width: 60, height: 80)
    }
    .padding()
}
