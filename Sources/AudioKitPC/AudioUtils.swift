import AVFoundation
import Accelerate

/// Audio processing utilities using Apple's Accelerate framework
public enum AudioUtils {
    
    /// Calculate RMS (Root Mean Square) of an audio buffer
    /// RMS is a measure of audio loudness - lower values indicate silence
    public static func calculateRMS(_ audioBuffer: AudioBuffer) -> Float {
        let bufferByteSize = Float(MemoryLayout<Float>.size)
        let bufferSize = Float(audioBuffer.mDataByteSize) / bufferByteSize
        
        guard bufferSize > 0,
              let buffer = audioBuffer.mData?.bindMemory(to: Float.self, capacity: Int(bufferSize)) else {
            return 0
        }
        
        var rms: Float = 0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(bufferSize))
        
        return rms
    }
    
    /// Calculate stereo RMS by averaging left and right channels
    public static func calculateStereoRMS(left: AudioBuffer, right: AudioBuffer) -> Float {
        let leftRMS = calculateRMS(left)
        let rightRMS = calculateRMS(right)
        return (leftRMS + rightRMS) / 2
    }
    
    /// Apply fade in or fade out to an audio buffer
    public static func fadeAudio(_ pcmBuffer: AVAudioPCMBuffer, fadeOut: Bool, channelCount: UInt32) {
        guard let floatData = pcmBuffer.floatChannelData else { return }
        
        let frameLength = Int(pcmBuffer.frameLength)
        let channels = Int(min(channelCount, pcmBuffer.format.channelCount))
        
        for channel in 0..<channels {
            let data = floatData[channel]
            performFade(fadeOut: fadeOut, length: vDSP_Length(frameLength), data: data)
        }
    }
    
    /// Apply a linear fade ramp to audio data
    private static func performFade(fadeOut: Bool, length: vDSP_Length, data: UnsafeMutablePointer<Float>) {
        var ramp = [Float](repeating: 0, count: Int(length))
        
        var startValue: Float = fadeOut ? 1.0 : 0.0
        var endValue: Float = fadeOut ? 0.0 : 1.0
        
        vDSP_vgen(&startValue, &endValue, &ramp, 1, length)
        vDSP_vmul(data, 1, ramp, 1, data, 1, length)
    }
    
    /// Normalize audio to a target peak level
    public static func normalizeAudio(_ pcmBuffer: AVAudioPCMBuffer, targetPeak: Float = 0.95) {
        guard let floatData = pcmBuffer.floatChannelData else { return }
        
        let frameLength = Int(pcmBuffer.frameLength)
        let channelCount = Int(pcmBuffer.format.channelCount)
        
        // Find current peak
        var maxPeak: Float = 0
        for channel in 0..<channelCount {
            var peak: Float = 0
            vDSP_maxmgv(floatData[channel], 1, &peak, vDSP_Length(frameLength))
            maxPeak = max(maxPeak, peak)
        }
        
        guard maxPeak > 0 else { return }
        
        // Calculate and apply gain
        var gain = targetPeak / maxPeak
        for channel in 0..<channelCount {
            vDSP_vsmul(floatData[channel], 1, &gain, floatData[channel], 1, vDSP_Length(frameLength))
        }
    }
    
    /// Calculate RMS from a PCM buffer
    public static func calculateBufferRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let floatData = buffer.floatChannelData else { return 0 }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        guard frameLength > 0 else { return 0 }
        
        var totalRMS: Float = 0
        
        for channel in 0..<channelCount {
            var rms: Float = 0
            vDSP_rmsqv(floatData[channel], 1, &rms, vDSP_Length(frameLength))
            totalRMS += rms
        }
        
        return totalRMS / Float(channelCount)
    }
}
