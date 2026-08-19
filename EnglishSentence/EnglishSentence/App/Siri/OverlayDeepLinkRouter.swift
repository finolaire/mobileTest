//
//  OverlayDeepLinkRouter.swift
//  EnglishSentence
//
//  Siri 捷径 / 深链：打开护眼或睡眠遮罩页。
//

import Foundation

enum OverlayDeepLink: String {
    /// 眼保健操 → EyesOverlayViewController
    case eyes
    /// 睡眠 → SleepOverlayViewController
    case sleep
}

final class OverlayDeepLinkRouter {
    static let shared = OverlayDeepLinkRouter()
    static let didEnqueueNotification = Notification.Name("OverlayDeepLinkRouter.didEnqueue")

    private let lock = NSLock()
    private var pending: OverlayDeepLink?

    private init() {}

    func enqueue(_ link: OverlayDeepLink) {
        lock.lock()
        pending = link
        lock.unlock()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.didEnqueueNotification, object: link)
        }
    }

    /// 取出并清空待处理路由；无则返回 nil
    func consume() -> OverlayDeepLink? {
        lock.lock()
        defer { lock.unlock() }
        let value = pending
        pending = nil
        return value
    }

    /// 只读，不消费（用于页面尚未就绪时判断）
    func peek() -> OverlayDeepLink? {
        lock.lock()
        defer { lock.unlock() }
        return pending
    }
}
