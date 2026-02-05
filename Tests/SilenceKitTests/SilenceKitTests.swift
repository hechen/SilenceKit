import XCTest
import AVFoundation
@testable import SilenceKit

final class SilenceKitTests: XCTestCase {
    
    // MARK: - TrimSilenceLevel Tests
    
    func testTrimSilenceLevelRawValues() {
        XCTAssertEqual(TrimSilenceLevel.off.rawValue, 0)
        XCTAssertEqual(TrimSilenceLevel.mild.rawValue, 1)
        XCTAssertEqual(TrimSilenceLevel.medium.rawValue, 2)
        XCTAssertEqual(TrimSilenceLevel.aggressive.rawValue, 3)
    }
    
    func testTrimSilenceLevelMinRMS() {
        XCTAssertEqual(TrimSilenceLevel.off.minRMS, 0)
        XCTAssertEqual(TrimSilenceLevel.mild.minRMS, 0.0055)
        XCTAssertEqual(TrimSilenceLevel.medium.minRMS, 0.00511)
        XCTAssertEqual(TrimSilenceLevel.aggressive.minRMS, 0.005)
    }
    
    func testTrimSilenceLevelMinGapSize() {
        XCTAssertEqual(TrimSilenceLevel.off.minGapSizeInFrames, 0)
        XCTAssertEqual(TrimSilenceLevel.mild.minGapSizeInFrames, 20)
        XCTAssertEqual(TrimSilenceLevel.medium.minGapSizeInFrames, 16)
        XCTAssertEqual(TrimSilenceLevel.aggressive.minGapSizeInFrames, 4)
    }
    
    func testTrimSilenceLevelFramesToReInsert() {
        XCTAssertEqual(TrimSilenceLevel.off.framesToReInsert, 0)
        XCTAssertEqual(TrimSilenceLevel.mild.framesToReInsert, 14)
        XCTAssertEqual(TrimSilenceLevel.medium.framesToReInsert, 12)
        XCTAssertEqual(TrimSilenceLevel.aggressive.framesToReInsert, 0)
    }
    
    func testTrimSilenceLevelDisplayNames() {
        XCTAssertEqual(TrimSilenceLevel.off.displayName, "Off")
        XCTAssertEqual(TrimSilenceLevel.mild.displayName, "Mild")
        XCTAssertEqual(TrimSilenceLevel.medium.displayName, "Medium")
        XCTAssertEqual(TrimSilenceLevel.aggressive.displayName, "Aggressive")
    }
    
    func testTrimSilenceLevelCaseIterable() {
        let allCases = TrimSilenceLevel.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertEqual(allCases[0], .off)
        XCTAssertEqual(allCases[1], .mild)
        XCTAssertEqual(allCases[2], .medium)
        XCTAssertEqual(allCases[3], .aggressive)
    }
    
    func testTrimSilenceLevelThresholdsOrder() {
        // More aggressive = lower threshold (catches more silence)
        XCTAssertGreaterThan(TrimSilenceLevel.mild.minRMS, TrimSilenceLevel.medium.minRMS)
        XCTAssertGreaterThan(TrimSilenceLevel.medium.minRMS, TrimSilenceLevel.aggressive.minRMS)
    }
    
    func testTrimSilenceLevelGapSizeOrder() {
        // More aggressive = smaller gap needed to trigger trim
        XCTAssertGreaterThan(TrimSilenceLevel.mild.minGapSizeInFrames, TrimSilenceLevel.medium.minGapSizeInFrames)
        XCTAssertGreaterThan(TrimSilenceLevel.medium.minGapSizeInFrames, TrimSilenceLevel.aggressive.minGapSizeInFrames)
    }
    
    // MARK: - AudioProcessor Initialization Tests
    
    func testAudioProcessorInitialization() {
        let processor = AudioProcessor()
        
        XCTAssertFalse(processor.isPlaying)
        XCTAssertEqual(processor.currentTime, 0)
        XCTAssertEqual(processor.duration, 0)
        XCTAssertEqual(processor.timeSavedByTrimming, 0)
    }
    
    func testAudioProcessorDefaultSettings() {
        let processor = AudioProcessor()
        
        XCTAssertEqual(processor.trimSilenceLevel, .off)
        XCTAssertEqual(processor.playbackSpeed, 1.0)
        XCTAssertEqual(processor.volumeBoost, 1.0)
    }
    
    func testAudioProcessorTrimSilenceLevelChange() {
        let processor = AudioProcessor()
        
        processor.trimSilenceLevel = .aggressive
        XCTAssertEqual(processor.trimSilenceLevel, .aggressive)
        
        processor.trimSilenceLevel = .mild
        XCTAssertEqual(processor.trimSilenceLevel, .mild)
    }
    
    func testAudioProcessorPlaybackSpeedChange() {
        let processor = AudioProcessor()
        
        processor.playbackSpeed = 1.5
        XCTAssertEqual(processor.playbackSpeed, 1.5)
        
        processor.playbackSpeed = 2.0
        XCTAssertEqual(processor.playbackSpeed, 2.0)
    }
    
    func testAudioProcessorVolumeBoostChange() {
        let processor = AudioProcessor()
        
        processor.volumeBoost = 1.5
        XCTAssertEqual(processor.volumeBoost, 1.5)
        
        processor.volumeBoost = 2.5
        XCTAssertEqual(processor.volumeBoost, 2.5)
    }
    
    // MARK: - AudioUtils Tests
    
    func testCalculateBufferRMSWithSilence() {
        // Create a silent buffer
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 1024
        
        // Fill with zeros (silence)
        if let channelData = buffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = 0.0
            }
        }
        
        let rms = AudioUtils.calculateBufferRMS(buffer)
        XCTAssertEqual(rms, 0.0, accuracy: 0.0001)
    }
    
    func testCalculateBufferRMSWithLoudAudio() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 1024
        
        // Fill with a sine wave (loud audio)
        if let channelData = buffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = sin(Float(i) * 0.1)
            }
        }
        
        let rms = AudioUtils.calculateBufferRMS(buffer)
        XCTAssertGreaterThan(rms, 0.5) // Sine wave RMS should be significant
    }
    
    func testCalculateBufferRMSWithQuietAudio() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 1024
        
        // Fill with very quiet audio
        if let channelData = buffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = sin(Float(i) * 0.1) * 0.001
            }
        }
        
        let rms = AudioUtils.calculateBufferRMS(buffer)
        XCTAssertLessThan(rms, TrimSilenceLevel.aggressive.minRMS)
    }
    
    func testCalculateBufferRMSStereo() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create stereo audio format/buffer")
            return
        }
        
        buffer.frameLength = 1024
        
        // Fill both channels with sine wave
        if let channelData = buffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = sin(Float(i) * 0.1)
                channelData[1][i] = sin(Float(i) * 0.1)
            }
        }
        
        let rms = AudioUtils.calculateBufferRMS(buffer)
        XCTAssertGreaterThan(rms, 0.5)
    }
    
    func testFadeAudioFadeOut() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 100
        
        // Fill with constant amplitude
        if let channelData = buffer.floatChannelData {
            for i in 0..<100 {
                channelData[0][i] = 1.0
            }
        }
        
        AudioUtils.fadeAudio(buffer, fadeOut: true, channelCount: 1)
        
        if let channelData = buffer.floatChannelData {
            // First sample should be close to 1.0, last should be close to 0.0
            XCTAssertEqual(channelData[0][0], 1.0, accuracy: 0.02)
            XCTAssertEqual(channelData[0][99], 0.0, accuracy: 0.02)
        }
    }
    
    func testFadeAudioFadeIn() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 100
        
        // Fill with constant amplitude
        if let channelData = buffer.floatChannelData {
            for i in 0..<100 {
                channelData[0][i] = 1.0
            }
        }
        
        AudioUtils.fadeAudio(buffer, fadeOut: false, channelCount: 1)
        
        if let channelData = buffer.floatChannelData {
            // First sample should be close to 0.0, last should be close to 1.0
            XCTAssertEqual(channelData[0][0], 0.0, accuracy: 0.02)
            XCTAssertEqual(channelData[0][99], 1.0, accuracy: 0.02)
        }
    }
    
    func testNormalizeAudio() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 100
        
        // Fill with quiet audio (peak at 0.5)
        if let channelData = buffer.floatChannelData {
            for i in 0..<100 {
                channelData[0][i] = sin(Float(i) * 0.1) * 0.5
            }
        }
        
        AudioUtils.normalizeAudio(buffer, targetPeak: 0.95)
        
        // Find new peak
        var maxPeak: Float = 0
        if let channelData = buffer.floatChannelData {
            for i in 0..<100 {
                maxPeak = max(maxPeak, abs(channelData[0][i]))
            }
        }
        
        XCTAssertEqual(maxPeak, 0.95, accuracy: 0.01)
    }
    
    func testNormalizeAudioWithSilence() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 100
        
        // Fill with silence
        if let channelData = buffer.floatChannelData {
            for i in 0..<100 {
                channelData[0][i] = 0.0
            }
        }
        
        // Should not crash with silent input
        AudioUtils.normalizeAudio(buffer, targetPeak: 0.95)
        
        // Verify still silent
        if let channelData = buffer.floatChannelData {
            for i in 0..<100 {
                XCTAssertEqual(channelData[0][i], 0.0)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testSilenceDetectionThresholds() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 1024
        
        // For a sine wave, RMS ≈ amplitude / √2 ≈ 0.707 * amplitude
        // Thresholds: aggressive=0.005, medium=0.00511, mild=0.0055
        // To get RMS of 0.006 (above all), need amplitude ≈ 0.0085
        // To get RMS of 0.004 (below all), need amplitude ≈ 0.0057
        
        let testCases: [(amplitude: Float, expectedSilentForAggressive: Bool)] = [
            (0.004, true),   // RMS ≈ 0.0028 - silent for all levels
            (0.006, true),   // RMS ≈ 0.0042 - silent for all levels
            (0.010, false),  // RMS ≈ 0.0071 - not silent for any level
            (0.020, false),  // RMS ≈ 0.0141 - clearly not silent
        ]
        
        for testCase in testCases {
            if let channelData = buffer.floatChannelData {
                for i in 0..<1024 {
                    channelData[0][i] = sin(Float(i) * 0.1) * testCase.amplitude
                }
            }
            
            let rms = AudioUtils.calculateBufferRMS(buffer)
            let isSilent = rms < TrimSilenceLevel.aggressive.minRMS
            
            XCTAssertEqual(isSilent, testCase.expectedSilentForAggressive,
                "Amplitude \(testCase.amplitude): expected \(testCase.expectedSilentForAggressive ? "silent" : "not silent") (RMS: \(rms), threshold: \(TrimSilenceLevel.aggressive.minRMS))")
        }
    }
    
    func testRMSRelationshipWithAmplitude() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create audio format/buffer")
            return
        }
        
        buffer.frameLength = 1024
        
        // Fill with sine wave of known amplitude
        let amplitude: Float = 1.0
        if let channelData = buffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = sin(Float(i) * 0.1) * amplitude
            }
        }
        
        let rms = AudioUtils.calculateBufferRMS(buffer)
        
        // For a sine wave, RMS should be approximately amplitude / √2
        let expectedRMS = amplitude / sqrt(2)
        XCTAssertEqual(rms, expectedRMS, accuracy: 0.05)
    }
    
    func testLouderAudioHasHigherRMS() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let quietBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024),
              let loudBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create audio buffers")
            return
        }
        
        quietBuffer.frameLength = 1024
        loudBuffer.frameLength = 1024
        
        // Quiet audio
        if let channelData = quietBuffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = sin(Float(i) * 0.1) * 0.1
            }
        }
        
        // Loud audio
        if let channelData = loudBuffer.floatChannelData {
            for i in 0..<1024 {
                channelData[0][i] = sin(Float(i) * 0.1) * 1.0
            }
        }
        
        let quietRMS = AudioUtils.calculateBufferRMS(quietBuffer)
        let loudRMS = AudioUtils.calculateBufferRMS(loudBuffer)
        
        XCTAssertGreaterThan(loudRMS, quietRMS)
        XCTAssertEqual(loudRMS / quietRMS, 10.0, accuracy: 0.1) // 10x amplitude = 10x RMS
    }
}
