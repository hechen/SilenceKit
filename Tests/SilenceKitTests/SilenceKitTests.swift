import XCTest
@testable import SilenceKit

final class SilenceKitTests: XCTestCase {
    
    func testTrimSilenceLevels() {
        XCTAssertEqual(TrimSilenceLevel.off.minRMS, 0)
        XCTAssertEqual(TrimSilenceLevel.mild.minRMS, 0.0055)
        XCTAssertEqual(TrimSilenceLevel.medium.minRMS, 0.00511)
        XCTAssertEqual(TrimSilenceLevel.aggressive.minRMS, 0.005)
    }
    
    func testAudioProcessorInitialization() {
        let processor = AudioProcessor()
        XCTAssertFalse(processor.isPlaying)
        XCTAssertEqual(processor.currentTime, 0)
        XCTAssertEqual(processor.playbackSpeed, 1.0)
    }
}
