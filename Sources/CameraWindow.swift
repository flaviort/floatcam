import AppKit
import AVFoundation

/// Borderless, transparent window visible on all Spaces and over full-screen apps
final class CameraWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isFloatingPanel = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    override var canBecomeKey: Bool { true }
}

/// View that shows the video, masked to the selected shape
final class CameraView: NSView {
    let previewLayer: AVCaptureVideoPreviewLayer

    var shape: CamShape = .circle { didSet { needsLayout = true } }
    var showBorder = false { didSet { needsLayout = true } }

    var menuProvider: (() -> NSMenu)?
    var onResize: ((CGFloat) -> Void)?
    var onDoubleClick: (() -> Void)?

    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.black.cgColor
        previewLayer.videoGravity = .resizeAspectFill
        layer?.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        layer?.cornerRadius = shape.cornerRadius(for: bounds.size)
        layer?.cornerCurve = shape == .circle ? .circular : .continuous
        layer?.borderWidth = showBorder ? 3 : 0
        layer?.borderColor = NSColor.white.withAlphaComponent(0.9).cgColor
        CATransaction.commit()
        window?.invalidateShadow()
    }

    func setMirrored(_ mirrored: Bool) {
        guard let connection = previewLayer.connection, connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = mirrored
    }

    // Drag to move / double-click to cycle shape
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
            return
        }
        window?.performDrag(with: event)
    }

    // Right-click opens the same menu as the menu bar icon
    override func menu(for event: NSEvent) -> NSMenu? {
        menuProvider?()
    }

    // Trackpad pinch to resize
    override func magnify(with event: NSEvent) {
        onResize?(event.magnification)
    }

    // ⌥ + scroll to resize
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            onResize?(event.scrollingDeltaY * 0.01)
        } else {
            super.scrollWheel(with: event)
        }
    }
}
