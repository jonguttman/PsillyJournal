import SwiftUI

/// Elegant iridescent fractal feather texture.
/// Inspired by recursive fern/peacock patterns with bilateral symmetry.
/// Color-shifting fronds: warm gold → rose → cool lavender.
/// Drawn as a luminous watermark on the warm parchment background.
struct FractalTexture: View {
    var body: some View {
        Canvas { context, size in
            // Primary feather — centered, spanning full height
            drawFeatherFractal(
                context: context,
                base: CGPoint(x: size.width * 0.50, y: size.height * 0.92),
                tip: CGPoint(x: size.width * 0.48, y: size.height * 0.04),
                maxSpread: size.width * 0.44,
                baseOpacity: 0.24
            )

            // Small accent feather — upper right, angled inward
            drawFeatherFractal(
                context: context,
                base: CGPoint(x: size.width * 0.92, y: size.height * 0.08),
                tip: CGPoint(x: size.width * 0.68, y: size.height * 0.48),
                maxSpread: size.width * 0.16,
                baseOpacity: 0.14
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Feather Fractal

    private func drawFeatherFractal(context: GraphicsContext,
                                     base: CGPoint, tip: CGPoint,
                                     maxSpread: CGFloat, baseOpacity: Double) {
        let spineCount = 30
        var spine: [CGPoint] = []

        // Perpendicular unit vector for the S-curve wobble
        let dx = tip.x - base.x
        let dy = tip.y - base.y
        let len = sqrt(dx * dx + dy * dy)
        let nx = -dy / len
        let ny = dx / len

        // Build spine with gentle S-curve
        for i in 0...spineCount {
            let t = CGFloat(i) / CGFloat(spineCount)
            let wobble = sin(t * .pi * 2.0) * maxSpread * 0.035
            let x = base.x + dx * t + nx * wobble
            let y = base.y + dy * t + ny * wobble
            spine.append(CGPoint(x: x, y: y))
        }

        // Draw the spine with glow
        drawSpine(context: context, points: spine, opacity: baseOpacity)

        // Draw frond pairs along the spine
        for i in 1..<spineCount {
            let t = CGFloat(i) / CGFloat(spineCount)

            // Length envelope: longest in middle, tapers smoothly at both ends
            let envelope = pow(sin(t * .pi), 0.55)
            let frondLen = maxSpread * envelope
            guard frondLen > 6 else { continue }

            // Spine tangent direction at this point
            let prev = spine[max(i - 1, 0)]
            let next = spine[min(i + 1, spineCount)]
            let spineAngle = atan2(next.y - prev.y, next.x - prev.x)

            // Fronds angle perpendicular, with slight backward sweep
            let sweep: CGFloat = 0.12 + 0.22 * (1.0 - t) // more sweep near base
            let rightAngle = spineAngle - .pi / 2 + sweep
            let leftAngle = spineAngle + .pi / 2 - sweep

            let color = iridescentColor(t: t)
            let opacity = baseOpacity * (0.45 + envelope * 0.55)

            // Right frond
            drawFrond(context: context, origin: spine[i],
                      angle: rightAngle, length: frondLen,
                      depth: 0, maxDepth: 2, t: t,
                      color: color, opacity: opacity)

            // Left frond (mirror)
            drawFrond(context: context, origin: spine[i],
                      angle: leftAngle, length: frondLen,
                      depth: 0, maxDepth: 2, t: t,
                      color: color, opacity: opacity)
        }
    }

    // MARK: - Spine

    private func drawSpine(context: GraphicsContext, points: [CGPoint], opacity: Double) {
        var path = Path()
        guard let first = points.first else { return }
        path.move(to: first)

        // Smooth quad curves through midpoints
        for i in 1..<points.count {
            if i < points.count - 1 {
                let mid = CGPoint(
                    x: (points[i].x + points[i + 1].x) / 2,
                    y: (points[i].y + points[i + 1].y) / 2
                )
                path.addQuadCurve(to: mid, control: points[i])
            } else {
                path.addLine(to: points[i])
            }
        }

        let color = iridescentColor(t: 0.5)

        // Glow halo
        context.stroke(path, with: .color(color.opacity(opacity * 0.3)),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round))
        // Core
        context.stroke(path, with: .color(color.opacity(opacity * 0.8)),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    // MARK: - Recursive Frond

    private func drawFrond(context: GraphicsContext, origin: CGPoint,
                           angle: CGFloat, length: CGFloat,
                           depth: Int, maxDepth: Int, t: CGFloat,
                           color: Color, opacity: Double) {
        let steps = max(5, 14 - depth * 4)
        var points: [CGPoint] = [origin]
        var path = Path()
        path.move(to: origin)

        // Fiddlehead curl — tightens toward tip
        let curlIntensity: CGFloat = 0.35 + CGFloat(depth) * 0.2
        var currentAngle = angle

        for s in 1...steps {
            let st = CGFloat(s) / CGFloat(steps)

            // Progressive curl (creates the fiddlehead spiral at tips)
            let curl = curlIntensity * st * st
            currentAngle = angle + curl

            let segLen = length / CGFloat(steps)
            let prev = points.last!
            let x = prev.x + segLen * cos(currentAngle)
            let y = prev.y + segLen * sin(currentAngle)
            let pt = CGPoint(x: x, y: y)
            points.append(pt)

            // Smooth control point for organic curve
            let cpOff = segLen * 0.2 * sin(st * .pi * 1.5)
            let cp = CGPoint(
                x: (prev.x + x) / 2 + cpOff * cos(currentAngle + .pi / 2),
                y: (prev.y + y) / 2 + cpOff * sin(currentAngle + .pi / 2)
            )
            path.addQuadCurve(to: pt, control: cp)
        }

        // Stroke width tapers with depth
        let lineWidth: CGFloat = [2.2, 1.2, 0.6][min(depth, 2)]
        let depthFade = 1.0 - Double(depth) * 0.25

        // Glow halo (wider, softer)
        context.stroke(path, with: .color(color.opacity(opacity * 0.30 * depthFade)),
                       style: StrokeStyle(lineWidth: lineWidth * 3.0, lineCap: .round, lineJoin: .round))
        // Core line
        context.stroke(path, with: .color(color.opacity(opacity * depthFade)),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

        // Recurse into sub-fronds
        guard depth < maxDepth, length > 8 else { return }

        let subStart = depth == 0 ? 3 : 2
        let subInterval = depth == 0 ? 3 : 3

        for s in stride(from: subStart, through: steps - 1, by: subInterval) {
            let st = CGFloat(s) / CGFloat(steps)
            let subLen = length * (1.0 - st) * 0.50
            guard subLen > 5 else { continue }

            // Direction of parent frond at this segment
            let parentDir = atan2(
                points[s].y - points[max(s - 1, 0)].y,
                points[s].x - points[max(s - 1, 0)].x
            )

            // Color shifts slightly at each recursion level
            let subColor = iridescentColor(t: min(t + st * 0.1, 1.0))
            let subOpacity = opacity * (0.50 - Double(depth) * 0.08)

            // Sub-frond pair (both sides)
            drawFrond(context: context, origin: points[s],
                      angle: parentDir - .pi / 2.6,
                      length: subLen, depth: depth + 1,
                      maxDepth: maxDepth, t: t + st * 0.08,
                      color: subColor, opacity: subOpacity)

            drawFrond(context: context, origin: points[s],
                      angle: parentDir + .pi / 2.6,
                      length: subLen, depth: depth + 1,
                      maxDepth: maxDepth, t: t + st * 0.08,
                      color: subColor, opacity: subOpacity)
        }
    }

    // MARK: - Iridescent Color Gradient

    /// Shifts from warm gold (base) → rose (middle) → cool lavender (tip)
    private func iridescentColor(t: CGFloat) -> Color {
        let c = min(max(t, 0), 1)

        if c < 0.3 {
            // Warm gold → Amber rose
            let l = c / 0.3
            return Color(
                red: 0.78 + l * 0.04,    // 0.78 → 0.82
                green: 0.62 - l * 0.18,   // 0.62 → 0.44
                blue: 0.34 + l * 0.12     // 0.34 → 0.46
            )
        } else if c < 0.6 {
            // Amber rose → Dusty mauve
            let l = (c - 0.3) / 0.3
            return Color(
                red: 0.82 - l * 0.16,    // 0.82 → 0.66
                green: 0.44 + l * 0.06,   // 0.44 → 0.50
                blue: 0.46 + l * 0.14     // 0.46 → 0.60
            )
        } else {
            // Dusty mauve → Cool lavender
            let l = (c - 0.6) / 0.4
            return Color(
                red: 0.66 - l * 0.14,    // 0.66 → 0.52
                green: 0.50 + l * 0.04,   // 0.50 → 0.54
                blue: 0.60 + l * 0.12     // 0.60 → 0.72
            )
        }
    }
}

// MARK: - Background Modifier

struct FractalBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    AppColor.background
                    FractalTexture()
                }
                .ignoresSafeArea()
            )
    }
}

extension View {
    func fractalBackground() -> some View {
        modifier(FractalBackground())
    }
}
