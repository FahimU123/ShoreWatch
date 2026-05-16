// CameraPreviewView.swift
// ShoreWatch
//
// A UIViewRepresentable that wraps an AVCaptureSession preview layer,
// used as the full-screen live camera background.

import SwiftUI
import AVFoundation

#if canImport(UIKit)
import UIKit

struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

// MARK: - PreviewUIView

final class PreviewUIView: UIView {

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
    }
}
#else
struct CameraPreviewView: View {
    let session: AVCaptureSession
    var body: some View {
        Color.black
            .overlay(Text("Camera Preview (iOS Only)").foregroundStyle(.white))
    }
}
#endif
