import AppKit

// MARK: - Tamil Nadu Actors & Latest Movies

enum TamilActor: String, CaseIterable {
    case vijay = "vijay"
    case ajith = "ajith"
    case rajini = "rajini"

    var displayName: String {
        switch self {
        case .vijay: return "Thalapathy Vijay"
        case .ajith: return "Ajith Kumar (AK)"
        case .rajini: return "Superstar Rajinikanth"
        }
    }

    var movieTitle: String {
        switch self {
        case .vijay: return "The Greatest of All Time (GOAT)"
        case .ajith: return "Good Bad Ugly"
        case .rajini: return "Vettaiyan"
        }
    }

    var portraitFileName: String {
        switch self {
        case .vijay: return "vijay_portrait.jpg"
        case .ajith: return "ajith_portrait.jpg"
        case .rajini: return "rajini_portrait.jpg"
        }
    }

    var imageFileName: String {
        switch self {
        case .vijay: return "vijay_goat.jpg"
        case .ajith: return "ajith_gbu.jpg"
        case .rajini: return "rajini_vettaiyan.jpg"
        }
    }

    var punchDialogue: String {
        switch self {
        case .vijay:
            return "“Whistle Podu! Time's up nanba, let's smash this goal!”"
        case .ajith:
            return "“Never Ever Give Up! Time to execute with speed!”"
        case .rajini:
            return "“Kuri vechaa irai vizhanum! Hukum — time is up!”"
        }
    }

    var themeColor: NSColor {
        switch self {
        case .vijay:
            return NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.1, alpha: 1.0) // Gold
        case .ajith:
            return NSColor(calibratedRed: 1.0, green: 0.25, blue: 0.1, alpha: 1.0) // Red/Orange
        case .rajini:
            return NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.05, alpha: 1.0) // Saffron
        }
    }

    var emoji: String {
        switch self {
        case .vijay: return "🐐"
        case .ajith: return "🏎️"
        case .rajini: return "👑"
        }
    }

    func loadImage() -> NSImage? {
        let candidateFiles = [portraitFileName, imageFileName]

        for file in candidateFiles {
            // 1. Bundle resource
            if let url = Bundle.main.url(forResource: file, withExtension: nil),
               let img = NSImage(contentsOf: url) {
                return img
            }
            // 2. Bundle resourcePath
            if let resPath = Bundle.main.resourcePath {
                let path = (resPath as NSString).appendingPathComponent(file)
                if let img = NSImage(contentsOfFile: path) {
                    return img
                }
            }
            // 3. Project / local Resources directory
            let searchPaths = [
                "Resources/" + file,
                "./Resources/" + file,
                "../Resources/" + file
            ]
            for p in searchPaths {
                if FileManager.default.fileExists(atPath: p), let img = NSImage(contentsOfFile: p) {
                    return img
                }
            }
        }
        return nil
    }
}

// MARK: - Reminder Model

struct ActiveReminder {
    let id = UUID()
    let title: String
    let actor: TamilActor
    let targetDate: Date
    let totalSeconds: Int
}

// MARK: - Reminder Manager

final class ReminderManager {

    static let shared = ReminderManager()

    private(set) var activeReminder: ActiveReminder?
    private var ticker: Timer?
    private var selectedActorPreference: TamilActor? // nil = Random

    var onTick: ((Int) -> Void)?
    var onFire: ((ActiveReminder) -> Void)?

    init() {
        if let saved = UserDefaults.standard.string(forKey: "ReminderActorPreference"),
           let actor = TamilActor(rawValue: saved) {
            selectedActorPreference = actor
        }
    }

    func setActorPreference(_ actor: TamilActor?) {
        selectedActorPreference = actor
        if let actor = actor {
            UserDefaults.standard.set(actor.rawValue, forKey: "ReminderActorPreference")
        } else {
            UserDefaults.standard.removeObject(forKey: "ReminderActorPreference")
        }
    }

    func currentActorPreference() -> TamilActor? {
        return selectedActorPreference
    }

    func resolveActor() -> TamilActor {
        if let pref = selectedActorPreference {
            return pref
        }
        return TamilActor.allCases.randomElement() ?? .vijay
    }

    func startReminder(minutes: Int, title: String, actor: TamilActor? = nil) {
        ticker?.invalidate()

        let chosenActor = actor ?? resolveActor()
        let seconds = max(5, minutes * 60)
        let target = Date().addingTimeInterval(TimeInterval(seconds))

        let reminder = ActiveReminder(
            title: title.isEmpty ? "Reminder Alert" : title,
            actor: chosenActor,
            targetDate: target,
            totalSeconds: seconds
        )
        activeReminder = reminder

        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.stepTick()
        }
        RunLoop.main.add(ticker!, forMode: .common)
    }

    func cancelReminder() {
        ticker?.invalidate()
        ticker = nil
        activeReminder = nil
        onTick?(0)
    }

    func snooze(minutes: Int = 5) {
        guard let current = activeReminder else { return }
        startReminder(minutes: minutes, title: current.title, actor: current.actor)
    }

    private func stepTick() {
        guard let reminder = activeReminder else {
            cancelReminder()
            return
        }

        let remaining = Int(reminder.targetDate.timeIntervalSinceNow)
        if remaining <= 0 {
            ticker?.invalidate()
            ticker = nil
            let fired = reminder
            activeReminder = nil
            onFire?(fired)
        } else {
            onTick?(remaining)
        }
    }
}

// MARK: - Reminder Notification Alert Window

final class ReminderAlertWindow: NSWindow {

    private let reminder: ActiveReminder

    init(reminder: ActiveReminder) {
        self.reminder = reminder

        let windowWidth: CGFloat = 460
        let windowHeight: CGFloat = 260
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screen.midX - windowWidth / 2,
            y: screen.maxY - windowHeight - 60
        )

        super.init(
            contentRect: NSRect(origin: origin, size: NSSize(width: windowWidth, height: windowHeight)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        setupContentView(width: windowWidth, height: windowHeight)

        // Play alert sound
        NSSound(named: "Hero")?.play()
    }

    private func setupContentView(width: CGFloat, height: CGFloat) {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true
        container.layer?.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 0.96).cgColor
        container.layer?.borderColor = reminder.actor.themeColor.withAlphaComponent(0.85).cgColor
        container.layer?.borderWidth = 2.0

        // 1. Movie Poster Image (Left side)
        let posterWidth: CGFloat = 135
        let posterHeight: CGFloat = 200
        let posterView = NSImageView(frame: NSRect(x: 18, y: 30, width: posterWidth, height: posterHeight))
        posterView.wantsLayer = true
        posterView.layer?.cornerRadius = 10
        posterView.layer?.masksToBounds = true
        posterView.layer?.borderColor = reminder.actor.themeColor.withAlphaComponent(0.6).cgColor
        posterView.layer?.borderWidth = 1.5
        posterView.imageScaling = .scaleAxesIndependently

        if let posterImg = reminder.actor.loadImage() {
            posterView.image = posterImg
        } else {
            posterView.image = NSImage(systemSymbolName: "film.fill", accessibilityDescription: nil)
        }
        container.addSubview(posterView)

        // 2. Right Side Content
        let contentX: CGFloat = posterWidth + 34
        let contentWidth: CGFloat = width - contentX - 18

        // Header: Actor Name + Movie
        let headerLabel = NSTextField(labelWithString: "\(reminder.actor.emoji)  \(reminder.actor.displayName)")
        headerLabel.frame = NSRect(x: contentX, y: height - 48, width: contentWidth, height: 22)
        headerLabel.font = NSFont.boldSystemFont(ofSize: 15.5)
        headerLabel.textColor = reminder.actor.themeColor
        container.addSubview(headerLabel)

        let movieLabel = NSTextField(labelWithString: "Latest Blockbuster: \(reminder.actor.movieTitle)")
        movieLabel.frame = NSRect(x: contentX, y: height - 70, width: contentWidth, height: 18)
        movieLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .medium)
        movieLabel.textColor = NSColor(calibratedWhite: 0.75, alpha: 1.0)
        container.addSubview(movieLabel)

        // Separator line
        let sep = NSBox(frame: NSRect(x: contentX, y: height - 80, width: contentWidth, height: 1))
        sep.boxType = .separator
        container.addSubview(sep)

        // Reminder Title
        let titleLabel = NSTextField(labelWithString: reminder.title)
        titleLabel.frame = NSRect(x: contentX, y: height - 114, width: contentWidth, height: 28)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        container.addSubview(titleLabel)

        // Actor Punchline Dialogue
        let dialogueLabel = NSTextField(wrappingLabelWithString: reminder.actor.punchDialogue)
        dialogueLabel.frame = NSRect(x: contentX, y: height - 172, width: contentWidth, height: 50)
        dialogueLabel.font = NSFont(name: "Helvetica-Oblique", size: 12.5) ?? NSFont.systemFont(ofSize: 12.5)
        dialogueLabel.textColor = NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.5, alpha: 0.95)
        container.addSubview(dialogueLabel)

        // 3. Action Buttons
        let btnY: CGFloat = 22

        let dismissBtn = NSButton(frame: NSRect(x: contentX, y: btnY, width: 85, height: 30))
        dismissBtn.title = "Dismiss"
        dismissBtn.bezelStyle = .rounded
        dismissBtn.target = self
        dismissBtn.action = #selector(dismissAction)
        container.addSubview(dismissBtn)

        let snoozeBtn = NSButton(frame: NSRect(x: contentX + 92, y: btnY, width: 95, height: 30))
        snoozeBtn.title = "+5m Snooze"
        snoozeBtn.bezelStyle = .rounded
        snoozeBtn.target = self
        snoozeBtn.action = #selector(snoozeAction)
        container.addSubview(snoozeBtn)

        let ritualBtn = NSButton(frame: NSRect(x: contentX + 194, y: btnY, width: 75, height: 30))
        ritualBtn.title = "🪔 Aarti"
        ritualBtn.bezelStyle = .rounded
        ritualBtn.target = self
        ritualBtn.action = #selector(ritualAction)
        container.addSubview(ritualBtn)

        self.contentView = container
    }

    @objc private func dismissAction() {
        close()
    }

    @objc private func snoozeAction() {
        ReminderManager.shared.snooze(minutes: 5)
        close()
    }

    @objc private func ritualAction() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.charmView.performRitual()
            if appDelegate.isFullScreen3PattaActive {
                appDelegate.fullScreenPoojaWindow?.triggerRitual()
            }
        }
        close()
    }
}
