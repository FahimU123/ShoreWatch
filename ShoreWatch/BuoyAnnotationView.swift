// BuoyAnnotationView.swift
// ShoreWatch

import SwiftUI

struct BuoyAnnotationView: View {
    let buoy: DemoBuoy
    var isSelected: Bool = false

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var alertColor: Color {
        DS.Color.alert(buoy.alertLevel)
    }

    private var shouldPulse: Bool {
        buoy.alertLevel == .getOutNow || buoy.alertLevel == .monitorClosely
    }

    var body: some View {
        ZStack {
            // Pulse ring for urgent states
            if shouldPulse && !reduceMotion {
                Circle()
                    .stroke(alertColor.opacity(0.4), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .scaleEffect(pulse ? 2.2 : 1.0)
                    .opacity(pulse ? 0 : 1)
            }

            // Selection ring
            if isSelected {
                Circle()
                    .stroke(DS.Color.primaryText, lineWidth: 3)
                    .frame(width: 30, height: 30)
            }

            // Backing ring so the dot is visible on any map tile
            Circle()
                .fill(DS.Color.background)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.15), radius: 2)

            Circle()
                .fill(alertColor)
                .frame(width: 14, height: 14)
        }
        .frame(width: 44, height: 44)
        .onAppear {
            guard shouldPulse, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(buoy.name): \(buoy.alertLevel.rawValue). Waves \(String(format: "%.1f", buoy.waveHeight)) m, wind \(String(format: "%.0f", buoy.windSpeed)) m/s.")
        .accessibilityAddTraits(.isButton)
    }
}
