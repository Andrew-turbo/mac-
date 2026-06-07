import AppKit
import Foundation

struct IconVariant {
    let id: Int
    let name: String
    let backgroundA: NSColor
    let backgroundB: NSColor
    let head: NSColor
    let innerEar: NSColor
    let eye: NSColor
    let accent: NSColor
    let sparkle: NSColor
    let mood: Mood
}

enum Mood {
    case classic
    case cyber
    case midnight
    case mint
    case sunset
    case graphite
    case cream
    case violet
    case aqua
    case mono
}

let variants: [IconVariant] = [
    IconVariant(id: 1, name: "Classic Cyan", backgroundA: color(0.11, 0.12, 0.18), backgroundB: color(0.05, 0.32, 0.47), head: color(0.92, 0.94, 0.98), innerEar: color(0.21, 0.55, 0.70), eye: color(0.0, 0.78, 0.82), accent: color(0.07, 0.12, 0.17), sparkle: color(1.0, 0.84, 0.24), mood: .classic),
    IconVariant(id: 2, name: "Dark Neon", backgroundA: color(0.06, 0.07, 0.11), backgroundB: color(0.12, 0.09, 0.26), head: color(0.13, 0.15, 0.22), innerEar: color(0.33, 0.26, 0.78), eye: color(0.18, 0.95, 0.82), accent: color(0.88, 0.92, 1.0), sparkle: color(0.95, 0.38, 1.0), mood: .cyber),
    IconVariant(id: 3, name: "Midnight Blue", backgroundA: color(0.03, 0.10, 0.22), backgroundB: color(0.08, 0.32, 0.62), head: color(0.83, 0.90, 1.0), innerEar: color(0.30, 0.50, 0.83), eye: color(0.03, 0.16, 0.34), accent: color(0.03, 0.16, 0.34), sparkle: color(0.54, 0.91, 1.0), mood: .midnight),
    IconVariant(id: 4, name: "Mint Cleaner", backgroundA: color(0.03, 0.34, 0.28), backgroundB: color(0.20, 0.72, 0.56), head: color(0.95, 1.0, 0.96), innerEar: color(0.35, 0.72, 0.60), eye: color(0.04, 0.28, 0.24), accent: color(0.04, 0.28, 0.24), sparkle: color(1.0, 0.95, 0.48), mood: .mint),
    IconVariant(id: 5, name: "Warm Sunset", backgroundA: color(0.42, 0.13, 0.32), backgroundB: color(0.95, 0.38, 0.23), head: color(1.0, 0.91, 0.78), innerEar: color(0.93, 0.48, 0.42), eye: color(0.18, 0.08, 0.14), accent: color(0.18, 0.08, 0.14), sparkle: color(1.0, 0.82, 0.26), mood: .sunset),
    IconVariant(id: 6, name: "Graphite Pro", backgroundA: color(0.10, 0.11, 0.13), backgroundB: color(0.33, 0.37, 0.42), head: color(0.87, 0.89, 0.91), innerEar: color(0.52, 0.57, 0.62), eye: color(0.05, 0.08, 0.11), accent: color(0.05, 0.08, 0.11), sparkle: color(0.38, 0.86, 1.0), mood: .graphite),
    IconVariant(id: 7, name: "Soft Cream", backgroundA: color(0.60, 0.28, 0.20), backgroundB: color(0.96, 0.75, 0.47), head: color(1.0, 0.95, 0.86), innerEar: color(0.84, 0.47, 0.37), eye: color(0.20, 0.12, 0.09), accent: color(0.20, 0.12, 0.09), sparkle: color(0.49, 0.92, 0.88), mood: .cream),
    IconVariant(id: 8, name: "Violet Spark", backgroundA: color(0.16, 0.09, 0.34), backgroundB: color(0.48, 0.25, 0.84), head: color(0.96, 0.94, 1.0), innerEar: color(0.58, 0.43, 0.92), eye: color(0.19, 0.12, 0.36), accent: color(0.19, 0.12, 0.36), sparkle: color(1.0, 0.72, 0.22), mood: .violet),
    IconVariant(id: 9, name: "Aqua Shield", backgroundA: color(0.02, 0.20, 0.30), backgroundB: color(0.0, 0.62, 0.78), head: color(0.91, 0.99, 1.0), innerEar: color(0.20, 0.67, 0.78), eye: color(0.02, 0.18, 0.24), accent: color(0.02, 0.18, 0.24), sparkle: color(0.84, 1.0, 0.36), mood: .aqua),
    IconVariant(id: 10, name: "Mono Line", backgroundA: color(0.02, 0.02, 0.03), backgroundB: color(0.20, 0.22, 0.25), head: color(0.94, 0.95, 0.97), innerEar: color(0.45, 0.47, 0.50), eye: color(0.04, 0.05, 0.06), accent: color(0.04, 0.05, 0.06), sparkle: color(0.86, 0.88, 0.92), mood: .mono)
]

let output = URL(filePath: "AppProject/IconVariants")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for variant in variants {
    let image = drawIcon(variant: variant, pixels: 1024)
    try writePNG(image, to: output.appending(path: "icon-v\(String(format: "%02d", variant.id)).png"))
}

let sheet = drawContactSheet(variants: variants, iconSize: 220, padding: 34)
try writePNG(sheet, to: output.appending(path: "contact-sheet.png"))

print("Generated \(variants.count) icon variants and contact sheet")

func drawIcon(variant: IconVariant, pixels: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.lockFocus()

    let scale = CGFloat(pixels)
    let rect = NSRect(x: 0, y: 0, width: scale, height: scale)

    let background = NSBezierPath(
        roundedRect: rect.insetBy(dx: scale * 0.06, dy: scale * 0.06),
        xRadius: scale * 0.22,
        yRadius: scale * 0.22
    )
    NSGradient(colors: [variant.backgroundA, variant.backgroundB])?.draw(in: background, angle: 135)

    let glow = NSBezierPath(ovalIn: NSRect(x: scale * 0.15, y: scale * 0.12, width: scale * 0.7, height: scale * 0.7))
    variant.eye.withAlphaComponent(0.14).setFill()
    glow.fill()

    switch variant.mood {
    case .cyber, .aqua:
        drawRing(scale: scale, color: variant.eye.withAlphaComponent(0.35))
    case .graphite, .mono:
        drawRing(scale: scale, color: NSColor.white.withAlphaComponent(0.12))
    default:
        break
    }

    drawCat(scale: scale, variant: variant)
    drawAccent(scale: scale, variant: variant)
    drawLabel(id: variant.id, scale: scale)

    image.unlockFocus()
    return image
}

func drawCat(scale: CGFloat, variant: IconVariant) {
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

    variant.head.setFill()
    leftEar.fill()
    rightEar.fill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.2, y: scale * 0.18, width: scale * 0.6, height: scale * 0.56)).fill()

    variant.innerEar.setFill()
    triangle(points: [
        NSPoint(x: scale * 0.29, y: scale * 0.64),
        NSPoint(x: scale * 0.31, y: scale * 0.76),
        NSPoint(x: scale * 0.38, y: scale * 0.66)
    ]).fill()
    triangle(points: [
        NSPoint(x: scale * 0.62, y: scale * 0.66),
        NSPoint(x: scale * 0.69, y: scale * 0.76),
        NSPoint(x: scale * 0.71, y: scale * 0.64)
    ]).fill()

    variant.accent.setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.35, y: scale * 0.48, width: scale * 0.075, height: scale * 0.095)).fill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.575, y: scale * 0.48, width: scale * 0.075, height: scale * 0.095)).fill()

    variant.eye.setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.372, y: scale * 0.522, width: scale * 0.026, height: scale * 0.026)).fill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.597, y: scale * 0.522, width: scale * 0.026, height: scale * 0.026)).fill()

    let nose = triangle(points: [
        NSPoint(x: scale * 0.5, y: scale * 0.43),
        NSPoint(x: scale * 0.535, y: scale * 0.465),
        NSPoint(x: scale * 0.465, y: scale * 0.465)
    ])
    variant.accent.withAlphaComponent(0.88).setFill()
    nose.fill()

    let mouth = NSBezierPath()
    mouth.move(to: NSPoint(x: scale * 0.5, y: scale * 0.43))
    mouth.curve(to: NSPoint(x: scale * 0.45, y: scale * 0.39), controlPoint1: NSPoint(x: scale * 0.49, y: scale * 0.4), controlPoint2: NSPoint(x: scale * 0.47, y: scale * 0.39))
    mouth.move(to: NSPoint(x: scale * 0.5, y: scale * 0.43))
    mouth.curve(to: NSPoint(x: scale * 0.55, y: scale * 0.39), controlPoint1: NSPoint(x: scale * 0.51, y: scale * 0.4), controlPoint2: NSPoint(x: scale * 0.53, y: scale * 0.39))
    variant.accent.withAlphaComponent(0.64).setStroke()
    mouth.lineWidth = max(1, scale * 0.012)
    mouth.stroke()

    variant.accent.withAlphaComponent(0.50).setStroke()
    for offset in [-0.03, 0.02] {
        drawWhisker(scale: scale, left: true, offset: offset)
        drawWhisker(scale: scale, left: false, offset: offset)
    }
}

func drawAccent(scale: CGFloat, variant: IconVariant) {
    switch variant.mood {
    case .classic, .sunset, .violet:
        drawSparkle(scale: scale, color: variant.sparkle)
    case .cyber:
        drawSparkle(scale: scale, color: variant.sparkle)
        drawTinySparkle(scale: scale, x: 0.22, y: 0.78, color: variant.eye)
    case .midnight:
        drawMoon(scale: scale, color: variant.sparkle)
    case .mint:
        drawBroom(scale: scale, color: variant.sparkle, handle: variant.accent)
    case .graphite:
        drawSparkle(scale: scale, color: variant.sparkle)
        drawShield(scale: scale, color: NSColor.white.withAlphaComponent(0.18))
    case .cream:
        drawLeaf(scale: scale, color: variant.sparkle)
    case .aqua:
        drawShield(scale: scale, color: variant.sparkle.withAlphaComponent(0.88))
    case .mono:
        drawTinySparkle(scale: scale, x: 0.78, y: 0.30, color: variant.sparkle)
        drawTinySparkle(scale: scale, x: 0.25, y: 0.77, color: variant.sparkle)
    }
}

func drawSparkle(scale: CGFloat, color: NSColor) {
    let sparkle = NSBezierPath()
    sparkle.move(to: NSPoint(x: scale * 0.78, y: scale * 0.22))
    sparkle.line(to: NSPoint(x: scale * 0.83, y: scale * 0.32))
    sparkle.line(to: NSPoint(x: scale * 0.94, y: scale * 0.36))
    sparkle.line(to: NSPoint(x: scale * 0.84, y: scale * 0.42))
    sparkle.line(to: NSPoint(x: scale * 0.8, y: scale * 0.53))
    sparkle.line(to: NSPoint(x: scale * 0.74, y: scale * 0.43))
    sparkle.line(to: NSPoint(x: scale * 0.63, y: scale * 0.39))
    sparkle.line(to: NSPoint(x: scale * 0.73, y: scale * 0.33))
    sparkle.close()
    color.setFill()
    sparkle.fill()
}

func drawTinySparkle(scale: CGFloat, x: CGFloat, y: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: scale * x, y: scale * (y - 0.08)))
    path.line(to: NSPoint(x: scale * (x + 0.025), y: scale * (y - 0.025)))
    path.line(to: NSPoint(x: scale * (x + 0.08), y: scale * y))
    path.line(to: NSPoint(x: scale * (x + 0.025), y: scale * (y + 0.025)))
    path.line(to: NSPoint(x: scale * x, y: scale * (y + 0.08)))
    path.line(to: NSPoint(x: scale * (x - 0.025), y: scale * (y + 0.025)))
    path.line(to: NSPoint(x: scale * (x - 0.08), y: scale * y))
    path.line(to: NSPoint(x: scale * (x - 0.025), y: scale * (y - 0.025)))
    path.close()
    color.setFill()
    path.fill()
}

func drawMoon(scale: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.73, y: scale * 0.27, width: scale * 0.18, height: scale * 0.18)).fill()
    NSColor(calibratedRed: 0.03, green: 0.10, blue: 0.22, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: scale * 0.78, y: scale * 0.31, width: scale * 0.16, height: scale * 0.16)).fill()
}

func drawBroom(scale: CGFloat, color: NSColor, handle: NSColor) {
    handle.setStroke()
    let handlePath = NSBezierPath()
    handlePath.move(to: NSPoint(x: scale * 0.66, y: scale * 0.2))
    handlePath.line(to: NSPoint(x: scale * 0.89, y: scale * 0.52))
    handlePath.lineWidth = scale * 0.035
    handlePath.stroke()

    color.setFill()
    let brush = NSBezierPath(roundedRect: NSRect(x: scale * 0.75, y: scale * 0.16, width: scale * 0.18, height: scale * 0.12), xRadius: scale * 0.03, yRadius: scale * 0.03)
    brush.fill()
}

func drawShield(scale: CGFloat, color: NSColor) {
    let shield = NSBezierPath()
    shield.move(to: NSPoint(x: scale * 0.78, y: scale * 0.2))
    shield.line(to: NSPoint(x: scale * 0.91, y: scale * 0.29))
    shield.line(to: NSPoint(x: scale * 0.88, y: scale * 0.49))
    shield.line(to: NSPoint(x: scale * 0.78, y: scale * 0.57))
    shield.line(to: NSPoint(x: scale * 0.68, y: scale * 0.49))
    shield.line(to: NSPoint(x: scale * 0.65, y: scale * 0.29))
    shield.close()
    color.setFill()
    shield.fill()
}

func drawLeaf(scale: CGFloat, color: NSColor) {
    let leaf = NSBezierPath()
    leaf.move(to: NSPoint(x: scale * 0.67, y: scale * 0.23))
    leaf.curve(to: NSPoint(x: scale * 0.91, y: scale * 0.48), controlPoint1: NSPoint(x: scale * 0.78, y: scale * 0.23), controlPoint2: NSPoint(x: scale * 0.9, y: scale * 0.34))
    leaf.curve(to: NSPoint(x: scale * 0.67, y: scale * 0.23), controlPoint1: NSPoint(x: scale * 0.78, y: scale * 0.5), controlPoint2: NSPoint(x: scale * 0.68, y: scale * 0.38))
    leaf.close()
    color.setFill()
    leaf.fill()
}

func drawRing(scale: CGFloat, color: NSColor) {
    color.setStroke()
    let ring = NSBezierPath(ovalIn: NSRect(x: scale * 0.15, y: scale * 0.12, width: scale * 0.7, height: scale * 0.7))
    ring.lineWidth = scale * 0.018
    ring.stroke()
}

func drawWhisker(scale: CGFloat, left: Bool, offset: CGFloat) {
    let y = scale * (0.42 + offset)
    let path = NSBezierPath()
    if left {
        path.move(to: NSPoint(x: scale * 0.41, y: y))
        path.line(to: NSPoint(x: scale * 0.23, y: y + scale * offset * 0.7))
    } else {
        path.move(to: NSPoint(x: scale * 0.59, y: y))
        path.line(to: NSPoint(x: scale * 0.77, y: y + scale * offset * 0.7))
    }
    path.lineWidth = max(1, scale * 0.008)
    path.stroke()
}

func drawLabel(id: Int, scale: CGFloat) {
    let text = "\(id)"
    let font = NSFont.systemFont(ofSize: scale * 0.075, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white.withAlphaComponent(0.9)
    ]
    text.draw(at: NSPoint(x: scale * 0.16, y: scale * 0.13), withAttributes: attrs)
}

func triangle(points: [NSPoint]) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: points[0])
    path.line(to: points[1])
    path.line(to: points[2])
    path.close()
    return path
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(url.lastPathComponent)")
    }

    try png.write(to: url)
}

func drawContactSheet(variants: [IconVariant], iconSize: Int, padding: Int) -> NSImage {
    let columns = 5
    let rows = Int(ceil(Double(variants.count) / Double(columns)))
    let labelHeight = 46
    let width = columns * iconSize + (columns + 1) * padding
    let height = rows * (iconSize + labelHeight) + (rows + 1) * padding
    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()
    NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    for (index, variant) in variants.enumerated() {
        let col = index % columns
        let row = index / columns
        let x = padding + col * (iconSize + padding)
        let y = height - padding - (row + 1) * (iconSize + labelHeight)

        let icon = drawIcon(variant: variant, pixels: iconSize)
        icon.draw(in: NSRect(x: x, y: y + labelHeight, width: iconSize, height: iconSize))

        let label = "V\(String(format: "%02d", variant.id))  \(variant.name)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        label.draw(in: NSRect(x: x, y: y + 8, width: iconSize, height: 26), withAttributes: attrs)
    }

    image.unlockFocus()
    return image
}
