import AppKit

let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let background = NSColor(srgbRed: 0.055, green: 0.075, blue: 0.065, alpha: 1)
let accent = NSColor(srgbRed: 0.69, green: 0.94, blue: 0.45, alpha: 1)
background.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

// Bold currency marks remain legible at Home Screen and Settings sizes.
func draw(_ text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: color
    ]
    (text as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
}
draw("€", x: 160, y: 430, fontSize: 370, color: .white)
draw("₺", x: 590, y: 148, fontSize: 370, color: accent)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 455, y: 580))
arrow.line(to: NSPoint(x: 570, y: 465))
arrow.move(to: NSPoint(x: 480, y: 465))
arrow.line(to: NSPoint(x: 570, y: 465))
arrow.line(to: NSPoint(x: 570, y: 555))
arrow.lineWidth = 30
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
accent.setStroke()
arrow.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
