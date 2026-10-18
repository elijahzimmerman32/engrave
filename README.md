# Engrave

An iPhone app for memorizing Bible verses, by listening, speaking, or typing.

- **Pick your verses** by typing or saying a reference like "John 3:16" or "Psalm 23:1-3", or by choosing from lists.
- **Listen** to any verse read aloud.
- **Practice in pieces.** The app reads the verse, then teaches it a phrase at a time. Each round you say everything learned so far. If a piece keeps tripping you up, the app splits it into something smaller.
- **Test yourself.** The app reads the reference and you recite the verse by voice or by typing.
- **Hands-free.** In Speak mode the app talks you through practice and tests and listens for your answers, so nothing needs a tap.
- **On-device AI.** On iPhone 15 Pro and newer with Apple Intelligence turned on, Apple's built-in AI judges close answers (forgiving speech-recognition slips) and gives specific, friendly feedback. Other phones use a word-by-word check.

The Bible text is the World English Bible, which is in the public domain. It's stored in the app, so everything works offline.

## Running it on your iPhone

You need a Mac with **Xcode 26 or newer** and a free Apple ID. A paid developer account isn't needed until you publish.

1. **Download the code.** Open Xcode. On the welcome window choose **Clone Git Repository** (or **Integrate > Clone** in the menu bar) and paste `https://github.com/elijahzimmerman32/engrave`. Pick a folder and Xcode opens the project.
2. **Sign in.** In the left sidebar click the blue **Engrave** project icon at the top, then the **Engrave** target, then the **Signing & Capabilities** tab. Under **Team**, choose **Add an Account…**, sign in with your Apple ID, then pick **Your Name (Personal Team)**. If Xcode says the bundle identifier is taken, change `com.elijahzimmerman.engrave` to something unique, like `com.elijahzimmerman.engrave2`.
3. **Connect your iPhone** with a cable and tap **Trust** on the phone.
4. **Turn on Developer Mode** on the iPhone: **Settings > Privacy & Security > Developer Mode**, switch it on, and restart when asked.
5. **Run it.** At the top of Xcode, click the device menu and choose your iPhone. Press the **▶ Run** button (or Cmd-R).
6. **Trust the app.** The first time, the phone may say "Untrusted Developer". Go to **Settings > General > VPN & Device Management**, tap your Apple ID, and tap **Trust**. Then open Engrave.

With a free Apple ID the app stops opening after 7 days. Just plug in and press Run again to refresh it.

For AI grading, turn on Apple Intelligence in **Settings > Apple Intelligence & Siri**.

## How the code is organized

| Folder | What's in it |
| --- | --- |
| `Engrave/App` | App startup and the two tabs |
| `Engrave/Bible` | Loading the bundled Bible, reading references, and the saved verse model |
| `Engrave/Voice` | Reading aloud, speech recognition, and the talk-then-listen turn-taking |
| `Engrave/Grading` | The word-by-word check and the on-device AI coach |
| `Engrave/Practice` | Your verse list, adding verses, and practicing in pieces |
| `Engrave/Test` | The test flow and results |
| `Engrave/Shared` | Buttons and cards used on several screens |
| `Engrave/Resources/web.json` | The World English Bible text |
