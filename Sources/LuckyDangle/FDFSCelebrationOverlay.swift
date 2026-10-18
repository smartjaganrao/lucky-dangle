import AppKit
import CoreGraphics
import QuartzCore

// MARK: - FDFS "Git Push / Build Success" Theatre Cutout Celebration
// Full-screen 5-second theatre celebration with Paal Abhishekam, Cutout garland, and 1000-wala crackers.

final class FDFSCelebrationOverlay: NSWindow {

    private let celebrationView: FDFSCelebrationView
    private var dismissTimer: Timer?

    init() {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        celebrationView = FDFSCelebrationView(frame: NSRect(origin: .zero, size: screenRect.size))

        super.init(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        ignoresMouseEvents = false

        contentView = celebrationView

        celebrationView.onDismissRequested = { [weak self] in
            self?.dismissCelebration()
        }
    }

    deinit {
        dismissTimer?.invalidate()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func startCelebration() {
        orderFrontRegardless()
        celebrationView.startAnimation()

        // Festive audio fanfare
        NSSound(named: "Hero")?.play()

        // Auto dismiss after 5.5 seconds
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.5, repeats: false) { [weak self] _ in
            self?.dismissCelebration()
        }
    }

    func dismissCelebration() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.5
            animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.celebrationView.stopAnimation()
            self?.close()
        })
    }
}

// MARK: - Celebration View

final class FDFSCelebrationView: NSView {

    var onDismissRequested: (() -> Void)?

    private var animationTimer: Timer?
    private var elapsedSeconds: CGFloat = 0.0

    // Cutout rise animation
    private var cutoutRiseProgress: CGFloat = 0.0

    // Paal Abhishekam Milk Droplets
    private struct MilkDrop {
        var x: CGFloat
        var y: CGFloat
        var vy: CGFloat
        var size: CGFloat
        var alpha: CGFloat
    }
    private var milkDrops: [MilkDrop] = []

    // 1000-Wala Confetti & Crackers
    private struct ConfettiParticle {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var color: NSColor
        var size: CGFloat
        var rotation: CGFloat
        var rotationSpeed: CGFloat
    }
    private var confetti: [ConfettiParticle] = []

    // Poster image cache
    private var posterImage: NSImage?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        loadHeroPoster()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        loadHeroPoster()
    }

    private func loadHeroPoster() {
        // Look for Vijay, Rajini, or Ajith poster in bundle or Resources
        let posterCandidates = [
            "vijay_portrait", "rajini_portrait", "ajith_portrait",
            "vijay_goat", "rajini_vettaiyan", "ajith_gbu", "rajini_coolie"
        ]
        for candidate in posterCandidates {
            if let bundleUrl = Bundle.main.url(forResource: candidate, withExtension: "jpg"),
               let img = NSImage(contentsOf: bundleUrl) {
                self.posterImage = img
                return
            }
            let relPath = "Resources/\(candidate).jpg"
            if let img = NSImage(contentsOfFile: relPath) {
                self.posterImage = img
                return
            }
        }
    }

    func startAnimation() {
        elapsedSeconds = 0.0
        cutoutRiseProgress = 0.0
        milkDrops.removeAll()
        confetti.removeAll()

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateStep()
        }
        RunLoop.main.add(animationTimer!, forMode: .common)
    }

    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    override func mouseDown(with event: NSEvent) {
        onDismissRequested?()
    }

    private func updateStep() {
        elapsedSeconds += 1.0 / 60.0

        // Smooth rise of the cutout (0 to 1 over 0.8s)
        if cutoutRiseProgress < 1.0 {
            cutoutRiseProgress = min(1.0, cutoutRiseProgress + 0.025)
        }

        // 1. Spawn Milk Drops from Notch / Top Center
        let notchX = bounds.midX
        let topY = bounds.maxY
        for _ in 0..<3 {
            let drop = MilkDrop(
                x: notchX + CGFloat.random(in: -35...35),
                y: topY - CGFloat.random(in: 0...20),
                vy: CGFloat.random(in: 9.0...14.0),
                size: CGFloat.random(in: 4...10),
                alpha: CGFloat.random(in: 0.8...1.0)
            )
            milkDrops.append(drop)
        }

        // Update milk drops
        for i in 0..<milkDrops.count {
            milkDrops[i].y -= milkDrops[i].vy
            milkDrops[i].vy += 0.2 // Gravity
        }
        // Keep drops above screen floor
        milkDrops.removeAll { $0.y < 20 }

        // 2. Spawn 1000-Wala Confetti from bottom corners & edges
        let colors: [NSColor] = [
            NSColor(calibratedRed: 1.0, green: 0.15, blue: 0.15, alpha: 1.0), // Red 1000-wala paper
            NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.1, alpha: 1.0),  // Gold spark
            NSColor(calibratedRed: 0.15, green: 0.85, blue: 0.3, alpha: 1.0), // Emerald
            NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.95, alpha: 1.0), // White
            NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.05, alpha: 1.0)  // Deep Saffron
        ]

        if confetti.count < 140 {
            for _ in 0..<4 {
                let fromLeft = Bool.random()
                let p = ConfettiParticle(
                    x: fromLeft ? CGFloat.random(in: 30...bounds.midX) : CGFloat.random(in: bounds.midX...bounds.maxX - 30),
                    y: CGFloat.random(in: 10...60),
                    vx: fromLeft ? CGFloat.random(in: 2.0...8.0) : CGFloat.random(in: -8.0 ... -2.0),
                    vy: CGFloat.random(in: 12.0...22.0),
                    color: colors.randomElement()!,
                    size: CGFloat.random(in: 6...12),
                    rotation: CGFloat.random(in: 0...CGFloat.pi * 2),
                    rotationSpeed: CGFloat.random(in: -0.2...0.2)
                )
                confetti.append(p)
            }
        }

        for i in 0..<confetti.count {
            confetti[i].x += confetti[i].vx
            confetti[i].y += confetti[i].vy
            confetti[i].vy -= 0.38 // Gravity
            confetti[i].rotation += confetti[i].rotationSpeed
        }
        confetti.removeAll { $0.y < 0 }

        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // 1. Subtle Dark Theater Vignette Overlay
        ctx.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let vignetteColors = [
            NSColor(calibratedWhite: 0.0, alpha: 0.25).cgColor,
            NSColor(calibratedWhite: 0.0, alpha: 0.65).cgColor
        ] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: vignetteColors, locations: [0.0, 1.0]) {
            ctx.drawRadialGradient(
                grad,
                startCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                startRadius: bounds.width * 0.2,
                endCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                endRadius: bounds.width * 0.7,
                options: []
            )
        }
        ctx.restoreGState()

        // 2. Sweeping Theater Spotlights
        drawSpotlights(ctx: ctx)

        // 3. Giant Hero Cutout with Scaffolding & Marigold Garland
        drawHeroCutout(ctx: ctx)

        // 4. Paal Abhishekam (Milk Streams & Pouring Pots)
        drawPaalAbhishekam(ctx: ctx)

        // 5. 1000-Wala Confetti & Crackers
        drawConfettiAndCrackers(ctx: ctx)

        // 6. Flashing Neon Marquee Banner
        drawNeonBanner(ctx: ctx)
    }

    private func drawSpotlights(ctx: CGContext) {
        ctx.saveGState()
        let sweep1 = sin(elapsedSeconds * 2.2) * 120.0
        let sweep2 = -cos(elapsedSeconds * 2.0) * 120.0

        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.5, alpha: 0.08).cgColor)

        // Left Spotlight
        let leftPath = NSBezierPath()
        leftPath.move(to: NSPoint(x: 40, y: 0))
        leftPath.line(to: NSPoint(x: bounds.midX - 140 + sweep1, y: bounds.maxY))
        leftPath.line(to: NSPoint(x: bounds.midX + 40 + sweep1, y: bounds.maxY))
        leftPath.close()
        leftPath.fill()

        // Right Spotlight
        let rightPath = NSBezierPath()
        rightPath.move(to: NSPoint(x: bounds.maxX - 40, y: 0))
        rightPath.line(to: NSPoint(x: bounds.midX - 40 + sweep2, y: bounds.maxY))
        rightPath.line(to: NSPoint(x: bounds.midX + 140 + sweep2, y: bounds.maxY))
        rightPath.close()
        rightPath.fill()

        ctx.restoreGState()
    }

    private func drawHeroCutout(ctx: CGContext) {
        ctx.saveGState()

        let cutoutWidth: CGFloat = 280.0
        let cutoutHeight: CGFloat = 420.0
        let targetY = bounds.minY + 30.0
        let currentY = bounds.minY - cutoutHeight + (cutoutHeight + targetY) * cutoutRiseProgress
        let cutoutRect = CGRect(x: bounds.midX - cutoutWidth / 2, y: currentY, width: cutoutWidth, height: cutoutHeight)

        // Wooden Scaffolding Bamboo Poles behind Cutout
        ctx.setStrokeColor(NSColor(calibratedRed: 0.55, green: 0.38, blue: 0.22, alpha: 0.75).cgColor)
        ctx.setLineWidth(4.0)

        // Vertical poles
        for xOffset in [-cutoutWidth * 0.45, -cutoutWidth * 0.15, cutoutWidth * 0.15, cutoutWidth * 0.45] {
            ctx.move(to: CGPoint(x: bounds.midX + xOffset, y: bounds.minY))
            ctx.addLine(to: CGPoint(x: bounds.midX + xOffset, y: cutoutRect.maxY + 30))
            ctx.strokePath()
        }
        // Diagonal cross braces
        ctx.move(to: CGPoint(x: cutoutRect.minX - 10, y: cutoutRect.minY + 40))
        ctx.addLine(to: CGPoint(x: cutoutRect.maxX + 10, y: cutoutRect.maxY - 40))
        ctx.move(to: CGPoint(x: cutoutRect.maxX + 10, y: cutoutRect.minY + 40))
        ctx.addLine(to: CGPoint(x: cutoutRect.minX - 10, y: cutoutRect.maxY - 40))
        ctx.strokePath()

        // Cutout Shadow
        ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 24, color: NSColor.black.withAlphaComponent(0.6).cgColor)

        // Cutout Poster or Gold Silhouette
        let cutoutPath = NSBezierPath(roundedRect: cutoutRect, xRadius: 18, yRadius: 18)
        if let img = posterImage {
            ctx.saveGState()
            cutoutPath.addClip()
            img.draw(in: cutoutRect, from: .zero, operation: .copy, fraction: 1.0)
            ctx.restoreGState()
        } else {
            // Procedural Majestic Golden Hero Silhouette
            NSColor(calibratedRed: 0.15, green: 0.12, blue: 0.18, alpha: 1.0).setFill()
            cutoutPath.fill()
        }

        // Cutout Frame Border
        NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 0.9).setStroke()
        cutoutPath.lineWidth = 3.5
        cutoutPath.stroke()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Massive Yellow & Orange Marigold Garland draped over Cutout
        drawCutoutGarland(ctx: ctx, cutoutRect: cutoutRect)

        ctx.restoreGState()
    }

    private func drawCutoutGarland(ctx: CGContext, cutoutRect: CGRect) {
        ctx.saveGState()

        let garlandTopY = cutoutRect.maxY - 80
        let garlandBottomY = cutoutRect.minY + 90
        let midX = cutoutRect.midX

        // Curve of garland across shoulders
        let points: [(x: CGFloat, y: CGFloat, color: NSColor)] = [
            (cutoutRect.minX + 20, garlandTopY, .systemOrange),
            (cutoutRect.minX + 45, garlandTopY - 25, .systemYellow),
            (cutoutRect.minX + 75, garlandTopY - 60, .systemOrange),
            (midX - 35, garlandBottomY + 30, .systemYellow),
            (midX, garlandBottomY, .systemOrange),
            (midX + 35, garlandBottomY + 30, .systemYellow),
            (cutoutRect.maxX - 75, garlandTopY - 60, .systemOrange),
            (cutoutRect.maxX - 45, garlandTopY - 25, .systemYellow),
            (cutoutRect.maxX - 20, garlandTopY, .systemOrange)
        ]

        for pt in points {
            // Fluffy marigold flower puff
            pt.color.setFill()
            let r: CGFloat = 14.0
            let flowerRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            let flowerPath = NSBezierPath(ovalIn: flowerRect)
            flowerPath.fill()

            // Flower center dot
            NSColor(calibratedRed: 0.85, green: 0.2, blue: 0.05, alpha: 1.0).setFill()
            let centerPath = NSBezierPath(ovalIn: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8))
            centerPath.fill()
        }

        ctx.restoreGState()
    }

    private func drawPaalAbhishekam(ctx: CGContext) {
        ctx.saveGState()

        let notchX = bounds.midX
        let topY = bounds.maxY

        // Brass Milk Kalash (Pot) at Notch
        ctx.setFillColor(NSColor(calibratedRed: 0.95, green: 0.78, blue: 0.25, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: notchX - 22, y: topY - 32, width: 44, height: 30))
        // Pot rim
        ctx.setFillColor(NSColor(calibratedRed: 0.8, green: 0.6, blue: 0.15, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: notchX - 16, y: topY - 14, width: 32, height: 8))

        // White Creamy Milk Droplets Cascading Down
        ctx.setFillColor(NSColor(calibratedWhite: 0.98, alpha: 0.92).cgColor)
        for drop in milkDrops {
            ctx.fillEllipse(in: CGRect(x: drop.x - drop.size / 2, y: drop.y - drop.size / 2, width: drop.size, height: drop.size * 1.4))
        }

        // White Milk splash foam at top of cutout
        let splashY = bounds.minY + 390 * cutoutRiseProgress
        ctx.setFillColor(NSColor(calibratedWhite: 1.0, alpha: 0.7).cgColor)
        for i in -3...3 {
            let offset = CGFloat(i) * 14.0
            let foamSize: CGFloat = 16.0 - abs(CGFloat(i)) * 2.0
            ctx.fillEllipse(in: CGRect(x: notchX + offset - foamSize / 2, y: splashY, width: foamSize, height: foamSize * 0.7))
        }

        ctx.restoreGState()
    }

    private func drawConfettiAndCrackers(ctx: CGContext) {
        ctx.saveGState()

        for p in confetti {
            ctx.saveGState()
            ctx.translateBy(x: p.x, y: p.y)
            ctx.rotate(by: p.rotation)

            p.color.setFill()
            let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size * 0.6)
            ctx.fill(rect)

            ctx.restoreGState()
        }

        // Red 1000-Wala Cracker Bursts at Bottom Edge
        let bursts: [CGPoint] = [
            CGPoint(x: bounds.midX - 220, y: 40),
            CGPoint(x: bounds.midX + 220, y: 40),
            CGPoint(x: bounds.midX - 340, y: 30),
            CGPoint(x: bounds.midX + 340, y: 30)
        ]
        let sparkFlash = sin(elapsedSeconds * 30.0) > 0

        for pt in bursts {
            // Flash circle
            ctx.setFillColor(NSColor(calibratedRed: 1.0, green: sparkFlash ? 0.9 : 0.3, blue: 0.1, alpha: 0.85).cgColor)
            ctx.fillEllipse(in: CGRect(x: pt.x - 12, y: pt.y - 12, width: 24, height: 24))

            // Spark rays
            ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 0.9).cgColor)
            ctx.setLineWidth(1.8)
            for angle in [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0] {
                let rad = angle * .pi / 180.0
                ctx.move(to: pt)
                ctx.addLine(to: CGPoint(x: pt.x + cos(rad) * 22, y: pt.y + sin(rad) * 22))
            }
            ctx.strokePath()
        }

        ctx.restoreGState()
    }

    private func drawNeonBanner(ctx: CGContext) {
        ctx.saveGState()

        let bannerWidth: CGFloat = min(720, bounds.width - 60)
        let bannerHeight: CGFloat = 84
        let bannerRect = CGRect(x: bounds.midX - bannerWidth / 2, y: bounds.maxY - 170, width: bannerWidth, height: bannerHeight)

        // Banner Glass / Neon Background
        ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 18, color: NSColor.systemRed.withAlphaComponent(0.5).cgColor)

        let path = NSBezierPath(roundedRect: bannerRect, xRadius: 18, yRadius: 18)
        NSColor(calibratedRed: 0.08, green: 0.05, blue: 0.12, alpha: 0.94).setFill()
        path.fill()

        // Flashing Gold/Red Neon Border
        let isFlashGold = sin(elapsedSeconds * 8.0) > 0
        let borderCol = isFlashGold
            ? NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            : NSColor(calibratedRed: 1.0, green: 0.25, blue: 0.2, alpha: 1.0)
        borderCol.setStroke()
        path.lineWidth = 2.5
        path.stroke()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Title Line
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.alignment = .center
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 21),
            .foregroundColor: NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.3, alpha: 1.0),
            .paragraphStyle: titleParagraph
        ]
        let title = "🚀 BUILD SUCCESS • FDFS BLOCKBUSTER DEPLOYMENT! 🥁🎺"
        (title as NSString).draw(
            in: CGRect(x: bannerRect.minX + 10, y: bannerRect.maxY - 44, width: bannerRect.width - 20, height: 30),
            withAttributes: titleAttrs
        )

        // Subtitle Line
        let subParagraph = NSMutableParagraphStyle()
        subParagraph.alignment = .center
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 0.95),
            .paragraphStyle: subParagraph
        ]
        let sub = "100% MASS • NO PRODUCTION BUGS • ALL THEATRES HOUSEFULL 🔥"
        (sub as NSString).draw(
            in: CGRect(x: bannerRect.minX + 10, y: bannerRect.minY + 12, width: bannerRect.width - 20, height: 20),
            withAttributes: subAttrs
        )

        ctx.restoreGState()
    }
}
