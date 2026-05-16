// WatsonxService.swift
// ShoreWatch
//
// Obtains an IAM bearer token, then calls IBM watsonx.ai to generate
// a threat assessment from NOAA buoy data.

import Foundation

enum WatsonxError: LocalizedError {
    case tokenFetchFailed(String)
    case generationFailed(String)
    case badResponse
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .tokenFetchFailed(let msg): return "IBM IAM auth failed: \(msg)"
        case .generationFailed(let msg): return "Granite generation failed: \(msg)"
        case .badResponse:               return "Unexpected response from watsonx.ai."
        case .networkError(let e):       return "Network error: \(e.localizedDescription)"
        }
    }
}

final class WatsonxService {

    // MARK: - IAM Token Cache

    private var cachedToken: String?
    private var tokenExpiry: Date = .distantPast

    // MARK: - Public API

    /// Returns an alert level and narrative for the given buoy observation.
    func assess(buoy: BuoyObservation) async throws -> (AlertLevel, String) {
        if Config.useMockAssessment {
            try? await Task.sleep(for: .seconds(2)) // feels like a real API call
            return (Config.mockAlertLevel, Config.mockNarrative)
        }
        let token = try await iamToken()
        let rawOutput = try await generateText(prompt: buildPrompt(buoy: buoy), token: token)
        return parseOutput(rawOutput)
    }

    // MARK: - IAM Token

    private func iamToken() async throws -> String {
        if let cached = cachedToken, Date() < tokenExpiry {
            return cached
        }

        guard let url = URL(string: Config.iamTokenURL) else {
            throw WatsonxError.tokenFetchFailed("Invalid IAM URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=\(Config.watsonxAPIKey)"
        request.httpBody = body.data(using: .utf8)

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw WatsonxError.networkError(error)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw WatsonxError.tokenFetchFailed(msg)
        }

        let expiresIn = (json["expires_in"] as? Double) ?? 3600
        cachedToken = token
        tokenExpiry = Date().addingTimeInterval(expiresIn - 60) // refresh 1 min early
        return token
    }

    // MARK: - Text Generation

    private func generateText(prompt: String, token: String) async throws -> String {
        guard let url = URL(string: Config.watsonxGenerationURL) else {
            throw WatsonxError.generationFailed("Invalid generation URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model_id": Config.graniteModelID,
            "project_id": Config.watsonxProjectID,
            "input": prompt,
            "parameters": [
                "decoding_method": "greedy",
                "max_new_tokens": 300,
                "stop_sequences": []
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw WatsonxError.networkError(error)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let first = results.first,
              let generated = first["generated_text"] as? String else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw WatsonxError.generationFailed(msg)
        }

        return generated
    }

    // MARK: - Prompt Builder

    private func buildPrompt(buoy: BuoyObservation) -> String {
        """
        \(Config.graniteSystemPrompt)

        Current NOAA buoy data:
        \(buoy.summary)

        Provide a threat assessment for Michigan maritime workers:
        """
    }

    // MARK: - Output Parser

    private func parseOutput(_ raw: String) -> (AlertLevel, String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)

        // The model is instructed to end with the alert level on its own line.
        var alertLevel: AlertLevel = .unknown
        var narrativeLines: [String] = []

        for line in lines.reversed() {
            let upper = line.trimmingCharacters(in: .whitespaces).uppercased()
            if upper == AlertLevel.getOutNow.rawValue {
                alertLevel = .getOutNow
                break
            } else if upper == AlertLevel.monitorClosely.rawValue {
                alertLevel = .monitorClosely
                break
            } else if upper == AlertLevel.allClear.rawValue {
                alertLevel = .allClear
                break
            }
        }

        // Everything before the alert level line is the narrative.
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
