import AppKit

let size = 1254
let canvas = NSImage(size: NSSize(width: size, height: size))

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func roundedRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: radius, yRadius: radius)
}

func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat, lineCap: NSBezierPath.LineCapStyle = .round, lineJoin: NSBezierPath.LineJoinStyle = .round) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = lineCap
    path.lineJoinStyle = lineJoin
    path.stroke()
}

canvas.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
NSGraphicsContext.current?.shouldAntialias = true

let bounds = NSRect(x: 0, y: 0, width: size, height: size)
color(247, 250, 252).setFill()
NSBezierPath(rect: bounds).fill()

color(38, 72, 100, 0.16).setFill()
roundedRect(x: 168, y: 132, width: 918, height: 936, radius: 232).fill()

let tile = roundedRect(x: 152, y: 166, width: 950, height: 950, radius: 232)
let gradient = NSGradient(colors: [
    color(18, 24, 33),
    color(27, 36, 48),
    color(42, 58, 77)
])!
gradient.draw(in: tile, angle: 315)

let pageFill = color(245, 248, 248)
let pageStroke = color(255, 255, 255)
let accent = color(39, 185, 129)

let bookLeft = NSBezierPath()
bookLeft.move(to: NSPoint(x: 604, y: 372))
bookLeft.curve(to: NSPoint(x: 352, y: 432), controlPoint1: NSPoint(x: 520, y: 348), controlPoint2: NSPoint(x: 422, y: 374))
bookLeft.line(to: NSPoint(x: 352, y: 798))
bookLeft.curve(to: NSPoint(x: 604, y: 850), controlPoint1: NSPoint(x: 434, y: 772), controlPoint2: NSPoint(x: 526, y: 798))
bookLeft.close()

let bookRight = NSBezierPath()
bookRight.move(to: NSPoint(x: 650, y: 372))
bookRight.curve(to: NSPoint(x: 902, y: 432), controlPoint1: NSPoint(x: 734, y: 348), controlPoint2: NSPoint(x: 832, y: 374))
bookRight.line(to: NSPoint(x: 902, y: 798))
bookRight.curve(to: NSPoint(x: 650, y: 850), controlPoint1: NSPoint(x: 820, y: 772), controlPoint2: NSPoint(x: 728, y: 798))
bookRight.close()

pageFill.setFill()
bookLeft.fill()
bookRight.fill()

strokePath(bookLeft, color: pageStroke.withAlphaComponent(0.96), width: 22)
strokePath(bookRight, color: pageStroke.withAlphaComponent(0.96), width: 22)

let crease = NSBezierPath()
crease.move(to: NSPoint(x: 627, y: 392))
crease.line(to: NSPoint(x: 627, y: 820))
strokePath(crease, color: color(190, 203, 213), width: 20)

let badge = NSBezierPath(ovalIn: NSRect(x: 744, y: 296, width: 250, height: 250))
accent.setFill()
badge.fill()

let wifiColor = color(255, 255, 255)
let wifiCenter = NSPoint(x: 869, y: 372)
for radius in [48.0, 84.0] {
    let arc = NSBezierPath()
    arc.appendArc(
        withCenter: wifiCenter,
        radius: CGFloat(radius),
        startAngle: 28,
        endAngle: 152,
        clockwise: false
    )
    strokePath(arc, color: wifiColor, width: 24)
}

wifiColor.setFill()
NSBezierPath(ovalIn: NSRect(x: wifiCenter.x - 18, y: wifiCenter.y - 20, width: 36, height: 36)).fill()

canvas.unlockFocus()

guard
    let tiff = canvas.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Could not render icon PNG.")
}

let outputURL = URL(fileURLWithPath: "Assets/KindleShareLogo-BookWifi.png")
try png.write(to: outputURL)
print("Wrote \(outputURL.path)")
