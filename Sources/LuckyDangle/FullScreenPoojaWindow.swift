import AppKit

// MARK: - Full Screen Ayudha Pooja Window

final class FullScreenPoojaWindow: NSWindow {

    private let poojaView: FullScreenPoojaView

    init() {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        poojaView = FullScreenPoojaView(frame: NSRect(origin: .zero, size: screen.size))

        super.init(
            contentRect: screen,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating // Sits gently above desktop windows, below menus
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovableByWindowBackground = false

        // CRITICAL: 100% click-through. Never intercepts mouse clicks, drags or keystrokes!
        ignoresMouseEvents = true

        contentView = poojaView

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged() {
        guard let screen = NSScreen.main?.frame else { return }
        setFrame(screen, display: true)
        poojaView.frame = NSRect(origin: .zero, size: screen.size)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func triggerRitual() {
        poojaView.triggerRitual()
    }
}

// MARK: - Full Screen View with 3 Patta Center & Toran

final class FullScreenPoojaView: NSView {

    private var petals: [FlowerPetal] = []
    private var aartiGlowAlpha: CGFloat = 0
    private var aartiRotation: CGFloat = 0
    private var bannerAlpha: CGFloat = 0
    private var bannerYOffset: CGFloat = 0
    private var timer: Timer?

    // 3 Patta breathing subtle glow pulse
    private var pulsePhase: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        startAnimationLoop()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    private func startAnimationLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.stepAnimation()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stepAnimation() {
        let dt: CGFloat = 1.0 / 60.0
        pulsePhase += dt * 1.5

        if aartiGlowAlpha > 0 {
            aartiGlowAlpha = max(0, aartiGlowAlpha - dt * 0.3)
            aartiRotation += dt * 0.7
        }

        if bannerAlpha > 0 {
            bannerAlpha = max(0, bannerAlpha - dt * 0.25)
            bannerYOffset += dt * 20.0
        }

        // Fullscreen Petal Physics
        let gravity: CGFloat = -95.0
        for i in (0..<petals.count).reversed() {
            petals[i].age += dt
            if petals[i].age >= petals[i].lifetime {
                petals.remove(at: i)
                continue
            }

            petals[i].velocity.y += gravity * dt
            petals[i].velocity.x *= 0.98
            petals[i].velocity.y *= 0.985

            petals[i].wobblePhase += petals[i].wobbleSpeed * dt
            let wobble = sin(petals[i].wobblePhase) * petals[i].wobbleAmplitude * dt

            petals[i].position.x += petals[i].velocity.x * dt + wobble
            petals[i].position.y += petals[i].velocity.y * dt
            petals[i].rotation += petals[i].rotationVelocity * dt

            let remaining = petals[i].lifetime - petals[i].age
            if remaining < 1.0 {
                petals[i].alpha = max(0, remaining / 1.0)
            }
        }

        needsDisplay = true
    }

    func triggerRitual() {
        aartiGlowAlpha = 1.0
        bannerAlpha = 1.0
        bannerYOffset = 0

        // Shower petals across the entire width of the screen
        let screenW = bounds.width
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        for _ in 0..<75 {
            let spawnX = CGFloat.random(in: (center.x - screenW * 0.45)...(center.x + screenW * 0.45))
            let spawnY = bounds.height - CGFloat.random(in: 10...120)

            let type = PetalType.allCases.randomElement() ?? .marigoldYellow
            let w = type == .jasmineIvory ? CGFloat.random(in: 8...12) : CGFloat.random(in: 12...18)
            let h = type == .jasmineIvory ? CGFloat.random(in: 12...16) : CGFloat.random(in: 16...24)

            let petal = FlowerPetal(
                position: CGPoint(x: spawnX, y: spawnY),
                velocity: CGPoint(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -40...10)),
                rotation: CGFloat.random(in: 0...(2 * .pi)),
                rotationVelocity: CGFloat.random(in: -3...3),
                wobblePhase: CGFloat.random(in: 0...(2 * .pi)),
                wobbleSpeed: CGFloat.random(in: 2...6),
                wobbleAmplitude: CGFloat.random(in: 20...45),
                size: CGSize(width: w, height: h),
                type: type,
                alpha: 1.0,
                lifetime: CGFloat.random(in: 4.5...7.0),
                age: 0
            )
            petals.append(petal)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(dirtyRect)

        let centerX = bounds.midX
        let centerY = bounds.midY

        // 1. Draw Top Mango Leaf & Marigold Toran across the entire screen
        drawTopToran(ctx: ctx)

        // 2. Aarti Divine Glow Pulse around center 3 Patta
        drawCenterAartiGlow(ctx: ctx, center: CGPoint(x: centerX, y: centerY))

        // 3. Draw The Sacred 3 Patta in the Exact Center
        drawThreePattaCenter(ctx: ctx, center: CGPoint(x: centerX, y: centerY))

        // 4. Draw Floating Petals Shower
        drawPetals(ctx: ctx)

        // 5. Draw Grand Blessing Banner during Ritual
        if bannerAlpha > 0 {
            drawBlessingBanner(ctx: ctx, center: CGPoint(x: centerX, y: centerY + 140))
        }
    }

    // MARK: - 3 Patta Center (Tripundra with Kumkum Bindu)

    private func drawThreePattaCenter(ctx: CGContext, center: CGPoint) {
        ctx.saveGState()

        let pattaWidth: CGFloat = 340.0
        let pattaHeight: CGFloat = 15.0
        let pattaSpacing: CGFloat = 11.0

        // Gentle breathing pulse
        let breathe = 0.92 + 0.08 * sin(pulsePhase)

        // Subtle warm sacred shadow
        ctx.setShadow(
            offset: CGSize(width: 0, height: -2),
            blur: 12.0,
            color: NSColor(calibratedRed: 0.8, green: 0.4, blue: 0.0, alpha: 0.35 * breathe).cgColor
        )

        // Three Patta Y coordinates (top, middle, bottom)
        let yOffsets: [CGFloat] = [
            pattaHeight + pattaSpacing, // Top stripe
            0,                          // Middle stripe
            -(pattaHeight + pattaSpacing) // Bottom stripe
        ]

        for yOff in yOffsets {
            let y = center.y + yOff
            let rect = NSRect(
                x: center.x - pattaWidth / 2,
                y: y - pattaHeight / 2,
                width: pattaWidth,
                height: pattaHeight
            )

            // Organic tapered finger-stroke path (Authentic Vibhuti / Chandanam)
            let path = CGMutablePath()
            let rx = rect.minX
            let rMaxX = rect.maxX
            let ry = rect.midY

            // Left tapered end -> top curve -> right tapered end -> bottom curve
            path.move(to: CGPoint(x: rx, y: ry))
            path.addCurve(
                to: CGPoint(x: rMaxX, y: ry),
                control1: CGPoint(x: rx + pattaWidth * 0.25, y: ry + pattaHeight * 0.7),
                control2: CGPoint(x: rx + pattaWidth * 0.75, y: ry + pattaHeight * 0.7)
            )
            path.addCurve(
                to: CGPoint(x: rx, y: ry),
                control1: CGPoint(x: rx + pattaWidth * 0.75, y: ry - pattaHeight * 0.7),
                control2: CGPoint(x: rx + pattaWidth * 0.25, y: ry - pattaHeight * 0.7)
            )
            path.closeSubpath()

            // Sacred Vibhuti / Holy White Sandalwood fill
            let baseColor = NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.94, alpha: 0.88 * breathe).cgColor
            ctx.setFillColor(baseColor)
            ctx.addPath(path)
            ctx.fillPath()

            // Subtle bright inner highlight
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.6 * breathe).cgColor)
            ctx.setLineWidth(1.2)
            ctx.strokeLineSegments(between: [
                CGPoint(x: rx + pattaWidth * 0.15, y: ry),
                CGPoint(x: rMaxX - pattaWidth * 0.15, y: ry)
            ])
            ctx.restoreGState()
        }

        // 4. Marigold Blossoms framing both sides of the 3 Patta
        drawMarigoldBlossom(ctx: ctx, center: CGPoint(x: center.x - pattaWidth / 2 - 14, y: center.y), radius: 11, isOrange: true)
        drawMarigoldBlossom(ctx: ctx, center: CGPoint(x: center.x + pattaWidth / 2 + 14, y: center.y), radius: 11, isOrange: false)

        // 5. Central Auspicious Kumkum Bindu (The Divine Red Tilak Dot)
        let kumkumRadius: CGFloat = 19.0

        // Golden Haldi / Turmeric base halo
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.05, alpha: 0.95).cgColor)
        ctx.fillEllipse(in: NSRect(
            x: center.x - (kumkumRadius + 3),
            y: center.y - (kumkumRadius + 3),
            width: (kumkumRadius + 3) * 2,
            height: (kumkumRadius + 3) * 2
        ))

        // Sacred Vermilion Kumkum Red
        ctx.setFillColor(NSColor(calibratedRed: 0.84, green: 0.04, blue: 0.12, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(
            x: center.x - kumkumRadius,
            y: center.y - kumkumRadius,
            width: kumkumRadius * 2,
            height: kumkumRadius * 2
        ))

        // Specular highlight on Kumkum
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.75).cgColor)
        ctx.fillEllipse(in: NSRect(
            x: center.x - 5,
            y: center.y + 4,
            width: 5.5,
            height: 5.5
        ))

        ctx.restoreGState()
    }

    private func drawCenterAartiGlow(ctx: CGContext, center: CGPoint) {
        let maxRadius: CGFloat = 260.0
        let intensity = max(0.25, aartiGlowAlpha)

        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.5, alpha: 0.35 * intensity).cgColor,
            NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.0, alpha: 0.18 * intensity).cgColor,
            NSColor(calibratedRed: 0.9, green: 0.1, blue: 0.0, alpha: 0.05 * intensity).cgColor,
            NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
        ] as CFArray

        let locations: [CGFloat] = [0.0, 0.4, 0.75, 1.0]
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            ctx.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 20,
                endCenter: center,
                endRadius: maxRadius,
                options: [.drawsAfterEndLocation]
            )
        }

        // Aarti sunburst rays when ritual is triggered
        if aartiGlowAlpha > 0 {
            let rays = 16
            ctx.setLineWidth(2.0)
            for i in 0..<rays {
                let ang = aartiRotation + (CGFloat(i) * 2 * .pi / CGFloat(rays))
                let r1: CGFloat = 60.0
                let r2: CGFloat = 190.0 + sin(CGFloat(i) + aartiRotation * 3) * 35.0
                let p1 = CGPoint(x: center.x + cos(ang) * r1, y: center.y + sin(ang) * r1)
                let p2 = CGPoint(x: center.x + cos(ang) * r2, y: center.y + sin(ang) * r2)
                ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 0.45 * aartiGlowAlpha).cgColor)
                ctx.strokeLineSegments(between: [p1, p2])
            }
        }

        ctx.restoreGState()
    }

    // MARK: - Top Screen Mango Leaf & Marigold Toran

    private func drawTopToran(ctx: CGContext) {
        ctx.saveGState()

        let screenW = bounds.width
        let topY = bounds.height
        let garlandSpacing: CGFloat = 85.0
        let count = Int(screenW / garlandSpacing) + 1

        // Top sacred Mauli string running across the screen
        let redStrand = NSColor(calibratedRed: 0.88, green: 0.15, blue: 0.15, alpha: 0.9).cgColor
        let goldStrand = NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.15, alpha: 0.9).cgColor

        ctx.setLineWidth(3.0)
        let segs = Int(screenW / 10.0)
        for s in 0..<segs {
            let x1 = CGFloat(s) * 10.0
            let x2 = CGFloat(s + 1) * 10.0
            ctx.setStrokeColor(s % 2 == 0 ? redStrand : goldStrand)
            ctx.strokeLineSegments(between: [CGPoint(x: x1, y: topY - 3), CGPoint(x: x2, y: topY - 3)])
        }

        for i in 0..<count {
            let x = CGFloat(i) * garlandSpacing
            let nextX = CGFloat(i + 1) * garlandSpacing

            // Catenary dipping marigold garland between points
            let blossomCount = 5
            for b in 0..<blossomCount {
                let frac = CGFloat(b) / CGFloat(blossomCount - 1)
                let bx = x + (nextX - x) * frac
                let dip = sin(frac * .pi) * 16.0
                let by = topY - 14.0 - dip
                let isOrange = (b % 2 == 0)
                drawMarigoldBlossom(ctx: ctx, center: CGPoint(x: bx, y: by), radius: 6.5, isOrange: isOrange)
            }

            // Fresh green Mango Leaves (Mavilai) hanging downward at joints
            drawHangingMangoLeaf(ctx: ctx, point: CGPoint(x: x, y: topY - 4))
        }

        ctx.restoreGState()
    }

    private func drawHangingMangoLeaf(ctx: CGContext, point: CGPoint) {
        ctx.saveGState()
        ctx.translateBy(x: point.x, y: point.y)

        let leafPath = CGMutablePath()
        leafPath.move(to: .zero)
        leafPath.addCurve(to: CGPoint(x: 0, y: -38), control1: CGPoint(x: 12, y: -12), control2: CGPoint(x: 10, y: -26))
        leafPath.addCurve(to: .zero, control1: CGPoint(x: -10, y: -26), control2: CGPoint(x: -12, y: -12))
        leafPath.closeSubpath()

        ctx.setFillColor(NSColor(calibratedRed: 0.16, green: 0.62, blue: 0.22, alpha: 0.92).cgColor)
        ctx.addPath(leafPath)
        ctx.fillPath()

        // Vein
        ctx.setStrokeColor(NSColor(calibratedRed: 0.35, green: 0.82, blue: 0.32, alpha: 0.8).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokeLineSegments(between: [.zero, CGPoint(x: 0, y: -32)])

        // Tilak dot on leaf base
        ctx.setFillColor(NSColor(calibratedRed: 0.88, green: 0.05, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: -2.5, y: -5, width: 5, height: 5))

        ctx.restoreGState()
    }

    private func drawMarigoldBlossom(ctx: CGContext, center: CGPoint, radius: CGFloat, isOrange: Bool) {
        ctx.saveGState()

        let baseColor = isOrange
            ? NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.0, alpha: 0.95)
            : NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.05, alpha: 0.95)
        let innerColor = isOrange
            ? NSColor(calibratedRed: 0.85, green: 0.22, blue: 0.0, alpha: 0.95)
            : NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.0, alpha: 0.95)

        let petalCount = 7
        for i in 0..<petalCount {
            let a = CGFloat(i) * 2 * .pi / CGFloat(petalCount)
            let px = center.x + cos(a) * (radius * 0.55)
            let py = center.y + sin(a) * (radius * 0.55)
            ctx.setFillColor(baseColor.cgColor)
            ctx.fillEllipse(in: NSRect(x: px - radius * 0.45, y: py - radius * 0.45, width: radius * 0.9, height: radius * 0.9))
        }

        ctx.setFillColor(innerColor.cgColor)
        ctx.fillEllipse(in: NSRect(x: center.x - radius * 0.4, y: center.y - radius * 0.4, width: radius * 0.8, height: radius * 0.8))

        ctx.restoreGState()
    }

    // MARK: - Fluttering Petals

    private func drawPetals(ctx: CGContext) {
        for petal in petals {
            ctx.saveGState()
            ctx.translateBy(x: petal.position.x, y: petal.position.y)
            ctx.rotate(by: petal.rotation)

            let w = petal.size.width
            let h = petal.size.height

            let path = CGMutablePath()
            switch petal.type {
            case .marigoldYellow, .marigoldOrange:
                path.move(to: CGPoint(x: 0, y: -h / 2))
                path.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: w / 2, y: -h / 3), control2: CGPoint(x: w * 0.7, y: -h / 6))
                path.addCurve(to: CGPoint(x: 0, y: h / 2), control1: CGPoint(x: w * 0.6, y: h / 3), control2: CGPoint(x: w * 0.3, y: h / 2))
                path.addCurve(to: CGPoint(x: -w / 2, y: 0), control1: CGPoint(x: -w * 0.3, y: h / 2), control2: CGPoint(x: -w * 0.6, y: h / 3))
                path.addCurve(to: CGPoint(x: 0, y: -h / 2), control1: CGPoint(x: -w * 0.7, y: -h / 6), control2: CGPoint(x: -w / 2, y: -h / 3))
                path.closeSubpath()
            case .sacredRoseRed:
                path.move(to: CGPoint(x: 0, y: -h / 2))
                path.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: w * 0.7, y: -h / 4))
                path.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w * 0.5, y: h * 0.6))
                path.addQuadCurve(to: CGPoint(x: -w / 2, y: 0), control: CGPoint(x: -w * 0.5, y: h * 0.6))
                path.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: -w * 0.7, y: -h / 4))
                path.closeSubpath()
            case .jasmineIvory:
                path.move(to: CGPoint(x: 0, y: -h / 2))
                path.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: w * 0.6, y: -h / 4))
                path.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w * 0.2, y: h / 3))
                path.addQuadCurve(to: CGPoint(x: -w / 2, y: 0), control: CGPoint(x: -w * 0.2, y: h / 3))
                path.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: -w * 0.6, y: -h / 4))
                path.closeSubpath()
            }

            ctx.setFillColor(petal.type.primaryColor.withAlphaComponent(petal.alpha).cgColor)
            ctx.addPath(path)
            ctx.fillPath()

            ctx.restoreGState()
        }
    }

    // MARK: - Grand Blessing Banner

    private func drawBlessingBanner(ctx: CGContext, center: CGPoint) {
        ctx.saveGState()

        let bannerText = "शुभ आयुध पूजा  🪔✨"
        let subtitleText = "Ayudha Pooja Blessings!"

        let font1 = NSFont.boldSystemFont(ofSize: 18)
        let font2 = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let attr1: [NSAttributedString.Key: Any] = [
            .font: font1,
            .foregroundColor: NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.2, alpha: bannerAlpha)
        ]
        let attr2: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: NSColor.white.withAlphaComponent(bannerAlpha * 0.95)
        ]

        let str1 = NSAttributedString(string: bannerText, attributes: attr1)
        let str2 = NSAttributedString(string: subtitleText, attributes: attr2)

        let size1 = str1.size()
        let size2 = str2.size()

        let bannerWidth = max(size1.width, size2.width) + 36
        let bannerHeight = size1.height + size2.height + 18

        let bannerX = center.x - bannerWidth / 2
        let bannerY = center.y + bannerYOffset

        let bannerRect = NSRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight)

        let bgPath = NSBezierPath(roundedRect: bannerRect, xRadius: 14, yRadius: 14)
        NSColor(calibratedRed: 0.12, green: 0.02, blue: 0.02, alpha: 0.88 * bannerAlpha).setFill()
        bgPath.fill()

        NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.1, alpha: 0.85 * bannerAlpha).setStroke()
        bgPath.lineWidth = 1.6
        bgPath.stroke()

        str1.draw(at: NSPoint(x: bannerX + (bannerWidth - size1.width) / 2, y: bannerY + size2.height + 10))
        str2.draw(at: NSPoint(x: bannerX + (bannerWidth - size2.width) / 2, y: bannerY + 8))

        ctx.restoreGState()
    }
}
