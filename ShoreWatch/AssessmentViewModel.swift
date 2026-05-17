// AssessmentViewModel.swift
// ShoreWatch
//
// Orchestrates the full data pipeline:
//   CoreLocation -> NOAA -> IBM Granite -> UI state

import SwiftUI
import CoreLocation
import Combine

@MainActor
final class AssessmentViewModel: ObservableObject {

    // MARK: - Published State

    @Published var loadingState: LoadingState = .idle
    @Published var assessment: ThreatAssessment?
    @Published var currentLocation: CLLocation?

    // MARK: - Services

    let locationManager = LocationManager()
    private let noaaService = NOAAService()
    private let geminiService = GeminiService()

    private var locationCancellable: AnyCancellable?
    private var hasTriggeredInitialFetch = false

    // MARK: - Lifecycle

    func start() async {
        await NotificationManager.shared.requestPermission()

        if Config.useDemoLocation {
            let demo = CLLocation(latitude: Config.demoLatitude, longitude: Config.demoLongitude)
            currentLocation = demo
            await runPipeline(from: demo)
            return
        }

        locationManager.requestPermissionAndStart()

        // Trigger the assessment pipeline once we have a location.
        locationCancellable = locationManager.$location
            .compactMap { $0 }
            .first()     // react to the first valid fix, then manually refresh
            .sink { [weak self] location in
                guard let self else { return }
                Task { @MainActor in
                    await self.runPipeline(from: location)
                }
            }
    }

    func refresh() async {
        guard let location = locationManager.location else { return }
        await runPipeline(from: location)
    }

    // MARK: - Pipeline

    private func runPipeline(from location: CLLocation) async {
        guard loadingState != .fetchingBuoy, loadingState != .assessing else { return }

        print("🌊 [Pipeline] Starting — coords: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        loadingState = .fetchingBuoy

        do {
            print("📡 [NOAA] Fetching buoy (useMockBuoy=\(Config.useMockBuoy))")
            let buoy = try await noaaService.fetchNearestBuoy(to: location.coordinate)
            print("✅ [NOAA] Got buoy \(buoy.stationID) — \(buoy.summary)")

            loadingState = .assessing
            print("🤖 [Gemini] Sending to AI (useMockAssessment=\(Config.useMockAssessment))")
            let (level, narrative) = try await geminiService.assess(buoy: buoy)
            print("✅ [Gemini] Level=\(level.rawValue) narrative=\(narrative.prefix(80))")

            let result = ThreatAssessment(
                alertLevel: level,
                narrative: narrative,
                buoy: buoy,
                fetchedAt: Date()
            )
            assessment = result
            loadingState = .ready

            NotificationManager.shared.sendAlert(level: level, narrative: narrative)

        } catch {
            print("❌ [Pipeline] FAILED: \(error)")
            loadingState = .failed(error.localizedDescription)
        }
    }
}
