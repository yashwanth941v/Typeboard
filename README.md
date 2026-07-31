# Typeboard

Typeboard is a macOS app that types your clipboard content for you with realistic, human-like typing — and can even answer questions using AI and type the response back (this feature is still in development).

It was built as a fun side project to explore macOS app development with SwiftUI, hotkey handling, and integrating local and cloud AI models. I've wanted to build apps for a long time, and this is the first macOS app I've built. Feel free to use it and send feedback.

<details>
<summary><h2>Features</h2></summary>

### Typing (built)
- **Type Clipboard** — press a hotkey and Typeboard types out whatever you copied, character by character, like a real person.
- **5 typing speeds** — Instant, Auto, Fast, Medium, and Slow, each with its own pacing behavior.
- **Esc to cancel** mid-typing, and **⌘Z right after** undoes the whole block.

### AI Answer (in progress)
- Press a hotkey with a question or prompt copied, and Typeboard sends it to an AI model, then types the answer back.
- Two providers to choose from:
  - **Local (Ollama)** — runs models on your own machine, completely private and free. One-click setup downloads and installs Ollama for you.
  - **Gemini (Cloud)** — uses Google's Gemini API with your own key. Currently in beta — free-tier quotas and API changes can cause hiccups.
- **Master toggle** to disable AI entirely (hotkey and all AI features turn off).
- Model stats bars (Speed, Brain, Code, Weight) to compare local models.

Note: Type Clipboard is fully built and working. The AI features are still under active development.

</details>

<details>
<summary><h2>How It Works</h2></summary>

- Built with SwiftUI and AppKit for macOS (requires macOS 26+).
- Hotkeys via the [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) library.
- Local AI uses the Ollama runtime, downloaded and managed automatically by the app.
- Cloud AI uses the Gemini API with your own key, stored in your Keychain.
- Sandboxed, with accessibility permission required to simulate typing.

</details>

## Download & Install

> **Note:** Typeboard isn't on the Mac App Store and isn't signed with a paid Developer ID certificate, so the first time you open it macOS shows an "Apple could not verify 'Typeboard' is free of malware" warning. It's safe — that warning just means the app wasn't notarized. Bypass it with **either** method below.

1. Download `Typeboard.dmg` from the [latest release](https://github.com/yashwanth941v/Typeboard/releases/latest).
2. Open the DMG and drag `Typeboard.app` into your **Applications** folder. macOS will show the "Apple could not verify" warning — click **Done** (not Move to Trash).
3. Remove the quarantine flag using one of these:

   **Option A — Terminal:** run this once, then open Typeboard again:

   ```zsh
   xattr -cr /Applications/Typeboard.app
   ```

   **Option B — System Settings:** go to **System Settings → Privacy & Security**, scroll down to the Security section, and click **Open Anyway** next to the Typeboard warning. Then open Typeboard again.

4. Enable **Accessibility** for Typeboard in System Settings when prompted — that's what lets it type for you.
5. Set your hotkeys in the **Typing** tab.

<details>
<summary><h2>Getting Started (from source)</h2></summary>

1. Clone the repo and open `Typeboard.xcodeproj` in Xcode.
2. Build and run (enable the Accessibility permission when prompted).
3. Set your hotkeys in the **Typing** tab.
4. (Optional) Enable AI in the **AI** tab and pick a provider.

To package your own DMG for sharing, run `./Scripts/build-dmg.sh` — it produces `Typeboard.dmg` on your Desktop.

</details>

## Disclaimer

This is a personal project I built to learn and experiment.

Use it for educational purposes only. Please do not use this app, or its code, to cheat on assignments, exams, or any academic work — that's on you. I am not responsible for how you use this project or any consequences that come from it.

## Connect

- Website: [yashwanth941v.com](https://yashwanth941v.com/)
- Twitter / X: [@yashwanth941v](https://twitter.com/yashwanth941v)
- GitHub: [yashwanth941v/Typeboard](https://github.com/yashwanth941v/Typeboard)
- Email: yashwanth.941v@gmail.com

Built and developed by [Yashwanth V](https://yashwanth941v.com/).
