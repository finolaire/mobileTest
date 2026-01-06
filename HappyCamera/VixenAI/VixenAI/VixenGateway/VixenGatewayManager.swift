//
//  VixenGatewayManager.swift
//  VixenAI
//
//  网络请求管理器
//

import Foundation
import Moya
import Combine

// MARK: - 网络响应基类
struct VixenBaseResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let code: Int?
}

// MARK: - 网络错误
enum VixenNetworkError: Error {
    case invalidResponse
    case decodingError
    case serverError(String)
    case networkError(String)
    
    var description: String {
        switch self {
        case .invalidResponse:
            return "无效的响应"
        case .decodingError:
            return "数据解析失败"
        case .serverError(let message):
            return message
        case .networkError(let message):
            return message
        }
    }
}

// MARK: - 网络管理器
class VixenGatewayManager {
    
    static let shared = VixenGatewayManager()
    
    private let provider: MoyaProvider<VixenAPI>
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 配置网络日志插件
        let loggerPlugin = NetworkLoggerPlugin(configuration: .init(
            logOptions: [.requestBody, .successResponseBody, .errorResponseBody]
        ))
        
        provider = MoyaProvider<VixenAPI>(plugins: [loggerPlugin])
    }
    
    // MARK: - 通用请求方法
    
    /// 发起请求
    func request<T: Codable>(
        _ target: VixenAPI,
        responseType: T.Type,
        completion: @escaping (Result<T, VixenNetworkError>) -> Void
    ) {
        provider.request(target) { result in
            switch result {
            case .success(let response):
                do {
                    // 检查状态码
                    if response.statusCode >= 200 && response.statusCode < 300 {
                        let baseResponse = try JSONDecoder().decode(VixenBaseResponse<T>.self, from: response.data)
                        
                        if baseResponse.success, let data = baseResponse.data {
                            completion(.success(data))
                        } else {
                            completion(.failure(.serverError(baseResponse.message ?? "请求失败")))
                        }
                    } else {
                        completion(.failure(.serverError("服务器错误: \(response.statusCode)")))
                    }
                } catch {
                    print("解析错误: \(error)")
                    completion(.failure(.decodingError))
                }
                
            case .failure(let error):
                print("网络错误: \(error)")
                completion(.failure(.networkError(error.localizedDescription)))
            }
        }
    }
    
    /// 发起请求（Combine 方式）
    func requestPublisher<T: Codable>(
        _ target: VixenAPI,
        responseType: T.Type
    ) -> AnyPublisher<T, VixenNetworkError> {
        return Future<T, VixenNetworkError> { [weak self] promise in
            self?.request(target, responseType: responseType) { result in
                switch result {
                case .success(let data):
                    promise(.success(data))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 发起请求（async/await 方式）
    @available(iOS 13.0, *)
    func request<T: Codable>(
        _ target: VixenAPI,
        responseType: T.Type
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            request(target, responseType: responseType) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - 便捷方法扩展
extension VixenGatewayManager {
    
    /// 上传图片
    func uploadImage(
        _ imageData: Data,
        completion: @escaping (Result<String, VixenNetworkError>) -> Void
    ) {
        struct ImageUploadResponse: Codable {
            let url: String
        }
        
        request(.uploadImage(image: imageData), responseType: ImageUploadResponse.self) { result in
            switch result {
            case .success(let response):
                completion(.success(response.url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

