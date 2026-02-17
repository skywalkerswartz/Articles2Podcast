# Articles2Podcast

An iOS app that converts web articles into audio for offline listening. Add articles via the app or the iOS Share menu, and listen to them like a podcast.

## Features

- **Article Extraction**: Extracts clean article text from any URL using Mozilla's Readability.js
- **On-Device TTS**: Generates high-quality speech audio using Kokoro (82M parameter neural TTS) or Apple's built-in speech synthesis
- **Podcast-Like Playback**: Full audio player with scrubbing, skip forward/back, variable speed (0.5x–2x), and resume support
- **Lock Screen Controls**: Play/pause, skip, and scrub from the lock screen and Control Center
- **Share Extension**: Add articles directly from Safari or any app via the iOS Share sheet
- **Queue Management**: Drag to reorder, swipe to delete, track extraction and generation progress
- **Offline Listening**: All audio is generated and stored on-device — no internet needed for playback
- **Background Processing**: Article extraction and audio generation continue in the background

## Requirements

- iOS 18.0+
- Xcode 26.0+ (Swift 6.2)
- ~330 MB free space for the Kokoro TTS model (optional — Apple Speech works without download)

## Building

1. Clone the repository:
   ```bash
   git clone https://github.com/lukeswartz/Articles2Podcast.git
   cd Articles2Podcast
   ```

2. Generate the Xcode project (requires [xcodegen](https://github.com/yonaskolb/XcodeGen)):
   ```bash
   xcodegen generate
   ```

3. Open `Articles2Podcast.xcodeproj` in Xcode

4. Configure signing:
   - Select the `Articles2Podcast` target and set your development team
   - Do the same for the `ShareExtension` target
   - Both targets need the App Group capability: `group.com.lukeswartz.articles2podcast`

5. Build and run on a device (background audio and lock screen controls require a real device)

## Architecture

```
Articles2Podcast/
├── App/                    # App entry point, AppDelegate
├── Models/                 # SwiftData models (Article, ArticleState, TTSEngine)
├── Services/               # Core logic (extraction, TTS, playback, file management)
├── Views/                  # SwiftUI views (Queue, Player, Settings)
└── ShareExtension/         # iOS Share Extension
```

### Key Technologies
- **SwiftUI** + **SwiftData** with App Groups for shared data between app and extension
- **AVAudioPlayer** for playback with variable speed and position tracking
- **MPRemoteCommandCenter** + **MPNowPlayingInfoCenter** for lock screen controls
- **swift-readability** (Mozilla Readability.js wrapper) for article extraction
- **KokoroSwift** (MLX-based neural TTS) for on-device speech synthesis
- **AVSpeechSynthesizer** as a fallback TTS engine

## TTS Engines

| Engine | Quality | Model Size | Speed |
|--------|---------|-----------|-------|
| Kokoro | High (neural) | ~330 MB download | ~3.3x realtime on iPhone 13 Pro |
| Apple Speech | Good (system) | Built-in | Real-time |

## License

MIT — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
