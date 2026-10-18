import AppKit

// MARK: - Flower Petal Types (Pushpanjali)

enum PetalType: CaseIterable {
    case marigoldYellow
    case marigoldOrange
    case sacredRoseRed
    case jasmineIvory

    var primaryColor: NSColor {
        switch self {
        case .marigoldYellow:
            return NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.03, alpha: 0.95) // #FFC107
        case .marigoldOrange:
            return NSColor(calibratedRed: 1.0, green: 0.43, blue: 0.0, alpha: 0.95)  // #FF6D00
        case .sacredRoseRed:
            return NSColor(calibratedRed: 0.85, green: 0.05, blue: 0.18, alpha: 0.95) // #D81B60 / Crimson
        case .jasmineIvory:
            return NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.92, alpha: 0.95) // Ivory
        }
    }

    var accentColor: NSColor {
        switch self {
        case .marigoldYellow:
            return NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.0, alpha: 0.9)
        case .marigoldOrange:
            return NSColor(calibratedRed: 0.85, green: 0.22, blue: 0.0, alpha: 0.9)
        case .sacredRoseRed:
            return NSColor(calibratedRed: 0.55, green: 0.0, blue: 0.08, alpha: 0.9)
        case .jasmineIvory:
            return NSColor(calibratedRed: 0.9, green: 0.88, blue: 0.75, alpha: 0.8)
        }
    }
}

struct FlowerPetal {
    var position: CGPoint
    var velocity: CGPoint
    var rotation: CGFloat
    var rotationVelocity: CGFloat
    var wobblePhase: CGFloat
    var wobbleSpeed: CGFloat
    var wobbleAmplitude: CGFloat
    var size: CGSize
    var type: PetalType
    var alpha: CGFloat
    var lifetime: CGFloat
    var age: CGFloat
}

struct IncenseWisp {
    var position: CGPoint
    var velocity: CGPoint
    var alpha: CGFloat
    var scale: CGFloat
    var age: CGFloat
    var lifetime: CGFloat
}

// MARK: - Ayudha Pooja Theme Engine

final class AyudhaPoojaEffect {

    private(set) var isEnabled: Bool = false
    private var petals: [FlowerPetal] = []
    private var smokeWisps: [IncenseWisp] = []

    // Ritual & Aura States
    private(set) var aartiGlowAlpha: CGFloat = 0
    private var blessingBannerAlpha: CGFloat = 0
    private var blessingBannerYOffset: CGFloat = 0
    private var smokeTimer: TimeInterval = 0
    private var aartiRotation: CGFloat = 0

    init(enabled: Bool = false) {
        self.isEnabled = enabled
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            petals.removeAll()
            smokeWisps.removeAll()
            aartiGlowAlpha = 0
            blessingBannerAlpha = 0
        }
    }

    // Custom banner text for viral meme rituals
    private var activeCustomBanner: (title: String, subtitle: String)? = nil

    // MARK: - Ritual Activation

    /// Triggers the grand blessing / celebration:
    /// - Pushpanjali (burst of marigold, rose & jasmine flower petals)
    /// - Divine Aarti flame aura with radiant golden rays
    /// - Auspicious chime
    /// - Floating blessing or meme banner
    func triggerRitual(at origin: CGPoint, customBanner: (title: String, subtitle: String)? = nil) {
        guard isEnabled else { return }

        self.activeCustomBanner = customBanner

        // 1. Divine Aarti Aura
        aartiGlowAlpha = 1.0

        // 2. Pushpanjali Petal Burst (45 fresh petals)
        for _ in 0..<45 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 40...140)
            let velX = cos(angle) * speed * 0.7
            let velY = sin(angle) * speed * 0.4 + CGFloat.random(in: 30...80) // upward burst before gravity takes over

            let type = PetalType.allCases.randomElement() ?? .marigoldYellow
            let width: CGFloat = type == .jasmineIvory ? CGFloat.random(in: 7...10) : CGFloat.random(in: 10...16)
            let height: CGFloat = type == .jasmineIvory ? CGFloat.random(in: 11...15) : CGFloat.random(in: 14...22)

            let petal = FlowerPetal(
                position: CGPoint(
                    x: origin.x + CGFloat.random(in: -25...25),
                    y: origin.y + CGFloat.random(in: -20...20)
                ),
                velocity: CGPoint(x: velX, y: velY),
                rotation: CGFloat.random(in: 0...(2 * .pi)),
                rotationVelocity: CGFloat.random(in: -4...4),
                wobblePhase: CGFloat.random(in: 0...(2 * .pi)),
                wobbleSpeed: CGFloat.random(in: 3...7),
                wobbleAmplitude: CGFloat.random(in: 15...35),
                size: CGSize(width: width, height: height),
                type: type,
                alpha: 1.0,
                lifetime: CGFloat.random(in: 3.0...4.5),
                age: 0
            )
            petals.append(petal)
        }

        // 3. Auspicious Blessing / Meme Banner
        blessingBannerAlpha = 1.0
        blessingBannerYOffset = 0

        // 4. Play Sound
        NSSound(named: "Glass")?.play()
    }

    // MARK: - Physics & Lifecycle Update

    func step(dt: CGFloat, bobPosition: CGPoint) {
        guard isEnabled else { return }

        // Update Aarti Glow & Rays
        if aartiGlowAlpha > 0 {
            aartiGlowAlpha = max(0, aartiGlowAlpha - dt * 0.35)
            aartiRotation += dt * 0.8
        }

        // Update Blessing Banner
        if blessingBannerAlpha > 0 {
            blessingBannerAlpha = max(0, blessingBannerAlpha - dt * 0.3)
            blessingBannerYOffset += dt * 24.0 // float upward
        }

        // Periodic subtle incense smoke (agarbatti)
        smokeTimer += Double(dt)
        if smokeTimer > 0.45 {
            smokeTimer = 0
            spawnIncenseWisp(near: bobPosition)
        }

        // Update Incense Wisps
        for i in (0..<smokeWisps.count).reversed() {
            smokeWisps[i].age += dt
            if smokeWisps[i].age >= smokeWisps[i].lifetime {
                smokeWisps.remove(at: i)
                continue
            }
            smokeWisps[i].position.x += smokeWisps[i].velocity.x * dt + sin(smokeWisps[i].age * 3) * 0.4
            smokeWisps[i].position.y += smokeWisps[i].velocity.y * dt
            smokeWisps[i].scale += dt * 0.4
            let progress = smokeWisps[i].age / smokeWisps[i].lifetime
            smokeWisps[i].alpha = (1.0 - progress) * 0.35
        }

        // Update Flower Petals
        let gravity: CGFloat = -110.0 // gentle drifting downward
        for i in (0..<petals.count).reversed() {
            petals[i].age += dt
            if petals[i].age >= petals[i].lifetime {
                petals.remove(at: i)
                continue
            }

            // Physics: Gravity & Air Resistance
            petals[i].velocity.y += gravity * dt
            petals[i].velocity.x *= 0.97
            petals[i].velocity.y *= 0.98

            // Wobble (natural leaf/petal fluttering)
            petals[i].wobblePhase += petals[i].wobbleSpeed * dt
            let wobbleOffset = sin(petals[i].wobblePhase) * petals[i].wobbleAmplitude * dt

            petals[i].position.x += petals[i].velocity.x * dt + wobbleOffset
            petals[i].position.y += petals[i].velocity.y * dt
            petals[i].rotation += petals[i].rotationVelocity * dt

            // Fade out smoothly near end of life
            let remaining = petals[i].lifetime - petals[i].age
            if remaining < 0.8 {
                petals[i].alpha = max(0, remaining / 0.8)
            }
        }
    }

    private func spawnIncenseWisp(near point: CGPoint) {
        guard smokeWisps.count < 12 else { return }
        let wisp = IncenseWisp(
            position: CGPoint(
                x: point.x + CGFloat.random(in: -10...10),
                y: point.y - 30
            ),
            velocity: CGPoint(
                x: CGFloat.random(in: -5...5),
                y: CGFloat.random(in: 25...45)
            ),
            alpha: 0.35,
            scale: 0.6,
            age: 0,
            lifetime: CGFloat.random(in: 1.8...2.6)
        )  
        smokeWisps.append(wisp)
    }

    // MARK: - Drawing: Background Effects (Aarti Aura)

    func drawBackgroundEffects(ctx: CGContext, anchor: CGPoint, bob: CGPoint) {
        guard isEnabled else { return }

        // If Aarti glow is active, draw the divine radial halo & sunburst rays
        if aartiGlowAlpha > 0 {
            ctx.saveGState()

            let maxRadius: CGFloat = 110.0
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            // 1. Soft radial Aarti halo (Gold -> Deep Saffron -> Transparent)
            let colors = [
                NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.6, alpha: 0.85 * aartiGlowAlpha).cgColor,
                NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.05, alpha: 0.5 * aartiGlowAlpha).cgColor,
                NSColor(calibratedRed: 0.95, green: 0.2, blue: 0.05, alpha: 0.25 * aartiGlowAlpha).cgColor,
                NSColor(calibratedRed: 0.9, green: 0.1, blue: 0.0, alpha: 0.0).cgColor
            ] as CFArray

            let locations: [CGFloat] = [0.0, 0.35, 0.7, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                ctx.drawRadialGradient(
                    gradient,
                    startCenter: bob,
                    startRadius: 8,
                    endCenter: bob,
                    endRadius: maxRadius,
                    options: [.drawsAfterEndLocation]
                )
            }

            // 2. Radiant Divine Rays (Auspicious Aarti Chariot)
            let rayCount = 12
            ctx.setLineWidth(1.6)
            for i in 0..<rayCount {
                let angle = aartiRotation + (CGFloat(i) * 2 * .pi / CGFloat(rayCount))
                let innerR: CGFloat = 35.0
                let outerR: CGFloat = 75.0 + sin(CGFloat(i) * 1.5 + aartiRotation * 4) * 15.0

                let p1 = CGPoint(x: bob.x + cos(angle) * innerR, y: bob.y + sin(angle) * innerR)
                let p2 = CGPoint(x: bob.x + cos(angle) * outerR, y: bob.y + sin(angle) * outerR)

                let rayColor = NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 0.45 * aartiGlowAlpha)
                ctx.setStrokeColor(rayColor.cgColor)
                ctx.strokeLineSegments(between: [p1, p2])
            }

            ctx.restoreGState()
        }
    }

    // MARK: - Drawing: Sacred Thread (Mauli / Kalawa with Mango Leaves & Marigold Beads)

    func drawSacredThread(ctx: CGContext, anchor: CGPoint, bob: CGPoint) {
        guard isEnabled else { return }

        ctx.saveGState()

        let dx = bob.x - anchor.x
        let dy = bob.y - anchor.y
        let length = hypot(dx, dy)
        let angle = atan2(dy, dx)

        // 1. Draw Sacred Twisted Mauli/Kalawa Thread (Red & Saffron strands)
        let segments = Int(length / 8.0)
        let redColor = NSColor(calibratedRed: 0.88, green: 0.12, blue: 0.15, alpha: 0.95).cgColor
        let yellowColor = NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.15, alpha: 0.95).cgColor

        ctx.setLineWidth(2.8)
        ctx.setLineCap(.round)

        for i in 0..<segments {
            let t1 = CGFloat(i) / CGFloat(segments)
            let t2 = CGFloat(i + 1) / CGFloat(segments)

            let p1 = CGPoint(x: anchor.x + dx * t1, y: anchor.y + dy * t1)
            let p2 = CGPoint(x: anchor.x + dx * t2, y: anchor.y + dy * t2)

            ctx.setStrokeColor(i % 2 == 0 ? redColor : yellowColor)
            ctx.strokeLineSegments(between: [p1, p2])
        }

        // 2. Sacred Marigold Flower Beads along the thread (at 25%, 50%, 75%)
        let beadPositions: [CGFloat] = [0.25, 0.50, 0.75]
        for (idx, frac) in beadPositions.enumerated() {
            let cx = anchor.x + dx * frac
            let cy = anchor.y + dy * frac
            let isOrange = (idx % 2 == 0)

            drawMarigoldBlossom(ctx: ctx, center: CGPoint(x: cx, y: cy), radius: 6.5, isOrange: isOrange)
        }

        // 3. Mango Leaves (Mavilai Toran) at the top anchor
        drawMangoLeavesAtAnchor(ctx: ctx, anchor: anchor, angle: angle)

        // Anchor Golden Stud
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.0, alpha: 0.95).cgColor)
        ctx.fillEllipse(in: NSRect(x: anchor.x - 4.5, y: anchor.y - 4.5, width: 9, height: 9))

        ctx.restoreGState()
    }

    private func drawMangoLeavesAtAnchor(ctx: CGContext, anchor: CGPoint, angle: CGFloat) {
        ctx.saveGState()

        // Left and Right Mango Leaves
        let leafAngles: [CGFloat] = [-0.65, 0.65]
        for leafAngle in leafAngles {
            ctx.saveGState()
            ctx.translateBy(x: anchor.x, y: anchor.y)
            ctx.rotate(by: leafAngle - .pi / 2)

            let leafPath = CGMutablePath()
            leafPath.move(to: .zero)
            leafPath.addCurve(to: CGPoint(x: 26, y: 0), control1: CGPoint(x: 8, y: 10), control2: CGPoint(x: 18, y: 8))
            leafPath.addCurve(to: .zero, control1: CGPoint(x: 18, y: -8), control2: CGPoint(x: 8, y: -10))
            leafPath.closeSubpath()

            // Fresh mango leaf green
            ctx.setFillColor(NSColor(calibratedRed: 0.16, green: 0.62, blue: 0.22, alpha: 0.9).cgColor)
            ctx.addPath(leafPath)
            ctx.fillPath()

            // Central vein
            ctx.setStrokeColor(NSColor(calibratedRed: 0.35, green: 0.8, blue: 0.3, alpha: 0.8).cgColor)
            ctx.setLineWidth(1.0)
            ctx.strokeLineSegments(between: [.zero, CGPoint(x: 22, y: 0)])

            ctx.restoreGState()
        }

        // Red auspicious tilak dot on the anchor
        ctx.setFillColor(NSColor(calibratedRed: 0.9, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: anchor.x - 3, y: anchor.y - 3, width: 6, height: 6))

        ctx.restoreGState()
    }

    private func drawMarigoldBlossom(ctx: CGContext, center: CGPoint, radius: CGFloat, isOrange: Bool) {
        ctx.saveGState()

        let baseColor = isOrange
            ? NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.0, alpha: 0.95)
            : NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.05, alpha: 0.95)
        let innerColor = isOrange
            ? NSColor(calibratedRed: 0.85, green: 0.2, blue: 0.0, alpha: 0.95)
            : NSColor(calibratedRed: 1.0, green: 0.52, blue: 0.0, alpha: 0.95)

        // Outer ruffled petals
        let petalCount = 7
        for i in 0..<petalCount {
            let a = CGFloat(i) * 2 * .pi / CGFloat(petalCount)
            let px = center.x + cos(a) * (radius * 0.55)
            let py = center.y + sin(a) * (radius * 0.55)
            ctx.setFillColor(baseColor.cgColor)
            ctx.fillEllipse(in: NSRect(x: px - radius * 0.45, y: py - radius * 0.45, width: radius * 0.9, height: radius * 0.9))
        }

        // Inner core
        ctx.setFillColor(innerColor.cgColor)
        ctx.fillEllipse(in: NSRect(x: center.x - radius * 0.4, y: center.y - radius * 0.4, width: radius * 0.8, height: radius * 0.8))

        ctx.restoreGState()
    }

    // MARK: - Drawing: Foreground Decorations (Chandanam & Kumkum Tilak + Garland)

    func drawForegroundDecorations(ctx: CGContext, bob: CGPoint, charmSize: CGSize, emoji: String) {
        guard isEnabled else { return }

        ctx.saveGState()

        // 1. Draw Marigold Garland (Toran) draped around the charm bob
        let garlandY = bob.y - charmSize.height * 0.32
        let garlandWidth = charmSize.width * 0.85
        let blossomCount = 5

        for i in 0..<blossomCount {
            let t = CGFloat(i) / CGFloat(blossomCount - 1)
            let bx = bob.x - garlandWidth / 2 + garlandWidth * t
            // slight gentle dip in the middle
            let sag = sin(t * .pi) * 8.0
            let by = garlandY - sag
            let isOrange = (i % 2 == 0)

            drawMarigoldBlossom(ctx: ctx, center: CGPoint(x: bx, y: by), radius: 6.0, isOrange: isOrange)
        }

        // 2. Draw Chandanam & Kumkum Tilak on the charm
        // (Sandalwood paste mark + bright vermilion Kumkum dot)
        let tilakY = bob.y + charmSize.height * 0.22
        let tilakX = bob.x

        // Sandalwood (Chandanam) yellow-gold halo/crescent
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.35, alpha: 0.95).cgColor)
        ctx.fillEllipse(in: NSRect(x: tilakX - 7.5, y: tilakY - 4, width: 15, height: 8))

        // Sacred Kumkum Red center dot
        ctx.setFillColor(NSColor(calibratedRed: 0.88, green: 0.05, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: tilakX - 3.5, y: tilakY - 3.5, width: 7, height: 7))

        // Specular highlight on Kumkum
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.7).cgColor)
        ctx.fillEllipse(in: NSRect(x: tilakX - 1.5, y: tilakY + 0.5, width: 2.2, height: 2.2))

        ctx.restoreGState()
    }

    // MARK: - Drawing: Foreground Effects (Petal Shower, Wisps & Blessing Banner)

    func drawForegroundEffects(ctx: CGContext) {
        guard isEnabled else { return }

        ctx.saveGState()

        // 1. Draw Incense Smoke Wisps
        for wisp in smokeWisps {
            ctx.saveGState()
            ctx.setFillColor(NSColor.white.withAlphaComponent(wisp.alpha).cgColor)
            let r = 8.0 * wisp.scale
            ctx.fillEllipse(in: NSRect(x: wisp.position.x - r, y: wisp.position.y - r, width: r * 2, height: r * 2))
            ctx.restoreGState()
        }

        // 2. Draw Fluttering Flower Petals (Pushpanjali)
        for petal in petals {
            ctx.saveGState()
            ctx.translateBy(x: petal.position.x, y: petal.position.y)
            ctx.rotate(by: petal.rotation)

            let w = petal.size.width
            let h = petal.size.height

            let path = CGMutablePath()
            switch petal.type {
            case .marigoldYellow, .marigoldOrange:
                // Scalloped ruffled marigold petal
                path.move(to: CGPoint(x: 0, y: -h / 2))
                path.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: w / 2, y: -h / 3), control2: CGPoint(x: w * 0.7, y: -h / 6))
                path.addCurve(to: CGPoint(x: 0, y: h / 2), control1: CGPoint(x: w * 0.6, y: h / 3), control2: CGPoint(x: w * 0.3, y: h / 2))
                path.addCurve(to: CGPoint(x: -w / 2, y: 0), control1: CGPoint(x: -w * 0.3, y: h / 2), control2: CGPoint(x: -w * 0.6, y: h / 3))
                path.addCurve(to: CGPoint(x: 0, y: -h / 2), control1: CGPoint(x: -w * 0.7, y: -h / 6), control2: CGPoint(x: -w / 2, y: -h / 3))
                path.closeSubpath()

            case .sacredRoseRed:
                // Curved heart/oval rose petal
                path.move(to: CGPoint(x: 0, y: -h / 2))
                path.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: w * 0.7, y: -h / 4))
                path.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w * 0.5, y: h * 0.6))
                path.addQuadCurve(to: CGPoint(x: -w / 2, y: 0), control: CGPoint(x: -w * 0.5, y: h * 0.6))
                path.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: -w * 0.7, y: -h / 4))
                path.closeSubpath()

            case .jasmineIvory:
                // Elegant pointed ivory jasmine petal
                path.move(to: CGPoint(x: 0, y: -h / 2))
                path.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: w * 0.6, y: -h / 4))
                path.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w * 0.2, y: h / 3))
                path.addQuadCurve(to: CGPoint(x: -w / 2, y: 0), control: CGPoint(x: -w * 0.2, y: h / 3))
                path.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: -w * 0.6, y: -h / 4))
                path.closeSubpath()
            }

            // Fill with vibrant petal gradient
            ctx.setFillColor(petal.type.primaryColor.withAlphaComponent(petal.alpha).cgColor)
            ctx.addPath(path)
            ctx.fillPath()

            // Subtle petal central vein/highlight
            ctx.setStrokeColor(petal.type.accentColor.withAlphaComponent(petal.alpha * 0.8).cgColor)
            ctx.setLineWidth(0.8)
            ctx.strokeLineSegments(between: [CGPoint(x: 0, y: -h * 0.35), CGPoint(x: 0, y: h * 0.35)])

            ctx.restoreGState()
        }

        // 3. Draw Floating Blessing Banner ("शुभ आयुध पूजा ✨")
        if blessingBannerAlpha > 0 {
            drawBlessingBanner(ctx: ctx)
        }

        ctx.restoreGState()
    }

    private func drawBlessingBanner(ctx: CGContext) {
        ctx.saveGState()

        let bannerText = activeCustomBanner?.title ?? "शुभ आयुध पूजा  🪔✨"
        let subtitleText = activeCustomBanner?.subtitle ?? "Ayudha Pooja Blessings!"

        let font1 = NSFont.boldSystemFont(ofSize: 13.5)
        let font2 = NSFont.systemFont(ofSize: 10.5, weight: .medium)

        let attr1: [NSAttributedString.Key: Any] = [
            .font: font1,
            .foregroundColor: NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.2, alpha: blessingBannerAlpha)
        ]
        let attr2: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: NSColor.white.withAlphaComponent(blessingBannerAlpha * 0.9)
        ]

        let str1 = NSAttributedString(string: bannerText, attributes: attr1)
        let str2 = NSAttributedString(string: subtitleText, attributes: attr2)

        let size1 = str1.size()
        let size2 = str2.size()

        let bannerWidth = max(size1.width, size2.width) + 24
        let bannerHeight = size1.height + size2.height + 12

        // Centered horizontally, floats up around mid-view
        let bannerX = (280 - bannerWidth) / 2
        let bannerY = 80 + blessingBannerYOffset

        let bannerRect = NSRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight)

        // Pill background with golden vermilion glow
        let bgPath = NSBezierPath(roundedRect: bannerRect, xRadius: 10, yRadius: 10)
        NSColor(calibratedRed: 0.1, green: 0.02, blue: 0.02, alpha: 0.82 * blessingBannerAlpha).setFill()
        bgPath.fill()

        NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.1, alpha: 0.75 * blessingBannerAlpha).setStroke()
        bgPath.lineWidth = 1.2
        bgPath.stroke()

        str1.draw(at: NSPoint(x: bannerX + (bannerWidth - size1.width) / 2, y: bannerY + size2.height + 7))
        str2.draw(at: NSPoint(x: bannerX + (bannerWidth - size2.width) / 2, y: bannerY + 5))

        ctx.restoreGState()
    }
}
