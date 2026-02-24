// Reflect/Views/Routine/QRScannerView.swift
import SwiftUI
import AVFoundation

struct QRScannerView: View {
    let onScan: (String) -> Void
    let onCancel: () -> Void

    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var isScanning = true

    var body: some View {
        ZStack {
            if cameraPermission == .authorized {
                CameraPreview(onCodeScanned: { code in
                    guard isScanning else { return }
                    isScanning = false
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onScan(code)
                })
                .ignoresSafeArea()

                // Viewfinder overlay
                scanOverlay
            } else if cameraPermission == .denied || cameraPermission == .restricted {
                cameraRequiredView
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .onDisappear {
            isScanning = false  // Prevent double-callback edge cases
        }
    }

    private var scanOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(Spacing.xl)
                }
            }

            Spacer()

            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(AppColor.amber, lineWidth: 2)
                .frame(width: 240, height: 240)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(AppColor.amber.opacity(0.05))
                )

            Text(Strings.routineScanSubtitle)
                .font(AppFont.callout)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, Spacing.lg)

            Spacer()
        }
    }

    private var cameraRequiredView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColor.secondaryLabel)
            Text(Strings.qrCameraRequiredTitle)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
            Text(Strings.qrCameraRequiredBody)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppFont.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(AppGradient.warmCTA)
            .cornerRadius(CornerRadius.lg)

            Button(Strings.cancel, action: onCancel)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
        }
        .padding(Spacing.xxl)
        .warmBackground()
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        } else {
            cameraPermission = status
        }
    }
}

// MARK: - Camera Preview (AVCaptureSession wrapper)

struct CameraPreview: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.onCodeScanned = onCodeScanned
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private let captureSession = AVCaptureSession()

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = bounds
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else { return }
        onCodeScanned?(value)
    }

    deinit {
        captureSession.stopRunning()
    }
}
