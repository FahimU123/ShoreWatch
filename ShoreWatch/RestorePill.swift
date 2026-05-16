// RestorePill.swift
// ShoreWatch

import SwiftUI

struct RestorePill: View {
    let assessment: ThreatAssessment
    let action: () -> Void

    @State private var hapticTrigger = false

    private var color: Color {
        DS.Color.alert(assessment.alertLevel)
    }

    private var symbol: String {
        DS.alertSymbol(for: assessment.alertLevel)
    }

    var body: some View {
        VStack {
            Spacer()
            Button {
                hapticTrigger.toggle()
                action()
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: symbol)
                        .font(.headline)
                        .foregroundStyle(color)
                        .symbolEffect(.pulse)

                    Text(assessment.alertLevel.displayLabel)
                        .font(DS.Typography.headline)
                        .foregroundStyle(.white)
                    
                    Image(systemName: "chevron.up")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.secondary.opacity(0.1), lineWidth: 0.5))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
            .padding(.bottom, DS.Spacing.xl)
        }
    }
}

