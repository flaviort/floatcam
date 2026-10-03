import Foundation
import CoreGraphics

enum CamShape: String, CaseIterable {
    case circle, roundedSquare, rectangle, portrait

    var title: String {
        switch self {
        case .circle: return "Circle"
        case .roundedSquare: return "Rounded square"
        case .rectangle: return "Rectangle 16:9"
        case .portrait: return "Portrait 3:4"
        }
    }

    /// width / height
    var aspect: CGFloat {
        switch self {
        case .circle, .roundedSquare: return 1
        case .rectangle: return 16.0 / 9.0
        case .portrait: return 3.0 / 4.0
        }
    }

    func cornerRadius(for size: CGSize) -> CGFloat {
        let side = min(size.width, size.height)
        switch self {
        case .circle: return side / 2
        case .roundedSquare: return side * 0.2
        case .rectangle, .portrait: return side * 0.08
        }
    }
}

/// Preferences persisted in UserDefaults
final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    var shape: CamShape {
        get { CamShape(rawValue: d.string(forKey: "shape") ?? "") ?? .circle }
        set { d.set(newValue.rawValue, forKey: "shape") }
    }

    /// Length of the window's shorter side, in points
    var size: CGFloat {
        get { let v = d.double(forKey: "size"); return v > 0 ? CGFloat(v) : 220 }
        set { d.set(Double(newValue), forKey: "size") }
    }

    var mirrored: Bool {
        get { d.object(forKey: "mirrored") as? Bool ?? true }
        set { d.set(newValue, forKey: "mirrored") }
    }

    var alwaysOnTop: Bool {
        get { d.object(forKey: "alwaysOnTop") as? Bool ?? true }
        set { d.set(newValue, forKey: "alwaysOnTop") }
    }

    var showBorder: Bool {
        get { d.object(forKey: "showBorder") as? Bool ?? false }
        set { d.set(newValue, forKey: "showBorder") }
    }

    var deviceID: String? {
        get { d.string(forKey: "deviceID") }
        set { d.set(newValue, forKey: "deviceID") }
    }

    var origin: CGPoint? {
        get {
            guard d.object(forKey: "originX") != nil else { return nil }
            return CGPoint(x: d.double(forKey: "originX"), y: d.double(forKey: "originY"))
        }
        set {
            if let p = newValue {
                d.set(Double(p.x), forKey: "originX")
                d.set(Double(p.y), forKey: "originY")
            } else {
                d.removeObject(forKey: "originX")
                d.removeObject(forKey: "originY")
            }
        }
    }
}
