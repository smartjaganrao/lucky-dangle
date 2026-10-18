import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var overlayWindow: CharmOverlayWindow!
    var charmView: CharmView!
    var fullScreenPoojaWindow: FullScreenPoojaWindow?
    var toggleMenuItem: NSMenuItem!
    var ayudhaThemeMenuItem: NSMenuItem!
    var fullScreenThemeMenuItem: NSMenuItem!
    var isVisible = true
    var isFullScreen3PattaActive = false

    // Reminders
    var reminderStatusMenuItem: NSMenuItem!
    var cancelReminderMenuItem: NSMenuItem!
    var actorPreferenceMenuItems: [TamilActor: NSMenuItem] = [:]
    var randomActorMenuItem: NSMenuItem!
    var currentAlertWindow: ReminderAlertWindow?

    // Viral Screen Hijackers (v2.0)
    var walkerWindow: ScreenWalkerWindow?
    var isWalkerActive: Bool = false
    var videoHeroWalkerWindow: VideoHeroWalkerWindow?
    var isVideoHeroWalkerActive: Bool = false
    var fdfsCelebrationOverlay: FDFSCelebrationOverlay?
    var walkerMenuItem: NSMenuItem!
    var videoHeroWalkerMenuItem: NSMenuItem!
    var surveillanceMenuItem: NSMenuItem!

    private let ayudhaCharms: [(emoji: String, name: String)] = [
        ("🍋🌶️", "Nimbu-Mirchi (Drishti Talisman)"),
        ("💻✨", "Blessed Mac (Ayudha Puja)"),
        ("🪔", "Aarti Diya (Sacred Flame)"),
        ("🥥", "Purna Kumbha (Coconut)"),
        ("🚗", "Vahana Pooja (Vehicle)"),
        ("⚙️", "Ayudha Tools (Machinery)")
    ]

    private let viralMemeCharms: [(id: String, name: String)] = [
        ("meme:veeramani", "📦  Veeramani COD Parcel (Madurai Special ₹99k)"),
        ("meme:gpmuthu", "✉️  GP Muthu Kadhudhasu Letter (Chellam)"),
        ("meme:nesamani", "🔨  Contractor Nesamani Hammer (#PrayForNesamani)")
    ]

    private let tamilCinemaCharms: [(actor: TamilActor, name: String)] = [
        (.vijay, "🎬  Thalapathy Vijay — Real Picture Body (GOAT)"),
        (.ajith, "🎬  Ajith Kumar — Real Picture Body (Good Bad Ugly)"),
        (.rajini, "🎬  Superstar Rajini — Real Picture Body (Vettaiyan)")
    ]

    private let classicCharms: [(emoji: String, name: String)] = [
        ("🍀", "Four-Leaf Clover"),
        ("🧿", "Nazar Boncuğu"),
        ("🔔", "Ghanta Bell"),
        ("🪬", "Hamsa"),
        ("🎎", "Daruma"),
        ("🐱", "Maneki-neko"),
        ("🧲", "Horseshoe"),
        ("🐞", "Ladybug")
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()
        setupStatusItem()
        setupGlobalHotkeys()
        setupReminderCallbacks()
        restoreSavedState()
    }

    // MARK: - Status item / menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusItemIcon()

        let menu = NSMenu()

        toggleMenuItem = NSMenuItem(title: "Hide Charm (⌃D)", action: #selector(toggleVisibility), keyEquivalent: "")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        let ritualItem = NSMenuItem(title: "Perform Ritual / Aarti (⌃S)", action: #selector(performRitual), keyEquivalent: "")
        ritualItem.target = self
        menu.addItem(ritualItem)

        menu.addItem(.separator())

        // Full Screen 3-Patta Center Theme
        fullScreenThemeMenuItem = NSMenuItem(
            title: "🔱  Full Screen 3-Patta Center (⌃F)",
            action: #selector(toggleFullScreen3PattaTheme),
            keyEquivalent: ""
        )
        fullScreenThemeMenuItem.target = self
        menu.addItem(fullScreenThemeMenuItem)

        // Ayudha Pooja Charm Theme Effect toggle
        ayudhaThemeMenuItem = NSMenuItem(
            title: "🪔  Dangling Ayudha Charm Effect (⌃A)",
            action: #selector(toggleAyudhaPoojaTheme),
            keyEquivalent: ""
        )
        ayudhaThemeMenuItem.target = self
        ayudhaThemeMenuItem.state = charmView.isAyudhaPoojaActive ? .on : .off
        menu.addItem(ayudhaThemeMenuItem)

        menu.addItem(.separator())

        // MARK: - Tamil Cinema Reminders Submenu
        let reminderMenu = NSMenu()

        reminderStatusMenuItem = NSMenuItem(title: "No Active Reminder", action: nil, keyEquivalent: "")
        reminderStatusMenuItem.isEnabled = false
        reminderMenu.addItem(reminderStatusMenuItem)

        cancelReminderMenuItem = NSMenuItem(title: "❌  Cancel Active Reminder", action: #selector(cancelReminderAction), keyEquivalent: "")
        cancelReminderMenuItem.target = self
        cancelReminderMenuItem.isEnabled = false
        reminderMenu.addItem(cancelReminderMenuItem)

        reminderMenu.addItem(.separator())

        let customReminderItem = NSMenuItem(title: "⏰  Custom Reminder… (⌃R)", action: #selector(promptCustomReminder), keyEquivalent: "")
        customReminderItem.target = self
        reminderMenu.addItem(customReminderItem)

        reminderMenu.addItem(.separator())

        let quickHeader = NSMenuItem(title: "— Quick Timers —", action: nil, keyEquivalent: "")
        quickHeader.isEnabled = false
        reminderMenu.addItem(quickHeader)

        let presets: [(name: String, mins: Int)] = [
            ("⚡  5 Minutes (Quick Break)", 5),
            ("🔥  15 Minutes (Short Sprint)", 15),
            ("🎯  25 Minutes (Pomodoro Focus)", 25),
            ("💼  45 Minutes (Deep Work)", 45),
            ("🚀  60 Minutes (Major Milestone)", 60)
        ]
        for p in presets {
            let item = NSMenuItem(title: p.name, action: #selector(quickTimerAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = p.mins
            reminderMenu.addItem(item)
        }

        reminderMenu.addItem(.separator())

        let actorHeader = NSMenuItem(title: "— Actor Theme & Movie —", action: nil, keyEquivalent: "")
        actorHeader.isEnabled = false
        reminderMenu.addItem(actorHeader)

        for actor in TamilActor.allCases {
            let item = NSMenuItem(
                title: "\(actor.emoji)  \(actor.displayName) (\(actor.movieTitle))",
                action: #selector(selectActorPreference(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = actor
            actorPreferenceMenuItems[actor] = item
            reminderMenu.addItem(item)
        }

        randomActorMenuItem = NSMenuItem(title: "🎲  Random Star (Surprise Me!)", action: #selector(selectRandomActorPreference), keyEquivalent: "")
        randomActorMenuItem.target = self
        reminderMenu.addItem(randomActorMenuItem)

        updateActorPreferenceMenuCheckmarks()

        let reminderMenuItem = NSMenuItem(title: "⏰  Reminders (Vijay / Ajith / Rajini)", action: nil, keyEquivalent: "")
        menu.setSubmenu(reminderMenu, for: reminderMenuItem)
        menu.addItem(reminderMenuItem)

        menu.addItem(.separator())

        // MARK: - Choose Charm Submenu
        let charmMenu = NSMenu()

        // Viral Tamil Memes (Trending)
        let memeHeader = NSMenuItem(title: "— 🔥 Viral Tamil Memes (Trending) —", action: nil, keyEquivalent: "")
        memeHeader.isEnabled = false
        charmMenu.addItem(memeHeader)

        for item in viralMemeCharms {
            let mi = NSMenuItem(title: item.name, action: #selector(chooseMemeCharm(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = item.id
            charmMenu.addItem(mi)
        }

        charmMenu.addItem(.separator())

        // Real Picture Body (Tamil Stars)
        let tamilHeader = NSMenuItem(title: "— Real Picture Body (Tamil Stars) —", action: nil, keyEquivalent: "")
        tamilHeader.isEnabled = false
        charmMenu.addItem(tamilHeader)

        for item in tamilCinemaCharms {
            let mi = NSMenuItem(title: item.name, action: #selector(chooseTamilActorPicture(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = item.actor
            charmMenu.addItem(mi)
        }

        charmMenu.addItem(.separator())

        // Ayudha Pooja specific charms
        let ayudhaHeader = NSMenuItem(title: "— Ayudha Pooja Charms —", action: nil, keyEquivalent: "")
        ayudhaHeader.isEnabled = false
        charmMenu.addItem(ayudhaHeader)

        for charm in ayudhaCharms {
            let item = NSMenuItem(title: "\(charm.emoji)  \(charm.name)", action: #selector(chooseAyudhaCharm(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = charm.emoji
            charmMenu.addItem(item)
        }

        charmMenu.addItem(.separator())

        let classicHeader = NSMenuItem(title: "— Classic Charms —", action: nil, keyEquivalent: "")
        classicHeader.isEnabled = false
        charmMenu.addItem(classicHeader)

        for charm in classicCharms {
            let item = NSMenuItem(title: "\(charm.emoji)  \(charm.name)", action: #selector(chooseCharm(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = charm.emoji
            charmMenu.addItem(item)
        }

        let customItem = NSMenuItem(title: "🔤  Custom Emoji…", action: #selector(chooseCustomEmoji), keyEquivalent: "")
        customItem.target = self
        charmMenu.addItem(.separator())
        charmMenu.addItem(customItem)

        let charmMenuItem = NSMenuItem(title: "Choose Charm", action: nil, keyEquivalent: "")
        menu.setSubmenu(charmMenu, for: charmMenuItem)
        menu.addItem(charmMenuItem)

        menu.addItem(.separator())

        // MARK: - Viral Screen Hijackers (v2.0)
        let hijackerHeader = NSMenuItem(title: "— 🎬 Viral Screen Hijackers (v2.0) —", action: nil, keyEquivalent: "")
        hijackerHeader.isEnabled = false
        menu.addItem(hijackerHeader)

        walkerMenuItem = NSMenuItem(
            title: "🚶‍♂️  Toggle Walking Hero (Window/Dock Walker)",
            action: #selector(toggleWalkingHero),
            keyEquivalent: ""
        )
        walkerMenuItem.target = self
        menu.addItem(walkerMenuItem)

        videoHeroWalkerMenuItem = NSMenuItem(
            title: "🕺  Toggle Real-Body Walking Hero",
            action: #selector(toggleVideoHeroWalker),
            keyEquivalent: ""
        )
        videoHeroWalkerMenuItem.target = self
        menu.addItem(videoHeroWalkerMenuItem)

        let testWaterItem = NSMenuItem(
            title: "🥃  Test Walking Hero Water Reminder",
            action: #selector(testWalkingHeroWaterReminder),
            keyEquivalent: ""
        )
        testWaterItem.target = self
        menu.addItem(testWaterItem)

        let bezelTestItem = NSMenuItem(
            title: "👀  Trigger Bezel Copy-Paste Watcher (Test Now)",
            action: #selector(triggerBezelWatcherTest),
            keyEquivalent: ""
        )
        bezelTestItem.target = self
        menu.addItem(bezelTestItem)

        surveillanceMenuItem = NSMenuItem(
            title: "☑️  Auto Copy-Paste Surveillance (60s Velocity)",
            action: #selector(toggleSurveillance),
            keyEquivalent: ""
        )
        surveillanceMenuItem.target = self
        surveillanceMenuItem.state = BezelWatcherManager.shared.isSurveillanceEnabled ? .on : .off
        menu.addItem(surveillanceMenuItem)

        let fdfsItem = NSMenuItem(
            title: "🥛🥁  Trigger FDFS Paal Abhishekam Celebration (⌘⇧F)",
            action: #selector(triggerFDFSCelebration),
            keyEquivalent: ""
        )
        fdfsItem.target = self
        menu.addItem(fdfsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Lucky Dangle", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateStatusItemIcon() {
        if charmView != nil && charmView.isAyudhaPoojaActive {
            statusItem.button?.title = "🪔"
        } else if charmView != nil {
            let current = charmView.currentEmoji()
            if current == "meme:veeramani" {
                statusItem.button?.title = "📦"
            } else if current == "meme:gpmuthu" {
                statusItem.button?.title = "✉️"
            } else if current == "meme:nesamani" {
                statusItem.button?.title = "🔨"
            } else if current.hasPrefix("actor:") {
                statusItem.button?.title = "🎬"
            } else if current.count <= 2 {
                statusItem.button?.title = current
            } else {
                statusItem.button?.title = "🍀"
            }
        } else {
            statusItem.button?.title = "📦"
        }
    }

    // MARK: - Overlay window

    private func setupOverlayWindow() {
        overlayWindow = CharmOverlayWindow()
        charmView = CharmView(frame: overlayWindow.contentRect)
        overlayWindow.contentView = charmView
        overlayWindow.orderFrontRegardless()
    }

    // MARK: - State Persistence

    private func restoreSavedState() {
        let defaults = UserDefaults.standard
        let savedEmoji = defaults.string(forKey: "SelectedCharmEmoji") ?? "meme:veeramani"
        let isAyudha = defaults.object(forKey: "AyudhaPoojaThemeActive") != nil
            ? defaults.bool(forKey: "AyudhaPoojaThemeActive")
            : true // Active by default for Ayudha Pooja

        let isFullScreen = defaults.object(forKey: "FullScreen3PattaActive") != nil
            ? defaults.bool(forKey: "FullScreen3PattaActive")
            : true // Active by default for 3-Patta Center Ayudha Pooja

        if savedEmoji.hasPrefix("actor:") {
            let key = String(savedEmoji.dropFirst(6))
            if let actor = TamilActor(rawValue: key) {
                charmView.setActorCharm(actor)
            } else {
                charmView.setCharm(savedEmoji)
            }
        } else {
            charmView.setCharm(savedEmoji)
        }

        charmView.isAyudhaPoojaActive = isAyudha
        ayudhaThemeMenuItem.state = isAyudha ? .on : .off
        updateStatusItemIcon()

        setFullScreen3Patta(enabled: isFullScreen)

        let isWalker = defaults.bool(forKey: "WalkingHeroActive")
        setWalkingHero(active: isWalker)

        let isVideoWalker = defaults.object(forKey: "VideoHeroWalkerActive") != nil
            ? defaults.bool(forKey: "VideoHeroWalkerActive")
            : true // Active by default for immediate enjoyment!
        setVideoHeroWalker(active: isVideoWalker)
    }

    @objc private func chooseMemeCharm(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        charmView.setCharm(id)
        UserDefaults.standard.set(id, forKey: "SelectedCharmEmoji")
        updateStatusItemIcon()
    }

    @objc private func chooseTamilActorPicture(_ sender: NSMenuItem) {
        guard let actor = sender.representedObject as? TamilActor else { return }
        charmView.setActorCharm(actor)
        UserDefaults.standard.set("actor:\(actor.rawValue)", forKey: "SelectedCharmEmoji")
        updateStatusItemIcon()
    }

    // MARK: - Reminder Callbacks & Actions

    private func setupReminderCallbacks() {
        ReminderManager.shared.onTick = { [weak self] remaining in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let rem = ReminderManager.shared.activeReminder, remaining > 0 {
                    let mins = remaining / 60
                    let secs = remaining % 60
                    self.reminderStatusMenuItem.title = String(format: "⏳ Active: %02d:%02d (%@)", mins, secs, rem.actor.displayName)
                    self.cancelReminderMenuItem.isEnabled = true
                } else {
                    self.reminderStatusMenuItem.title = "No Active Reminder"
                    self.cancelReminderMenuItem.isEnabled = false
                }
            }
        }

        ReminderManager.shared.onFire = { [weak self] fired in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.reminderStatusMenuItem.title = "⏰ Just Fired: \(fired.actor.displayName)"
                self.cancelReminderMenuItem.isEnabled = false

                self.currentAlertWindow?.close()
                let alertWin = ReminderAlertWindow(reminder: fired)
                self.currentAlertWindow = alertWin
                alertWin.makeKeyAndOrderFront(nil)

                self.charmView.performRitual()

                // Also notify real-body video walker if active!
                if self.isVideoHeroWalkerActive {
                    self.videoHeroWalkerWindow?.deliverReminder(fired)
                }
            }
        }
    }

    private func updateActorPreferenceMenuCheckmarks() {
        let current = ReminderManager.shared.currentActorPreference()
        for (actor, item) in actorPreferenceMenuItems {
            item.state = (actor == current) ? .on : .off
        }
        randomActorMenuItem?.state = (current == nil) ? .on : .off
    }

    @objc private func cancelReminderAction() {
        ReminderManager.shared.cancelReminder()
    }

    @objc private func quickTimerAction(_ sender: NSMenuItem) {
        guard let mins = sender.representedObject as? Int else { return }
        let actor = ReminderManager.shared.resolveActor()
        let title = "Time to conquer! (\(mins) min session)"
        ReminderManager.shared.startReminder(minutes: mins, title: title, actor: actor)
    }

    @objc private func selectActorPreference(_ sender: NSMenuItem) {
        guard let actor = sender.representedObject as? TamilActor else { return }
        ReminderManager.shared.setActorPreference(actor)
        updateActorPreferenceMenuCheckmarks()
    }

    @objc private func selectRandomActorPreference() {
        ReminderManager.shared.setActorPreference(nil)
        updateActorPreferenceMenuCheckmarks()
    }

    @objc private func promptCustomReminder() {
        let alert = NSAlert()
        alert.messageText = "Set Tamil Cinema Reminder"
        alert.informativeText = "Pick your task, time duration, and star."
        alert.addButton(withTitle: "Start Reminder")
        alert.addButton(withTitle: "Cancel")

        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 110))

        let titleLabel = NSTextField(labelWithString: "Reminder Note:")
        titleLabel.frame = NSRect(x: 0, y: 88, width: 280, height: 18)
        let titleField = NSTextField(frame: NSRect(x: 0, y: 64, width: 280, height: 24))
        titleField.placeholderString = "e.g. Wrap up coding, stretch, deploy build"

        let minsLabel = NSTextField(labelWithString: "Duration:")
        minsLabel.frame = NSRect(x: 0, y: 38, width: 90, height: 18)
        let minsField = NSTextField(frame: NSRect(x: 0, y: 14, width: 80, height: 24))
        minsField.stringValue = "25"
        let minsUnit = NSTextField(labelWithString: "minutes")
        minsUnit.frame = NSRect(x: 88, y: 16, width: 80, height: 18)

        let actorPopup = NSPopUpButton(frame: NSRect(x: 155, y: 12, width: 145, height: 26), pullsDown: false)
        actorPopup.addItem(withTitle: "🦁 Vijay (GOAT)")
        actorPopup.addItem(withTitle: "🏎️ Ajith (GBU)")
        actorPopup.addItem(withTitle: "👑 Rajini (Vettaiyan)")
        actorPopup.addItem(withTitle: "🎲 Random Star")

        accessory.addSubview(titleLabel)
        accessory.addSubview(titleField)
        accessory.addSubview(minsLabel)
        accessory.addSubview(minsField)
        accessory.addSubview(minsUnit)
        accessory.addSubview(actorPopup)
        alert.accessoryView = accessory

        if alert.runModal() == .alertFirstButtonReturn {
            let note = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let mins = Int(minsField.stringValue) ?? 25
            var selectedActor: TamilActor? = nil
            switch actorPopup.indexOfSelectedItem {
            case 0: selectedActor = .vijay
            case 1: selectedActor = .ajith
            case 2: selectedActor = .rajini
            default: selectedActor = nil
            }
            ReminderManager.shared.startReminder(
                minutes: mins,
                title: note.isEmpty ? "Focus Session Done!" : note,
                actor: selectedActor
            )
        }
    }

    // MARK: - Hotkeys

    private func setupGlobalHotkeys() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkey(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            self?.handleHotkey(event)
            return event
        }
    }

    private func handleHotkey(_ event: NSEvent) {
        // Command + Shift + F: FDFS Celebration
        if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
            if event.charactersIgnoringModifiers?.lowercased() == "f" {
                triggerFDFSCelebration()
                return
            }
        }

        guard event.modifierFlags.contains(.control) else { return }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "d": toggleVisibility()
        case "s": performRitual()
        case "a": toggleAyudhaPoojaTheme()
        case "f": toggleFullScreen3PattaTheme()
        case "r": promptCustomReminder()
        default: break
        }
    }

    // MARK: - Actions

    @objc private func toggleVisibility() {
        isVisible.toggle()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            overlayWindow.animator().alphaValue = isVisible ? 1 : 0
        }
        toggleMenuItem.title = isVisible ? "Hide Charm (⌃D)" : "Show Charm (⌃D)"
    }

    @objc private func performRitual() {
        charmView.performRitual()
        if isFullScreen3PattaActive {
            fullScreenPoojaWindow?.triggerRitual()
        }
    }

    func setFullScreen3Patta(enabled: Bool) {
        isFullScreen3PattaActive = enabled
        fullScreenThemeMenuItem?.state = enabled ? .on : .off
        UserDefaults.standard.set(enabled, forKey: "FullScreen3PattaActive")

        if enabled {
            if fullScreenPoojaWindow == nil {
                fullScreenPoojaWindow = FullScreenPoojaWindow()
            }
            fullScreenPoojaWindow?.orderFrontRegardless()
        } else {
            fullScreenPoojaWindow?.orderOut(nil)
        }
    }

    @objc private func toggleFullScreen3PattaTheme() {
        setFullScreen3Patta(enabled: !isFullScreen3PattaActive)
        if isFullScreen3PattaActive {
            fullScreenPoojaWindow?.triggerRitual()
        }
    }

    @objc private func toggleAyudhaPoojaTheme() {
        let newState = !charmView.isAyudhaPoojaActive
        charmView.isAyudhaPoojaActive = newState
        ayudhaThemeMenuItem.state = newState ? .on : .off
        UserDefaults.standard.set(newState, forKey: "AyudhaPoojaThemeActive")
        updateStatusItemIcon()

        if newState {
            performRitual()
        }
    }

    @objc private func chooseAyudhaCharm(_ sender: NSMenuItem) {
        guard let emoji = sender.representedObject as? String else { return }
        charmView.setCharm(emoji)
        if !charmView.isAyudhaPoojaActive {
            charmView.isAyudhaPoojaActive = true
            ayudhaThemeMenuItem.state = .on
            UserDefaults.standard.set(true, forKey: "AyudhaPoojaThemeActive")
        }
        UserDefaults.standard.set(emoji, forKey: "SelectedCharmEmoji")
        updateStatusItemIcon()
    }

    @objc private func chooseCharm(_ sender: NSMenuItem) {
        guard let emoji = sender.representedObject as? String else { return }
        charmView.setCharm(emoji)
        UserDefaults.standard.set(emoji, forKey: "SelectedCharmEmoji")
        updateStatusItemIcon()
    }

    @objc private func chooseCustomEmoji() {
        let alert = NSAlert()
        alert.messageText = "Pick your charm"
        alert.informativeText = "Type any single emoji to hang it instead."
        alert.addButton(withTitle: "Hang It")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.placeholderString = "🍀"
        alert.accessoryView = field

        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
            let emoji = field.stringValue
            charmView.setCharm(emoji)
            UserDefaults.standard.set(emoji, forKey: "SelectedCharmEmoji")
            updateStatusItemIcon()
        }
    }

    // MARK: - luckydangle:// URL scheme

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "luckydangle" {
            switch url.host {
            case "bless":
                if !isVisible { toggleVisibility() }
                performRitual()
            case "fullscreen":
                toggleFullScreen3PattaTheme()
            case "ayudhapooja", "ayudha":
                if !charmView.isAyudhaPoojaActive {
                    toggleAyudhaPoojaTheme()
                } else {
                    performRitual()
                }
            case "reminder":
                promptCustomReminder()
            case "walker":
                toggleWalkingHero()
            case "videowalker":
                toggleVideoHeroWalker()
            case "water":
                testWalkingHeroWaterReminder()
            case "fdfs":
                triggerFDFSCelebration()
            case "bezel":
                triggerBezelWatcherTest()
            default:
                break
            }
        }
    }

    // MARK: - Viral Screen Hijackers Actions (v2.0)

    @objc func toggleWalkingHero() {
        setWalkingHero(active: !isWalkerActive)
    }

    func setWalkingHero(active: Bool) {
        isWalkerActive = active
        walkerMenuItem?.state = active ? .on : .off
        UserDefaults.standard.set(active, forKey: "WalkingHeroActive")

        if active {
            if walkerWindow == nil {
                walkerWindow = ScreenWalkerWindow()
            }
            walkerWindow?.orderFrontRegardless()
            walkerWindow?.startTracking()
        } else {
            walkerWindow?.stopTracking()
            walkerWindow?.orderOut(nil)
        }
    }

    @objc func triggerBezelWatcherTest() {
        BezelWatcherManager.shared.triggerManualPeek()
    }

    @objc func toggleSurveillance() {
        let current = BezelWatcherManager.shared.isSurveillanceEnabled
        BezelWatcherManager.shared.isSurveillanceEnabled = !current
        surveillanceMenuItem?.state = !current ? .on : .off
    }

    @objc func triggerFDFSCelebration() {
        fdfsCelebrationOverlay?.close()
        let overlay = FDFSCelebrationOverlay()
        fdfsCelebrationOverlay = overlay
        overlay.startCelebration()
    }

    // MARK: - Video Hero Walker Actions

    @objc func toggleVideoHeroWalker() {
        setVideoHeroWalker(active: !isVideoHeroWalkerActive)
    }

    func setVideoHeroWalker(active: Bool) {
        isVideoHeroWalkerActive = active
        videoHeroWalkerMenuItem?.state = active ? .on : .off
        UserDefaults.standard.set(active, forKey: "VideoHeroWalkerActive")

        if active {
            if videoHeroWalkerWindow == nil {
                videoHeroWalkerWindow = VideoHeroWalkerWindow()
            }
            videoHeroWalkerWindow?.orderFrontRegardless()
            videoHeroWalkerWindow?.startTracking()
        } else {
            videoHeroWalkerWindow?.stopTracking()
            videoHeroWalkerWindow?.orderOut(nil)
        }
    }

    @objc func testWalkingHeroWaterReminder() {
        if !isVideoHeroWalkerActive {
            setVideoHeroWalker(active: true)
        }
        videoHeroWalkerWindow?.testWaterReminder()
    }
}
