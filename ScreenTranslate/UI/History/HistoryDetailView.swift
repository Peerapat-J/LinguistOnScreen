import SwiftUI

struct HistoryDetailView: View {
    let record: TranslationRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 번역문 섹션
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.translatedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let translated = record.translatedText {
                        Text(translated)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let error = record.errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                // 원문 섹션
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.originalText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.sourceText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // 메타 정보
                HStack {
                    if let sourceLang = record.sourceLanguageCode {
                        Text(languageName(for: sourceLang))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(languageName(for: record.targetLanguageCode))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(L10n.smartTimestamp(for: record.timestamp))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // 액션 버튼
                HStack(spacing: 12) {
                    if let translated = record.translatedText {
                        Button(L10n.copyTranslation) {
                            copyToClipboard(translated)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if !record.sourceText.isEmpty {
                        Button(L10n.copyOriginal) {
                            copyToClipboard(record.sourceText)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(20)
        }
    }

    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
