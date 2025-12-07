import SwiftUI
import AppKit

// MARK: - Onboarding View (Apple HIG Compliant)

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var hasPermission = false
    @State private var selectedMode: InputMode = .telex
    @State private var permissionTimer: Timer?

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                PermissionPage(
                    hasPermission: hasPermission,
                    onOpenSettings: openAccessibilitySettings
                )
                .tag(1)

                SetupPage(selectedMode: $selectedMode)
                    .tag(2)
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Bottom bar (Apple-style)
            HStack {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                // Navigation buttons
                HStack(spacing: 12) {
                    if currentPage > 0 {
                        Button("Quay lại") {
                            withAnimation { currentPage -= 1 }
                        }
                        .keyboardShortcut(.leftArrow, modifiers: [])
                    }

                    if currentPage == 0 {
                        Button("Tiếp tục") {
                            withAnimation {
                                currentPage = hasPermission ? 2 : 1
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                    } else if currentPage == 1 {
                        Button("Khởi động lại") {
                            restartApp()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .disabled(!hasPermission)
                    } else if currentPage == 2 {
                        Button("Hoàn tất") {
                            finishOnboarding()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 480, height: 400)
        .onAppear { startPermissionCheck() }
        .onDisappear { stopPermissionCheck() }
    }

    // MARK: - Actions

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func restartApp() {
        UserDefaults.standard.set(selectedMode.rawValue, forKey: SettingsKey.method)

        let path = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.5 && open \"\(path)\""]
        try? task.run()
        NSApp.terminate(nil)
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(selectedMode.rawValue, forKey: SettingsKey.method)
        UserDefaults.standard.set(true, forKey: SettingsKey.hasCompletedOnboarding)
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        NSApp.keyWindow?.close()
    }

    // MARK: - Permission Timer

    private func startPermissionCheck() {
        checkPermission()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkPermission()
        }
    }

    private func stopPermissionCheck() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    private func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon (Apple-style large icon)
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            // Title
            Text("Chào mừng đến với \(AppMetadata.name)")
                .font(.system(size: 24, weight: .bold))

            // Description
            Text(AppMetadata.tagline)
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Permission Page

private struct PermissionPage: View {
    let hasPermission: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            // Title
            Text("Cần quyền Accessibility")
                .font(.system(size: 24, weight: .bold))

            // Description
            Text("\(AppMetadata.name) cần quyền Accessibility để có thể gõ tiếng Việt trong các ứng dụng.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                PermissionStep(
                    number: 1,
                    text: "Mở System Settings → Privacy & Security → Accessibility",
                    isComplete: false
                )
                PermissionStep(
                    number: 2,
                    text: "Bật \(AppMetadata.name) trong danh sách",
                    isComplete: hasPermission
                )
                PermissionStep(
                    number: 3,
                    text: "Nhấn \"Khởi động lại\" để áp dụng",
                    isComplete: false
                )
            }
            .padding(.top, 8)

            // Open Settings button
            Button(action: onOpenSettings) {
                Label("Mở System Settings", systemImage: "gear")
            }
            .buttonStyle(.link)
            .padding(.top, 4)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct PermissionStep: View {
    let number: Int
    let text: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.secondary.opacity(0.2))
                    .frame(width: 22, height: 22)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(text)
                .font(.callout)
                .foregroundStyle(isComplete ? .secondary : .primary)
        }
    }
}

// MARK: - Setup Page

private struct SetupPage: View {
    @Binding var selectedMode: InputMode

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "keyboard")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            // Title
            Text("Chọn kiểu gõ")
                .font(.system(size: 24, weight: .bold))

            // Description
            Text("Bạn có thể thay đổi trong menu bất cứ lúc nào.")
                .font(.body)
                .foregroundStyle(.secondary)

            // Mode selection
            VStack(spacing: 8) {
                ForEach(InputMode.allCases, id: \.rawValue) { mode in
                    ModeOption(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onSelect: { selectedMode = mode }
                    )
                }
            }
            .frame(maxWidth: 300)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct ModeOption: View {
    let mode: InputMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.name)
                        .font(.headline)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary.opacity(0.4))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
