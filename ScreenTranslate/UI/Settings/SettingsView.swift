import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("번역") {
                Picker("원문 언어", selection: $settings.sourceLanguageCode) {
                    Text("자동 감지").tag("auto")
                    Divider()
                    ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)

                Picker("번역 결과 언어", selection: $settings.targetLanguageCode) {
                    ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)

                Picker("OCR 엔진", selection: $settings.ocrProviderName) {
                    Text("Apple Vision").tag("Apple Vision")
                }
                .pickerStyle(.menu)
                .disabled(true)  // v1에서는 단일 옵션

                Picker("번역 엔진", selection: $settings.translationProviderName) {
                    Text("Apple Translation (로컬)").tag("Apple Translation")
                }
                .pickerStyle(.menu)
                .disabled(true)  // v1에서는 단일 옵션
            }

            Section("단축키") {
                KeyboardShortcuts.Recorder("번역 단축키", name: .translate)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
    }
}
