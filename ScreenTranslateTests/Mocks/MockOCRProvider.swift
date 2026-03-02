import Foundation
import CoreGraphics
@testable import ScreenTranslate

final class MockOCRProvider: OCRProvider {
    nonisolated(unsafe) var shouldFail = false
    nonisolated(unsafe) var recognizedText = "Mock Text"
    nonisolated(unsafe) var detectedLanguage: Locale.Language? = Locale.Language(identifier: "en")
    nonisolated(unsafe) var confidence: Float = 0.95

    func recognize(image: CGImage) async throws -> OCRResult {
        if shouldFail { throw OCRError.noTextFound }
        return OCRResult(
            text: recognizedText,
            detectedLanguage: detectedLanguage,
            confidence: confidence
        )
    }
}
