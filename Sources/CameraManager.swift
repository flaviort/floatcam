import AVFoundation

final class CameraManager {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "floatcam.session")
    private var currentInput: AVCaptureDeviceInput?

    static func availableDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    /// Starts the camera (or switches device if already running)
    func start(deviceID: String?, completion: (() -> Void)? = nil) {
        queue.async {
            self.configure(deviceID: deviceID)
            if !self.session.isRunning { self.session.startRunning() }
            DispatchQueue.main.async { completion?() }
        }
    }

    /// Stops the camera (the green light turns off)
    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configure(deviceID: String?) {
        let devices = Self.availableDevices()
        guard let device = devices.first(where: { $0.uniqueID == deviceID })
                ?? AVCaptureDevice.default(for: .video)
                ?? devices.first else { return }

        if currentInput?.device.uniqueID == device.uniqueID { return }

        session.beginConfiguration()
        if let current = currentInput {
            session.removeInput(current)
            currentInput = nil
        }
        if let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
        session.commitConfiguration()
    }
}
