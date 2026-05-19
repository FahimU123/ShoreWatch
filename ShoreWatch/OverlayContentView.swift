// OverlayContentView.swift
// ShoreWatch
// Primary assessment sheet — shown automatically when the pipeline completes.

import SwiftUI
import CoreLocation

struct OverlayContentView: View {
    let assessment: ThreatAssessment
    let location: CLLocation?

    @State private var showCallConfirm = false
    @State private var isPulsing = false
    @State private var showNarrative = false
    @State private var showForecast = false
    @State private var showVHF = false
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.openURL) private var openURL

    private var alertColor: Color {
        DS.Color.alert(assessment.alertLevel)
    }

    private var demoBuoy: DemoBuoy? {
        DemoBuoy.lakeErie.first { $0.id == assessment.buoy.stationID }
    }

    private var nearestHarbor: SafeHarbor? {
        guard let loc = location else { return SafeHarbor.lakeErieHarbors.first }
        return SafeHarbor.lakeErieHarbors.min {
            let a = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let b = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return loc.distance(from: a) < loc.distance(from: b)
        }
    }

    private func navigateToHarbor(_ harbor: SafeHarbor) {
        let name = harbor.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? harbor.name
        let url = URL(string: "maps://?q=\(name)&ll=\(harbor.coordinate.latitude),\(harbor.coordinate.longitude)&dirflg=d")
            ?? URL(string: "https://maps.apple.com/?q=\(name)&ll=\(harbor.coordinate.latitude),\(harbor.coordinate.longitude)")
        if let url { openURL(url) }
    }

    private var distanceLabel: String {
        guard let loc = location else { return "Lake Erie" }
        let buoyLoc = CLLocation(latitude: assessment.buoy.latitude, longitude: assessment.buoy.longitude)
        let nm = loc.distance(from: buoyLoc) / 1_852.0
        return "\(nm.formatted(.number.precision(.fractionLength(0)))) nm away"
    }

    private var updatedLabel: String {
        let elapsed = Date.now.timeIntervalSince(assessment.fetchedAt)
        if elapsed < 60 { return "Just now" }
        return "\(Int(elapsed / 60))m ago"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                headerSection

                statsGrid

                safetyInsightsGrid

                aiAssessmentSection

                forecastSection

                radioReferenceSection

                contactSection

                Spacer(minLength: DS.Spacing.xxxl)
            }
            .padding(DS.Spacing.lg)
        }
        .background(DS.Color.background)
        .scrollIndicators(.hidden)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(DS.Anim.pulse) { isPulsing = true }
        }
        .onDisappear {
            speechManager.stop()
        }
        .confirmationDialog(
            "Contact Coast Guard?",
            isPresented: $showCallConfirm,
            titleVisibility: .visible
        ) {
            Button("Call 1-800-424-8802") {
                if let url = URL(string: "tel:18004248802") { openURL(url) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("USCG National Response Center. Available 24/7.")
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(demoBuoy?.name ?? "Buoy \(assessment.buoy.stationID)")
                    .font(.title2.weight(.bold))
                Text("Station \(assessment.buoy.stationID)  ·  \(distanceLabel)  ·  \(updatedLabel)")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            AlertBadgeView(level: assessment.alertLevel)
        }
        .padding(.bottom, DS.Spacing.sm)
    }

    private var statsGrid: some View {
        let waveValue = assessment.buoy.windSpeed
            .map { "\($0.formatted(.number.precision(.fractionLength(1))))m" } ?? "—m"
        let windValue = assessment.buoy.waveHeight
            .map { "\($0.formatted(.number.precision(.fractionLength(0))))m/s" } ?? "—m/s"

        return HStack(spacing: DS.Spacing.md) {
            statCard(title: "WAVES", value: waveValue, icon: "water.waves")
            statCard(title: "WIND", value: windValue, icon: "wind")
            if let period = assessment.buoy.dominantWavePeriod {
                statCard(title: "PERIOD", value: "\(period.formatted(.number.precision(.fractionLength(0))))s", icon: "timer")
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label(title, systemImage: icon)
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    private var safetyInsightsGrid: some View {
        HStack(spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Label("SURVIVAL TIME", systemImage: "lifepreserver")
                    .font(DS.Typography.sectionLabel())
                    .foregroundStyle(.secondary)
                if let minutes = assessment.buoy.survivalTimeMinutes {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(minutes)")
                            .font(.title2.weight(.bold))
                        Text("min")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("—")
                        .font(.title2.weight(.bold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.md)
            .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))

            Button {
                if let harbor = nearestHarbor { navigateToHarbor(harbor) }
            } label: {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Label("NEAREST HARBOR", systemImage: "ferry")
                        .font(DS.Typography.sectionLabel())
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.monochrome)
                    HStack(alignment: .firstTextBaseline) {
                        Text(nearestHarbor?.name ?? "Detecting…")
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.monochrome)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.md)
                .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var aiAssessmentSection: some View {
        DisclosureGroup(isExpanded: $showNarrative) {
            Text(cleanedNarrative)
                .font(DS.Typography.body)
                .padding(.top, DS.Spacing.sm)
                .fixedSize(horizontal: false, vertical: true)
        } label: {
            HStack {
                Label("Assessment", systemImage: "sparkles")
                    .font(DS.Typography.sectionLabel())
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.monochrome)
                Spacer()
                Button {
                    speechManager.speak(cleanedNarrative)
                } label: {
                    Image(systemName: speechManager.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.monochrome)
                }
                .buttonStyle(.plain)
            }
        }
        .tint(.secondary)
        .padding(DS.Spacing.md)
        .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    private var forecastSection: some View {
        Group {
            if let buoy = demoBuoy {
                DisclosureGroup(isExpanded: $showForecast) {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        HStack {
                            Text("Trend")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Label(buoy.forecastTrend.label, systemImage: buoy.forecastTrend.systemImage)
                                .foregroundStyle(.primary)
                                .symbolRenderingMode(.monochrome)
                        }
                        if let window = buoy.safeWindowLabel {
                            Divider()
                            Text(window)
                                .font(DS.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(DS.Typography.subheadline)
                    .padding(.top, DS.Spacing.sm)
                } label: {
                    Label("FORECAST", systemImage: "chart.line.uptrend.xyaxis")
                        .font(DS.Typography.sectionLabel())
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.monochrome)
                }
                .tint(.secondary)
                .padding(DS.Spacing.md)
                .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            }
        }
    }

    private var radioReferenceSection: some View {
        DisclosureGroup(isExpanded: $showVHF) {
            VStack(spacing: 0) {
                ForEach(VHFChannel.standardChannels) { item in
                    HStack {
                        Text("CH \(item.channel)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 50, alignment: .leading)
                        Text(item.purpose)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.vertical, DS.Spacing.xs)
                    if item.id != VHFChannel.standardChannels.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, DS.Spacing.sm)
        } label: {
            Label("RADIO REFERENCE", systemImage: "radio")
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.monochrome)
        }
        .tint(.secondary)
        .padding(DS.Spacing.md)
        .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    private var contactSection: some View {
        VStack(spacing: DS.Spacing.md) {
            if assessment.alertLevel == .getOutNow || assessment.alertLevel == .monitorClosely {
                Button(action: { showCallConfirm = true }) {
                    Label("Contact Coast Guard", systemImage: "phone.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DS.Color.danger, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                }
            }
            
            Text("Emergency: 1-800-424-8802")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func forecastColor(_ trend: ForecastTrend) -> Color {
        switch trend {
        case .worsening: DS.Color.danger
        case .steady:    DS.Color.warning
        case .improving: DS.Color.success
        }
    }

    private var cleanedNarrative: String {
        assessment.narrative
            .replacing("**", with: "")
            .replacing("*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
