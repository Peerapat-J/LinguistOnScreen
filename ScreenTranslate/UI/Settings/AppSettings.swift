import Foundation
import Observation

/// @Observable + UserDefaults 연동.
/// computed property에서는 @Observable의 자동 tracking이 동작하지 않으므로
/// access(keyPath:) / withMutation(keyPath:) 를 수동으로 호출한다.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Source Language

    /// "auto"이면 자동 감지, 그 외에는 언어 코드
    var sourceLanguageCode: String {
        get {
            access(keyPath: \.sourceLanguageCode)
            return UserDefaults.standard.string(forKey: "com.screentranslate.sourceLanguageCode") ?? "auto"
        }
        set {
            withMutation(keyPath: \.sourceLanguageCode) {
                UserDefaults.standard.set(newValue, forKey: "com.screentranslate.sourceLanguageCode")
            }
        }
    }

    // MARK: - Target Language

    var targetLanguageCode: String {
        get {
            access(keyPath: \.targetLanguageCode)
            return UserDefaults.standard.string(forKey: "com.screentranslate.targetLanguageCode") ?? "ko"
        }
        set {
            withMutation(keyPath: \.targetLanguageCode) {
                UserDefaults.standard.set(newValue, forKey: "com.screentranslate.targetLanguageCode")
            }
        }
    }

    // MARK: - OCR Provider

    var ocrProviderName: String {
        get {
            access(keyPath: \.ocrProviderName)
            return UserDefaults.standard.string(forKey: "com.screentranslate.ocrProviderName") ?? "Apple Vision"
        }
        set {
            withMutation(keyPath: \.ocrProviderName) {
                UserDefaults.standard.set(newValue, forKey: "com.screentranslate.ocrProviderName")
            }
        }
    }

    // MARK: - Translation Provider

    var translationProviderName: String {
        get {
            access(keyPath: \.translationProviderName)
            return UserDefaults.standard.string(forKey: "com.screentranslate.translationProviderName") ?? "Apple Translation"
        }
        set {
            withMutation(keyPath: \.translationProviderName) {
                UserDefaults.standard.set(newValue, forKey: "com.screentranslate.translationProviderName")
            }
        }
    }

    // MARK: - Computed Helpers

    var sourceLanguage: Locale.Language? {
        sourceLanguageCode == "auto" ? nil : Locale.Language(identifier: sourceLanguageCode)
    }

    var targetLanguage: Locale.Language {
        Locale.Language(identifier: targetLanguageCode)
    }

    // MARK: - Supported Languages

    static let supportedLanguages: [(code: String, name: String)] = [
        ("ko", "한국어"),
        ("en", "English"),
        ("ja", "日本語"),
        ("zh-Hans", "中文(简体)"),
        ("zh-Hant", "中文(繁體)"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("es", "Español"),
        ("pt", "Português"),
        ("it", "Italiano"),
        ("ru", "Русский"),
        ("ar", "العربية"),
    ]
}
