// CameraManager.swift
// ShoreWatch
//
// Sets up an AVCaptureSession with the back wide-angle camera.
// The session is started on a background queue and kept running
// for the app's lifetime.

import AVFoundation
import Combine

@MainActor
final class CameraManager: ObservableObject {

    nonisolated let session = AVCaptureSession()
    @Published var isAuthorized = false

    private let sessionQueue = DispatchQueue(label: "com.shorewatch.camera.session")

    // MARK: - Setup

    func requestPermissionAndConfigure() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }

        if isAuthorized {
            configureSession()
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                ),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}
