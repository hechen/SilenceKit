import Foundation

/// Trim silence aggressiveness level
public enum TrimSilenceLevel: Int, CaseIterable, Sendable {
    case off = 0
    case mild = 1      // Conservative - only obvious silences
    case medium = 2    // Balanced
    case aggressive = 3 // Maximum trimming
    
    /// Minimum gap size in frames before trimming
    public var minGapSizeInFrames: Int {
        switch self {
        case .off: return 0
        case .mild: return 20
        case .medium: return 16
        case .aggressive: return 4
        }
    }
    
    /// Number of silent frames to keep at gap edges (for smooth transition)
    public var framesToReInsert: Int {
        switch self {
        case .off: return 0
        case .mild: return 14
        case .medium: return 12
        case .aggressive: return 0
        }
    }
    
    /// Minimum RMS threshold - below this is considered silence
    public var minRMS: Float {
        switch self {
        case .off: return 0
        case .mild: return 0.0055
        case .medium: return 0.00511
        case .aggressive: return 0.005
        }
    }
    
    public var displayName: String {
        switch self {
        case .off: return "Off"
        case .mild: return "Mild"
        case .medium: return "Medium"
        case .aggressive: return "Aggressive"
        }
    }
}
