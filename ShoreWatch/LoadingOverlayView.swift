// LoadingOverlayView.swift
// ShoreWatch

import SwiftUI

struct LoadingOverlayView: View {
    let state: LoadingState

    @State private var pulseOuter = false
    @State private var pulseInner = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLoading: Bool {
        switch state {
        case .idle, .locating, .fetchingBuoy, .assessing: true
        case .ready, .failed: false
        }
    }

    private var label: String {
        switch state {
        case .idle:         "Starting up…"
        case .locating:     "Finding your location…"
        case .fetchingBuoy: "Reading buoy data…"
        case .assessing:    "Analyzing conditions…"
        case .ready, .failed: ""
        }
    }

    var body: some View {
        if isLoading {
            VStack {
                Spacer()
                HStack(spacing: DS.Spacing.md) {
                    ProgressView()
                        .tint(.secondary)

                    Text(label)
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.secondary.opacity(0.1), lineWidth: 0.5))
                .padding(.bottom, DS.Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
        }
    }
}


