import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var packManager = LanguagePackManager()
    @State private var showDownloadAlert = false
    @State private var pendingDownloadCode: String?

    var body: some View {
        Form {
            Section(L10n.generalSection) {
                Picker(L10n.appLanguageLabel, selection: $settings.appLanguage) {
                    Text("English").tag("en")
                    Text("한국어").tag("ko")
                }
                .pickerStyle(.menu)
            }

            Section(L10n.translationSection) {
                Picker(L10n.sourceLanguageLabel, selection: $settings.sourceLanguageCode) {
                    Text(L10n.autoDetect).tag("auto")
                    Divider()
                    ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                        Label {
                            Text(lang.name)
                        } icon: {
                            sourceStatusIcon(for: lang.code)
                        }
                        .tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settings.sourceLanguageCode) { _, newValue in
                    if newValue != "auto" {
                        let status = packManager.sourceStatuses[newValue]
                        if status == .available {
                            pendingDownloadCode = newValue
                            showDownloadAlert = true
                        }
                    }
                    Task {
                        await packManager.refreshStatuses(sourceCode: newValue)
                    }
                }

                Picker(L10n.targetLanguageLabel, selection: $settings.targetLanguageCode) {
                    ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                        Label {
                            Text(lang.name)
                        } icon: {
                            statusIcon(for: lang.code)
                        }
                        .tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settings.targetLanguageCode) { _, newValue in
                    let status = packManager.statuses[newValue]
                    if status == .available {
                        pendingDownloadCode = newValue
                        showDownloadAlert = true
                    }
                    Task {
                        await packManager.refreshSourceStatuses(targetCode: newValue)
                    }
                }

                Picker(L10n.ocrEngine, selection: $settings.ocrProviderName) {
                    Text("Apple Vision").tag("Apple Vision")
                }
                .pickerStyle(.menu)
                .disabled(true)

                Picker(L10n.translationEngine, selection: $settings.translationProviderName) {
                    Text("Apple Translation (로컬)").tag("Apple Translation")
                }
                .pickerStyle(.menu)
                .disabled(true)
            }

            Section(L10n.shortcutSection) {
                KeyboardShortcuts.Recorder(L10n.translationShortcut, name: .translate)
            }
        }
        .formStyle(.grouped)
        .frame(
            minWidth: 450, idealWidth: 500, maxWidth: 600,
            minHeight: 320, idealHeight: 380, maxHeight: 500
        )
        .task {
            await packManager.refreshStatuses(sourceCode: settings.sourceLanguageCode)
            await packManager.refreshSourceStatuses(targetCode: settings.targetLanguageCode)
        }
        .alert(L10n.languagePackNotInstalled, isPresented: $showDownloadAlert) {
            Button(L10n.confirm) {}
                .keyboardShortcut(.defaultAction)
        } message: {
            if let code = pendingDownloadCode,
               let name = AppSettings.supportedLanguages.first(where: { $0.code == code })?.name {
                Text(L10n.languagePackMessage(name: name))
            }
        }
    }

    // MARK: - 상태 아이콘

    @ViewBuilder
    private func statusIcon(for code: String) -> some View {
        switch packManager.statuses[code] {
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .available:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.orange)
        case .checking:
            ProgressView()
                .controlSize(.small)
                .frame(width: 16, height: 16)
        case .unsupported:
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private func sourceStatusIcon(for code: String) -> some View {
        switch packManager.sourceStatuses[code] {
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .available:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.orange)
        case .checking:
            ProgressView()
                .controlSize(.small)
                .frame(width: 16, height: 16)
        case .unsupported:
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
        case .none:
            EmptyView()
        }
    }
}
