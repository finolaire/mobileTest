//
//  OverlayAppIntents.swift
//  EnglishSentence
//
//  Siri / 快捷指令：
//  - 「打开兔子英语睡眠」→ SleepOverlayViewController
//  - 「打开兔子英语眼保健操」→ EyesOverlayViewController
//
//  说明：App Shortcuts 短语必须包含 \(.applicationName)（显示名「兔子英语」）。
//

import AppIntents
import Foundation

// MARK: - Intents

@available(iOS 16.0, *)
struct OpenSleepOverlayIntent: AppIntent {
    static var title: LocalizedStringResource = "兔子英语睡眠"
    static var description = IntentDescription("打开兔子英语睡眠页面")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        OverlayDeepLinkRouter.shared.enqueue(.sleep)
        return .result()
    }
}

@available(iOS 16.0, *)
struct OpenEyesOverlayIntent: AppIntent {
    static var title: LocalizedStringResource = "兔子眼保健操"
    static var description = IntentDescription("打开兔子眼保健操页面")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        OverlayDeepLinkRouter.shared.enqueue(.eyes)
        return .result()
    }
}

// MARK: - App Shortcuts（安装并首次打开 App 后，Siri 即可用）

@available(iOS 16.0, *)
struct EnglishSentenceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSleepOverlayIntent(),
            phrases: [
                "打开\(.applicationName)睡眠",
                "\(.applicationName)睡眠",
                "开始\(.applicationName)睡眠"
            ],
            systemImageName: "moon.zzz.fill"
        )
        AppShortcut(
            intent: OpenEyesOverlayIntent(),
            phrases: [
                "打开\(.applicationName)眼保健操",
                "\(.applicationName)眼保健操",
                "开始\(.applicationName)眼保健操"
            ],
            systemImageName: "eye.fill"
        )
    }
}
