//
//  VixenLanguageConfig.swift
//  VixenAI
//
//  文本内容管理配置
//

import Foundation

struct VixenLanguageConfig {
    
    // MARK: - 首页相关文本
    struct VixenHomeCanvas {
        static let title = "Vixen AI"
        static let captureButton = "开始拍摄"
        static let welcomeMessage = "欢迎使用 Vixen AI"
    }
    
    // MARK: - 拍照界面相关文本
    struct VixenCaptureCanvas {
        static let title = "拍摄"
        static let captureAction = "拍照"
        static let retakeAction = "重拍"
        static let confirmAction = "确认"
        static let cancelAction = "取消"
        static let switchCamera = "切换镜头"
        static let cameraPermissionDenied = "相机权限未开启"
        static let cameraPermissionMessage = "请在设置中开启相机权限"
        static let openSettings = "前往设置"
        static let saving = "保存中..."
        static let saveSuccess = "照片已保存到相册"
        static let saveFailed = "保存失败"
        static let photoPermissionDenied = "相册权限未开启"
        static let photoPermissionMessage = "需要相册权限才能保存照片"
    }
}

