// SafetyDashboardView.swift
// ShoreWatch

import SwiftUI
import CoreLocation

struct SafetyDashboardView: View {
    let location: CLLocation?
    let assessment: ThreatAssessment?
    @Environment(\.dismiss) private var dismiss
    
    @State private var checklist = [
        ChecklistItem(text: "Life jackets for everyone"),
        ChecklistItem(text: "VHF Radio (CH 16) checked"),
        ChecklistItem(text: "Fuel and engine checked"),
        ChecklistItem(text: "Weather forecast reviewed"),
        ChecklistItem(text: "Float plan left with family")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xxl) {
                titleSection

                shareLocationSection

                preDepartureSection

                vhfReferenceSection

                emergencySection
            }
            .padding(DS.Spacing.lg)
        }
        .background(DS.Color.background)
        .scrollIndicators(.hidden)
    }

    private var titleSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Safety Dashboard")
                .font(.largeTitle.weight(.bold))
            Spacer()
            Button("Done") { dismiss() }
                .font(DS.Typography.headline)
        }
    }
    
    private var shareLocationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label("Emergency Location", systemImage: "person.line.dotted.person.fill")
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(.red)
                .textCase(.uppercase)
            
            if let loc = location {
                ShareLink(
                    item: "EMERGENCY — ShoreWatch alert. My location: \(loc.coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \(loc.coordinate.longitude.formatted(.number.precision(.fractionLength(4)))). Please send help or contact Coast Guard: 1-800-424-8802",
                    subject: Text("ShoreWatch Emergency Location"),
                    message: Text("I need assistance. My GPS coordinates are below.")
                ) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                        VStack(alignment: .leading) {
                            Text("Share My Location")
                                .font(DS.Typography.headline)
                            Text("Send coordinates to family or rescue")
                                .font(DS.Typography.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(DS.Spacing.lg)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    .foregroundStyle(.red)
                }
            } else {
                Text("Waiting for GPS signal…")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.secondaryText)
            }
        }
    }
    
    private var preDepartureSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label("Pre-Departure Checklist", systemImage: "checklist")
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach($checklist) { $item in
                    Toggle(isOn: $item.isDone) {
                        Text(item.text)
                            .font(DS.Typography.body)
                    }
                    .padding(.vertical, DS.Spacing.md)
                    
                    if item.id != checklist.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
    }

    private var vhfReferenceSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label("VHF Radio Reference", systemImage: "radio")
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(DS.Color.secondaryText)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                ForEach(VHFChannel.standardChannels) { item in
                    HStack {
                        Text("CH \(item.channel)")
                            .font(DS.Typography.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(item.purpose)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Color.primaryText)
                        
                        Spacer()
                    }
                    .padding(.vertical, DS.Spacing.sm)
                    
                    if item.id != VHFChannel.standardChannels.last?.id {
                        Divider()
                    }
                }
            }
            .padding(DS.Spacing.lg)
            .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
    }

    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label("Emergency Contacts", systemImage: "phone.fill")
                .font(DS.Typography.sectionLabel())
                .foregroundStyle(DS.Color.danger)
                .textCase(.uppercase)
            
            VStack(spacing: DS.Spacing.sm) {
                emergencyLink(name: "Coast Guard (Rescue)", phone: "18004248802", display: "1-800-424-8802")
                emergencyLink(name: "Local Towing (BoatUS)", phone: "18003914869", display: "1-800-391-4869")
            }
        }
    }
    
    private func emergencyLink(name: String, phone: String, display: String) -> some View {
        Link(destination: URL(string: "tel:\(phone)")!) {
            HStack {
                Text(name)
                    .font(DS.Typography.body.weight(.semibold))
                Spacer()
                Text(display)
                    .font(DS.Typography.caption.monospaced())
            }
            .padding(DS.Spacing.lg)
            .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .foregroundStyle(DS.Color.primaryText)
        }
    }
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let text: String
    var isDone = false
}
