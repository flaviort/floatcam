// Draws the FloatCam app icon and writes Resources/AppIcon.icns.
// Run from the repo root: swift scripts/make-icon.swift
import AppKit

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
}

/// Renders a square image. Drawing code uses a 1024 x 1024 canvas with the origin at the top left.
func render(pixels: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let cg = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    cg.translateBy(x: 0, y: CGFloat(pixels))
    cg.scaleBy(x: CGFloat(pixels) / 1024, y: -CGFloat(pixels) / 1024)
    draw(cg)
    return rep
}

func drawIcon(_ c: CGContext) {
    // Body follows Apple's macOS icon grid: 824 x 824 centered, with room for the shadow
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: color(0x000000, 0.35))
    c.addPath(bodyPath)
    c.setFillColor(color(0x312E81))
    c.fillPath()
    c.restoreGState()

    c.saveGState()
    c.addPath(bodyPath)
    c.clip()
    c.drawLinearGradient(gradient([color(0x6D6AF8), color(0x2E2A85)]),
                         start: CGPoint(x: 200, y: 100), end: CGPoint(x: 824, y: 924), options: [])

    // A screen in the background, standing for whatever is being recorded
    let screen = CGRect(x: 196, y: 248, width: 560, height: 400)
    let screenPath = CGPath(roundedRect: screen, cornerWidth: 34, cornerHeight: 34, transform: nil)
    c.addPath(screenPath)
    c.setFillColor(color(0xFFFFFF, 0.13))
    c.fillPath()
    c.addPath(screenPath)
    c.setStrokeColor(color(0xFFFFFF, 0.28))
    c.setLineWidth(5)
    c.strokePath()
    for (i, x) in [236, 270, 304].enumerated() {
        c.setFillColor(color(0xFFFFFF, 0.55 - CGFloat(i) * 0.1))
        c.fillEllipse(in: CGRect(x: CGFloat(x) - 11, y: 280, width: 22, height: 22))
    }
    for (y, w) in [(344, 300), (392, 380), (440, 240), (488, 330)] {
        let bar = CGRect(x: 236, y: CGFloat(y), width: CGFloat(w), height: 22)
        c.addPath(CGPath(roundedRect: bar, cornerWidth: 11, cornerHeight: 11, transform: nil))
        c.setFillColor(color(0xFFFFFF, 0.28))
        c.fillPath()
    }

    // The floating camera bubble
    let center = CGPoint(x: 648, y: 640)
    let outer: CGFloat = 206, inner: CGFloat = 182
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: 22), blur: 44, color: color(0x0B0A2E, 0.55))
    c.setFillColor(color(0xFFFFFF))
    c.fillEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
    c.restoreGState()

    c.saveGState()
    c.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
    c.clip()
    c.drawLinearGradient(gradient([color(0xFFC27A), color(0xF7709B)]),
                         start: CGPoint(x: center.x, y: center.y - inner),
                         end: CGPoint(x: center.x, y: center.y + inner), options: [])
    // Person silhouette
    c.setFillColor(color(0x241F5C))
    c.fillEllipse(in: CGRect(x: center.x - 140, y: center.y + 70, width: 280, height: 260))
    c.fillEllipse(in: CGRect(x: center.x - 66, y: center.y - 110, width: 132, height: 140))
    c.restoreGState()

    // Live dot
    let dot = CGPoint(x: center.x + 146, y: center.y - 146)
    c.setFillColor(color(0xFFFFFF))
    c.fillEllipse(in: CGRect(x: dot.x - 36, y: dot.y - 36, width: 72, height: 72))
    c.setFillColor(color(0xFF3B4E))
    c.fillEllipse(in: CGRect(x: dot.x - 25, y: dot.y - 25, width: 50, height: 50))

    c.restoreGState()
}

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let png = render(pixels: base * scale, drawIcon).representation(using: .png, properties: [:])!
        try! png.write(to: iconset.appendingPathComponent(name))
    }
}

try! fm.createDirectory(atPath: "Resources", withIntermediateDirectories: true)
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! iconutil.run()
iconutil.waitUntilExit()

let preview = render(pixels: 1024, drawIcon).representation(using: .png, properties: [:])!
try! preview.write(to: URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.png"))
print(iconutil.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
