// ContentView.swift
// ShoreWatch

import SwiftUI
import CoreLocation

// Single source of truth for which sheet is presented.
enum ActiveSheet: Identifiable {
    case assessment
    case buoy(DemoBuoy)
    case safetyDashboard

    var id: String {
        switch self {
        case .assessment:      "assessment"
        case .buoy(let b):     "buoy-\(b.id)"
        case .safetyDashboard: "safetyDashboard"
        }
    }
}

struct ContentView: View {

    @StateObject private var viewModel = AssessmentViewModel()
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedBuoy: DemoBuoy?
    @State private var activeSheet: ActiveSheet?
    @State private var isARMode = false
    @State private var refreshHapticToken = false
    @AppStorage("showAIS") private var showAIS = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mainContentStack
                
                VStack {
                    LoadingOverlayView(state: viewModel.loadingState)
                    failureOverlay
                }
            }
            .navigationTitle("ShoreWatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    safetyButton
                    refreshButton
                    aisToggle
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    viewModeToggle
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task { await viewModel.start() }
        .sheet(item: $activeSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: - Subviews

    private var safetyButton: some View {
        Button {
            activeSheet = .safetyDashboard
        } label: {
            Label("Safety", systemImage: "shield")
        }
    }

    private var viewModeToggle: some View {
        Button {
            isARMode.toggle()
        } label: {
            Label(isARMode ? "AR" : "Map", systemImage: isARMode ? "arkit" : "map")
        }
    }

    private var aisToggle: some View {
        Button {
            showAIS.toggle()
        } label: {
            Label("AIS", systemImage: showAIS ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
        }
    }

    private var refreshButton: some View {
        Group {
            if viewModel.assessment != nil {
                Button {
                    refreshHapticToken.toggle()
                    Task {
                        activeSheet = nil
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var mainContentStack: some View {
        ZStack {
            if isARMode {
                arModeView
            } else {
                mapModeView
            }

            vignetteOverlay

            if viewModel.assessment != nil, activeSheet == nil {
                restorePillView
            }
        }
        .animation(DS.Anim.spring, value: activeSheet == nil)
        .animation(.easeInOut(duration: 0.4), value: isARMode)
        .onChange(of: selectedBuoy) { _, buoy in
            if let buoy {
                activeSheet = .buoy(buoy)
            }
        }
        .onChange(of: activeSheet?.id) { _, _ in
            if case .buoy(let b) = activeSheet { selectedBuoy = b }
            else { selectedBuoy = nil }
        }
        .onChange(of: viewModel.loadingState) { _, state in
            if case .ready = state { activeSheet = .assessment }
        }
        .onChange(of: isARMode) { _, active in
            handleARModeChange(active)
        }
    }

    private var arModeView: some View {
        CameraPreviewView(session: cameraManager.session)
            .ignoresSafeArea()
            .transition(.opacity)
            .overlay {
                arHUD
            }
    }

    private var arHUD: some View {
        VStack {
            Spacer()
            if let assessment = viewModel.assessment {
                VStack(spacing: DS.Spacing.xl) {
                    CompassPointerView(
                        userLocation: viewModel.currentLocation,
                        targetCoordinate: assessment.buoy.coordinate,
                        userHeading: viewModel.locationManager.heading?.trueHeading ?? 0
                    )
                    ARInfoBar(assessment: assessment)
                }
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.massive)
            }
        }
    }

    private var mapModeView: some View {
        BuoyMapView(
            buoys: DemoBuoy.lakeErie,
            vessels: Vessel.lakeErieVessels,
            selectedBuoy: $selectedBuoy
        )
        .ignoresSafeArea()
        .transition(.opacity)
    }

    private var vignetteOverlay: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.3)],
            startPoint: .center,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var restorePillView: some View {
        Group {
            if let assessment = viewModel.assessment {
                RestorePill(assessment: assessment) {
                    activeSheet = .assessment
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
            }
        }
    }

    private var failureOverlay: some View {
        Group {
            if case .failed(let message) = viewModel.loadingState {
                VStack {
                    CornerPill {
                        Text(message)
                            .font(DS.Typography.caption.bold())
                            .foregroundStyle(.white)
                    }
                    .background(DS.Color.danger, in: Capsule())
                    Spacer()
                }
                .padding(.top, DS.Spacing.sm)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .assessment:
            if let assessment = viewModel.assessment {
                OverlayContentView(
                    assessment: assessment,
                    location: viewModel.currentLocation
                )
            }
        case .buoy(let buoy):
            BuoyDetailSheet(buoy: buoy, primaryAssessment: viewModel.assessment)
        case .safetyDashboard:
            SafetyDashboardView(
                location: viewModel.currentLocation,
                assessment: viewModel.assessment
            )
        }
    }

    private func handleARModeChange(_ active: Bool) {
        if active {
            Task { await cameraManager.requestPermissionAndConfigure() }
        } else {
            cameraManager.stop()
        }
    }
}

struct CornerPill<Content: View>: View {
    let content: () -> Content
    var body: some View {
        content()
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
    }
}

#Preview {
    ContentView()
}
