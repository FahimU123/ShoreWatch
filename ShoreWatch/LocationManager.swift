// LocationManager.swift
// ShoreWatch

import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 100 // metres — avoid constant updates
    }

    func requestPermissionAndStart() {
        let status = manager.authorizationStatus
        #if os(iOS)
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startServices()
        case .denied, .restricted:
            errorMessage = "Location access is required. Enable it in Settings."
        @unknown default:
            break
        }
        #else
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            startServices()
        case .denied, .restricted:
            errorMessage = "Location access is required. Enable it in Settings."
        @unknown default:
            break
        }
        #endif
    }
    
    private func startServices() {
        manager.startUpdatingLocation()
        #if os(iOS)
        manager.startUpdatingHeading()
        #endif
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            authorizationStatus = status
            #if os(iOS)
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                startServices()
            }
            #else
            if status == .authorizedAlways {
                startServices()
            }
            #endif
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            location = latest
        }
    }

    #if os(iOS)
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            heading = newHeading
        }
    }
    #endif

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
}
