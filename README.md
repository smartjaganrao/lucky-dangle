# Lucky Dangle v2.0 (macOS Native Menu Bar & Screen Hijacker Engine)

A high-performance, native macOS menu bar charm and interactive screen hijacker engine — built with Swift 5.9 + AppKit, CoreGraphics, AVFoundation, and QuartzCore.

Inspired by [luckydangle.app](https://luckydangle.app/), this is an independent, native macOS implementation expanded into a multi-mode cultural desktop experience with real-time physics, Kollywood health reminders, trending viral memes, full-screen sacred celebrations, and screen ledge walking heroes.

---

## 🌟 Key Features

### 1. 🪔 Dynamic Pendulum Physics & Cultural Charms (`CharmView.swift`)
- **Real-Time Physics:** Natural pendulum swinging simulation (Hooke's law + angular damping + gravitational pull + cursor flick inertia).
- **Interactive Click-Through:** Borderless floating window that never blocks your coding or browsing clicks except right on the charm.
- **Traditional Charms:**
  - 🍋🌶️ Nimbu-Mirchi (Drishti Talisman with lemon, chillies, and coal)
  - 🧿 Nazar Boncuğu (Evil Eye)
  - 🕉️ Om & 卐 Swastik
  - 🧲 Lucky Horseshoe & 🪙 Feng Shui Coins

### 2. 🔥 Viral Tamil Memes (Trending Edition)
- **📦 Veeramani Madurai COD Sweet Box (`meme:veeramani`):**
  - Cardboard parcel marked with `COD: ₹99,999`, `TO: VEERAMANI, MDU`, `DIWALI SWEETS`, hazard tape, and barcode.
  - Interactive delivery ritual: *"Sir, OTP sollunga! Sweet box parcel vandhurukku! 🚚💨"*.
- **✉️ GP Muthu Letter (`meme:gpmuthu`):**
  - Dangling postal envelope marked *"LETTER FOR G.P. MUTHU"* and *"SETHTHA PAYALE"*.
- **🔨 Contractor Nesamani Hammer (`meme:nesamani`):**
  - Custom steel hammer with wooden handle dangling above your code (#PrayForNesamani).

### 3. 🔱 Sacred Full-Screen Ayudha Pooja 3-Patta Theme (`FullScreenPoojaWindow.swift`)
- **Sacred 3-Patta (Tripundra):** 3 horizontal white Vibhuti lines with soft finger-stroke textures and a central vermilion **Kumkum Bindu (🔴)**.
- **Top Screen Toran:** Mango leaves (*Mavilai*) and draped golden-orange marigold flower garlands strung across the display.
- **Grand Aarti Ritual (`⌃S`):** Showers of fragrant marigold, orange petal, and jasmine flowers with camphor flame aura and temple bell chimes.

### 4. 🕺 Real-Body Video Hero Walker (`VideoHeroWalkerWindow.swift`)
- **Window-Ledge & Dock Snapping:**
  - Automatically detects the top title bar of your active frontmost application window (VS Code, Chrome, Terminal, Xcode) using `CGWindowListCopyWindowInfo` and walks along the ledge. Falls back to the macOS Dock floor.
- **Dual Rendering & Green-Screen Chroma Keyer:**
  - Plays transparent alpha `.mov` clips (`AVPlayerLayer` with `kCVPixelFormatType_32BGRA`).
  - Built-in runtime CoreImage chroma-keyer automatically keys out bright green backgrounds from `.mp4` video files without needing FFmpeg!
  - Built-in high-definition solo actor portrait cutout with animated strides, dust puffs, and glass bottle in hand.
- **Direction Flipping:** Automatically turns around and walks back when hitting screen boundaries.

### 5. ⏰ Kollywood Star Health Reminders (`ActorReminder.swift`)
- **Solo Actor Photographs:** High-resolution clean celebrity portraits of:
  - **Thalapathy Vijay** (Hydration Break: *"Whistle Podu! Water break time da nanba! 💧🥃"*)
  - **Ajith Kumar (AK)** (Physical Stretch: *"Never, Ever Give Up! Stand up & stretch now! 🏎️"*)
  - **Superstar Rajinikanth** (20-20-20 Eye Rest: *"Kuri vechaa irai vizhanum! Take eye rest! 👑"*)
- **Interactive HUD & Walker Delivery:**
  - The walking hero pauses mid-screen, attaches a comic speech bubble with the dialogue, and plays victory fanfare audio.

### 6. 👀 Bezel & Notch Copy-Paste Surveillance (`BezelWatcherManager.swift`)
- Monitors clipboard velocity (`NSPasteboard.general.changeCount`).
- Automatically triggers when `>= 3` copy-pastes occur within 60 seconds.
- Slides out a frosted glass HUD card from the Right Bezel or down from the MacBook Notch:
  - **🚨 StackOverflow Police:** *"Ennada, full project-ume ChatGPT & Copy-Paste dhana? 👀"*
  - **😭 Kaipulla Build Alert:** *"Aahaan! Code-la kai vechittiya? Ipdi panringale ma! 😭"*
  - **📦 Madurai Courier Dept:** *"Sir, copy-paste OTP sollunga! ₹99,999 sweet parcel ready! 🚚"*

### 7. 🥛🥁 FDFS "Build Success / Git Push" Theatre Celebration (`FDFSCelebrationOverlay.swift`)
- **Trigger Shortcut:** **`⌘ ⇧ F`** (Command + Shift + F) or right-click menu.
- **50-Foot Theatre Cutout:** Rises at the bottom center with wooden scaffolding bamboo lattice poles.
- **Fresh Marigold Garland:** Draped across the cutout's shoulders.
- **Paal Abhishekam (Milk Waterfall):** Brass pot at the MacBook Notch pours creamy white milk streams and splash foam cascading over the hero.
- **1000-Wala Crackers & Confetti:** Rapid red cracker bursts with golden sparks along the bottom edge + neon marquee banner:
  > **🚀 BUILD SUCCESS • FDFS BLOCKBUSTER DEPLOYMENT! 🥁🎺**  
  > *100% MASS • NO PRODUCTION BUGS • ALL THEATRES HOUSEFULL 🔥*

---

## ⌨️ Keyboard Shortcuts & URL Schemes

| Shortcut / URL | Action |
| :--- | :--- |
| **`⌘ ⇧ F`** | Trigger FDFS 50-Foot Cutout & Paal Abhishekam Celebration |
| **`⌃ F`** | Toggle Full Screen 3-Patta Center Ayudha Pooja Theme |
| **`⌃ S`** | Perform Grand Aarti & Flower Shower Ritual |
| **`⌃ A`** | Toggle Dangling Ayudha Pooja Theme on/off |
| **`⌃ D`** | Toggle Charm Visibility |
| **`⌃ R`** | Set Custom Actor Health Reminder |
| `luckydangle://water` | Trigger Walking Hero Water Break Reminder |
| `luckydangle://fdfs` | Trigger FDFS Celebration |
| `luckydangle://walker` | Toggle Walking Hero |
| `luckydangle://bezel` | Trigger Bezel Copy-Paste Watcher Test |

---

## 🛠️ Build & Installation

### Fast Build via Terminal
```bash
git clone https://github.com/ajayts97/lucky-dangle.git
cd lucky-dangle

# Build in release mode and package into a signed .app bundle
./Scripts/build_app.sh

# Launch the app
open "./Lucky Dangle.app"
```

To install permanently, move `Lucky Dangle.app` to your `/Applications` folder.

---

## 🔒 Permissions Note
Global keyboard shortcuts (`⌘⇧F`, `⌃D`, `⌃S`, etc.) require **Input Monitoring** permission:
- `System Settings ▸ Privacy & Security ▸ Input Monitoring` → Enable **Lucky Dangle**.
- The app never intercepts your keystrokes; it only listens for its registered global shortcut triggers.

---

## 📄 License
MIT License. Open source and free for everyone.
