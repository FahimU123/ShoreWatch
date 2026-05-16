// AlertBadgeView.swift
// ShoreWatch

import SwiftUI

struct AlertBadgeView: View {
    let level: AlertLevel

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var badgeColor: Color {
        DS.Color.alert(level)
    }

    private var symbolName: String {
        DS.alertSymbol(for: level)
    }

    private var verdictText: String {
        level.displayLabel
    }

    var body: some View {
        Label {
            Text(verdictText)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Color.primaryText)
        } icon: {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(badgeColor)
                .shadow(
                    color: badgeColor.opacity(pulse ? 0.3 : 0.1),
                    radius: pulse ? 12 : 4
                )
                .scaleEffect(pulse && level == .getOutNow ? 1.05 : 1.0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alert level: \(verdictText)")
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear {
            guard !reduceMotion,
                  level == .getOutNow || level == .monitorClosely else { return }
            withAnimation(DS.Anim.pulse) {
                pulse = true
            }
        }
        .sensoryFeedback(level == .getOutNow ? .error : .warning, trigger: level) { _, new in
            new == .getOutNow || new == .monitorClosely
        }
    }
}
