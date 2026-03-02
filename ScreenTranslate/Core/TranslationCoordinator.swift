import CoreGraphics
import Foundation
import Observation

/// OCR → Translation 데이터 파이프라인 상태 머신.
/// OCRProvider와 TranslationProvider를 주입받아 사용한다.
@Observable
final class TranslationCoordinator {
    var state: State = .idle

    /// H4: 진행 중인 Task 참조를 보관하여 ESC 취소를 지원한다.
    private var currentTask: Task<Void, Never>?

    nonisolated enum State: Equatable {
        case idle
        case recognizing
        case translating
        case completed(TranslationResult)
        case failed(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.recognizing, .recognizing), (.translating, .translating):
                return true
            case (.completed(let a), .completed(let b)):
                return a.text == b.text
            case (.failed(let a), .failed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    nonisolated struct TranslationResult: Sendable {
        let text: String
        let lowConfidence: Bool  // OCR 신뢰도가 낮은 경우
    }

    private let ocrProvider: OCRProvider
    private let translationProvider: TranslationProvider
    var targetLanguage: Locale.Language

    init(
        ocrProvider: OCRProvider,
        translationProvider: TranslationProvider,
        targetLanguage: Locale.Language = Locale.Language(identifier: "ko")
    ) {
        self.ocrProvider = ocrProvider
        self.translationProvider = translationProvider
        self.targetLanguage = targetLanguage
    }

    /// 이미지에서 텍스트를 인식하고 번역한다.
    /// H4: Task 참조를 보관하여 ESC 취소를 지원한다.
    /// C4: 각 단계 사이에서 state를 변경하여 UI가 중간 상태를 관찰할 수 있게 한다.
    func startProcessing(image: CGImage) {
        currentTask?.cancel()
        currentTask = Task {
            state = .recognizing

            do {
                let ocrResult = try await ocrProvider.recognize(image: image)
                try Task.checkCancellation()  // ESC 체크 포인트

                // C4: OCR 완료 후, 번역 호출 전에 state를 변경해야 UI가 "번역 중..." 표시
                state = .translating

                let translated = try await translationProvider.translate(
                    text: ocrResult.text,
                    from: ocrResult.detectedLanguage,
                    to: targetLanguage
                )
                try Task.checkCancellation()  // ESC 체크 포인트

                let result = TranslationResult(
                    text: translated,
                    lowConfidence: ocrResult.confidence < 0.3
                )
                state = .completed(result)
            } catch is CancellationError {
                state = .idle  // 조용히 취소
            } catch OCRError.noTextFound {
                state = .failed("선택한 영역에서 텍스트를 찾을 수 없습니다.")
            } catch TranslationError.languageNotSupported {
                state = .failed("이 언어 조합은 지원되지 않습니다.")
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    /// ESC 등으로 진행 중인 작업을 취소한다.
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
    }

    func reset() {
        cancel()
    }
}
