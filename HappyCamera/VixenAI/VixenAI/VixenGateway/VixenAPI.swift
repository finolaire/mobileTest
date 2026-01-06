//
//  VixenAPI.swift
//  VixenAI
//
//  网络 API 定义
//

import Foundation
import Moya

// MARK: - API 定义
enum VixenAPI {
    // 示例 API
    case uploadImage(image: Data)
    case getUserInfo(userId: String)
    case login(username: String, password: String)
}

// MARK: - Moya TargetType 实现
extension VixenAPI: TargetType {
    
    /// 基础 URL
    var baseURL: URL {
        return URL(string: "https://api.example.com")! // TODO: 替换为实际的 API 地址
    }
    
    /// 路径
    var path: String {
        switch self {
        case .uploadImage:
            return "/upload/image"
        case .getUserInfo(let userId):
            return "/user/\(userId)"
        case .login:
            return "/auth/login"
        }
    }
    
    /// 请求方法
    var method: Moya.Method {
        switch self {
        case .uploadImage, .login:
            return .post
        case .getUserInfo:
            return .get
        }
    }
    
    /// 请求任务
    var task: Task {
        switch self {
        case .uploadImage(let imageData):
            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "image",
                fileName: "photo.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])
            
        case .login(let username, let password):
            let parameters: [String: Any] = [
                "username": username,
                "password": password
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .getUserInfo:
            return .requestPlain
        }
    }
    
    /// 请求头
    var headers: [String: String]? {
        var headers = [String: String]()
        headers["Content-Type"] = "application/json"
        
        // TODO: 添加 token 或其他认证信息
        // if let token = UserDefaults.standard.string(forKey: "token") {
        //     headers["Authorization"] = "Bearer \(token)"
        // }
        
        return headers
    }
    
    /// 示例数据（用于测试）
    var sampleData: Data {
        switch self {
        case .uploadImage:
            return """
            {
                "success": true,
                "data": {
                    "url": "https://example.com/image.jpg"
                }
            }
            """.data(using: .utf8)!
            
        case .getUserInfo:
            return """
            {
                "success": true,
                "data": {
                    "id": "123",
                    "name": "测试用户",
                    "avatar": "https://example.com/avatar.jpg"
                }
            }
            """.data(using: .utf8)!
            
        case .login:
            return """
            {
                "success": true,
                "data": {
                    "token": "xxx",
                    "userId": "123"
                }
            }
            """.data(using: .utf8)!
        }
    }
}

