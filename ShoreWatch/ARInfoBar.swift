// ARInfoBar.swift
// ShoreWatch

import SwiftUI

struct ARInfoBar: View {
    let assessment: ThreatAssessment

    private var alertColor: Color {
        DS.Color.alert(assessment.alertLevel)
    }

    var body: some View {
        let buoy = assessment.buoy
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("BUOY \(buoy.stationID)")
                    .font(DS.Typography.sectionLabel())
                    .foregroundStyle(.secondary)

                HStack(spacing: DS.Spacing.md) {
                    Label(
                        buoy.waterTemperature.map {
                            "\($0.formatted(.number.precision(.fractionLength(1))))°C"
                        } ?? "—",
                        systemImage: "thermometer.low"
                    )
                    Label(
                        buoy.survivalTimeMinutes.map { "\($0) min" } ?? "—",
                        systemImage: "lifepreserver"
                    )
                }
                .font(DS.Typography.caption.weight(.bold))
                .foregroundStyle(DS.Color.primaryText)

                Text(
                    "LAT: \(buoy.latitude.formatted(.number.precision(.fractionLength(4))))  LON: \(buoy.longitude.formatted(.number.precision(.fractionLength(4))))"
                )
                .font(DS.Typography.caption.monospaced())
                .foregroundStyle(DS.Color.secondaryText)
            }
            Spacer()
            Text(assessment.alertLevel.displayLabel)
                .font(DS.Typography.caption.bold())
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(alertColor, in: Capsule())
                .foregroundStyle(.white)
        }
        .padding(DS.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).stroke(.secondary.opacity(0.1), lineWidth: 0.5))
    }
}



