// NOAAService.swift
// ShoreWatch
//
// Finds the nearest NOAA buoy and fetches its latest observations.
// Uses the NDBC station list and latest observation text format.

import Foundation
import CoreLocation

enum NOAAError: LocalizedError {
    case noStationsFound
    case dataUnavailable
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noStationsFound:  return "No NOAA buoys found near your location."
        case .dataUnavailable:  return "Buoy data is temporarily unavailable."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        }
    }
}

// A lightweight struct just for the station-finder step
private struct BuoyStation {
    let id: String
    let lat: Double
    let lon: Double
}

final class NOAAService {

    // MARK: - Public API

    /// Fetches the observation for the nearest NDBC buoy to `coordinate`.
    func fetchNearestBuoy(to coordinate: CLLocationCoordinate2D) async throws -> BuoyObservation {
        if Config.useMockBuoy {
            return BuoyObservation(
                stationID: Config.mockBuoyStation,
                latitude: Config.demoLatitude,
                longitude: Config.demoLongitude,
                waveHeight: 2.4,
                windSpeed: 24.2,
                dominantWavePeriod: 8.0,
                pressure: 988.5,
                waterTemperature: 4.2,
                airTemperature: 2.1
            )
        }
        let stations = try await fetchStationList()
        guard let nearest = closestStation(to: coordinate, from: stations) else {
            throw NOAAError.noStationsFound
        }
        return try await fetchObservation(for: nearest)
    }

    // MARK: - Station List

    /// Downloads the NDBC active stations XML and parses out id/lat/lon.
    private func fetchStationList() async throws -> [BuoyStation] {
        let urlString = "\(Config.noaaBaseURL)/data/stations/stations.xml"
        guard let url = URL(string: urlString) else { throw NOAAError.dataUnavailable }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw NOAAError.networkError(error)
        }

        return parseStations(from: data)
    }

    /// Simple SAX-style parse of the NDBC stations XML.
    private func parseStations(from data: Data) -> [BuoyStation] {
        let parser = StationXMLParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.stations
    }

    // MARK: - Nearest Station

    private func closestStation(to coordinate: CLLocationCoordinate2D,
                                from stations: [BuoyStation]) -> BuoyStation? {
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return stations.min(by: {
            CLLocation(latitude: $0.lat, longitude: $0.lon).distance(from: target) <
            CLLocation(latitude: $1.lat, longitude: $1.lon).distance(from: target)
        })
    }

    // MARK: - Latest Observation

    private func fetchObservation(for station: BuoyStation) async throws -> BuoyObservation {
        // NDBC latest observation in text format
        let urlString = "\(Config.noaaBaseURL)/data/latest_obs/\(station.id).txt"
        guard let url = URL(string: urlString) else { throw NOAAError.dataUnavailable }

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw NOAAError.networkError(error)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw NOAAError.dataUnavailable
        }

        return parseObservation(text: text, station: station)
    }

    /// Parses the NDBC fixed-width latest observation text file.
    private func parseObservation(text: String, station: BuoyStation) -> BuoyObservation {
        // Lines 1-2 are headers, line 3 is units, line 4 onward is data.
        // Column order: #YY MM DD hh mm WDIR WSPD GST WVHT DPD APD MWD PRES ATMP WTMP DEWP VIS PTDY TIDE
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        var waveHeight: Double?
        var windSpeed: Double?
        var dominantWavePeriod: Double?
        var pressure: Double?
        var airTemp: Double?
        var waterTemp: Double?

        // Data starts at line index 2 (after two header rows)
        if lines.count > 2 {
            let dataLine = lines[2]
            let cols = dataLine.split(separator: " ", omittingEmptySubsequences: true)
            // Indices (0-based): 0=YY,1=MM,2=DD,3=hh,4=mm,5=WDIR,6=WSPD,7=GST,
            //                    8=WVHT,9=DPD,10=APD,11=MWD,12=PRES,13=ATMP,14=WTMP...
            if cols.count > 14 {
                waveHeight         = parseMeasurement(String(cols[8]))
                windSpeed          = parseMeasurement(String(cols[6]))
                dominantWavePeriod = parseMeasurement(String(cols[9]))
                pressure           = parseMeasurement(String(cols[12]))
                airTemp            = parseMeasurement(String(cols[13]))
                waterTemp          = parseMeasurement(String(cols[14]))
            }
        }

        return BuoyObservation(
            stationID: station.id,
            latitude: station.lat,
            longitude: station.lon,
            waveHeight: waveHeight,
            windSpeed: windSpeed,
            dominantWavePeriod: dominantWavePeriod,
            pressure: pressure,
            waterTemperature: waterTemp,
            airTemperature: airTemp
        )
    }

    /// Returns nil for NDBC's sentinel "MM" (missing) value.
    private func parseMeasurement(_ raw: String) -> Double? {
        guard raw != "MM" else { return nil }
        return Double(raw)
    }
}

// MARK: - XML Parser Helper

private final class StationXMLParser: NSObject, XMLParserDelegate {
    var stations: [BuoyStation] = []

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {

        // The NDBC XML uses <station id="..." lat="..." lng="..." ...>
        guard elementName == "station",
              let id  = attributeDict["id"],
              let latStr = attributeDict["lat"],
              let lonStr = attributeDict["lng"] ?? attributeDict["lon"],
              let lat = Double(latStr),
              let lon = Double(lonStr) else { return }

        stations.append(BuoyStation(id: id, lat: lat, lon: lon))
    }
}
