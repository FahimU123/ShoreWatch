// BuoyMapView.swift
// ShoreWatch

import SwiftUI
import MapKit

private let greatLakesRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 22.2, longitude: -40.5),
    span: MKCoordinateSpan(latitudeDelta: 7.5, longitudeDelta: 14.0)
)

struct BuoyMapView: View {
    let buoys: [DemoBuoy]
    let vessels: [Vessel]
    @Binding var selectedBuoy: DemoBuoy?

    @State private var position: MapCameraPosition = .region(greatLakesRegion)
    @AppStorage("showAIS") private var showAIS = true

    private var dangerBuoys: [DemoBuoy] {
        buoys.filter { $0.alertLevel == .getOutNow || $0.alertLevel == .monitorClosely }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(dangerBuoys) { buoy in
                MapCircle(
                    center: buoy.coordinate,
                    radius: buoy.alertLevel == .getOutNow ? 50_000 : 30_000
                )
                .foregroundStyle(zoneColor(for: buoy.alertLevel).opacity(0.14))
                .stroke(zoneColor(for: buoy.alertLevel).opacity(0.5), lineWidth: 1.5)
            }

            ForEach(buoys) { buoy in
                Annotation(buoy.name, coordinate: buoy.coordinate, anchor: .center) {
                    Button {
                        withAnimation(DS.Anim.snappy) {
                            selectedBuoy = buoy
                        }
                    } label: {
                        BuoyAnnotationView(
                            buoy: buoy,
                            isSelected: selectedBuoy?.id == buoy.id
                        )
                    }
                    .buttonStyle(.plain)
                }
                .annotationTitles(.hidden)
            }

            if showAIS {
                ForEach(vessels) { vessel in
                    Annotation(vessel.name, coordinate: vessel.coordinate) {
                        VesselMarkerView(vessel: vessel)
                    }
                    .annotationTitles(.hidden)
                }
            }

            UserAnnotation()
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    private func zoneColor(for level: AlertLevel) -> Color {
        switch level {
        case .getOutNow, .monitorClosely:
            DS.Color.alert(level)
        default:
            .clear
        }
    }
}

struct VesselMarkerView: View {
    let vessel: Vessel
    
    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.2), radius: 4)
                
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(vessel.heading))
            }
            
            Text(vessel.name)
                .font(DS.Typography.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.xs)
                .background(.black.opacity(0.6), in: Capsule())
        }
    }
}

