//
//  VixenAIApp.swift
//  VixenAI
//
//  Created by lgd on 2025/10/29.
//

import SwiftUI

@main
struct VixenAIApp: App {
    
    @StateObject private var router = AppRouter.shared
    
    init() {
        // 初始化配置并打印内容
        _ = VixenConfigManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navigationPath) {
                HomeCanvas()
                    .navigationDestination(for: AppRoute.self) { route in
                        // 根据路由返回对应视图
                        routeDestination(for: route)
                    }
            }
            .environmentObject(router)
        }
    }
    
    // MARK: - 路由视图映射
    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        // 未来在这里添加路由对应的视图
        // switch route {
        // case .settings:
        //     SettingsView()
        // case .albumList:
        //     AlbumListView()
        // case .albumDetail(let albumId):
        //     AlbumDetailView(albumId: albumId)
        // }
        EmptyView()
    }
}
