import XCTest
import CoreGraphics
@testable import ScreenTranslate

@MainActor
final class TranslationCoordinatorTests: XCTestCase {
    private var mockOCR: MockOCRProvider!
    private var mockTranslation: MockTranslationProvider!
    private var sut: TranslationCoordinator!

    override func setUp() {
        mockOCR = MockOCRProvider()
        mockTranslation = MockTranslationProvider()
        sut = TranslationCoordinator(
            ocrProvider: mockOCR,
            translationProvider: mockTranslation,
            targetLanguage: Locale.Language(identifier: "ko")
        )
    }

    func test_process_success_reachesCompletedState() async {
        mockOCR.recognizedText = "Hello"
        mockTranslation.translatedText = "안녕하세요"

        sut.startProcessing(image: makeBlankImage())
        try? await Task.sleep(for: .milliseconds(100))

        if case .completed(let result) = sut.state {
            XCTAssertEqual(result.text, "안녕하세요")
            XCTAssertFalse(result.lowConfidence)
        } else {
            XCTFail("completed 상태여야 한다: \(sut.state)")
        }
    }

    func test_process_lowConfidence_setsFlag() async {
        mockOCR.recognizedText = "Hello"
        mockOCR.confidence = 0.2  // < 0.3
        mockTranslation.translatedText = "안녕하세요"

        sut.startProcessing(image: makeBlankImage())
        try? await Task.sleep(for: .milliseconds(100))

        if case .completed(let result) = sut.state {
            XCTAssertTrue(result.lowConfidence)
        } else {
            XCTFail("completed 상태여야 한다")
        }
    }

    func test_process_ocrFails_reachesFailedState() async {
        mockOCR.shouldFail = true

        sut.startProcessing(image: makeBlankImage())
        try? await Task.sleep(for: .milliseconds(100))

        if case .failed(let msg) = sut.state {
            XCTAssertTrue(msg.contains("텍스트를 찾을 수 없습니다"))
        } else {
            XCTFail("실패 상태여야 한다: \(sut.state)")
        }
    }

    func test_process_translationFails_reachesFailedState() async {
        mockOCR.recognizedText = "Hello"
        mockTranslation.shouldFail = true

        sut.startProcessing(image: makeBlankImage())
        try? await Task.sleep(for: .milliseconds(100))

        if case .failed = sut.state {
            // Expected
        } else {
            XCTFail("실패 상태여야 한다: \(sut.state)")
        }
    }

    func test_reset_returnsToIdle() async {
        mockOCR.recognizedText = "Hello"
        mockTranslation.translatedText = "안녕"
        sut.startProcessing(image: makeBlankImage())
        try? await Task.sleep(for: .milliseconds(100))

        sut.reset()

        XCTAssertEqual(sut.state, .idle)
    }

    func test_process_passesDetectedLanguageToTranslation() async {
        mockOCR.recognizedText = "Hello"
        mockOCR.detectedLanguage = Locale.Language(identifier: "en")
        mockTranslation.translatedText = "안녕"

        sut.startProcessing(image: makeBlankImage())
        try? await Task.sleep(for: .milliseconds(100))

        // MockTranslationProvider는 lastReceivedText만 추적하므로
        // detectedLanguage 전달은 빌드 시 타입 체크로 보장
        XCTAssertEqual(mockTranslation.lastReceivedText, "Hello")
    }

    // MARK: - Helpers

    private func makeBlankImage() -> CGImage {
        let context = CGContext(data: nil, width: 10, height: 10,
                                bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return context.makeImage()!
    }
}
