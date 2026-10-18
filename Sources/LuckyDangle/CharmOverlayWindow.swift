import AppKit

/// A small, borderless, transparent, click-through-everywhere-except-itself
/// window that hangs at the top of the screen. Because it's sized to just
/// the charm + string (not the full screen), it never intercepts clicks
/// anywhere else on the desktop.
final class CharmOverlayWindow: NSWindow {

    static let windowSize = NSSize(width: 280, height: 480)

    var contentRect: NSRect { NSRect(origin: .zero, size: Self.windowSize) }

    private var clickThroughTimer: Timer?

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screenFrame.maxX - Self.windowSize.width - 40,
            y: screenFrame.maxY - Self.windowSize.height
        )
        let frame = NSRect(origin: origin, size: Self.windowSize)

        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        // Start click-through: only the charm + anchor regions are interactable,
        // everything else (string, blank space) passes clicks to the app behind.
        ignoresMouseEvents = true

        startClickThroughMonitoring()
    }

    deinit { clickThroughTimer?.invalidate() }

    /// Polls the cursor and makes the window click-through except when the
    /// pointer is near the charm or the anchor (or a drag is in progress), so
    /// the area around the string never blocks clicks on the desktop.
    private func startClickThroughMonitoring() {
        clickThroughTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateClickThrough()
        }
        RunLoop.main.add(clickThroughTimer!, forMode: .common)
    }

    private func updateClickThrough() {
        guard let view = contentView as? CharmView else { return }
        guard let anchor = view.screenAnchor, let bob = view.screenBob else { return }

        if alphaValue < 0.05 {
            ignoresMouseEvents = true
            return
        }

        let mouse = NSEvent.mouseLocation
        let anchorHit = CGRect(x: anchor.x - 24, y: anchor.y - 24, width: 48, height: 48).contains(mouse)
        let bobHit = CGRect(x: bob.x - 56, y: bob.y - 65, width: 112, height: 130).contains(mouse)
        ignoresMouseEvents = !(anchorHit || bobHit || view.isDraggingCharmOrAnchor)
    }

    // Never take keyboard focus away from whatever app the user is in —
    // the charm reacts to mouse clicks/drags but shouldn't steal typing.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
