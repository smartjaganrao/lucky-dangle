import AppKit

/// Draws a charm dangling from a string and simulates a lightly damped
/// pendulum. Dragging near the charm "flicks" it; dragging near the anchor
/// (top of the string) re-hangs the whole window elsewhere along the top
/// edge of the screen.
final class CharmView: NSView {

    private var emoji: String = "🍀"
    private let stringLength: CGFloat = 280
    private let anchor: NSPoint

    private var angle: CGFloat = 0.05
    private var angularVelocity: CGFloat = 0
    private let gravity: CGFloat = 9.0
    private let damping: CGFloat = 0.985

    private var timer: Timer?

    private var isDraggingAnchor = false
    private var isDraggingCharm = false
    private var lastDragLocation: NSPoint = .zero
    private var lastDragTime: TimeInterval = 0
    private var dragAngularVelocitySample: CGFloat = 0

    private var flashOpacity: CGFloat = 0

    // Ayudha Pooja Theme Engine
    private let ayudhaEffect = AyudhaPoojaEffect()
    var isAyudhaPoojaActive: Bool {
        get { ayudhaEffect.isEnabled }
        set {
            ayudhaEffect.setEnabled(newValue)
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        anchor = NSPoint(x: frameRect.width / 2, y: frameRect.height - 24)
        super.init(frame: frameRect)
        wantsLayer = true
        startPhysicsLoop()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    // Active Tamil Actor for Real Picture Body
    private var activeActor: TamilActor?
    private var cachedActorImages: [TamilActor: NSImage] = [:]

    func setActorCharm(_ actor: TamilActor) {
        activeActor = actor
        emoji = "actor:\(actor.rawValue)"
        needsDisplay = true
    }

    func setCharm(_ newEmoji: String) {
        if newEmoji.hasPrefix("actor:") {
            let key = String(newEmoji.dropFirst(6))
            if let actor = TamilActor(rawValue: key) {
                setActorCharm(actor)
                return
            }
        }
        activeActor = nil
        emoji = newEmoji
        needsDisplay = true
    }

    func currentEmoji() -> String {
        return emoji
    }

    /// A celebratory kick + glow, used for the built-in "ritual"
    /// (⌃S, or the luckydangle://bless URL). If Ayudha Pooja theme
    /// is active, triggers Pushpanjali petal shower, Aarti aura and temple chime.
    func performRitual() {
        angularVelocity += 0.55 * (Bool.random() ? 1 : -1)
        flashOpacity = 1.0

        if isAyudhaPoojaActive {
            if emoji == "meme:veeramani" || emoji.contains("veeramani") {
                ayudhaEffect.triggerRitual(
                    at: bobPosition(),
                    customBanner: (
                        title: "📦 COD ₹99,999 • Veeramani Madurai 🚚💨",
                        subtitle: "Sir, OTP sollunga! Sweet box parcel vandhurukku!"
                    )
                )
            } else if emoji == "meme:gpmuthu" || emoji.contains("gpmuthu") {
                ayudhaEffect.triggerRitual(
                    at: bobPosition(),
                    customBanner: (
                        title: "✉️ GP Muthu Kadhudhasu Letter",
                        subtitle: "Seththapayale Narapayale! Ozhunga Padida!"
                    )
                )
            } else if emoji == "meme:nesamani" || emoji.contains("nesamani") {
                ayudhaEffect.triggerRitual(
                    at: bobPosition(),
                    customBanner: (
                        title: "🔨 #PrayForNesamani Suthiyal",
                        subtitle: "Aahaa... Suthiyal mandaila vizhundhuruchu!"
                    )
                )
            } else {
                ayudhaEffect.triggerRitual(at: bobPosition())
            }
        }
    }

    // MARK: - Physics

    private func startPhysicsLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.stepPhysics()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stepPhysics() {
        let dt: CGFloat = 1.0 / 60.0
        if !isDraggingCharm {
            let restoring = -gravity / stringLength * sin(angle)
            angularVelocity += restoring * dt * 30
            angularVelocity *= damping
            angle += angularVelocity * dt
        }
        if flashOpacity > 0 {
            flashOpacity = max(0, flashOpacity - dt)
        }

        if isAyudhaPoojaActive {
            ayudhaEffect.step(dt: dt, bobPosition: bobPosition())
        }

        needsDisplay = true
    }

    private func bobPosition() -> NSPoint {
        NSPoint(
            x: anchor.x + stringLength * sin(angle),
            y: anchor.y - stringLength * cos(angle)
        )
    }

    /// True while the user is actively dragging the charm or its anchor —
    /// used by the window to keep receiving events (and keep the click-through
    /// off) for the duration of the gesture.
    var isDraggingCharmOrAnchor: Bool { isDraggingCharm || isDraggingAnchor }

    var screenAnchor: NSPoint? {
        guard let window = window else { return nil }
        let p = convert(anchor, to: nil)
        return NSPoint(x: window.frame.minX + p.x, y: window.frame.minY + p.y)
    }

    var screenBob: NSPoint? {
        guard let window = window else { return nil }
        let p = convert(bobPosition(), to: nil)
        return NSPoint(x: window.frame.minX + p.x, y: window.frame.minY + p.y)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(dirtyRect)

        let bob = bobPosition()

        if isAyudhaPoojaActive {
            // 1. Ayudha Pooja Background Aarti Radiance
            ayudhaEffect.drawBackgroundEffects(ctx: ctx, anchor: anchor, bob: bob)

            // 2. Sacred Twisted Mauli / Kalawa Thread with Mango Leaves & Marigold Beads
            ayudhaEffect.drawSacredThread(ctx: ctx, anchor: anchor, bob: bob)
        } else {
            // Standard minimalist string and anchor
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.55).cgColor)
            ctx.setLineWidth(2.4)
            ctx.move(to: anchor)
            ctx.addLine(to: bob)
            ctx.strokePath()

            ctx.setFillColor(NSColor.white.withAlphaComponent(0.7).cgColor)
            ctx.fillEllipse(in: NSRect(x: anchor.x - 4, y: anchor.y - 4, width: 8, height: 8))

            if flashOpacity > 0 {
                ctx.setFillColor(NSColor.systemYellow.withAlphaComponent(flashOpacity * 0.35).cgColor)
                ctx.fillEllipse(in: NSRect(x: bob.x - 60, y: bob.y - 60, width: 120, height: 120))
            }
        }

        // Draw the charm body
        let fontSize: CGFloat = 68
        var charmSize = CGSize(width: fontSize, height: fontSize)

        if let actor = activeActor {
            // REAL PICTURE OF THE ACTOR'S BODY (Movie Card / Pendant that sways with physics)
            let img = cachedActorImages[actor] ?? actor.loadImage()
            if let image = img {
                cachedActorImages[actor] = image
                drawActorPhotoBody(ctx: ctx, at: bob, actor: actor, image: image)
                charmSize = CGSize(width: 88, height: 126)
            } else {
                let str = NSAttributedString(string: actor.emoji, attributes: [.font: NSFont.systemFont(ofSize: fontSize)])
                let size = str.size()
                charmSize = size
                str.draw(at: NSPoint(x: bob.x - size.width / 2, y: bob.y - size.height / 2))
            }
        } else if emoji == "meme:veeramani" || emoji.contains("veeramani") {
            // VIRAL VEERAMANI COD PARCEL / SWEET BOX
            drawVeeramaniParcel(ctx: ctx, at: bob)
            charmSize = CGSize(width: 92, height: 114)
        } else if emoji == "meme:gpmuthu" || emoji.contains("gpmuthu") {
            // GP MUTHU KADHUDHASU LETTER
            drawGPMuthuLetter(ctx: ctx, at: bob)
            charmSize = CGSize(width: 88, height: 62)
        } else if emoji == "meme:nesamani" || emoji.contains("nesamani") {
            // CONTRACTOR NESAMANI SUTHIYAL
            drawNesamaniHammer(ctx: ctx, at: bob)
            charmSize = CGSize(width: 64, height: 95)
        } else if emoji == "🍋🌶️" {
            // Authentic vertical hanging Nimbu-Mirchi talisman
            drawStackedNimbuMirchi(at: bob)
            charmSize = CGSize(width: 50, height: 90)
        } else {
            let str = NSAttributedString(string: emoji, attributes: [.font: NSFont.systemFont(ofSize: fontSize)])
            let size = str.size()
            charmSize = size
            str.draw(at: NSPoint(x: bob.x - size.width / 2, y: bob.y - size.height / 2))
        }

        if isAyudhaPoojaActive {
            // 3. Chandanam & Kumkum Tilak + Marigold Mala Garland
            ayudhaEffect.drawForegroundDecorations(ctx: ctx, bob: bob, charmSize: charmSize, emoji: emoji)

            // 4. Fluttering Flower Petals, Incense Wisps & Blessing Banner
            ayudhaEffect.drawForegroundEffects(ctx: ctx)
        }
    }

    /// Draws the real picture of the actor's body as the pendulum bob,
    /// tilting dynamically with the pendulum swing angle!
    private func drawActorPhotoBody(ctx: CGContext, at center: CGPoint, actor: TamilActor, image: NSImage) {
        ctx.saveGState()

        // Rotate with the pendulum angle for realistic swaying physics!
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)

        let width: CGFloat = 88.0
        let height: CGFloat = 126.0
        let rect = NSRect(x: -width / 2, y: -height / 2, width: width, height: height)

        // 1. Top Hanging Ring / Eyelet
        let ringRect = NSRect(x: -6, y: height / 2 - 2, width: 12, height: 12)
        ctx.setFillColor(NSColor(calibratedRed: 0.9, green: 0.75, blue: 0.2, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: ringRect)
        ctx.setFillColor(NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: -3, y: height / 2 + 1, width: 6, height: 6))

        // 2. Card Shadow
        ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14.0, color: NSColor.black.withAlphaComponent(0.6).cgColor)

        // 3. Card Base & Clip Path
        let cardPath = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 0.95).setFill()
        cardPath.fill()

        // Clip to rounded rect for image
        ctx.saveGState()
        cardPath.addClip()

        // Draw Real Actor Image
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        // Subtle gradient vignette at the bottom for text legibility
        let gradientColors = [
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(0.75).cgColor
        ] as CFArray
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: 0, y: -height / 2 + 35),
                end: CGPoint(x: 0, y: -height / 2),
                options: []
            )
        }

        // Star / Movie Name at bottom of card
        let nameFont = NSFont.boldSystemFont(ofSize: 8.5)
        let nameAttr: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: actor.themeColor
        ]
        let nameStr = NSAttributedString(string: actor.displayName.uppercased(), attributes: nameAttr)
        let nSize = nameStr.size()
        nameStr.draw(at: NSPoint(x: -nSize.width / 2, y: -height / 2 + 4))

        ctx.restoreGState()

        // 4. Glowing Metallic Outer Border
        actor.themeColor.withAlphaComponent(0.85).setStroke()
        cardPath.lineWidth = 2.0
        cardPath.stroke()

        // 5. Subtle Inner Border
        let innerRect = rect.insetBy(dx: 2, dy: 2)
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 8, yRadius: 8)
        NSColor.white.withAlphaComponent(0.2).setStroke()
        innerPath.lineWidth = 1.0
        innerPath.stroke()

        ctx.restoreGState()
    }

    /// Draws the viral Madurai Veeramani Cash On Delivery Parcel / Sweet Box
    private func drawVeeramaniParcel(ctx: CGContext, at center: CGPoint) {
        ctx.saveGState()

        // Pendulum dynamic tilt
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)

        let w: CGFloat = 92.0
        let h: CGFloat = 114.0
        let boxRect = NSRect(x: -w / 2, y: -h / 2, width: w, height: h)

        // Drop shadow
        ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 12.0, color: NSColor.black.withAlphaComponent(0.55).cgColor)

        // Cardboard Box Body
        let path = NSBezierPath(roundedRect: boxRect, xRadius: 8, yRadius: 8)
        let cardboardColor = NSColor(calibratedRed: 0.78, green: 0.58, blue: 0.36, alpha: 1.0)
        cardboardColor.setFill()
        path.fill()

        // 3D side edge shade
        NSColor(calibratedRed: 0.65, green: 0.46, blue: 0.28, alpha: 0.8).setFill()
        let sideFlap = NSBezierPath(rect: NSRect(x: -w/2, y: -h/2, width: 7, height: h))
        sideFlap.fill()
        let bottomFlap = NSBezierPath(rect: NSRect(x: -w/2, y: -h/2, width: w, height: 6))
        bottomFlap.fill()

        // Clear Packing Tape across vertical center & top flap
        NSColor(calibratedRed: 0.95, green: 0.82, blue: 0.52, alpha: 0.55).setFill()
        let tapeH = NSBezierPath(rect: NSRect(x: -w/2, y: h/2 - 18, width: w, height: 14))
        tapeH.fill()
        let tapeV = NSBezierPath(rect: NSRect(x: -7, y: -h/2, width: 14, height: h))
        tapeV.fill()

        // White Shipping Label
        let labelRect = NSRect(x: -w/2 + 10, y: -h/2 + 14, width: w - 20, height: h - 38)
        let labelPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor.white.setFill()
        labelPath.fill()
        NSColor.lightGray.withAlphaComponent(0.5).setStroke()
        labelPath.lineWidth = 0.8
        labelPath.stroke()

        // Header: EXPRESS DELIVERY
        let headFont = NSFont.boldSystemFont(ofSize: 6.5)
        let headAttr: [NSAttributedString.Key: Any] = [.font: headFont, .foregroundColor: NSColor.darkGray]
        let headStr = NSAttributedString(string: "🚚 EXPRESS COD PARCEL", attributes: headAttr)
        headStr.draw(at: NSPoint(x: labelRect.minX + 4, y: labelRect.maxY - 11))

        // Big Red COD Stamp
        let codFont = NSFont.boldSystemFont(ofSize: 10.5)
        let codAttr: [NSAttributedString.Key: Any] = [.font: codFont, .foregroundColor: NSColor(calibratedRed: 0.85, green: 0.05, blue: 0.1, alpha: 1.0)]
        let codStr = NSAttributedString(string: "C.O.D. ₹99,999", attributes: codAttr)
        let cSize = codStr.size()
        codStr.draw(at: NSPoint(x: -cSize.width / 2, y: labelRect.maxY - 25))

        // Recipient: VEERAMANI
        let toFont = NSFont.systemFont(ofSize: 7.5, weight: .bold)
        let toAttr: [NSAttributedString.Key: Any] = [.font: toFont, .foregroundColor: NSColor.black]
        let toStr = NSAttributedString(string: "TO: VEERAMANI", attributes: toAttr)
        toStr.draw(at: NSPoint(x: labelRect.minX + 4, y: labelRect.maxY - 37))

        let locFont = NSFont.systemFont(ofSize: 6.5)
        let locAttr: [NSAttributedString.Key: Any] = [.font: locFont, .foregroundColor: NSColor.darkGray]
        let locStr = NSAttributedString(string: "MADURAI, TN (DIWALI)", attributes: locAttr)
        locStr.draw(at: NSPoint(x: labelRect.minX + 4, y: labelRect.maxY - 46))

        // Barcode lines
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.2)
        let barY = labelRect.minY + 6
        let barWidths: [CGFloat] = [2, 1, 3, 1, 2, 1, 4, 1, 2, 1, 3, 2, 1, 2, 4, 1]
        var currX = labelRect.minX + 8
        for bw in barWidths {
            ctx.setLineWidth(bw)
            ctx.strokeLineSegments(between: [CGPoint(x: currX, y: barY), CGPoint(x: currX, y: barY + 11)])
            currX += bw + 1.8
            if currX > labelRect.maxX - 8 { break }
        }

        // Top Eyelet Ring (where string connects)
        ctx.setFillColor(NSColor(calibratedRed: 0.9, green: 0.75, blue: 0.2, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: -5, y: h/2 - 2, width: 10, height: 10))
        ctx.setFillColor(NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: -2.5, y: h/2 + 0.5, width: 5, height: 5))

        // Fragile badge / Sweet Box indicator
        let sweetStr = NSAttributedString(string: "🎁 SWEETS", attributes: [.font: NSFont.boldSystemFont(ofSize: 7), .foregroundColor: NSColor(calibratedRed: 0.9, green: 0.4, blue: 0.0, alpha: 1.0)])
        sweetStr.draw(at: NSPoint(x: labelRect.maxX - 44, y: labelRect.maxY - 46))

        ctx.restoreGState()
    }

    /// Draws GP Muthu's inland letter envelope
    private func drawGPMuthuLetter(ctx: CGContext, at center: CGPoint) {
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)

        let w: CGFloat = 88.0
        let h: CGFloat = 62.0
        let rect = NSRect(x: -w / 2, y: -h / 2, width: w, height: h)

        ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 10.0, color: NSColor.black.withAlphaComponent(0.5).cgColor)

        // Vintage inland envelope
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.88, alpha: 1.0).setFill()
        path.fill()

        // Red Airmail border
        NSColor(calibratedRed: 0.8, green: 0.1, blue: 0.1, alpha: 0.8).setStroke()
        path.lineWidth = 1.5
        path.stroke()

        // Envelope Flap Lines
        ctx.setStrokeColor(NSColor.gray.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokeLineSegments(between: [CGPoint(x: -w/2, y: h/2), CGPoint(x: 0, y: 0)])
        ctx.strokeLineSegments(between: [CGPoint(x: w/2, y: h/2), CGPoint(x: 0, y: 0)])

        // Red Wax Seal in Center
        ctx.setFillColor(NSColor(calibratedRed: 0.8, green: 0.08, blue: 0.1, alpha: 0.95).cgColor)
        ctx.fillEllipse(in: NSRect(x: -9, y: -9, width: 18, height: 18))
        let sealLetter = NSAttributedString(string: "✉️", attributes: [.font: NSFont.systemFont(ofSize: 10)])
        sealLetter.draw(at: NSPoint(x: -6, y: -6))

        // Text: TO CHELLAM
        let textAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 8),
            .foregroundColor: NSColor.darkGray
        ]
        let text = NSAttributedString(string: "To: GP Muthu Chellam", attributes: textAttr)
        text.draw(at: NSPoint(x: -w/2 + 6, y: -h/2 + 5))

        // Top ring
        ctx.setFillColor(NSColor(calibratedRed: 0.9, green: 0.75, blue: 0.2, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: -4, y: h/2 - 2, width: 8, height: 8))

        ctx.restoreGState()
    }

    /// Draws Contractor Nesamani's iconic Suthiyal (Hammer)
    private func drawNesamaniHammer(ctx: CGContext, at center: CGPoint) {
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)

        ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 10.0, color: NSColor.black.withAlphaComponent(0.5).cgColor)

        // 1. Hammer Steel Head (at top)
        let headRect = NSRect(x: -32, y: 22, width: 64, height: 18)
        let headPath = NSBezierPath(roundedRect: headRect, xRadius: 4, yRadius: 4)
        NSColor(calibratedWhite: 0.75, alpha: 1.0).setFill()
        headPath.fill()
        NSColor(calibratedWhite: 0.35, alpha: 0.9).setStroke()
        headPath.lineWidth = 1.2
        headPath.stroke()

        // Steel claw curve on left
        let claw = NSBezierPath()
        claw.move(to: CGPoint(x: -32, y: 36))
        claw.curve(to: CGPoint(x: -44, y: 18), controlPoint1: CGPoint(x: -38, y: 32), controlPoint2: CGPoint(x: -42, y: 24))
        claw.curve(to: CGPoint(x: -32, y: 24), controlPoint1: CGPoint(x: -38, y: 20), controlPoint2: CGPoint(x: -34, y: 22))
        claw.close()
        NSColor(calibratedWhite: 0.7, alpha: 1.0).setFill()
        claw.fill()

        // 2. Yellow Wooden Handle (hanging down)
        let handleRect = NSRect(x: -6, y: -50, width: 12, height: 74)
        let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: 4, yRadius: 4)
        NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.1, alpha: 1.0).setFill()
        handlePath.fill()
        NSColor(calibratedRed: 0.8, green: 0.55, blue: 0.0, alpha: 1.0).setStroke()
        handlePath.lineWidth = 1.0
        handlePath.stroke()

        // Rubber grip at bottom
        let gripRect = NSRect(x: -7, y: -50, width: 14, height: 32)
        NSColor(calibratedWhite: 0.2, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: gripRect, xRadius: 3, yRadius: 3).fill()

        // Text: NESAMANI
        let textAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 7),
            .foregroundColor: NSColor.white
        ]
        let txt = NSAttributedString(string: "#NESAMANI", attributes: textAttr)
        let tSize = txt.size()
        txt.draw(at: NSPoint(x: -tSize.width / 2, y: -45))

        // Top ring
        ctx.setFillColor(NSColor(calibratedRed: 0.9, green: 0.75, blue: 0.2, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: NSRect(x: -4, y: 38, width: 8, height: 8))

        ctx.restoreGState()
    }

    /// Draws an authentic vertically stacked Nimbu-Mirchi talisman:
    /// Green chillies with fresh lemon and black drishti thread.
    private func drawStackedNimbuMirchi(at center: CGPoint) {
        let chilliFont = NSFont.systemFont(ofSize: 34)
        let lemonFont = NSFont.systemFont(ofSize: 48)

        // Top chilli pointing down
        let topChilli = NSAttributedString(string: "🌶️", attributes: [.font: chilliFont])
        let tcSize = topChilli.size()
        topChilli.draw(at: NSPoint(x: center.x - tcSize.width / 2, y: center.y + 16))

        // Central juicy lemon
        let lemon = NSAttributedString(string: "🍋", attributes: [.font: lemonFont])
        let lSize = lemon.size()
        lemon.draw(at: NSPoint(x: center.x - lSize.width / 2, y: center.y - 18))

        // Bottom hanging chilli
        let bottomChilli = NSAttributedString(string: "🌶️", attributes: [.font: chilliFont])
        let bcSize = bottomChilli.size()
        bottomChilli.draw(at: NSPoint(x: center.x - bcSize.width / 2, y: center.y - 48))
    }

    // MARK: - Mouse handling

    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        lastDragLocation = loc
        lastDragTime = event.timestamp

        if loc.y > anchor.y - 32 {
            isDraggingAnchor = true
        } else {
            isDraggingCharm = true
            angularVelocity = 0
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        if isDraggingAnchor, let window = self.window {
            let dx = loc.x - lastDragLocation.x
            var frame = window.frame
            frame.origin.x += dx
            window.setFrameOrigin(frame.origin)
        } else if isDraggingCharm {
            let dx = loc.x - anchor.x
            let dy = anchor.y - loc.y
            angle = max(-1.3, min(1.3, atan2(dx, max(dy, 20))))

            let dt = max(event.timestamp - lastDragTime, 1.0 / 120.0)
            dragAngularVelocitySample = CGFloat((loc.x - lastDragLocation.x) / dt) * 0.01
        }

        lastDragLocation = loc
        lastDragTime = event.timestamp
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if isDraggingCharm {
            angularVelocity = dragAngularVelocitySample
        }
        isDraggingCharm = false
        isDraggingAnchor = false
    }
}

