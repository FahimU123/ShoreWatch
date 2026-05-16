// Models.swift
// ShoreWatch

import Foundation
import CoreLocation

// MARK: - Alert Level

enum AlertLevel: String, Equatable {
    case getOutNow      = "GET OUT NOW"
    case monitorClosely = "MONITOR CLOSELY"
    case allClear       = "ALL CLEAR"
    case unknown        = "ASSESSING"

    /// Human-readable sentence-case label for display in UI surfaces.
    var displayLabel: String {
        switch self {
        case .getOutNow:      "Get out now"
        case .monitorClosely: "Monitor closely"
        case .allClear:       "All clear"
        case .unknown:        "Assessing…"
        }
    }
}

// MARK: - NOAA Buoy Data

struct BuoyObservation {
    let stationID: String
    let latitude: Double
    let longitude: Double
    let waveHeight: Double?
    let windSpeed: Double?
    let dominantWavePeriod: Double?
    let pressure: Double?
    let waterTemperature: Double?
    let airTemperature: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var summary: String {
        var parts: [String] = []
        if let wh = waveHeight           { parts.append(String(format: "Wave %.1f m", wh)) }
        if let ws = windSpeed            { parts.append(String(format: "Wind %.0f m/s", ws)) }
        if let wt = waterTemperature     { parts.append(String(format: "Water %.1f°C", wt)) }
        if let pr = pressure             { parts.append(String(format: "%.0f hPa", pr)) }
        return parts.joined(separator: "  ·  ")
    }
    
    /// Estimated survival time in minutes based on water temperature (approximate USCG table)
    var survivalTimeMinutes: Int? {
        guard let temp = waterTemperature else { return nil }
        // Simple linear interpolation of common survival curves
        if temp < 4.5  { return 30 }
        if temp < 10.0 { return 60 }
        if temp < 15.0 { return 120 }
        if temp < 21.0 { return 180 }
        return 720 // 12+ hours
    }
}

// MARK: - Safe Harbor

struct SafeHarbor: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    static let lakeErieHarbors = [
        SafeHarbor(name: "Port Clinton", coordinate: CLLocationCoordinate2D(latitude: 41.51, longitude: -82.94)),
        SafeHarbor(name: "Sandusky Bay", coordinate: CLLocationCoordinate2D(latitude: 41.45, longitude: -82.71)),
        SafeHarbor(name: "Toledo Harbor", coordinate: CLLocationCoordinate2D(latitude: 41.69, longitude: -83.47))
    ]
}

// MARK: - VHF Channels

struct VHFChannel: Identifiable {
    let id = UUID()
    let channel: String
    let purpose: String
    
    static let standardChannels = [
        VHFChannel(channel: "16", purpose: "Distress, Safety and Calling"),
        VHFChannel(channel: "09", purpose: "Alternate Calling (Pleasure)"),
        VHFChannel(channel: "22A", purpose: "Coast Guard Liaison"),
        VHFChannel(channel: "13", purpose: "Bridge-to-Bridge")
    ]
}


// MARK: - Assessment Result

struct ThreatAssessment {
    let alertLevel: AlertLevel
    let narrative: String
    let buoy: BuoyObservation
    let fetchedAt: Date
}

// MARK: - Forecast Trend

enum ForecastTrend {
    case worsening, steady, improving

    var label: String {
        switch self {
        case .worsening: "Worsening"
        case .steady:    "Steady"
        case .improving: "Improving"
        }
    }

    var systemImage: String {
        switch self {
        case .worsening: "arrow.up.right"
        case .steady:    "minus"
        case .improving: "arrow.down.right"
        }
    }
}

// MARK: - Vessel (AIS Simulation)

struct Vessel: Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: String
    let coordinate: CLLocationCoordinate2D
    let heading: Double
    let speed: Double // knots
    
    static func == (lhs: Vessel, rhs: Vessel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.heading == rhs.heading
    }
    
    static let lakeErieVessels: [Vessel] = [
        Vessel(
            id: UUID(),
            name: "STEWART J. CORT",
            type: "Bulk Carrier",
            coordinate: CLLocationCoordinate2D(latitude: 41.72, longitude: -82.45),
            heading: 285,
            speed: 12.4
        ),
        Vessel(
            id: UUID(),
            name: "ALGOMA COMPASS",
            type: "Self-Discharger",
            coordinate: CLLocationCoordinate2D(latitude: 41.65, longitude: -82.25),
            heading: 105,
            speed: 10.1
        ),
        Vessel(
            id: UUID(),
            name: "LAKE GUARDIAN",
            type: "Research Vessel",
            coordinate: CLLocationCoordinate2D(latitude: 41.80, longitude: -82.60),
            heading: 45,
            speed: 8.5
        )
    ]
}

// MARK: - Demo Buoy Marker (map display)

struct DemoBuoy: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let alertLevel: AlertLevel
    let waveHeight: Double
    let windSpeed: Double
    let forecastWaveHeight: Double
    let forecastTrend: ForecastTrend
    let safeWindowLabel: String?
    
    static func == (lhs: DemoBuoy, rhs: DemoBuoy) -> Bool {
        lhs.id == rhs.id &&
        lhs.alertLevel == rhs.alertLevel &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

extension DemoBuoy {
    static let lakeErie: [DemoBuoy] = [
        DemoBuoy(
            id: "45005",
            name: "West Erie",
            coordinate: CLLocationCoordinate2D(latitude: 41.68, longitude: -82.39),
            alertLevel: .getOutNow,
            waveHeight: 2.4,
            windSpeed: 24.2,
            forecastWaveHeight: 3.1,
            forecastTrend: .worsening,
            safeWindowLabel: "May ease after 20:00 local"
        ),
        DemoBuoy(
            id: "45147",
            name: "Central Erie",
            coordinate: CLLocationCoordinate2D(latitude: 42.20, longitude: -81.10),
            alertLevel: .monitorClosely,
            waveHeight: 1.4,
            windSpeed: 14.8,
            forecastWaveHeight: 1.8,
            forecastTrend: .worsening,
            safeWindowLabel: nil
        ),
        DemoBuoy(
            id: "45142",
            name: "East Erie",
            coordinate: CLLocationCoordinate2D(latitude: 42.58, longitude: -79.87),
            alertLevel: .allClear,
            waveHeight: 0.5,
            windSpeed: 6.1,
            forecastWaveHeight: 0.4,
            forecastTrend: .improving,
            safeWindowLabel: nil
        ),
        DemoBuoy(
            id: "45008",
            name: "Lake Huron South",
            coordinate: CLLocationCoordinate2D(latitude: 44.27, longitude: -83.21),
            alertLevel: .monitorClosely,
            waveHeight: 1.1,
            windSpeed: 12.3,
            forecastWaveHeight: 0.9,
            forecastTrend: .improving,
            safeWindowLabel: nil
        ),
        DemoBuoy(
            id: "45007",
            name: "Lake Michigan South",
            coordinate: CLLocationCoordinate2D(latitude: 42.67, longitude: -87.03),
            alertLevel: .allClear,
            waveHeight: 0.3,
            windSpeed: 5.4,
            forecastWaveHeight: 0.3,
            forecastTrend: .steady,
            safeWindowLabel: nil
        ),
    ]
}
