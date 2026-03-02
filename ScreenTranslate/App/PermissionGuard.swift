import AppKit
import SwiftUI

/// Screen Recording 권한 안내를 floating 팝업으로 표시한다.
/// 모달 NSAlert 대신 TranslationPopup과 동일한 비모달 팝업 패턴을 사용하여
/// 사용자가 기대하는 가벼운 인터랙션 흐름을 유지한다.
enum PermissionGuard {
    private static var permissionWindow: NSPanel?

    static func requestScreenRecordingPermission() {
        // 이미 표시 중이면 무시
        guard permissionWindow == nil else { return }

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false  // ARC 환경에서 close() 시 이중 해제 방지
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hidesOnDeactivate = false

        let permissionView = PermissionRequestView(
            onOpenSettings: {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            },
            onClose: {
                permissionWindow?.close()
                permissionWindow = nil
            }
        )

        panel.contentView = NSHostingView(rootView: permissionView)

        // 화면 중앙에 표시
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let popupWidth: CGFloat = 360
        let popupHeight: CGFloat = 180
        let origin = CGPoint(
            x: screen.frame.midX - popupWidth / 2,
            y: screen.frame.midY - popupHeight / 2
        )
        panel.setFrameOrigin(origin)
        panel.setContentSize(NSSize(width: popupWidth, height: popupHeight))
        panel.makeKeyAndOrderFront(nil)
        permissionWindow = panel
    }
}

/// 권한 요청 팝업 뷰.
struct PermissionRequestView: View {
    let onOpenSettings: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.dashed.badge.record")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(L10n.permissionRequired)
                .font(.headline)

            Text(L10n.permissionDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button(L10n.openSystemSettings) { onOpenSettings() }
                    .buttonStyle(.borderedProminent)

                Button(L10n.close) { onClose() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 12, y: 4)
    }
}
