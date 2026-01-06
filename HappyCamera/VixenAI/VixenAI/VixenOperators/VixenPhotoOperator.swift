//
//  VixenPhotoOperator.swift
//  VixenAI
//
//  照片相册管理器
//

import UIKit
import Photos

// MARK: - 照片保存结果
enum VixenPhotoSaveResult {
    case success
    case failure(Error)
    case permissionDenied
}

// MARK: - 照片管理器
class VixenPhotoOperator {
    
    static let shared = VixenPhotoOperator()
    
    private init() {}
    
    // MARK: - 检查相册权限
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            completion(true)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
            
        case .denied, .restricted:
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - 保存图片到相册
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (VixenPhotoSaveResult) -> Void) {
        // 先检查权限
        checkPhotoLibraryPermission { hasPermission in
            guard hasPermission else {
                completion(.permissionDenied)
                return
            }
            
            // 保存图片
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success)
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "VixenPhotoOperator", code: -1, userInfo: [NSLocalizedDescriptionKey: "保存失败"])))
                    }
                }
            }
        }
    }
    
    // MARK: - 保存图片到相册（带水印）
    func saveImageWithWatermark(_ image: UIImage, watermark: String? = nil, completion: @escaping (VixenPhotoSaveResult) -> Void) {
        var finalImage = image
        
        // 如果有水印，添加水印
        if let watermarkText = watermark {
            finalImage = image.addWatermark(text: watermarkText)
        }
        
        // 保存图片
        saveImageToPhotos(finalImage, completion: completion)
    }
    
    // MARK: - 保存多张图片
    func saveMultipleImages(_ images: [UIImage], completion: @escaping (Int, Int) -> Void) {
        checkPhotoLibraryPermission { [weak self] hasPermission in
            guard hasPermission else {
                completion(0, images.count)
                return
            }
            
            var successCount = 0
            var failureCount = 0
            let dispatchGroup = DispatchGroup()
            
            for image in images {
                dispatchGroup.enter()
                self?.saveImageToPhotos(image) { result in
                    switch result {
                    case .success:
                        successCount += 1
                    case .failure, .permissionDenied:
                        failureCount += 1
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(successCount, failureCount)
            }
        }
    }
    
    // MARK: - 打开系统设置
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}

