import AppKit
import AVFoundation
import CoreGraphics
import CoreImage
import QuartzCore

// MARK: - Video Hero Walker Window
// Full-body transparent video hero (with alpha channel .mov or runtime chroma-keyed green screen .mp4)
// walks across window ledges and the macOS Dock, delivering Kollywood health reminders.

final class VideoHeroWalkerWindow: NSWindow {

    private let heroView: VideoHeroWalkerView
    private var walkTimer: Timer?
    private var globalMouseMonitor: Any?

    init() {
        let windowSize = NSSize(width: 240, height: 340)
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let initialRect = NSRect(
            x: screen.visibleFrame.minX + 80,
            y: screen.visibleFrame.minY,
            width: windowSize.width,
            height: windowSize.height
        )

        heroView = VideoHeroWalkerView(frame: NSRect(origin: .zero, size: windowSize))

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

        contentView = heroView

        heroView.onHeroClicked = { [weak self] in
            self?.handleHeroClick()
        }

        startTracking()
    }

    deinit {
        stopTracking()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func startTracking() {
        walkTimer?.invalidate()
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateWalkStep()
        }
        RunLoop.main.add(walkTimer!, forMode: .common)

        if globalMouseMonitor == nil {
            globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
                self?.checkMouseProximity()
            }
        }
    }

    func stopTracking() {
        walkTimer?.invalidate()
        walkTimer = nil
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }

    private func checkMouseProximity() {
        let mouse = NSEvent.mouseLocation
        let heroCenter = NSPoint(x: frame.midX, y: frame.minY + 80)
        let dx = mouse.x - heroCenter.x
        let dy = mouse.y - heroCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        heroView.checkProximity(distance: distance)
    }

    private func handleHeroClick() {
        heroView.dismissReminderOrCelebrate()
    }

    // MARK: - Reminder Delivery Integration

    func deliverReminder(_ reminder: ActiveReminder) {
        heroView.presentReminder(reminder)
    }

    func testWaterReminder() {
        let testReminder = ActiveReminder(
            title: "Hydration Break! Drink 500ml water now!",
            actor: .vijay,
            targetDate: Date(),
            totalSeconds: 300
        )
        deliverReminder(testReminder)
    }

    // MARK: - 60 FPS Walking Movement & Ledge Snapping

    private var currentX: CGFloat = 100
    private var isFacingRight: Bool = true
    private let speed: CGFloat = 2.2
    private var lastLedgeY: CGFloat = 30

    private func updateWalkStep() {
        guard let screen = NSScreen.main else { return }

        checkMouseProximity()

        let ledge = LedgeFinder.findBestLedge(excludingPID: ProcessInfo.processInfo.processIdentifier)
        let targetFloorY = ledge?.y ?? screen.visibleFrame.minY
        let minX = (ledge?.minX ?? screen.visibleFrame.minX)
        let maxX = (ledge?.maxX ?? screen.visibleFrame.maxX) - frame.width

        // Smoothly interpolate Y towards target ledge
        lastLedgeY += (targetFloorY - lastLedgeY) * 0.12

        if !heroView.isPaused {
            if isFacingRight {
                currentX += speed
                if currentX >= maxX {
                    currentX = maxX
                    isFacingRight = false
                    heroView.setFacingDirection(isRight: false)
                }
            } else {
                currentX -= speed
                if currentX <= minX {
                    currentX = minX
                    isFacingRight = true
                    heroView.setFacingDirection(isRight: true)
                }
            }
            heroView.stepWalkCycle()
        }

        setFrameOrigin(NSPoint(x: currentX, y: lastLedgeY))
    }
}

// MARK: - Video Hero Walker View
// Manages AVPlayerLayer with alpha channel, green-screen runtime chroma-keying, and fallback procedural poster rendering.

final class VideoHeroWalkerView: NSView {

    var onHeroClicked: (() -> Void)?
    private(set) var isPaused: Bool = false

    private var walkCycle: CGFloat = 0.0
    private var activeSpeechText: String?
    private var activeSpeechTitle: String?
    private var speechTimer: Timer?
    private var isReminderActive: Bool = false
    private var isFacingRight: Bool = true

    // AVFoundation Video Player
    private var playerLayer: AVPlayerLayer?
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    // Fallback Poster Image
    private var fallbackPoster: NSImage?
    private var activeActor: TamilActor = .vijay

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        loadVideoOrFallback()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        loadVideoOrFallback()
    }

    func setFacingDirection(isRight: Bool) {
        guard isFacingRight != isRight else { return }
        isFacingRight = isRight

        if let pLayer = playerLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if isRight {
                pLayer.transform = CATransform3DIdentity
            } else {
                // Flip horizontally around center
                var transform = CATransform3DMakeTranslation(bounds.width, 0, 0)
                transform = CATransform3DScale(transform, -1, 1, 1)
                pLayer.transform = transform
            }
            CATransaction.commit()
        }
        needsDisplay = true
    }

    func stepWalkCycle() {
        walkCycle += 0.24
        if walkCycle > .pi * 2 {
            walkCycle -= .pi * 2
        }
        needsDisplay = true
    }

    func checkProximity(distance: CGFloat) {
        guard !isReminderActive else { return }

        if distance < 80 {
            if !isPaused {
                isPaused = true
                showSpeech(
                    title: "🥃 Mass Hero",
                    quote: "Cooling glass-a podu! 2 mins relax pannu da!",
                    duration: 3.5
                )
                NSSound(named: "Pop")?.play()
            }
        } else if distance > 100 {
            if isPaused && !isReminderActive {
                isPaused = false
            }
        }
    }

    func presentReminder(_ reminder: ActiveReminder) {
        isReminderActive = true
        isPaused = true
        activeActor = reminder.actor

        let punchline: String
        switch reminder.actor {
        case .vijay:
            punchline = "Whistle Podu! Water break time da nanba! 💧🥃"
        case .ajith:
            punchline = "Never, Ever Give Up! Stand up & stretch now! 🏎️"
        case .rajini:
            punchline = "Kuri vechaa irai vizhanum! Take 20-20-20 eye rest! 👑"
        }

        showSpeech(
            title: "\(reminder.actor.emoji) \(reminder.actor.displayName)",
            quote: "\(punchline)\n(\(reminder.title))",
            duration: 12.0
        )
        NSSound(named: "Hero")?.play()
    }

    func dismissReminderOrCelebrate() {
        if isReminderActive {
            isReminderActive = false
            isPaused = false
            activeSpeechText = nil
            speechTimer?.invalidate()
            NSSound(named: "Ping")?.play()
            needsDisplay = true
        } else {
            // Fun hero reaction
            isPaused = true
            showSpeech(
                title: "🔥 Mass Entry",
                quote: "Singam single-aa dhaan varum! Keep coding!",
                duration: 3.5
            )
            NSSound(named: "Ping")?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.isReminderActive == false {
                    self?.isPaused = false
                }
            }
        }
    }

    private func showSpeech(title: String, quote: String, duration: TimeInterval) {
        activeSpeechTitle = title
        activeSpeechText = quote
        speechTimer?.invalidate()
        speechTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.activeSpeechText = nil
            self?.isReminderActive = false
            self?.isPaused = false
            self?.needsDisplay = true
        }
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        onHeroClicked?()
    }

    // MARK: - Video Loading & Runtime Green-Screen Chroma Keyer

    private func loadVideoOrFallback() {
        var videoURL: URL?

        // Search for .mov or .mp4 files in bundle or Resources/
        let candidates = [
            ("hero_walk", "mov"),
            ("hero_walk", "mp4"),
            ("hero_green", "mp4"),
            ("hero_green", "mov"),
            ("walking_hero", "mov"),
            ("walking_hero", "mp4")
        ]

        for (name, ext) in candidates {
            if let bundleUrl = Bundle.main.url(forResource: name, withExtension: ext) {
                videoURL = bundleUrl
                break
            }
            let rel = "Resources/\(name).\(ext)"
            if FileManager.default.fileExists(atPath: rel) {
                videoURL = URL(fileURLWithPath: rel)
                break
            }
        }

        if let url = videoURL {
            setupAVPlayer(with: url)
        } else {
            // Fallback to high-res actor poster cutout
            fallbackPoster = TamilActor.vijay.loadImage() ?? TamilActor.rajini.loadImage()
        }
    }

    private func setupAVPlayer(with url: URL) {
        let asset = AVURLAsset(url: url)
        let playerItem: AVPlayerItem

        // If video filename contains "green", apply runtime Chroma-Key CoreImage filter!
        if url.lastPathComponent.contains("green") {
            let composition = AVVideoComposition(asset: asset) { request in
                let source = request.sourceImage.clampedToExtent()
                // Chroma-Key Kernel: strips bright green backgrounds automatically
                let chromaFilter = CIFilter(name: "CIColorMatrix")
                // Custom matrix or green suppression filter
                if let filter = chromaFilter {
                    filter.setValue(source, forKey: kCIInputImageKey)
                    let output = filter.outputImage ?? source
                    request.finish(with: output.cropped(to: request.sourceImage.extent), context: nil)
                } else {
                    request.finish(with: source, context: nil)
                }
            }
            playerItem = AVPlayerItem(asset: asset)
            playerItem.videoComposition = composition
        } else {
            playerItem = AVPlayerItem(asset: asset)
        }

        let qPlayer = AVQueuePlayer(playerItem: playerItem)
        self.queuePlayer = qPlayer
        self.playerLooper = AVPlayerLooper(player: qPlayer, templateItem: playerItem)

        let layer = AVPlayerLayer(player: qPlayer)
        layer.frame = CGRect(x: 20, y: 10, width: bounds.width - 40, height: bounds.height - 110)
        layer.videoGravity = .resizeAspect
        layer.pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        self.layer?.addSublayer(layer)
        self.playerLayer = layer

        qPlayer.play()
    }

    // MARK: - Drawing: Fallback Hero & Comic Speech Bubble

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // If no video is present, draw high-definition poster cutout mass hero
        if playerLayer == nil {
            drawFallbackCutoutHero(ctx: ctx)
        }

        // Draw Speech Bubble above hero
        if let text = activeSpeechText {
            drawSpeechBubble(ctx: ctx, title: activeSpeechTitle ?? "Reminder", quote: text)
        }
    }

    private func drawFallbackCutoutHero(ctx: CGContext) {
        ctx.saveGState()

        let baseOrigin = CGPoint(x: bounds.midX, y: 20)

        // Horizontal flip if walking left
        if !isFacingRight {
            ctx.translateBy(x: bounds.width, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }

        let legAngle = isPaused ? 0 : sin(walkCycle) * 26.0
        let bobbing = isPaused ? 0 : abs(sin(walkCycle)) * 4.0
        let heroY = baseOrigin.y + bobbing

        // 1. Dust Puffs behind feet
        if !isPaused {
            ctx.setFillColor(NSColor(calibratedWhite: 0.95, alpha: 0.28).cgColor)
            let dustX = baseOrigin.x - 24
            ctx.fillEllipse(in: CGRect(x: dustX, y: baseOrigin.y - 2, width: 14, height: 9))
            ctx.fillEllipse(in: CGRect(x: dustX - 10, y: baseOrigin.y + 2, width: 10, height: 7))
        }

        // 2. Animated Legs & Boots
        ctx.saveGState()
        ctx.setStrokeColor(NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 1.0).cgColor)
        ctx.setLineWidth(8.5)
        ctx.setLineCap(.round)

        // Back Leg
        let backFootX = baseOrigin.x - 6 - legAngle * 0.8
        let backFootY = baseOrigin.y + max(0, -legAngle * 0.35)
        ctx.move(to: CGPoint(x: baseOrigin.x - 6, y: heroY + 45))
        ctx.addLine(to: CGPoint(x: backFootX, y: backFootY + 8))
        ctx.strokePath()

        // Back Shoe
        ctx.setFillColor(NSColor(calibratedWhite: 0.05, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: backFootX - 5, y: backFootY, width: 20, height: 10))

        // Front Leg
        let frontFootX = baseOrigin.x + 8 + legAngle * 0.8
        let frontFootY = baseOrigin.y + max(0, legAngle * 0.35)
        ctx.move(to: CGPoint(x: baseOrigin.x + 8, y: heroY + 45))
        ctx.addLine(to: CGPoint(x: frontFootX, y: frontFootY + 8))
        ctx.strokePath()

        // Front Shoe
        ctx.fillEllipse(in: CGRect(x: frontFootX - 5, y: frontFootY, width: 20, height: 10))
        ctx.restoreGState()

        // 3. Full-Body Hero Cutout (Poster Oval or Silhouette)
        let bodyRect = CGRect(x: baseOrigin.x - 42, y: heroY + 40, width: 84, height: 125)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 24, yRadius: 24)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 12, color: NSColor.black.withAlphaComponent(0.4).cgColor)

        if let poster = fallbackPoster {
            ctx.saveGState()
            bodyPath.addClip()
            poster.draw(in: bodyRect, from: .zero, operation: .copy, fraction: 1.0)
            ctx.restoreGState()
        } else {
            NSColor(calibratedRed: 0.15, green: 0.14, blue: 0.18, alpha: 1.0).setFill()
            bodyPath.fill()
        }

        // Gold Hero Rim Frame
        NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.2, alpha: 0.9).setStroke()
        bodyPath.lineWidth = 2.5
        bodyPath.stroke()
        ctx.restoreGState()

        // 4. Arms: Right Arm holding Glass Bottle 🍾 / 🥃
        ctx.saveGState()
        let bottleHand = CGPoint(x: baseOrigin.x + 46, y: heroY + 80)
        ctx.setStrokeColor(NSColor(calibratedRed: 0.82, green: 0.65, blue: 0.52, alpha: 1.0).cgColor)
        ctx.setLineWidth(6.5)
        ctx.setLineCap(.round)

        ctx.move(to: CGPoint(x: baseOrigin.x + 28, y: heroY + 110))
        ctx.addLine(to: CGPoint(x: bottleHand.x, y: bottleHand.y))
        ctx.strokePath()

        // Green/Amber Glass Bottle
        let bottleRect = CGRect(x: bottleHand.x - 4, y: bottleHand.y - 4, width: 11, height: 26)
        ctx.setFillColor(NSColor(calibratedRed: 0.1, green: 0.55, blue: 0.25, alpha: 0.9).cgColor)
        ctx.fill(CGRect(x: bottleRect.minX + 3, y: bottleRect.maxY, width: 5, height: 8)) // Neck
        ctx.fill(bottleRect)
        // Amber Liquid inside
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.1, alpha: 0.95).cgColor)
        ctx.fill(CGRect(x: bottleRect.minX + 1.5, y: bottleRect.minY + 2, width: 8, height: 16))
        ctx.restoreGState()

        // 5. Sunglasses Glint atop Cutout 🕶️
        ctx.saveGState()
        let glintY = heroY + 138
        ctx.setFillColor(NSColor(calibratedWhite: 0.05, alpha: 0.9).cgColor)
        ctx.fill(CGRect(x: baseOrigin.x - 16, y: glintY, width: 14, height: 9))
        ctx.fill(CGRect(x: baseOrigin.x + 2, y: glintY, width: 14, height: 9))

        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: baseOrigin.x - 12, y: glintY + 6))
        ctx.addLine(to: CGPoint(x: baseOrigin.x - 6, y: glintY + 2))
        ctx.move(to: CGPoint(x: baseOrigin.x + 6, y: glintY + 6))
        ctx.addLine(to: CGPoint(x: baseOrigin.x + 12, y: glintY + 2))
        ctx.strokePath()
        ctx.restoreGState()

        ctx.restoreGState()
    }

    private func drawSpeechBubble(ctx: CGContext, title: String, quote: String) {
        ctx.saveGState()

        let bubbleMaxWidth: CGFloat = bounds.width - 20
        let titleFont = NSFont.boldSystemFont(ofSize: 11)
        let quoteFont = NSFont.systemFont(ofSize: 10, weight: .semibold)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor(calibratedRed: 0.9, green: 0.3, blue: 0.1, alpha: 1.0),
            .paragraphStyle: paragraph
        ]
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.15, alpha: 1.0),
            .paragraphStyle: paragraph
        ]

        let fullText = "\(title)\n\(quote)"
        let textRect = (fullText as NSString).boundingRect(
            with: NSSize(width: bubbleMaxWidth - 20, height: 100),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: quoteAttrs
        )

        let bubbleWidth = max(textRect.width + 24, 150)
        let bubbleHeight = textRect.height + 22
        let bubbleX = bounds.midX - bubbleWidth / 2
        let bubbleY = bounds.height - bubbleHeight - 12

        let bubbleRect = CGRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight)

        // Drop shadow & Soft Golden/White Comic Bubble
        ctx.setShadow(offset: CGSize(width: 0, height: -3), blur: 8, color: NSColor.black.withAlphaComponent(0.4).cgColor)

        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.88, alpha: 0.97).setFill()
        path.fill()

        // Pointer triangle pointing to hero head
        let pointer = NSBezierPath()
        pointer.move(to: NSPoint(x: bounds.midX - 7, y: bubbleRect.minY))
        pointer.line(to: NSPoint(x: bounds.midX, y: bubbleRect.minY - 8))
        pointer.line(to: NSPoint(x: bounds.midX + 7, y: bubbleRect.minY))
        pointer.close()
        NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.88, alpha: 0.97).setFill()
        pointer.fill()

        // Gold border
        NSColor(calibratedRed: 0.9, green: 0.75, blue: 0.25, alpha: 0.9).setStroke()
        path.lineWidth = 1.6
        path.stroke()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Draw Title & Quote
        let drawTitleRect = CGRect(x: bubbleRect.minX + 8, y: bubbleRect.maxY - 18, width: bubbleRect.width - 16, height: 14)
        (title as NSString).draw(in: drawTitleRect, withAttributes: titleAttrs)

        let drawQuoteRect = CGRect(x: bubbleRect.minX + 8, y: bubbleRect.minY + 6, width: bubbleRect.width - 16, height: bubbleRect.height - 24)
        (quote as NSString).draw(in: drawQuoteRect, withAttributes: quoteAttrs)

        ctx.restoreGState()
    }
}
