import AppKit
import AVFoundation

/// Menu item that runs a closure
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", checked: Bool = false, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
        state = checked ? .on : .off
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func fire() { handler() }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let settings = Settings.shared
    private let camera = CameraManager()
    private var window: CameraWindow!
    private var cameraView: CameraView!
    private var statusItem: NSStatusItem!
    private var isVisible = false

    private let sizePresets: [(String, CGFloat)] = [
        ("Small", 150), ("Medium", 220), ("Large", 320), ("Extra large", 450)
    ]

    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight, center }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        setupStatusItem()
        showCamera()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Setup

    private func setupWindow() {
        let size = frameSize(for: settings.shape, side: settings.size)
        var frame = NSRect(origin: settings.origin ?? defaultOrigin(for: size), size: size)
        if !NSScreen.screens.contains(where: { $0.visibleFrame.contains(NSPoint(x: frame.midX, y: frame.midY)) }) {
            frame.origin = defaultOrigin(for: size) // saved display is no longer connected
        }

        window = CameraWindow(contentRect: frame)
        window.delegate = self

        cameraView = CameraView(session: camera.session)
        cameraView.frame = NSRect(origin: .zero, size: size)
        cameraView.autoresizingMask = [.width, .height]
        cameraView.shape = settings.shape
        cameraView.showBorder = settings.showBorder
        cameraView.menuProvider = { [weak self] in self?.buildMenu() ?? NSMenu() }
        cameraView.onResize = { [weak self] delta in self?.resize(by: delta) }
        cameraView.onDoubleClick = { [weak self] in self?.cycleShape() }
        window.contentView = cameraView

        applyLevel()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "web.camera", accessibilityDescription: "FloatCam")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Rebuild the menu every time it opens so the checkmarks stay current
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        populate(menu)
    }

    // MARK: - Camera

    private func toggleCamera() {
        isVisible ? hideCamera() : showCamera()
    }

    private func showCamera() {
        camera.requestAccess { [weak self] granted in
            guard let self else { return }
            guard granted else { self.showPermissionAlert(); return }
            self.camera.start(deviceID: self.settings.deviceID) { [weak self] in
                guard let self else { return }
                self.cameraView.setMirrored(self.settings.mirrored)
            }
            self.window.orderFrontRegardless()
            self.isVisible = true
        }
    }

    private func hideCamera() {
        window.orderOut(nil)
        camera.stop()
        isVisible = false
    }

    private func selectDevice(_ id: String) {
        settings.deviceID = id
        guard isVisible else { return }
        camera.start(deviceID: id) { [weak self] in
            guard let self else { return }
            self.cameraView.setMirrored(self.settings.mirrored)
        }
    }

    private func showPermissionAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "No camera access"
        alert.informativeText = "Allow FloatCam in System Settings › Privacy & Security › Camera."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Shape, size and position

    private func frameSize(for shape: CamShape, side: CGFloat) -> NSSize {
        shape.aspect >= 1
            ? NSSize(width: side * shape.aspect, height: side)
            : NSSize(width: side, height: side / shape.aspect)
    }

    private func defaultOrigin(for size: NSSize) -> NSPoint {
        let vf = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSPoint(x: vf.maxX - size.width - 24, y: vf.minY + 24)
    }

    private func clampToScreen(_ frame: NSRect) -> NSRect {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return frame }
        var f = frame
        f.origin.x = min(max(f.minX, vf.minX), vf.maxX - f.width)
        f.origin.y = min(max(f.minY, vf.minY), vf.maxY - f.height)
        return f
    }

    /// Applies shape/size while keeping the window centered
    private func updateFrame(animated: Bool = true) {
        let newSize = frameSize(for: settings.shape, side: settings.size)
        let old = window.frame
        let target = clampToScreen(NSRect(x: old.midX - newSize.width / 2,
                                          y: old.midY - newSize.height / 2,
                                          width: newSize.width,
                                          height: newSize.height))
        cameraView.shape = settings.shape
        window.setFrame(target, display: true, animate: animated)
        window.invalidateShadow()
        settings.origin = target.origin
    }

    private func setShape(_ shape: CamShape) {
        settings.shape = shape
        updateFrame()
    }

    private func cycleShape() {
        let all = CamShape.allCases
        let next = all[(all.firstIndex(of: settings.shape)! + 1) % all.count]
        setShape(next)
    }

    private func setSize(_ side: CGFloat) {
        settings.size = side
        updateFrame()
    }

    private func resize(by delta: CGFloat) {
        settings.size = min(max(settings.size * (1 + delta), 100), 800)
        updateFrame(animated: false)
    }

    private func move(to corner: Corner) {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        let s = window.frame.size
        let m: CGFloat = 24
        let origin: NSPoint
        switch corner {
        case .topLeft:     origin = NSPoint(x: vf.minX + m, y: vf.maxY - s.height - m)
        case .topRight:    origin = NSPoint(x: vf.maxX - s.width - m, y: vf.maxY - s.height - m)
        case .bottomLeft:  origin = NSPoint(x: vf.minX + m, y: vf.minY + m)
        case .bottomRight: origin = NSPoint(x: vf.maxX - s.width - m, y: vf.minY + m)
        case .center:      origin = NSPoint(x: vf.midX - s.width / 2, y: vf.midY - s.height / 2)
        }
        window.setFrame(NSRect(origin: origin, size: s), display: true, animate: true)
    }

    private func applyLevel() {
        // .statusBar stays above regular windows and full-screen apps
        window.level = settings.alwaysOnTop ? .statusBar : .normal
    }

    func windowDidMove(_ notification: Notification) {
        settings.origin = window.frame.origin
    }

    // MARK: - Menu (menu bar + right-click)

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        populate(menu)
        return menu
    }

    private func submenu(_ title: String, _ sub: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = sub
        return item
    }

    private func populate(_ menu: NSMenu) {
        menu.addItem(ClosureMenuItem(isVisible ? "Hide camera" : "Show camera", key: "c") { [weak self] in
            self?.toggleCamera()
        })
        menu.addItem(.separator())

        // Shape
        let shapeMenu = NSMenu()
        for shape in CamShape.allCases {
            shapeMenu.addItem(ClosureMenuItem(shape.title, checked: settings.shape == shape) { [weak self] in
                self?.setShape(shape)
            })
        }
        menu.addItem(submenu("Shape", shapeMenu))

        // Size
        let sizeMenu = NSMenu()
        for (title, value) in sizePresets {
            sizeMenu.addItem(ClosureMenuItem(title, checked: abs(settings.size - value) < 1) { [weak self] in
                self?.setSize(value)
            })
        }
        menu.addItem(submenu("Size", sizeMenu))

        // Position
        let posMenu = NSMenu()
        let corners: [(String, Corner)] = [
            ("Top left", .topLeft), ("Top right", .topRight),
            ("Bottom left", .bottomLeft), ("Bottom right", .bottomRight),
            ("Center", .center)
        ]
        for (title, corner) in corners {
            posMenu.addItem(ClosureMenuItem(title) { [weak self] in self?.move(to: corner) })
        }
        menu.addItem(submenu("Position", posMenu))

        // Camera
        let camMenu = NSMenu()
        let devices = CameraManager.availableDevices()
        let selected = settings.deviceID ?? AVCaptureDevice.default(for: .video)?.uniqueID
        if devices.isEmpty {
            let none = NSMenuItem(title: "No camera found", action: nil, keyEquivalent: "")
            none.isEnabled = false
            camMenu.addItem(none)
        }
        for device in devices {
            camMenu.addItem(ClosureMenuItem(device.localizedName, checked: device.uniqueID == selected) { [weak self] in
                self?.selectDevice(device.uniqueID)
            })
        }
        menu.addItem(submenu("Camera", camMenu))

        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem("Mirror video", checked: settings.mirrored) { [weak self] in
            guard let self else { return }
            self.settings.mirrored.toggle()
            self.cameraView.setMirrored(self.settings.mirrored)
        })
        menu.addItem(ClosureMenuItem("Always on top", checked: settings.alwaysOnTop) { [weak self] in
            guard let self else { return }
            self.settings.alwaysOnTop.toggle()
            self.applyLevel()
        })
        menu.addItem(ClosureMenuItem("Show border", checked: settings.showBorder) { [weak self] in
            guard let self else { return }
            self.settings.showBorder.toggle()
            self.cameraView.showBorder = self.settings.showBorder
        })

        menu.addItem(.separator())
        let hint = NSMenuItem(title: "Drag to move · Pinch or ⌥+scroll to resize · Double-click to change shape",
                              action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)
        menu.addItem(ClosureMenuItem("Quit FloatCam", key: "q") { NSApp.terminate(nil) })
    }
}
