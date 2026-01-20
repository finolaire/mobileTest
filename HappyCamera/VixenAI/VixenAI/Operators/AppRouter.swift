//
//  AppRouter.swift
//  VixenAI
//
//  应用路由管理 - 管理 NavigationStack 的导航状态
//

import SwiftUI

// MARK: - 路由枚举
enum AppRoute: Hashable {
    // 未来可以在这里添加需要 push 的页面
    // case settings
    // case albumList
    // case albumDetail(albumId: String)
}

// MARK: - 路由管理器
@MainActor
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    
    @Published var navigationPath = NavigationPath()
    
    private init() {}
    
    // MARK: - 导航方法
    
    /// 导航到指定页面
    func navigate(to route: AppRoute) {
        navigationPath.append(route)
    }
    
    /// 返回上一页
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// 返回根视图
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    /// 返回指定层数
    func goBack(steps: Int) {
        let count = min(steps, navigationPath.count)
        navigationPath.removeLast(count)
    }
}
