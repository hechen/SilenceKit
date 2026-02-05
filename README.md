# AudioKitPC

Audio processing Swift Package with Trim Silence, Speed Control, and Volume Boost.

Extracted and adapted from [Pocket Casts](https://github.com/Automattic/pocket-casts-ios) (GPL-3.0).

## Features

- **Trim Silence**: Automatically detect and remove silent portions from audio using RMS analysis
- **Playback Speed**: Variable rate playback (0.5x - 3x) without pitch change
- **Volume Boost**: Amplify audio with optional normalization

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/AudioKit-PC.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL

## Usage

```swift
import AudioKitPC

// Create processor
let processor = AudioProcessor()

// Load audio file
try processor.loadFile(url: audioFileURL)

// Configure effects
processor.trimSilenceLevel = .medium  // .off, .mild, .medium, .aggressive
processor.playbackSpeed = 1.5         // 0.5 - 3.0
processor.volumeBoost = 1.2           // 1.0 = normal

// Control playback
processor.play()
processor.pause()
processor.seek(to: 30.0)  // seconds
processor.stop()

// Observe state (Combine)
processor.$isPlaying.sink { playing in ... }
processor.$currentTime.sink { time in ... }
processor.$timeSavedByTrimming.sink { saved in ... }
```

## Trim Silence Levels

| Level | Description | RMS Threshold |
|-------|-------------|---------------|
| off | No trimming | - |
| mild | Conservative, only obvious silences | 0.0055 |
| medium | Balanced | 0.00511 |
| aggressive | Maximum trimming | 0.005 |

## How Trim Silence Works

1. Audio is read in small buffers
2. RMS (Root Mean Square) is calculated for each buffer
3. If RMS < threshold, buffer is considered "silence"
4. Consecutive silent buffers are tracked
5. If silence gap is long enough, middle is removed
6. Fade in/out applied at cut points for smooth transitions
7. Last 5 seconds are never trimmed (to preserve endings)

## License

GPL-3.0 (same as Pocket Casts source)
