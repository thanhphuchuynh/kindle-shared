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
color(244, 248, 255).setFill()
NSBezierPath(rect: bounds).fill()

let tile = roundedRect(x: 122, y: 122, width: 1010, height: 1010, radius: 244)
let gradient = NSGradient(colors: [
    color(25, 103, 210),
    color(26, 115, 232),
    color(66, 133, 244)
])!
gradient.draw(in: tile, angle: 315)

color(7, 43, 96, 0.18).setFill()
roundedRect(x: 186, y: 102, width: 882, height: 980, radius: 220).fill()

let bookColor = color(255, 255, 255)
let bookWidth: CGFloat = 430
let bookHeight: CGFloat = 382
let bookX: CGFloat = 274
let bookY: CGFloat = 424
let spineX = bookX + bookWidth / 2

let leftPage = NSBezierPath()
leftPage.move(to: NSPoint(x: spineX, y: bookY + 42))
leftPage.curve(to: NSPoint(x: bookX + 82, y: bookY + 82), controlPoint1: NSPoint(x: spineX - 58, y: bookY + 32), controlPoint2: NSPoint(x: bookX + 138, y: bookY + 48))
leftPage.line(to: NSPoint(x: bookX + 82, y: bookY + bookHeight - 86))
leftPage.curve(to: NSPoint(x: spineX, y: bookY + bookHeight - 44), controlPoint1: NSPoint(x: bookX + 142, y: bookY + bookHeight - 62), controlPoint2: NSPoint(x: spineX - 54, y: bookY + bookHeight - 54))

let rightPage = NSBezierPath()
rightPage.move(to: NSPoint(x: spineX, y: bookY + 42))
rightPage.curve(to: NSPoint(x: bookX + bookWidth - 82, y: bookY + 82), controlPoint1: NSPoint(x: spineX + 58, y: bookY + 32), controlPoint2: NSPoint(x: bookX + bookWidth - 138, y: bookY + 48))
rightPage.line(to: NSPoint(x: bookX + bookWidth - 82, y: bookY + bookHeight - 86))
rightPage.curve(to: NSPoint(x: spineX, y: bookY + bookHeight - 44), controlPoint1: NSPoint(x: bookX + bookWidth - 142, y: bookY + bookHeight - 62), controlPoint2: NSPoint(x: spineX + 54, y: bookY + bookHeight - 54))

strokePath(leftPage, color: bookColor, width: 52)
strokePath(rightPage, color: bookColor, width: 52)

let centerLine = NSBezierPath()
centerLine.move(to: NSPoint(x: spineX, y: bookY + 64))
centerLine.line(to: NSPoint(x: spineX, y: bookY + bookHeight - 64))
strokePath(centerLine, color: bookColor.withAlphaComponent(0.78), width: 34)

let wifiCenter = NSPoint(x: 832, y: 438)
for (index, radius) in [105.0, 182.0, 258.0].enumerated() {
    let arc = NSBezierPath()
    arc.appendArc(
        withCenter: wifiCenter,
        radius: CGFloat(radius),
        startAngle: 26,
        endAngle: 154,
        clockwise: false
    )
    strokePath(arc, color: bookColor.withAlphaComponent(index == 2 ? 0.88 : 0.96), width: 46)
}

bookColor.setFill()
NSBezierPath(ovalIn: NSRect(x: wifiCenter.x - 35, y: wifiCenter.y - 36, width: 70, height: 70)).fill()

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
