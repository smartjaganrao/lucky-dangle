import AppKit
import AVFoundation
import CoreGraphics
import QuartzCore

// MARK: - Screen Walker Window
// Transparent floating window that translates across window ledges or the macOS Dock.

final class ScreenWalkerWindow: NSWindow {

    private let walkerView: ScreenWalkerView
    private var ledgeTimer: Timer?
    private var globalMouseMonitor: Any?

    init() {
        let size = NSSize(width: 220, height: 180)
        let initialRect = NSRect(
            x: (NSScreen.main?.visibleFrame.midX ?? 700) - size.width / 2,
            y: NSScreen.main?.visibleFrame.minY ?? 30,
            width: size.width,
            height: size.height
        )

        walkerView = ScreenWalkerView(frame: NSRect(origin: .zero, size: size))

        super.init(
            contentRect: initialRect,
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

        contentView = walkerView

        walkerView.onWindowClick = { [weak self] in
            self?.handleWalkerClicked()
        }

        startTracking()
    }

    deinit {
        stopTracking()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func startTracking() {
        // Poll ledges and move walker ~40fps
        ledgeTimer?.invalidate()
        ledgeTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 40.0, repeats: true) { [weak self] _ in
            self?.updateWalkerMovement()
        }
        RunLoop.main.add(ledgeTimer!, forMode: .common)

        if globalMouseMonitor == nil {
            globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
                self?.checkMouseProximity()
            }
        }
    }

    func stopTracking() {
        ledgeTimer?.invalidate()
        ledgeTimer = nil
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }

    private func checkMouseProximity() {
        let mouse = NSEvent.mouseLocation
        let walkerCenter = NSPoint(x: frame.midX, y: frame.minY + 50)
        let dx = mouse.x - walkerCenter.x
        let dy = mouse.y - walkerCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        walkerView.setMouseProximity(distance: distance)
    }

    private func handleWalkerClicked() {
        walkerView.triggerClickReaction()
    }

    // MARK: - Movement & Ledge Snapping

    private var currentX: CGFloat = 400
    private var isFacingRight: Bool = true
    private let speed: CGFloat = 2.0
    private var lastLedgeY: CGFloat = 30

    private func updateWalkerMovement() {
        guard let screen = NSScreen.main else { return }

        checkMouseProximity()

        let ledge = LedgeFinder.findBestLedge(excludingPID: ProcessInfo.processInfo.processIdentifier)
        let targetFloorY = ledge?.y ?? screen.visibleFrame.minY
        let minX = (ledge?.minX ?? screen.visibleFrame.minX)
        let maxX = (ledge?.maxX ?? screen.visibleFrame.maxX) - frame.width

        // Smoothly transition Y towards target ledge
        lastLedgeY += (targetFloorY - lastLedgeY) * 0.15

        if !walkerView.isPaused {
            if isFacingRight {
                currentX += speed
                if currentX >= maxX {
                    currentX = maxX
                    isFacingRight = false
                    walkerView.isFacingRight = false
                }
            } else {
                currentX -= speed
                if currentX <= minX {
                    currentX = minX
                    isFacingRight = true
                    walkerView.isFacingRight = true
                }
            }
            walkerView.advanceWalkCycle()
        }

        setFrameOrigin(NSPoint(x: currentX, y: lastLedgeY))
    }
}

// MARK: - Screen Walker View
// Supports both AVPlayerLayer transparent video or procedural "Mass Hero with Bottle & Sunglasses"

final class ScreenWalkerView: NSView {

    var onWindowClick: (() -> Void)?
    var isFacingRight: Bool = true {
        didSet { needsDisplay = true }
    }
    private(set) var isPaused: Bool = false

    private var walkCycle: CGFloat = 0.0
    private var speechText: String?
    private var speechTimer: Timer?
    private var hasSaidNearSpeech: Bool = false

    // Video Layer support
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: Any? // AVPlayerLooper or observer

    private let punchlines = [
        "🥃 Cooling glass-a podu! Break time!",
        "🔥 Kuri vechcha eray vizhanum!",
        "😎 Hukum... Tiger ka Hukum!",
        "💥 Polakattum para para!",
        "⚡ Naan oru thadava sonna, nooru thadava sonna maadhiri!",
        "🚶‍♂️ Paththu rooba tea-um, Mass-ana walk-um!"
    ]

    private let clickPunchlines = [
        "🔥 Singam single-aa dhaan varum!",
        "🕶️ Mass entry! Code review passed!",
        "🥁 Thalaivar vandhutaaaru-nu sollu!",
        "💥 Idhu namma aatam!"
    ]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupVideoIfAvailable()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupVideoIfAvailable()
    }

    private func setupVideoIfAvailable() {
        // Look for transparent video "walking_hero.mov" or "walking_hero.mp4"
        var videoURL: URL?
        if let bundleURL = Bundle.main.url(forResource: "walking_hero", withExtension: "mov") {
            videoURL = bundleURL
        } else if let bundleURL = Bundle.main.url(forResource: "walking_hero", withExtension: "mp4") {
            videoURL = bundleURL
        } else {
            let relativePath = "Resources/walking_hero.mov"
            if FileManager.default.fileExists(atPath: relativePath) {
                videoURL = URL(fileURLWithPath: relativePath)
            }
        }

        guard let url = videoURL else { return }

        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        self.playerLooper = looper

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.frame = bounds
        layer.videoGravity = .resizeAspect
        self.layer?.addSublayer(layer)
        self.playerLayer = layer
        queuePlayer.play()
    }

    func advanceWalkCycle() {
        walkCycle += 0.22
        if walkCycle > .pi * 2 {
            walkCycle -= .pi * 2
        }
        needsDisplay = true
    }

    func setMouseProximity(distance: CGFloat) {
        if distance < 75 {
            if !isPaused {
                isPaused = true
                if !hasSaidNearSpeech {
                    hasSaidNearSpeech = true
                    showSpeech(punchlines.randomElement() ?? punchlines[0], duration: 4.0)
                    NSSound(named: "Pop")?.play()
                }
            }
        } else if distance > 90 {
            if isPaused {
                isPaused = false
                hasSaidNearSpeech = false
            }
        }
    }

    func triggerClickReaction() {
        showSpeech(clickPunchlines.randomElement() ?? clickPunchlines[0], duration: 4.5)
        NSSound(named: "Ping")?.play()
        // Little hop
        walkCycle += .pi * 0.5
        needsDisplay = true
    }

    private func showSpeech(_ text: String, duration: TimeInterval) {
        speechText = text
        speechTimer?.invalidate()
        speechTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.speechText = nil
            self?.needsDisplay = true
        }
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        onWindowClick?()
    }

    // MARK: - Procedural Mass Hero Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // If video player layer exists, let it render the character
        if playerLayer == nil {
            drawProceduralHero(ctx: ctx)
        }

        // Draw Comic Speech Bubble above the character
        if let text = speechText {
            drawSpeechBubble(ctx: ctx, text: text)
        }
    }

    private func drawProceduralHero(ctx: CGContext) {
        ctx.saveGState()

        let baseOrigin = CGPoint(x: bounds.midX, y: 30)

        // Flip horizontally if walking left
        if !isFacingRight {
            ctx.translateBy(x: bounds.width, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }

        let legSwing = isPaused ? 0 : sin(walkCycle) * 24.0
        let bobbing = isPaused ? 0 : abs(sin(walkCycle)) * 4.0
        let heroY = baseOrigin.y + bobbing

        // 1. Dust Puffs behind walking feet
        if !isPaused {
            ctx.setFillColor(NSColor(calibratedWhite: 0.9, alpha: 0.25).cgColor)
            let dustX = baseOrigin.x - 22
            ctx.fillEllipse(in: CGRect(x: dustX, y: baseOrigin.y - 2, width: 12, height: 8))
            ctx.fillEllipse(in: CGRect(x: dustX - 8, y: baseOrigin.y + 2, width: 8, height: 6))
        }

        // 2. Legs & Black Shoes
        ctx.saveGState()
        // Left Leg (Back)
        ctx.setStrokeColor(NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).cgColor)
        ctx.setLineWidth(7.0)
        ctx.setLineCap(.round)

        ctx.move(to: CGPoint(x: baseOrigin.x - 4, y: heroY + 28))
        let backFootX = baseOrigin.x - 4 - legSwing * 0.7
        let backFootY = baseOrigin.y + max(0, -legSwing * 0.3)
        ctx.addLine(to: CGPoint(x: backFootX, y: backFootY + 6))
        ctx.strokePath()

        // Back Shoe
        ctx.setFillColor(NSColor(calibratedWhite: 0.05, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: backFootX - 4, y: backFootY, width: 16, height: 8))

        // Right Leg (Front)
        ctx.move(to: CGPoint(x: baseOrigin.x + 6, y: heroY + 28))
        let frontFootX = baseOrigin.x + 6 + legSwing * 0.7
        let frontFootY = baseOrigin.y + max(0, legSwing * 0.3)
        ctx.addLine(to: CGPoint(x: frontFootX, y: frontFootY + 6))
        ctx.strokePath()

        // Front Shoe
        ctx.fillEllipse(in: CGRect(x: frontFootX - 4, y: frontFootY, width: 16, height: 8))
        ctx.restoreGState()

        // 3. Torso & Rolled-Sleeve Shirt (Black/Charcoal with Gold Chain)
        ctx.saveGState()
        let torsoRect = CGRect(x: baseOrigin.x - 14, y: heroY + 26, width: 28, height: 36)
        let torsoPath = NSBezierPath(roundedRect: torsoRect, xRadius: 6, yRadius: 6)
        NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.18, alpha: 1.0).setFill()
        torsoPath.fill()

        // Red Pocket Square / Scarf accent
        ctx.setFillColor(NSColor(calibratedRed: 0.9, green: 0.2, blue: 0.2, alpha: 0.9).cgColor)
        ctx.fill(CGRect(x: baseOrigin.x + 4, y: heroY + 48, width: 6, height: 5))

        // Gold Chain
        ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.2, alpha: 1.0).cgColor)
        ctx.setLineWidth(2.0)
        ctx.move(to: CGPoint(x: baseOrigin.x - 5, y: heroY + 58))
        ctx.addLine(to: CGPoint(x: baseOrigin.x, y: heroY + 52))
        ctx.addLine(to: CGPoint(x: baseOrigin.x + 5, y: heroY + 58))
        ctx.strokePath()
        ctx.restoreGState()

        // 4. Arms: Right Arm holding Glass Bottle 🍾 / 🥃
        ctx.saveGState()
        ctx.setStrokeColor(NSColor(calibratedRed: 0.82, green: 0.65, blue: 0.52, alpha: 1.0).cgColor) // Skin tone
        ctx.setLineWidth(5.5)
        ctx.setLineCap(.round)

        // Right Arm (Forward holding bottle)
        let bottleHand = CGPoint(x: baseOrigin.x + 18, y: heroY + 46)
        ctx.move(to: CGPoint(x: baseOrigin.x + 8, y: heroY + 56))
        ctx.addLine(to: CGPoint(x: baseOrigin.x + 14, y: heroY + 48))
        ctx.addLine(to: CGPoint(x: bottleHand.x, y: bottleHand.y))
        ctx.strokePath()

        // Draw Bottle in Hand
        let bottleRect = CGRect(x: bottleHand.x - 3, y: bottleHand.y - 4, width: 9, height: 20)
        ctx.setFillColor(NSColor(calibratedRed: 0.1, green: 0.55, blue: 0.25, alpha: 0.85).cgColor) // Green bottle
        ctx.fill(CGRect(x: bottleRect.minX + 2, y: bottleRect.maxY, width: 5, height: 7)) // Neck
        ctx.fill(bottleRect) // Body
        // Amber drink fill inside
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.1, alpha: 0.9).cgColor)
        ctx.fill(CGRect(x: bottleRect.minX + 1, y: bottleRect.minY + 2, width: 7, height: 11))

        // Left Arm (Swinging back)
        let backArmSwing = isPaused ? 0 : -sin(walkCycle) * 16.0
        ctx.move(to: CGPoint(x: baseOrigin.x - 8, y: heroY + 56))
        ctx.addLine(to: CGPoint(x: baseOrigin.x - 14 - backArmSwing * 0.5, y: heroY + 40 + backArmSwing * 0.3))
        ctx.strokePath()
        ctx.restoreGState()

        // 5. Head, Styled Hair & Sunglasses (Cooling Glass 🕶️)
        ctx.saveGState()
        let headCenter = CGPoint(x: baseOrigin.x, y: heroY + 74)

        // Neck
        ctx.setFillColor(NSColor(calibratedRed: 0.82, green: 0.65, blue: 0.52, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: headCenter.x - 4, y: heroY + 58, width: 8, height: 10))

        // Face
        ctx.fillEllipse(in: CGRect(x: headCenter.x - 11, y: headCenter.y - 10, width: 22, height: 23))

        // Dark Mass Pompadour Hair
        ctx.setFillColor(NSColor(calibratedWhite: 0.08, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: headCenter.x - 13, y: headCenter.y + 1, width: 26, height: 16))
        ctx.fillEllipse(in: CGRect(x: headCenter.x - 8, y: headCenter.y + 6, width: 18, height: 12))

        // Beard / Stubble trim
        ctx.setFillColor(NSColor(calibratedWhite: 0.18, alpha: 0.6).cgColor)
        ctx.fillEllipse(in: CGRect(x: headCenter.x - 8, y: headCenter.y - 9, width: 16, height: 8))

        // Iconic Sunglasses (Cooling Glass) 🕶️
        let glassY = headCenter.y - 1
        ctx.setFillColor(NSColor(calibratedWhite: 0.05, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: headCenter.x - 10, y: glassY, width: 9, height: 7))
        ctx.fill(CGRect(x: headCenter.x + 1, y: glassY, width: 9, height: 7))
        // Bridge
        ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor) // Gold rim
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: headCenter.x - 1, y: glassY + 4))
        ctx.addLine(to: CGPoint(x: headCenter.x + 1, y: glassY + 4))
        ctx.strokePath()

        // White Glint reflection on glasses
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: headCenter.x - 8, y: glassY + 5))
        ctx.addLine(to: CGPoint(x: headCenter.x - 4, y: glassY + 2))
        ctx.move(to: CGPoint(x: headCenter.x + 3, y: glassY + 5))
        ctx.addLine(to: CGPoint(x: headCenter.x + 7, y: glassY + 2))
        ctx.strokePath()

        ctx.restoreGState()

        ctx.restoreGState()
    }

    private func drawSpeechBubble(ctx: CGContext, text: String) {
        ctx.saveGState()

        let bubbleMaxWidth: CGFloat = 190.0
        let font = NSFont.boldSystemFont(ofSize: 11)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.15, alpha: 1.0),
            .paragraphStyle: paragraph
        ]

        let textRect = (text as NSString).boundingRect(
            with: NSSize(width: bubbleMaxWidth - 16, height: 60),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs
        )

        let bubbleWidth = max(textRect.width + 20, 110)
        let bubbleHeight = textRect.height + 14
        let bubbleX = bounds.midX - bubbleWidth / 2
        let bubbleY = bounds.height - bubbleHeight - 12

        let bubbleRect = CGRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight)

        // Outer Glow & Bubble Background
        ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 6, color: NSColor.black.withAlphaComponent(0.35).cgColor)

        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 10, yRadius: 10)
        NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.88, alpha: 0.96).setFill()
        path.fill()

        // Pointer triangle pointing to hero head
        let pointer = NSBezierPath()
        pointer.move(to: NSPoint(x: bounds.midX - 6, y: bubbleRect.minY))
        pointer.line(to: NSPoint(x: bounds.midX, y: bubbleRect.minY - 7))
        pointer.line(to: NSPoint(x: bounds.midX + 6, y: bubbleRect.minY))
        pointer.close()
        NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.88, alpha: 0.96).setFill()
        pointer.fill()

        // Border
        NSColor(calibratedRed: 0.85, green: 0.75, blue: 0.4, alpha: 0.9).setStroke()
        path.lineWidth = 1.2
        path.stroke()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Text
        let drawTextRect = CGRect(
            x: bubbleRect.minX + 8,
            y: bubbleRect.minY + (bubbleRect.height - textRect.height) / 2,
            width: bubbleRect.width - 16,
            height: textRect.height
        )
        (text as NSString).draw(in: drawTextRect, withAttributes: attrs)

        ctx.restoreGState()
    }
}

// MARK: - Ledge Finder
// Discovers top title bar edge of frontmost normal application window or falls back to Dock/screen floor.

enum LedgeFinder {

    struct Ledge {
        let y: CGFloat
        let minX: CGFloat
        let maxX: CGFloat
    }

    static func findBestLedge(excludingPID: pid_t) -> Ledge? {
        guard let screen = NSScreen.main else { return nil }

        let windowInfoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        guard let windows = windowInfoList else { return nil }

        for win in windows {
            guard let layer = win[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let ownerPID = win[kCGWindowOwnerPID as String] as? pid_t, ownerPID != excludingPID else { continue }
            guard let boundsDict = win[kCGWindowBounds as String] as? NSDictionary,
                  let cgBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }

            // Filter out tiny popups or giant full-desktop backdrops
            if cgBounds.width < 320 || cgBounds.height < 220 { continue }
            if cgBounds.width >= screen.frame.width && cgBounds.height >= screen.frame.height { continue }

            // Convert Quartz screen coordinates (top-left is 0,0) to AppKit (bottom-left is 0,0)
            let appKitTopY = screen.frame.height - cgBounds.origin.y

            // Ensure ledge is within reasonable screen bounds
            if appKitTopY >= screen.visibleFrame.minY + 60 && appKitTopY <= screen.visibleFrame.maxY - 40 {
                let minX = max(screen.visibleFrame.minX, cgBounds.origin.x)
                let maxX = min(screen.visibleFrame.maxX, cgBounds.maxX)
                if maxX - minX > 200 {
                    return Ledge(y: appKitTopY, minX: minX, maxX: maxX)
                }
            }
        }

        return nil
    }
}
