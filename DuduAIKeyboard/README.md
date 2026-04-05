# ✦ Dudu AI Keyboard — iOS Custom Keyboard Extension

A full-featured AI-powered iOS keyboard with:
- **Smart suggestions bar** (3 continuations powered by Groq, updates as you type)
- **Expandable AI panel** with preset prompts, tone selector, and full streaming generation
- Full QWERTY layout with shift, caps lock, symbols, numbers, backspace, return
- Dark purple UI matching your Android overlay app

---

## Project Structure

```
DuduAIKeyboard/
├── DuduAIKeyboard/                  ← Main app (setup/instructions screen)
│   ├── DuduAIKeyboardApp.swift
│   ├── ContentView.swift
│   └── Info.plist
│
├── DuduAIKeyboardExtension/         ← The actual keyboard extension
│   ├── KeyboardViewController.swift ← UIInputViewController entry point
│   ├── KeyboardViewModel.swift      ← All state & business logic
│   ├── KeyboardRootView.swift       ← QWERTY keys + suggestion bar
│   ├── AIPanelView.swift            ← Expanded AI writing panel
│   ├── GroqClient.swift             ← Groq API (streaming + suggestions)
│   └── Info.plist
│
└── DuduAIKeyboard.xcodeproj/
    └── project.pbxproj
```

---

## Setup Steps

### 1. Add your Groq API Key

Open `DuduAIKeyboardExtension/GroqClient.swift` and replace:
```swift
static let apiKey = "YOUR_GROQ_API_KEY_HERE"
```
with your actual Groq key from https://console.groq.com

### 2. Set your Team ID in Xcode

Open the project in Xcode → select each target → Signing & Capabilities → set your Apple Developer Team.

Replace `"YOUR_TEAM_ID"` in `project.pbxproj` with your actual team ID.

### 3. Set Bundle IDs

Main app:     `com.dudu.ai.keyboard`  (or your own reverse-domain)
Extension:    `com.dudu.ai.keyboard.extension`

⚠️ The extension bundle ID MUST start with the main app's bundle ID.

### 4. Add App Group Capability

Both targets need the **same App Group** so they can share data:

In Xcode → each target → Signing & Capabilities → + Capability → App Groups
Add: `group.com.dudu.ai.keyboard`

This is already referenced in the code via:
```swift
UserDefaults(suiteName: "group.com.dudu.ai.keyboard")
```

### 5. Enable Full Access in Extension Info.plist

Already set: `RequestsOpenAccess = true`
This is required for network access (calling Groq API) from inside the keyboard.

---

## Build & Run

1. Open `DuduAIKeyboard.xcodeproj` in Xcode 15+
2. Select the **DuduAIKeyboard** scheme
3. Build & run on a real device (keyboard extensions don't work in Simulator)
4. On device: Settings → General → Keyboard → Keyboards → Add New Keyboard → Dudu AI
5. Tap Dudu AI → enable **Allow Full Access**
6. Open any app, tap a text field, switch to Dudu AI keyboard

---

## How It Works

### Suggestion Bar
- Watches text context (last 80 chars) with 0.8s debounce
- Calls `llama-3.1-8b-instant` for 3 short completions (fast, ~500ms)
- Tap any chip to insert it

### AI Panel (✦ button)
- Full prompt input with 6 quick presets
- 6 tone options: Auto, Casual, Formal, Funny, Heartfelt, Direct
- Streams response token-by-token with blinking cursor
- Insert button pastes directly into the active text field
- Retry and conversation history (last 3 turns)

---

## iOS Limitations vs Android

| Feature | Android Overlay | iOS Keyboard |
|---|---|---|
| Appears over any app | ✅ | ✅ (inside text fields) |
| Floating button | ✅ | ❌ (keyboard only) |
| AI suggestions | ✅ | ✅ |
| Full AI panel | ✅ | ✅ |
| Network access | ✅ free | ✅ (needs Full Access) |
| App Store | Google Play | App Store |

---

## App Store Submission Notes

1. **Privacy**: Keyboard extensions with Full Access CAN read what users type. Add a Privacy Policy clearly stating you do NOT log keystrokes. Only the explicit prompt sent to Groq is transmitted.
2. **App Review**: Apple scrutinizes keyboard apps. Make sure your privacy policy URL is in App Store Connect.
3. **Minimum iOS**: Set to 16.0 (SwiftUI features used require it)

---

## Monetization (Optional)

Add the same `UsageManager` + `StoreKit 2` pattern from your Android app:
- 10 free AI generations
- ₹99/month via In-App Purchase (StoreKit 2)
- Store usage in App Group UserDefaults so both app + extension share state

Ask if you want this added!
