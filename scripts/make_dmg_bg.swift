import Foundation
import CoreGraphics
import ImageIO
import AppKit

// MARK: - Args
let args = CommandLine.arguments
let outputPath: String = {
    if let i = args.firstIndex(of: "--output"), i+1 < args.count { return args[i+1] }
    return "dmg_background.png"
}()

// MARK: - Setup
let W = 540, H = 380
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: W, height: H,
                          bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { fatalError("CGContext failed") }

// Flip to top‑left coordinate system so all drawing (including text) is right‑side up
ctx.translateBy(x: 0, y: CGFloat(H))
ctx.scaleBy(x: 1, y: -1)

func cgColor(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs,
            components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

func fillRect(_ rect: CGRect, radius: CGFloat, fill: CGColor,
              stroke: CGColor? = nil, lw: CGFloat = 1) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(fill)
    if let s = stroke {
        ctx.setStrokeColor(s)
        ctx.setLineWidth(lw)
        ctx.drawPath(using: .fillStroke)
    } else {
        ctx.fillPath()
    }
}

func strokeRect(_ rect: CGRect, radius: CGFloat, color: CGColor, lw: CGFloat) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(path)
    ctx.setStrokeColor(color)
    ctx.setLineWidth(lw)
    ctx.strokePath()
}

func gradientRect(_ rect: CGRect, radius: CGFloat, gradient: CGGradient,
                  start: CGPoint, end: CGPoint) {
    ctx.saveGState()
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(path)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
    ctx.restoreGState()
}

// MARK: - Background (modern soft gradient)
let bgGradient = CGGradient(colorsSpace: cs,
    colors: [cgColor(248, 249, 252), cgColor(241, 242, 247)] as CFArray,
    locations: [0, 1])!
ctx.drawLinearGradient(bgGradient,
    start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: CGFloat(H)), options: [])

// MARK: - Cards (modern soft‑shadow + warm white)
let cardR: CGFloat = 20
let card1Rect = CGRect(x: 26, y: 50, width: 224, height: 244)
let card2Rect = CGRect(x: 288, y: 50, width: 224, height: 244)
let cardFill = cgColor(253, 253, 254)
let cardBorder = cgColor(212, 212, 220)

// Shadow pass
ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 12, color: cgColor(0, 0, 0, 0.06))
ctx.setFillColor(cardFill)
ctx.addPath(CGPath(roundedRect: card1Rect, cornerWidth: cardR, cornerHeight: cardR, transform: nil))
ctx.fillPath()
ctx.addPath(CGPath(roundedRect: card2Rect, cornerWidth: cardR, cornerHeight: cardR, transform: nil))
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// Border pass (no shadow)
strokeRect(card1Rect, radius: cardR, color: cardBorder, lw: 0.5)
strokeRect(card2Rect, radius: cardR, color: cardBorder, lw: 0.5)

// MARK: - App icon (gradient circle + clipboard)
// let icx: CGFloat = 138, icy: CGFloat = 156, icr: CGFloat = 38
// let iconGradient = CGGradient(colorsSpace: cs,
//     colors: [cgColor(64, 156, 255), cgColor(88, 86, 214)] as CFArray,
//     locations: [0, 1])!

// // Glow shadow behind icon
// ctx.setShadow(offset: .zero, blur: 10, color: cgColor(88, 86, 214, 0.18))
// ctx.setFillColor(cgColor(64, 156, 255))
// ctx.fillEllipse(in: CGRect(x: icx - icr, y: icy - icr, width: icr * 2, height: icr * 2))
// ctx.setShadow(offset: .zero, blur: 0, color: nil)

// // Gradient fill
// ctx.saveGState()
// ctx.addEllipse(in: CGRect(x: icx - icr, y: icy - icr, width: icr * 2, height: icr * 2))
// ctx.clip()
// ctx.drawLinearGradient(iconGradient,
//     start: CGPoint(x: icx - icr, y: icy - icr),
//     end: CGPoint(x: icx + icr, y: icy + icr), options: [])
// ctx.restoreGState()

// // Clipboard body
// fillRect(CGRect(x: icx - 14, y: icy + 17, width: 28, height: 36),
//          radius: 5, fill: cgColor(255, 255, 255, 0.92))
// // Clipboard clip
// fillRect(CGRect(x: icx - 8, y: icy - 8, width: 16, height: 10),
//          radius: 3, fill: cgColor(255, 255, 255),
//          stroke: cgColor(210, 225, 255, 0.6), lw: 1)
// // Clipboard lines
// for (i, lw) in [(0, CGFloat(18)), (1, CGFloat(14)), (2, CGFloat(10))] {
//     let ly = icy + 5 + CGFloat(i) * 7
//     fillRect(CGRect(x: icx - 9, y: ly + 2, width: lw, height: 2),
//              radius: 1, fill: cgColor(160, 200, 255, 0.7))
// }

// MARK: - Folder icon (gradient blue)
// let fx: CGFloat = 362, fy: CGFloat = 136
// let folderGrad = CGGradient(colorsSpace: cs,
//     colors: [cgColor(64, 156, 255), cgColor(88, 86, 214)] as CFArray,
//     locations: [0, 1])!

// Tab
// gradientRect(CGRect(x: fx, y: fy - 2, width: 26, height: 10), radius: 4,
//              gradient: folderGrad, start: CGPoint(x: fx, y: fy - 2), end: CGPoint(x: fx + 26, y: fy + 8))
// // Body
// gradientRect(CGRect(x: fx, y: fy + 8, width: 72, height: 58), radius: 6,
//              gradient: folderGrad, start: CGPoint(x: fx, y: fy + 8), end: CGPoint(x: fx + 72, y: fy + 66))
// // Inner highlight
// fillRect(CGRect(x: fx + 4, y: fy + 20, width: 64, height: 16),
//          radius: 4, fill: cgColor(255, 255, 255, 0.12))

// MARK: - Arrow (sleek modern style)
let arrowColor = cgColor(170, 170, 180)
ctx.setStrokeColor(arrowColor)
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

// Arrow shaft
ctx.move(to: CGPoint(x: 255, y: 180))
ctx.addLine(to: CGPoint(x: 270, y: 180))
ctx.strokePath()

// Arrow head
let head = CGMutablePath()
head.move(to: CGPoint(x: 270, y: 171))
head.addLine(to: CGPoint(x: 285, y: 180))
head.addLine(to: CGPoint(x: 270, y: 189))
head.closeSubpath()
ctx.addPath(head)
ctx.setFillColor(arrowColor)
ctx.fillPath()

// MARK: - Text
func drawText(_ text: String, cx: CGFloat, cy: CGFloat,
              size: CGFloat = 11, weight: NSFont.Weight = .regular,
              r: Int = 30, g: Int = 30, b: Int = 35) {
    let nsColor = NSColor(calibratedRed: CGFloat(r) / 255,
                          green: CGFloat(g) / 255,
                          blue: CGFloat(b) / 255, alpha: 1)
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: nsColor]
    let str = text as NSString
    let sz = str.size(withAttributes: attrs)

    // Temporarily undo the context flip so NSString draws right‑side up
    ctx.saveGState()
    ctx.scaleBy(x: 1, y: -1)
    ctx.translateBy(x: 0, y: -CGFloat(H))

    let drawPt = CGPoint(x: cx - sz.width / 2, y: CGFloat(H) - cy - sz.height / 2)

    NSGraphicsContext.saveGraphicsState()
    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.current = nsCtx
    str.draw(at: drawPt, withAttributes: attrs)
    NSGraphicsContext.restoreGraphicsState()

    ctx.restoreGState()
}

drawText("Install PasteHub",    cx: 270, cy: 26, size: 17, weight: .semibold, r: 20, g: 20, b: 25)
// drawText("PasteHub",            cx: 138, cy: 218, size: 13, weight: .medium,   r: 25, g: 25, b: 30)
// drawText("1.0.0",               cx: 138, cy: 235, size: 10,                    r: 130, g: 130, b: 140)
// drawText("Applications",        cx: 398, cy: 218, size: 13, weight: .medium,   r: 25, g: 25, b: 30)
drawText("Drag PasteHub to Applications to install",
                                cx: 270, cy: 338, size: 10,                    r: 130, g: 130, b: 140)

// divider — thin & subtle
ctx.setFillColor(cgColor(210, 210, 218))
ctx.fill(CGRect(x: 60, y: 352, width: 420, height: 0.5))

// MARK: - Export
guard let cgImage = ctx.makeImage() else { fatalError("makeImage failed") }
let url = URL(fileURLWithPath: outputPath)
try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                         withIntermediateDirectories: true)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
else { fatalError("Cannot create destination") }
CGImageDestinationAddImage(dest, cgImage, nil)
CGImageDestinationFinalize(dest)
print("✅ Background: \(outputPath)  (\(W)×\(H))")
