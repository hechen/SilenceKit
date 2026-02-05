/// SilenceKit - Audio processing library with trim silence, speed control, and volume boost
/// Extracted and adapted from Pocket Casts (GPL-3.0)
///
/// Features:
/// - Trim Silence: Remove silent portions from audio using RMS detection
/// - Playback Speed: Variable rate playback without pitch change
/// - Volume Boost: Amplify audio with normalization
///
/// Usage:
/// ```swift
/// import SilenceKit
///
/// let processor = AudioProcessor()
/// try processor.loadFile(url: audioURL)
/// processor.trimSilenceLevel = .medium
/// processor.playbackSpeed = 1.5
/// processor.play()
/// ```

@_exported import AVFoundation

// Re-export public types
public typealias TrimLevel = TrimSilenceLevel
