//
//  VixenCameraOperator.swift
//  VixenAI
//
//  相机管理器
//

import SwiftUI
import AVFoundation

class VixenCameraOperator: NSObject, ObservableObject {
    
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var cameraPermissionGranted = false
    @Published var isFlashOn = false
    @Published var isTorchOn = false  // 手电筒状态
    @Published var currentFilter: String = "CIPhotoEffectNone"  // 当前滤镜
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    // 保存取景框信息，用于精确裁剪
    var viewportRect: CGRect = .zero
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    weak var previewView: UIView?  // 新的预览视图引用
    
    // MARK: - 检查相机权限
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
        @unknown default:
            cameraPermissionGranted = false
        }
    }
    
    // MARK: - 设置相机
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: currentCameraPosition) else {
            session.commitConfiguration()
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            session.commitConfiguration()
        } catch {
            print("相机设置失败: \(error.localizedDescription)")
            session.commitConfiguration()
        }
    }
    
    // MARK: - 开始会话
    func startSession() {
        guard !isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }
    
    // MARK: - 停止会话
    func stopSession() {
        guard isSessionRunning else { return }
        
        // 停止会话前先关闭手电筒
        if isTorchOn {
            toggleTorch()
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    // MARK: - 拍照
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        // 设置闪光灯
        if let device = videoDeviceInput?.device, device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }
        
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                photoOutputConnection.videoRotationAngle = 0
            } else {
                photoOutputConnection.videoOrientation = .portrait
            }
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - 切换闪光灯
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    // MARK: - 切换摄像头
    func switchCamera() {
        guard let currentInput = videoDeviceInput else { return }
        
        // 切换摄像头前先关闭手电筒
        if isTorchOn {
            toggleTorch()
        }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: currentCameraPosition),
              let newVideoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(newVideoInput) {
            session.addInput(newVideoInput)
            videoDeviceInput = newVideoInput
        } else {
            session.addInput(currentInput)
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - 重置
    func reset() {
        capturedImage = nil
    }
    
    // MARK: - 点击对焦
    func focusAndExposure(at point: CGPoint) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // 设置对焦
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            // 设置曝光
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("对焦失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 调节亮度（曝光补偿）
    func setBrightness(_ value: Double) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // 曝光补偿范围通常是 -2.0 到 +2.0
            let exposureValue = Float(value * 4.0 - 2.0)  // 将 0-1 映射到 -2 到 +2
            let clampedValue = max(device.minExposureTargetBias, min(device.maxExposureTargetBias, exposureValue))
            
            device.setExposureTargetBias(clampedValue)
            
            device.unlockForConfiguration()
        } catch {
            print("调节亮度失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 调节缩放
    func setZoom(_ value: Double) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // 缩放范围：1.0 到最大缩放值（通常是 5-10 倍）
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)  // 限制最大5倍
            let zoomFactor = 1.0 + (maxZoom - 1.0) * CGFloat(value)
            
            device.videoZoomFactor = zoomFactor
            
            device.unlockForConfiguration()
        } catch {
            print("调节缩放失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 切换手电筒
    func toggleTorch() {
        guard let device = videoDeviceInput?.device else { return }
        
        // 检查设备是否支持手电筒
        guard device.hasTorch && device.isTorchAvailable else {
            print("设备不支持手电筒功能")
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if isTorchOn {
                // 关闭手电筒
                device.torchMode = .off
                isTorchOn = false
            } else {
                // 开启手电筒
                device.torchMode = .on
                isTorchOn = true
            }
            
            device.unlockForConfiguration()
        } catch {
            print("切换手电筒失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 简单直接的裁剪方法（所见即所得）
    func cropImageUsingPreviewLayer(_ image: UIImage) -> UIImage {
        print("🔍 开始裁剪：")
        print("  - 取景框信息: \(viewportRect)")
        
        guard viewportRect != .zero else {
            print("⚠️ 缺少取景框信息，返回原图")
            return image
        }
        
        // 获取屏幕尺寸
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("⚠️ 无法获取屏幕尺寸，返回原图")
            return image
        }
        
        let screenWidth = window.bounds.width
        let screenHeight = window.bounds.height
        
        print("📸 裁剪信息：")
        print("  - 照片尺寸: \(image.size.width) × \(image.size.height)")
        print("  - 屏幕尺寸: \(screenWidth) × \(screenHeight)")
        print("  - 取景框: \(viewportRect)")
        
        // 计算取景框在屏幕上的相对位置（比例）
        let topRatio = viewportRect.origin.y / screenHeight
        let leftRatio = viewportRect.origin.x / screenWidth
        let widthRatio = viewportRect.width / screenWidth
        let heightRatio = viewportRect.height / screenHeight
        
        print("  - 取景框比例: top=\(topRatio), left=\(leftRatio), width=\(widthRatio), height=\(heightRatio)")
        
        // 按相同比例裁剪照片
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        let cropX = leftRatio * imageWidth
        let cropY = topRatio * imageHeight
        let cropWidth = widthRatio * imageWidth
        let cropHeight = heightRatio * imageHeight
        
        print("  - 裁剪区域: x=\(cropX), y=\(cropY), w=\(cropWidth), h=\(cropHeight)")
        
        // 使用 UIImage 的裁剪方法（自动处理方向）
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        // 绘制裁剪后的图片
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(at: CGPoint(x: -cropX, y: -cropY))
        
        guard let croppedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("  ⚠️ 裁剪失败，返回原图")
            return image
        }
        
        print("  ✅ 裁剪成功！最终尺寸: \(croppedImage.size.width) × \(croppedImage.size.height)")
        
        return croppedImage
    }
    
    // MARK: - 水平翻转图片（用于前置摄像头镜像效果）
    private func flipImageHorizontally(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        // 创建翻转后的图片（水平镜像）
        let flippedImage = UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: .upMirrored  // 水平翻转
        )
        
        // 重新绘制以确保翻转生效
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        flippedImage.draw(in: CGRect(origin: .zero, size: image.size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    // MARK: - 应用滤镜
    func applyFilter(to image: UIImage, filterName: String) -> UIImage {
        // 如果是原图滤镜，直接返回
        if filterName == "CIPhotoEffectNone" {
            return image
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("⚠️ 无法创建CIImage")
            return image
        }
        
        // 创建滤镜
        guard let filter = CIFilter(name: filterName) else {
            print("⚠️ 无法创建滤镜: \(filterName)")
            return image
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        // 获取输出图像
        guard let outputImage = filter.outputImage else {
            print("⚠️ 滤镜处理失败")
            return image
        }
        
        // 转换为UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("⚠️ 无法创建CGImage")
            return image
        }
        
        let filteredImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        print("✅ 已应用滤镜: \(filterName)")
        
        return filteredImage
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension VixenCameraOperator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("拍照失败: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("无法转换图片数据")
            return
        }
        
        // 立即裁剪图片，确保展示的就是最终保存的
        var croppedImage = cropImageUsingPreviewLayer(image)
        
        // 如果是前置摄像头，进行水平翻转（镜像效果）
        if self.currentCameraPosition == .front {
            croppedImage = self.flipImageHorizontally(croppedImage)
            print("📸 前置摄像头，已进行水平翻转")
        }
        
        // 应用滤镜
        let filteredImage = self.applyFilter(to: croppedImage, filterName: self.currentFilter)
        
        DispatchQueue.main.async {
            self.capturedImage = filteredImage
        }
    }
}

