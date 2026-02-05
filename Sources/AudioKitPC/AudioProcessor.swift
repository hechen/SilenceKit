import AVFoundation
import Accelerate

/// Main audio processor with trim silence, speed control, and volume boost
public class AudioProcessor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isPlaying = false
    @Published public private(set) var currentTime: TimeInterval = 0
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var timeSavedByTrimming: TimeInterval = 0
    
    // MARK: - Audio Engine
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timePitchNode: AVAudioUnitTimePitch?
    private var audioFile: AVAudioFile?
    
    // MARK: - Settings
    
    public var trimSilenceLevel: TrimSilenceLevel = .off {
        didSet { updateTrimSettings() }
    }
    
    public var playbackSpeed: Float = 1.0 {
        didSet { timePitchNode?.rate = playbackSpeed }
    }
    
    public var volumeBoost: Float = 1.0 {
        didSet { playerNode?.volume = volumeBoost }
    }
    
    // MARK: - Trim Silence State
    
    private var minRMS: Float = 0.005
    private var minGapSizeInFrames = 3
    private var framesToReInsert = 1
    private let maxSilenceBuffer = 1000
    
    private var foundGap = false
    private var silenceBufferStack: [AVAudioPCMBuffer] = []
    
    // MARK: - Threading
    
    private let processingQueue = DispatchQueue(label: "com.audiokit.processing", qos: .userInitiated)
    private var isCancelled = false
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Load an audio file for processing
    public func loadFile(url: URL) throws {
        stop()
        
        audioFile = try AVAudioFile(forReading: url)
        duration = Double(audioFile!.length) / audioFile!.processingFormat.sampleRate
        currentTime = 0
        timeSavedByTrimming = 0
        
        setupAudioEngine()
    }
    
    /// Start playback
    public func play() {
        guard let playerNode = playerNode, audioFile != nil else { return }
        
        isCancelled = false
        
        processingQueue.async { [weak self] in
            self?.processAndScheduleAudio()
        }
        
        try? audioEngine?.start()
        playerNode.play()
        isPlaying = true
    }
    
    /// Pause playback
    public func pause() {
        playerNode?.pause()
        isPlaying = false
    }
    
    /// Stop playback
    public func stop() {
        isCancelled = true
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
        currentTime = 0
    }
    
    /// Seek to a specific time
    public func seek(to time: TimeInterval) {
        guard let audioFile = audioFile else { return }
        
        let wasPlaying = isPlaying
        stop()
        
        let framePosition = AVAudioFramePosition(time * audioFile.processingFormat.sampleRate)
        audioFile.framePosition = min(framePosition, audioFile.length)
        currentTime = time
        
        if wasPlaying {
            play()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        timePitchNode = AVAudioUnitTimePitch()
        
        guard let engine = audioEngine,
              let player = playerNode,
              let timePitch = timePitchNode,
              let file = audioFile else { return }
        
        timePitch.rate = playbackSpeed
        player.volume = volumeBoost
        
        engine.attach(player)
        engine.attach(timePitch)
        
        let format = file.processingFormat
        engine.connect(player, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
        
        engine.prepare()
    }
    
    private func updateTrimSettings() {
        minRMS = trimSilenceLevel.minRMS
        minGapSizeInFrames = trimSilenceLevel.minGapSizeInFrames
        framesToReInsert = trimSilenceLevel.framesToReInsert
    }
    
    private func processAndScheduleAudio() {
        guard let audioFile = audioFile,
              let playerNode = playerNode else { return }
        
        let bufferSize: AVAudioFrameCount = 4096
        let format = audioFile.processingFormat
        
        foundGap = false
        silenceBufferStack.removeAll()
        
        while !isCancelled && audioFile.framePosition < audioFile.length {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { break }
            
            do {
                try audioFile.read(into: buffer)
            } catch {
                break
            }
            
            if buffer.frameLength == 0 { break }
            
            // Update current time
            let currentPos = audioFile.framePosition
            let sampleRate = audioFile.processingFormat.sampleRate
            DispatchQueue.main.async { [weak self] in
                self?.currentTime = Double(currentPos) / sampleRate
            }
            
            // Process for silence trimming
            let buffersToPlay = processBuffer(buffer)
            
            // Schedule buffers for playback
            for processedBuffer in buffersToPlay {
                playerNode.scheduleBuffer(processedBuffer)
            }
        }
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) -> [AVAudioPCMBuffer] {
        guard trimSilenceLevel != .off else {
            return [buffer]
        }
        
        // Don't trim last 5 seconds
        if audioFile != nil {
            let timeLeft = duration - currentTime
            if timeLeft <= 5 {
                return [buffer]
            }
        }
        
        // Calculate RMS
        let rms = AudioUtils.calculateBufferRMS(buffer)
        
        var result: [AVAudioPCMBuffer] = []
        
        if rms > minRMS && !foundGap {
            // Normal audio - play it
            result.append(buffer)
        } else if rms < minRMS && !foundGap {
            // Start of a gap
            foundGap = true
            silenceBufferStack.append(buffer)
        } else if rms < minRMS && foundGap {
            // Inside a gap
            silenceBufferStack.append(buffer)
            
            // Safety limit
            if silenceBufferStack.count > maxSilenceBuffer {
                result.append(contentsOf: flushSilenceBuffer(endOfGap: false))
            }
        } else if rms > minRMS && foundGap {
            // End of gap
            foundGap = false
            result.append(contentsOf: flushSilenceBuffer(endOfGap: true))
            
            // Fade in the new buffer
            AudioUtils.fadeAudio(buffer, fadeOut: false, channelCount: buffer.format.channelCount)
            result.append(buffer)
        }
        
        return result
    }
    
    private func flushSilenceBuffer(endOfGap: Bool) -> [AVAudioPCMBuffer] {
        var result: [AVAudioPCMBuffer] = []
        
        if silenceBufferStack.count < minGapSizeInFrames {
            // Gap too small - play all saved buffers
            result.append(contentsOf: silenceBufferStack)
        } else if endOfGap {
            // Gap big enough - trim it
            let framesToKeep = min(framesToReInsert, silenceBufferStack.count)
            
            // Keep first few frames
            for i in 0..<framesToKeep {
                result.append(silenceBufferStack[i])
            }
            
            // Fade out the last kept frame
            if let lastBuffer = result.last {
                AudioUtils.fadeAudio(lastBuffer, fadeOut: true, channelCount: lastBuffer.format.channelCount)
            }
            
            // Calculate time saved
            let framesTrimmed = silenceBufferStack.count - framesToKeep
            if let file = audioFile, framesTrimmed > 0, let firstBuffer = silenceBufferStack.first {
                let secondsSaved = Double(framesTrimmed * Int(firstBuffer.frameLength)) / file.processingFormat.sampleRate
                DispatchQueue.main.async { [weak self] in
                    self?.timeSavedByTrimming += secondsSaved
                }
            }
        }
        
        silenceBufferStack.removeAll()
        return result
    }
}
