# Typeboard

Typeboard is a macOS app that types your clipboard content for you with realistic, human-like typing — and can even answer questions using AI and type the response back (this feature is still in development).

It was built as a fun side project to explore macOS app development with SwiftUI, hotkey handling, and integrating local and cloud AI models. I've wanted to build apps for a long time, and this is the first macOS app I've built. Feel free to use it and send feedback.

---

## Features

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

---

## How It Works

- Built with SwiftUI and AppKit for macOS (requires macOS 26+).
- Hotkeys via the [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) library.
- Local AI uses the Ollama runtime, downloaded and managed automatically by the app.
- Cloud AI uses the Gemini API with your own key, stored in your Keychain.
- Sandboxed, with accessibility permission required to simulate typing.

---

## Getting Started

1. Clone the repo and open `Typeboard.xcodeproj` in Xcode.
2. Build and run (enable the Accessibility permission when prompted).
3. Set your hotkeys in the **Typing** tab.
4. (Optional) Enable AI in the **AI** tab and pick a provider.

---

## Disclaimer

This is a personal project I built to learn and experiment.

Use it for educational purposes only. Please do not use this app, or its code, to cheat on assignments, exams, or any academic work — that's on you. I am not responsible for how you use this project or any consequences that come from it.

---

## Connect

- Website: [yashwanth941v.com](https://yashwanth941v.com/)
- Twitter / X: [@yashwanth941v](https://twitter.com/yashwanth941v)
- GitHub: [yashwanth941v/Typeboard](https://github.com/yashwanth941v/Typeboard)
- Email: yashwanth.941v@gmail.com

Built and developed by [Yashwanth V](https://yashwanth941v.com/).
