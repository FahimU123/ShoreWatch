// BuoyDetailSheet.swift
// ShoreWatch

import SwiftUI

struct BuoyDetailSheet: View {
    let buoy: DemoBuoy
    let primaryAssessment: ThreatAssessment?

    @State private var showCallConfirm = false
    @State private var isPulsing = false
    @State private var showNarrative = false
    @State private var showForecast = true
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var alertColor: Color {
        DS.Color.alert(buoy.alertLevel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                headerSection

                statsGrid

                aiAssessmentSection

                forecastSection

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
                Text(buoy.name)
                    .font(.title2.weight(.bold))
                Text("Station \(buoy.id)")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AlertBadgeView(level: buoy.alertLevel)
        }
        .padding(.bottom, DS.Spacing.sm)
    }

    private var statsGrid: some View {
        HStack(spacing: DS.Spacing.md) {
            statCard(title: "WAVES", value: "\(buoy.waveHeight.formatted(.number.precision(.fractionLength(1))))m", icon: "water.waves")
            statCard(title: "WIND", value: "\(buoy.windSpeed.formatted(.number.precision(.fractionLength(0))))m/s", icon: "wind")
            statCard(title: "SURVIVAL", value: primaryAssessment?.buoy.survivalTimeMinutes.map { "\($0) min" } ?? "—", icon: "lifepreserver")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label(title, systemImage: icon)
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    private var aiAssessmentSection: some View {
        DisclosureGroup(isExpanded: $showNarrative) {
            Text(narrative)
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
                    speechManager.speak(narrative)
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

    private var contactSection: some View {
        VStack(spacing: DS.Spacing.md) {
            if buoy.alertLevel == .getOutNow || buoy.alertLevel == .monitorClosely {
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

    private var forecastColor: Color {
        switch buoy.forecastTrend {
        case .worsening: DS.Color.danger
        case .steady:    DS.Color.warning
        case .improving: DS.Color.success
        }
    }

    // MARK: - Narrative Text

    private var narrative: String {
        if let primary = primaryAssessment, buoy.id == primary.buoy.stationID {
            return primary.narrative
                .replacing("**", with: "")
                .replacing("*", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return syntheticNarrative
    }

    private var syntheticNarrative: String {
        let wave = buoy.waveHeight.formatted(.number.precision(.fractionLength(1)))
        let wind = buoy.windSpeed.formatted(.number.precision(.fractionLength(0)))
        switch buoy.alertLevel {
        case .getOutNow:
            return "Waves at \(wave) m with sustained winds of \(wind) m/s. Conditions are extremely dangerous. Exit the water immediately and secure all equipment ashore."
        case .monitorClosely:
            return "Waves at \(wave) m with winds of \(wind) m/s. Conditions are deteriorating. Exercise caution and check for updates before going out."
        case .allClear:
            return "Waves at \(wave) m with light winds of \(wind) m/s. Conditions are favourable. Standard safety precautions apply."
        case .unknown:
            return "Telemetry from this buoy is limited. Conditions cannot be fully assessed — proceed with caution and check an adjacent buoy."
        }
    }
}
