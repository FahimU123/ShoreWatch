// GeminiService.swift
// ShoreWatch

import Foundation

final class GeminiService {

    func assess(buoy: BuoyObservation) async throws -> (AlertLevel, String) {
        if Config.useMockAssessment {
            return (Config.mockAlertLevel, Config.mockNarrative)
        }

        guard let url = URL(string: "\(Config.geminiURL)?key=\(Config.geminiAPIKey)") else {
            throw WatsonxError.generationFailed("Invalid Gemini URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": Config.graniteSystemPrompt]]
            ],
            "contents": [
                ["parts": [["text": """
                Current NOAA buoy data:
                \(buoy.summary)
                Air Temp: \(buoy.airTemperature != nil ? String(format: "%.1f°C", buoy.airTemperature!) : "Unknown")
                Survival Time Est: \(buoy.survivalTimeMinutes != nil ? "\(buoy.survivalTimeMinutes!) mins" : "Unknown")
                
                Provide a threat assessment for Michigan maritime workers. Include specific survival time warnings if water is cold. 
                Reference nearest safe harbors if conditions are worsening.
                """]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 300,
                "temperature": 0.4
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        print("🌐 [Gemini] Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            let raw = String(data: data, encoding: .utf8) ?? "unknown"
            throw WatsonxError.generationFailed(raw)
        }

        return parseOutput(text)
    }

    private func parseOutput(_ raw: String) -> (AlertLevel, String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)

        var alertLevel: AlertLevel = .unknown
        for line in lines.reversed() {
            let upper = line.trimmingCharacters(in: .whitespaces).uppercased()
            if upper == AlertLevel.getOutNow.rawValue      { alertLevel = .getOutNow;      break }
            if upper == AlertLevel.monitorClosely.rawValue { alertLevel = .monitorClosely; break }
            if upper == AlertLevel.allClear.rawValue       { alertLevel = .allClear;       break }
        }

        var narrativeLines: [String] = []
        for line in lines {
            let upper = line.trimmingCharacters(in: .whitespaces).uppercased()
            if upper == alertLevel.rawValue { break }
            narrativeLines.append(line)
        }

        let narrative = narrativeLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (alertLevel, narrative.isEmpty ? trimmed : narrative)
    }
}
