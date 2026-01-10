//
//  VixenAIApp.swift
//  VixenAI
//
//  Created by lgd on 2025/10/29.
//

import SwiftUI

@main
struct VixenAIApp: App {
    
    init() {
        // 初始化配置并打印内容
        _ = VixenConfigManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            HomeCanvas()
        }
    }
}
