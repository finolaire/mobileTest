//
//  SceneDelegate.swift
//  EnglishSentence
//
//  Created by apple2026 on 2026/2/10.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        // 冷启动：若由 Siri / 快捷指令拉起，Intent 可能已先 enqueue
        if OverlayDeepLinkRouter.shared.peek() != nil {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: OverlayDeepLinkRouter.didEnqueueNotification,
                    object: OverlayDeepLinkRouter.shared.peek()
                )
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 回前台时若仍有未消费的深链，再通知一次（页面可能刚就绪）
        if OverlayDeepLinkRouter.shared.peek() != nil {
            NotificationCenter.default.post(
                name: OverlayDeepLinkRouter.didEnqueueNotification,
                object: OverlayDeepLinkRouter.shared.peek()
            )
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
