# SilenceKit

A Swift package for podcast-style audio processing, extracted from [Pocket Casts](https://github.com/Automattic/pocket-casts-ios).

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B%20%7C%20macOS%2012%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)

## Features

- **Trim Silence** - Remove silent portions using RMS-based detection
- **Playback Speed** - Variable rate playback (0.5x to 3.0x)
- **Volume Boost** - Amplify audio with normalization (0.5x to 3.0x)

## Installation

### Swift Package Manager

Add SilenceKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hechen/SilenceKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → Enter the repository URL.

## Usage

### Basic Setup

```swift
import SilenceKit

// Create processor
let processor = AudioProcessor()

// Load audio file
try processor.loadFile(url: audioFileURL)

// Play
processor.play()
```

### Trim Silence

Remove silent portions to speed up podcast listening:

```swift
// Set trim level
processor.trimSilenceLevel = .medium

// Available levels:
// - .off         - No trimming
// - .mild        - Light trimming (threshold: 0.0055)
// - .medium      - Moderate trimming (threshold: 0.00511)
// - .aggressive  - Heavy trimming (threshold: 0.005)
```

### Playback Speed

Adjust playback rate without pitch distortion:

```swift
// Speed up (1.5x)
processor.playbackSpeed = 1.5

// Slow down (0.75x)
processor.playbackSpeed = 0.75

// Range: 0.5x to 3.0x
```

### Volume Boost

Amplify quiet audio:

```swift
// Boost volume 50%
processor.volumeBoost = 1.5

// Range: 0.5x to 3.0x
```

### Playback Controls

```swift
// Play/Pause
processor.play()
processor.pause()

// Seek
processor.seek(to: 30.0)  // Jump to 30 seconds

// State
processor.isPlaying      // Bool
processor.currentTime    // TimeInterval
processor.duration       // TimeInterval
```

### Statistics

Track time saved by silence trimming:

```swift
let saved = processor.timeSavedByTrimming
print("Saved \(saved) seconds")
```

## Trim Silence Algorithm

The silence detection uses **RMS (Root Mean Square)** analysis:

1. Audio is divided into frames
2. Each frame's RMS value is calculated using `vDSP_rmsqv`
3. Frames below the threshold are marked as silent
4. Consecutive silent frames (gap size varies by level) are removed
5. Fade in/out applied at boundaries using `vDSP_vmul`

| Level | RMS Threshold | Min Gap Size |
|-------|---------------|--------------|
| Mild | 0.0055 | 20 frames |
| Medium | 0.00511 | 10 frames |
| Aggressive | 0.005 | 4 frames |

## TrimSilenceLevel

```swift
public enum TrimSilenceLevel: Int, CaseIterable {
    case off = 0
    case mild = 1
    case medium = 2
    case aggressive = 3
    
    var minRMS: Float { ... }
    var minGapSize: Int { ... }
    var displayName: String { ... }
}
```

## AudioUtils

Low-level utilities using Apple's Accelerate framework:

```swift
// Calculate RMS of audio buffer
let rms = AudioUtils.calculateRMS(buffer)

// Apply fade in/out
AudioUtils.applyFadeIn(to: &buffer, sampleCount: 1000)
AudioUtils.applyFadeOut(to: &buffer, sampleCount: 1000)

// Normalize volume
AudioUtils.normalizeVolume(of: &buffer, to: 0.9)
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15+

## License

GPL-3.0 (same license as Pocket Casts source)

The audio processing algorithms are extracted and adapted from [Pocket Casts iOS](https://github.com/Automattic/pocket-casts-ios), which is licensed under GPL-3.0.

## Credits

- Original audio processing code from [Automattic/pocket-casts-ios](https://github.com/Automattic/pocket-casts-ios)
- RMS-based silence detection using Apple's Accelerate framework (`vDSP`)

## See Also

- [AudioDemo](https://github.com/hechen/AudioDemo) - Demo iOS app showcasing SilenceKit
