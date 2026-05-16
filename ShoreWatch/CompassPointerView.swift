// CompassPointerView.swift
// ShoreWatch

import SwiftUI
import CoreLocation

struct CompassPointerView: View {
    let userLocation: CLLocation?
    let targetCoordinate: CLLocationCoordinate2D
    let userHeading: Double

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(DS.Color.primaryText.opacity(0.1), lineWidth: 1.5)
                    .frame(width: 80, height: 80)

                Image(systemName: "location.north.fill")
                    .font(.title.bold())
                    .foregroundStyle(DS.Color.accent)
                    .rotationEffect(.degrees(bearing - userHeading))
                    .shadow(color: DS.Color.accent.opacity(0.3), radius: 8)
            }

            VStack(spacing: 2) {
                Text("TO BUOY")
                    .font(DS.Typography.sectionLabel())
                    .foregroundStyle(.secondary)
                Text("\(Int(bearing))°")
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(DS.Spacing.lg)
        .background(DS.Color.secondaryBackground.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }

    private var bearing: Double {
        guard let userLoc = userLocation else { return 0 }

        let lat1 = userLoc.coordinate.latitude * .pi / 180
        let lon1 = userLoc.coordinate.longitude * .pi / 180
        let lat2 = targetCoordinate.latitude * .pi / 180
        let lon2 = targetCoordinate.longitude * .pi / 180
        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(y, x) * 180 / .pi
    }
}
