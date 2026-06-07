import AppKit
import Foundation

let outputDirectory = URL(filePath: "AppProject/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for icon in iconSizes {
    let image = NSImage(size: NSSize(width: icon.pixels, height: icon.pixels))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: icon.pixels, height: icon.pixels)
    let scale = CGFloat(icon.pixels)

    let background = NSBezierPath(
        roundedRect: rect.insetBy(dx: scale * 0.06, dy: scale * 0.06),
        xRadius: scale * 0.22,
        yRadius: scale * 0.22
    )
    NSGradient(colors: [
        NSColor(calibratedRed: 0.03, green: 0.10, blue: 0.22, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.32, blue: 0.62, alpha: 1)
    ])?.draw(in: background, angle: 135)

    let glow = NSBezierPath(ovalIn: NSRect(x: scale * 0.15, y: scale * 0.12, width: scale * 0.7, height: scale * 0.7))
    NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.14).setFill()
    glow.fill()

    let leftEar = NSBezierPath()
    leftEar.move(to: NSPoint(x: scale * 0.24, y: scale * 0.62))
    leftEar.line(to: NSPoint(x: scale * 0.28, y: scale * 0.86))
    leftEar.line(to: NSPoint(x: scale * 0.43, y: scale * 0.68))
    leftEar.close()

    let rightEar = NSBezierPath()
    rightEar.move(to: NSPoint(x: scale * 0.57, y: scale * 0.68))
    rightEar.line(to: NSPoint(x: scale * 0.72, y: scale * 0.86))
    rightEar.line(to: NSPoint(x: scale * 0.76, y: scale * 0.62))
    rightEar.close()

    let catHead = NSBezierPath(ovalIn: NSRect(x: scale * 0.2, y: scale * 0.18, width: scale * 0.6, height: scale * 0.56))
    let catColor = NSColor(calibratedRed: 0.83, green: 0.90, blue: 1.0, alpha: 1)
    catColor.setFill()
    leftEar.fill()
    rightEar.fill()
    catHead.fill()

    let innerEarColor = NSColor(calibratedRed: 0.30, green: 0.50, blue: 0.83, alpha: 0.85)
    innerEarColor.setFill()

    let leftInnerEar = NSBezierPath()
    leftInnerEar.move(to: NSPoint(x: scale * 0.29, y: scale * 0.64))
    leftInnerEar.line(to: NSPoint(x: scale * 0.31, y: scale * 0.76))
    leftInnerEar.line(to: NSPoint(x: scale * 0.38, y: scale * 0.66))
    leftInnerEar.close()
    leftInnerEar.fill()

    let rightInnerEar = NSBezierPath()
    rightInnerEar.move(to: NSPoint(x: scale * 0.62, y: scale * 0.66))
    rightInnerEar.line(to: NSPoint(x: scale * 0.69, y: scale * 0.76))
    rightInnerEar.line(to: NSPoint(x: scale * 0.71, y: scale * 0.64))
    rightInnerEar.close()
    rightInnerEar.fill()

    NSColor(calibratedRed: 0.03, green: 0.16, blue: 0.34, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.35, y: scale * 0.48, width: scale * 0.075, height: scale * 0.095)).fill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.575, y: scale * 0.48, width: scale * 0.075, height: scale * 0.095)).fill()

    NSColor(calibratedRed: 0.03, green: 0.16, blue: 0.34, alpha: 0.88).setFill()
    let nose = NSBezierPath()
    nose.move(to: NSPoint(x: scale * 0.5, y: scale * 0.43))
    nose.line(to: NSPoint(x: scale * 0.535, y: scale * 0.465))
    nose.line(to: NSPoint(x: scale * 0.465, y: scale * 0.465))
    nose.close()
    nose.fill()

    let mouth = NSBezierPath()
    mouth.move(to: NSPoint(x: scale * 0.5, y: scale * 0.43))
    mouth.curve(
        to: NSPoint(x: scale * 0.45, y: scale * 0.39),
        controlPoint1: NSPoint(x: scale * 0.49, y: scale * 0.4),
        controlPoint2: NSPoint(x: scale * 0.47, y: scale * 0.39)
    )
    mouth.move(to: NSPoint(x: scale * 0.5, y: scale * 0.43))
    mouth.curve(
        to: NSPoint(x: scale * 0.55, y: scale * 0.39),
        controlPoint1: NSPoint(x: scale * 0.51, y: scale * 0.4),
        controlPoint2: NSPoint(x: scale * 0.53, y: scale * 0.39)
    )
    NSColor(calibratedRed: 0.03, green: 0.16, blue: 0.34, alpha: 0.65).setStroke()
    mouth.lineWidth = max(1, scale * 0.012)
    mouth.stroke()

    let whiskerColor = NSColor(calibratedRed: 0.03, green: 0.16, blue: 0.34, alpha: 0.45)
    whiskerColor.setStroke()
    for offset in [-0.03, 0.02] {
        let y = scale * (0.42 + offset)
        let leftWhisker = NSBezierPath()
        leftWhisker.move(to: NSPoint(x: scale * 0.41, y: y))
        leftWhisker.line(to: NSPoint(x: scale * 0.23, y: y + scale * offset * 0.7))
        leftWhisker.lineWidth = max(1, scale * 0.008)
        leftWhisker.stroke()

        let rightWhisker = NSBezierPath()
        rightWhisker.move(to: NSPoint(x: scale * 0.59, y: y))
        rightWhisker.line(to: NSPoint(x: scale * 0.77, y: y + scale * offset * 0.7))
        rightWhisker.lineWidth = max(1, scale * 0.008)
        rightWhisker.stroke()
    }

    NSColor(calibratedRed: 0.54, green: 0.91, blue: 1.0, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.73, y: scale * 0.27, width: scale * 0.18, height: scale * 0.18)).fill()
    NSColor(calibratedRed: 0.03, green: 0.10, blue: 0.22, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.78, y: scale * 0.31, width: scale * 0.16, height: scale * 0.16)).fill()

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(icon.name)")
    }

    try png.write(to: outputDirectory.appending(path: icon.name))
}

print("Generated \(iconSizes.count) app icons")
