//
//  VixenHomePresenter.swift
//  VixenAI
//
//  首页视图模型
//

import SwiftUI
import Combine

class VixenHomePresenter: ObservableObject {
    
    // MARK: - Published 属性
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var userInfo: VixenUserSchema?
    @Published var recentImages: [VixenImageInfoSchema] = []
    
    // MARK: - Private 属性
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = VixenGatewayManager.shared
    private let storageManager = VixenStorageOperator.shared
    
    // MARK: - 初始化
    init() {
        loadCachedData()
    }
    
    // MARK: - 公开方法
    
    /// 加载缓存数据
    func loadCachedData() {
        // 从本地加载用户信息
        if let cachedUser = storageManager.getObject(VixenUserSchema.self, forKey: VixenStorageOperator.Keys.userName) {
            self.userInfo = cachedUser
        }
    }
    
    /// 刷新数据
    func refreshData() {
        isLoading = true
        
        // 示例：获取用户信息
        // 实际使用时需要传入真实的 userId
        // networkManager.request(.getUserInfo(userId: "123"), responseType: VixenUserSchema.self) { [weak self] result in
        //     DispatchQueue.main.async {
        //         self?.isLoading = false
        //         
        //         switch result {
        //         case .success(let user):
        //             self?.userInfo = user
        //             self?.storageManager.saveObject(user, forKey: VixenStorageOperator.Keys.userName)
        //         case .failure(let error):
        //             self?.showErrorMessage(error.description)
        //         }
        //     }
        // }
        
        // 模拟数据加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
        }
    }
    
    /// 上传图片
    func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showErrorMessage("图片处理失败")
            return
        }
        
        isLoading = true
        
        networkManager.uploadImage(imageData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let url):
                    print("图片上传成功: \(url)")
                    // TODO: 处理上传成功的逻辑
                case .failure(let error):
                    self?.showErrorMessage(error.description)
                }
            }
        }
    }
    
    /// 显示错误信息
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// 清除错误
    func clearError() {
        errorMessage = ""
        showError = false
    }
}

