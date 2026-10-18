import AppKit

// MARK: - Bezel & Notch Copy-Paste Meme Watcher
// Monitors clipboard velocity and triggers funny meme peeking alerts from screen edges.

final class BezelWatcherManager {

    static let shared = BezelWatcherManager()

    var isSurveillanceEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSurveillanceEnabled, forKey: "BezelSurveillanceEnabled")
        }
    }

    private var pasteboardTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var copyTimestamps: [Date] = []
    private var lastTriggerTime: Date = Date.distantPast
    private var peekerWindow: BezelPeekerWindow?

    init() {
        if UserDefaults.standard.object(forKey: "BezelSurveillanceEnabled") != nil {
            isSurveillanceEnabled = UserDefaults.standard.bool(forKey: "BezelSurveillanceEnabled")
        }
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        pasteboardTimer?.invalidate()
        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPasteboardVelocity()
        }
        RunLoop.main.add(pasteboardTimer!, forMode: .common)
    }

    func stopMonitoring() {
        pasteboardTimer?.invalidate()
        pasteboardTimer = nil
    }

    private func checkPasteboardVelocity() {
        guard isSurveillanceEnabled else { return }

        let currentCount = NSPasteboard.general.changeCount
        if currentCount != lastChangeCount {
            lastChangeCount = currentCount
            let now = Date()
            copyTimestamps.append(now)

            // Keep only timestamps within last 60 seconds
            copyTimestamps = copyTimestamps.filter { now.timeIntervalSince($0) <= 60.0 }

            // Trigger if >= 3 copy-pastes within 60s and past 25s cooldown
            if copyTimestamps.count >= 3 && now.timeIntervalSince(lastTriggerTime) > 25.0 {
                lastTriggerTime = now
                copyTimestamps.removeAll()
                triggerRandomMemeAlert(reason: .copyPasteDetected)
            }
        }
    }

    func triggerManualPeek() {
        triggerRandomMemeAlert(reason: .manualTrigger)
    }

    enum TriggerReason {
        case copyPasteDetected
        case manualTrigger
    }

    private func triggerRandomMemeAlert(reason: TriggerReason) {
        let personas = MemePersona.allCases
        let chosen = personas.randomElement() ?? .stackoverflowPolice

        DispatchQueue.main.async { [weak self] in
            self?.peekerWindow?.close()
            let window = BezelPeekerWindow(persona: chosen, reason: reason)
            self?.peekerWindow = window
            window.showPeeking()
        }
    }
}

// MARK: - Meme Personas

enum MemePersona: CaseIterable {
    case stackoverflowPolice
    case kaipullaBuildAlert
    case veeramaniDeliveryAlert

    var avatar: String {
        switch self {
        case .stackoverflowPolice: return "👮‍♂️🚨"
        case .kaipullaBuildAlert: return "😭🥋"
        case .veeramaniDeliveryAlert: return "📦🚚"
        }
    }

    var title: String {
        switch self {
        case .stackoverflowPolice: return "StackOverflow Police"
        case .kaipullaBuildAlert: return "Kaipulla Build Alert"
        case .veeramaniDeliveryAlert: return "Madurai Courier Dept"
        }
    }

    var quotes: [String] {
        switch self {
        case .stackoverflowPolice:
            return [
                "Ennada, full project-ume ChatGPT & Copy-Paste dhana? 👀",
                "Copy pannadha da! Variable name kooda maathala nee! 😂",
                "StackOverflow-ku royalty anupitiya pa? 🚨"
            ]
        case .kaipullaBuildAlert:
            return [
                "Aahaan! Code-la kai vechittiya? Ipdi panringale ma! 😭",
                "Vandhutanunga da vandhutanunga! Bug fixed-nu solli push pannitanunga!",
                "Naan appave sonnen indha logic venam-nu! 🏃‍♂️💨"
            ]
        case .veeramaniDeliveryAlert:
            return [
                "Sir, copy-paste OTP sollunga! ₹99,999 sweet parcel ready! 📦",
                "Veeramani bro address-ku delivery poga vendiyadhu inga vandhurukku! 🚚",
                "COD parcel vandhurukku... Sign pannunga boss! 😂"
            ]
        }
    }

    var subtitle: String {
        switch self {
        case .stackoverflowPolice: return "Clipboard velocity: 3+ copies in 60s!"
        case .kaipullaBuildAlert: return "Caution: Extreme testing in production"
        case .veeramaniDeliveryAlert: return "Madurai Special Diwali Express"
        }
    }
}

// MARK: - Bezel Peeker Window

final class BezelPeekerWindow: NSWindow {

    private let peekerCardView: BezelPeekerCardView
    private let targetScreen: NSScreen
    private let peekFromNotch: Bool
    private var autoDismissTimer: Timer?

    init(persona: MemePersona, reason: BezelWatcherManager.TriggerReason) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        self.targetScreen = screen
        // Alternate between Notch peek (if available) and Right Bezel peek
        self.peekFromNotch = Bool.random()

        let cardSize = NSSize(width: 320, height: 110)
        let initialRect: NSRect

        if peekFromNotch {
            // Start hidden above notch
            initialRect = NSRect(
                x: screen.frame.midX - cardSize.width / 2,
                y: screen.frame.maxY + 10,
                width: cardSize.width,
                height: cardSize.height
            )
        } else {
            // Start hidden off the right bezel
            initialRect = NSRect(
                x: screen.frame.maxX + 10,
                y: screen.frame.midY - cardSize.height / 2,
                width: cardSize.width,
                height: cardSize.height
            )
        }

        peekerCardView = BezelPeekerCardView(frame: NSRect(origin: .zero, size: cardSize), persona: persona)

        super.init(
            contentRect: initialRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        contentView = peekerCardView

        peekerCardView.onClick = { [weak self] in
            self?.retractAndClose()
        }
    }

    deinit {
        autoDismissTimer?.invalidate()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func showPeeking() {
        orderFrontRegardless()
        NSSound(named: "Tink")?.play()

        let finalRect: NSRect
        if peekFromNotch {
            finalRect = NSRect(
                x: frame.origin.x,
                y: targetScreen.frame.maxY - frame.height - 18,
                width: frame.width,
                height: frame.height
            )
        } else {
            finalRect = NSRect(
                x: targetScreen.frame.maxX - frame.width - 20,
                y: frame.origin.y,
                width: frame.width,
                height: frame.height
            )
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.42
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(finalRect, display: true)
        }

        autoDismissTimer?.invalidate()
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.retractAndClose()
        }
    }

    func retractAndClose() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil

        let offscreenRect: NSRect
        if peekFromNotch {
            offscreenRect = NSRect(
                x: frame.origin.x,
                y: targetScreen.frame.maxY + 15,
                width: frame.width,
                height: frame.height
            )
        } else {
            offscreenRect = NSRect(
                x: targetScreen.frame.maxX + 15,
                y: frame.origin.y,
                width: frame.width,
                height: frame.height
            )
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().setFrame(offscreenRect, display: true)
            animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }
}

// MARK: - Bezel Peeker Card View (Frosted Glass HUD)

final class BezelPeekerCardView: NSView {

    var onClick: (() -> Void)?
    private let persona: MemePersona
    private let quoteText: String

    init(frame frameRect: NSRect, persona: MemePersona) {
        self.persona = persona
        self.quoteText = persona.quotes.randomElement() ?? persona.quotes[0]
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.saveGState()

        let cardRect = bounds.insetBy(dx: 4, dy: 4)
        let path = NSBezierPath(roundedRect: cardRect, xRadius: 16, yRadius: 16)

        // Glassmorphism dark gradient background
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.18, alpha: 0.94).cgColor,
            NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.11, alpha: 0.96).cgColor
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.saveGState()
            path.addClip()
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: cardRect.maxY), end: CGPoint(x: 0, y: cardRect.minY), options: [])
            ctx.restoreGState()
        }

        // Neon Border Accent
        let strokeColor: NSColor
        switch persona {
        case .stackoverflowPolice:
            strokeColor = NSColor(calibratedRed: 0.3, green: 0.6, blue: 1.0, alpha: 0.8)
        case .kaipullaBuildAlert:
            strokeColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.2, alpha: 0.8)
        case .veeramaniDeliveryAlert:
            strokeColor = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.1, alpha: 0.8)
        }
        strokeColor.setStroke()
        path.lineWidth = 1.6
        path.stroke()

        // Avatar Emoji Badge
        let avatarRect = CGRect(x: cardRect.minX + 12, y: cardRect.midY - 24, width: 48, height: 48)
        let avatarFont = NSFont.systemFont(ofSize: 28)
        let avatarAttrs: [NSAttributedString.Key: Any] = [.font: avatarFont]
        (persona.avatar as NSString).draw(
            in: CGRect(x: avatarRect.minX, y: avatarRect.minY + 4, width: 48, height: 40),
            withAttributes: avatarAttrs
        )

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: strokeColor
        ]
        (persona.title as NSString).draw(
            at: CGPoint(x: cardRect.minX + 66, y: cardRect.maxY - 28),
            withAttributes: titleAttrs
        )

        // Subtitle badge
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 0.9)
        ]
        (persona.subtitle as NSString).draw(
            at: CGPoint(x: cardRect.minX + 66, y: cardRect.maxY - 42),
            withAttributes: subAttrs
        )

        // Speech Quote
        let quoteFont = NSFont.boldSystemFont(ofSize: 11)
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: NSColor(calibratedWhite: 0.98, alpha: 1.0)
        ]
        let quoteRect = CGRect(x: cardRect.minX + 66, y: cardRect.minY + 10, width: cardRect.width - 76, height: 38)
        (quoteText as NSString).draw(
            in: quoteRect,
            withAttributes: quoteAttrs
        )

        ctx.restoreGState()
    }
}
