// Config.swift
// ShoreWatch
//
// Fill in your credentials here. Never commit this file with real keys.

enum Config {
    // IBM watsonx.ai
    static let watsonxAPIKey: String = "YOUR_IBM_WATSONX_API_KEY"
    static let watsonxProjectID: String = "YOUR_IBM_WATSONX_PROJECT_ID"

    // IBM IAM token endpoint
    static let iamTokenURL: String = "https://iam.cloud.ibm.com/identity/token"

    // IBM watsonx.ai generation endpoint
    static let watsonxGenerationURL: String =
        "https://us-south.ml.cloud.ibm.com/ml/v1/text/generation?version=2023-05-29"

    // IBM Granite model ID
    static let graniteModelID: String = "ibm/granite-3-8b-instruct"

    // NOAA National Data Buoy Center
    static let noaaBaseURL: String = "https://www.ndbc.noaa.gov"

    // Demo: set to true to force a location on Lake Erie (Station 45005)
    // so the nearest-buoy lookup always succeeds in the simulator.
    static let useDemoLocation: Bool = true
    static let demoLatitude: Double  = 41.68   // Lake Erie, west basin
    static let demoLongitude: Double = -82.39  // ~40 mi south of Detroit

    // Gemini API (replaces IBM watsonx for AI assessment)
    static let geminiAPIKey: String = "AIzaSyBgJVFXO_b4ohneo8WuCWwDkuzRAFHKRe8"
    static let geminiURL: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    // Demo: skip the real NOAA fetch and return a hardcoded buoy observation.
    static let useMockBuoy: Bool = true
    static let mockBuoyStation: String = "45005"

    // Demo: skip the real AI API and return a canned assessment.
    static let useMockAssessment: Bool = true
    static let mockAlertLevel: AlertLevel = .getOutNow
    static let mockNarrative: String = """
        Wave height 2.4 m and rising rapidly. Sustained winds at 47 knots out of the southwest \
        with gusts exceeding 58. Barometric pressure has fallen 9 hPa in three hours — \
        a severe deepening event. Lake Erie's west basin is fully exposed on this fetch. \
        All vessels under 40 ft should be out of the water immediately. \
        Commercial operators: secure equipment and seek shelter. \
        Coast Guard has issued a Gale Warning for this zone through 20:00 local time.
        """

    // Granite system prompt
    static let graniteSystemPrompt: String = """
        You are ShoreWatch, a Great Lakes coastal safety AI advisor for Michigan maritime workers. \
        You receive raw NOAA buoy data and output a plain English threat assessment. \
        Always be direct, specific, and urgent when conditions are dangerous. \
        End every response with exactly one of these three alert levels on its own line: \
        GET OUT NOW, MONITOR CLOSELY, or ALL CLEAR.
        """
}
