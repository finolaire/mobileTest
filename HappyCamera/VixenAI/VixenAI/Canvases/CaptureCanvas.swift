//
//  CaptureCanvas.swift
//  VixenAI
//
//  拍照界面视图
//

import SwiftUI
import AVFoundation
import MetalKit

// MARK: - 滤镜数据模型
struct CameraFilter: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    
    static let filters: [CameraFilter] = [
        CameraFilter(name: "CIPhotoEffectNone", displayName: "原图"),
        CameraFilter(name: "CIPhotoEffectMono", displayName: "黑白"),
        CameraFilter(name: "CIPhotoEffectChrome", displayName: "铬黄"),
        CameraFilter(name: "CIPhotoEffectFade", displayName: "褪色"),
        CameraFilter(name: "CIPhotoEffectInstant", displayName: "怀旧"),
        CameraFilter(name: "CIPhotoEffectNoir", displayName: "黑白经典"),
        CameraFilter(name: "CIPhotoEffectProcess", displayName: "冲印"),
        CameraFilter(name: "CIPhotoEffectTonal", displayName: "色调"),
        CameraFilter(name: "CIPhotoEffectTransfer", displayName: "岁月")
    ]
}

struct CaptureCanvas: View {
    
    var captureMode: CarouselItem?
    var templateImageName: String? // 新增：模板图片名称（蒙版）
    
    @StateObject private var cameraOperator = VixenCameraOperator()
    @Environment(\.dismiss) private var dismiss
    @State private var showPermissionAlert = false
    @State private var isSaving = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    @State private var focusPoint: CGPoint?
    @State private var showFocusAnimation = false
    @State private var brightness: Double = 0.5  // 亮度 0-1
    @State private var zoomLevel: Double = 0.0   // 缩放 0-1
    @State private var timerMode: Int = 0        // 定时模式 0=关闭, 3, 5, 10
    @State private var isCountingDown = false    // 是否正在倒计时
    @State private var countdownValue = 0        // 倒计时数值
    @State private var selectedFilter: CameraFilter = CameraFilter.filters[0]  // 当前选中的滤镜
    
    var body: some View {
        ZStack {
            if cameraOperator.cameraPermissionGranted {
                if let capturedImage = cameraOperator.capturedImage {
                    // 显示已拍摄的照片
                    capturedImageView(capturedImage)
                } else {
                    // 显示相机预览
                    cameraPreviewView
                }
            } else {
                // 权限未授予提示
                permissionDeniedView
            }
        }
        .onAppear {
            print("📸 [调试] CaptureCanvas onAppear")
            print("📸 [调试] captureMode?.title: \(captureMode?.title ?? "nil")")
            print("📸 [调试] captureMode?.imageName: \(captureMode?.imageName ?? "nil")")
            print("📸 [调试] templateImageName: \(templateImageName ?? "nil")")
            
            cameraOperator.checkCameraPermission()
            cameraOperator.startSession()
            
            // 重置所有设置为默认值
            brightness = 0.5
            zoomLevel = 0.0
            timerMode = 0
            isCountingDown = false
            countdownValue = 0
            selectedFilter = CameraFilter.filters[0]  // 重置为原图滤镜
            
            cameraOperator.setBrightness(0.5)
            cameraOperator.setZoom(0.0)
            cameraOperator.isFlashOn = false
            cameraOperator.capturedImage = nil
            cameraOperator.currentFilter = "CIPhotoEffectNone"  // 重置滤镜为原图
            
            // 关闭手电筒（如果开着的话）
            if cameraOperator.isTorchOn {
                cameraOperator.toggleTorch()
            }
        }
        .onDisappear {
            // 关闭手电筒（避免退出后还开着）
            if cameraOperator.isTorchOn {
                cameraOperator.toggleTorch()
            }
            
            cameraOperator.stopSession()
            
            // 恢复默认设置
            cameraOperator.setBrightness(0.5)
            cameraOperator.setZoom(0.0)
            cameraOperator.isFlashOn = false
            cameraOperator.capturedImage = nil
        }
        .alert(VixenLanguageConfig.CaptureCanvas.cameraPermissionDenied, isPresented: $showPermissionAlert) {
            Button(VixenLanguageConfig.CaptureCanvas.cancelAction, role: .cancel) {
                dismiss()
            }
            Button(VixenLanguageConfig.CaptureCanvas.openSettings) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text(VixenLanguageConfig.CaptureCanvas.cameraPermissionMessage)
        }
        .alert(VixenLanguageConfig.CaptureCanvas.saveSuccess, isPresented: $showSaveSuccessAlert) {
            Button("好的", role: .cancel) {}
        }
        .alert(VixenLanguageConfig.CaptureCanvas.saveFailed, isPresented: $showSaveErrorAlert) {
            Button(VixenLanguageConfig.CaptureCanvas.cancelAction, role: .cancel) {}
            Button(VixenLanguageConfig.CaptureCanvas.openSettings) {
                VixenPhotoOperator.shared.openSettings()
            }
        } message: {
            Text(saveErrorMessage)
        }
    }
    
    // MARK: - 相机预览视图
    private var cameraPreviewView: some View {
        ZStack {
            // 全屏相机预览层（和系统相机一样）
            VixenCameraPreviewLayer(session: cameraOperator.session, cameraOperator: cameraOperator)
                .ignoresSafeArea()
            
            // 可视区域手势层（只在 3:4 区域内响应对焦）
            GeometryReader { geometry in
                let frameWidth: CGFloat = geometry.size.width
                let frameHeight: CGFloat = frameWidth * 4 / 3
                let topMargin = (geometry.size.height - frameHeight) / 2
                
                VStack(spacing: 0) {
                    // 上方透明区域（不响应点击）
                    Color.clear
                        .frame(height: topMargin)
                        .allowsHitTesting(false)
                    
                    // 中间可视区域（响应对焦手势）
                    Color.clear
                        .frame(height: frameHeight)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    // 转换为屏幕坐标
                                    let screenLocation = CGPoint(
                                        x: value.location.x,
                                        y: value.location.y + topMargin
                                    )
                                    handleFocusTap(at: screenLocation)
                                }
                        )
                    
                    // 下方透明区域（不响应点击）
                    Color.clear
                        .frame(minHeight: topMargin)
                        .allowsHitTesting(false)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            
            // 对焦动画指示器（在黑色遮罩层之前，会被遮罩遮住）
            if let point = focusPoint, showFocusAnimation {
                Circle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .position(point)
                    .opacity(showFocusAnimation ? 1 : 0)
                    .scaleEffect(showFocusAnimation ? 1 : 1.5)
                    .animation(.easeOut(duration: 0.3), value: showFocusAnimation)
            }
            
            // 黑色遮罩层 - 3:4 取景框（和系统相机一致）
            GeometryReader { geometry in
                // 标准 3:4 比例取景框（宽:高 = 3:4，和系统相机一致）
                let frameWidth: CGFloat = geometry.size.width
                let frameHeight: CGFloat = frameWidth * 4 / 3  // 3:4 比例（宽:高）
                let topMargin = (geometry.size.height - frameHeight) / 2
                
                VStack(spacing: 0) {
                    // 上方黑色遮罩 + 顶部控制按钮 🎯
                    ZStack(alignment: .bottom) {
                        Color.black
                            .frame(height: topMargin)
                            .allowsHitTesting(false)  // 背景不拦截触摸
                        
                        // 顶部控制栏（放在黑色遮罩上方，类似 UIKit 的 addSubview）
                        HStack {
                            // 返回按钮
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            
                            Spacer()
                            
                            // 定时拍照按钮
                            Button(action: {
                                cycleTimerMode()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 44, height: 44)
                                    
                                    if timerMode == 0 {
                                        Image(systemName: "timer")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(timerMode)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                            
                            // 手电筒按钮
                            Button(action: {
                                cameraOperator.toggleTorch()
                            }) {
                                Image(systemName: cameraOperator.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(cameraOperator.isTorchOn ? .yellow : .white)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            
                            // 闪光灯按钮
                            Button(action: {
                                cameraOperator.toggleFlash()
                            }) {
                                Image(systemName: cameraOperator.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(cameraOperator.isFlashOn ? .yellow : .white)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            
                            // 切换摄像头按钮
                            Button(action: {
                                cameraOperator.switchCamera()
                            }) {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 10)  // 距离遮罩层底部10px ✅
                    }
                    
                    // 中间可视区域（透明）+ 模板蒙版图片
                    ZStack {
                        Color.clear
                            .frame(height: frameHeight)
                            .allowsHitTesting(false)  // 不拦截触摸
                        
                        // 模板蒙版图片（如果提供了模板图片名称）
                        if let templateImageName = templateImageName, UIImage(named: templateImageName) != nil {
                            Image(templateImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: frameHeight)
                                .opacity(0.5) // 半透明蒙版
                                .allowsHitTesting(false)  // 不拦截触摸
                        }
                        // 人像模式辅助图片（只在人像模式下显示，且没有模板图片时）
                        else if captureMode?.title == "人像模式" {
                            Image("portrait")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: frameHeight)
                                .opacity(0.3)
                                .allowsHitTesting(false)  // 不拦截触摸
                        }
                    }
                    
                    // 下方黑色遮罩（延伸到底部）+ 滤镜选择器 + 拍照按钮 🎯
                    ZStack(alignment: .top) {
                        Color.black
                            .frame(maxHeight: .infinity)  // 填充剩余所有空间到底部
                            .ignoresSafeArea(edges: .bottom)  // 忽略底部安全区域，紧贴底部边缘 ✅
                            .allowsHitTesting(false)  // 背景不拦截触摸
                        
                        VStack(spacing: 20) {
                            // 滤镜选择器（横向滚动，选中自动居中）
                            GeometryReader { geometry in
                                ScrollViewReader { proxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            // 添加左侧占位，确保第一个item能居中
                                            Color.clear
                                                .frame(width: (geometry.size.width - 60) / 2)
                                            
                                            ForEach(CameraFilter.filters) { filter in
                                                FilterItem(
                                                    filter: filter,
                                                    isSelected: selectedFilter.id == filter.id
                                                )
                                                .id(filter.id)  // 设置id用于滚动定位
                                                .onTapGesture {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        selectedFilter = filter
                                                        cameraOperator.currentFilter = filter.name
                                                        // 滚动到选中的item，居中显示
                                                        proxy.scrollTo(filter.id, anchor: .center)
                                                    }
                                                }
                                            }
                                            
                                            // 添加右侧占位，确保最后一个item能居中
                                            Color.clear
                                                .frame(width: (geometry.size.width - 60) / 2)
                                        }
                                    }
                                    .frame(height: 80)
                                    .padding(.top, 0)
                                    .onAppear {
                                        // 初始化时滚动到默认选中的滤镜
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation {
                                                proxy.scrollTo(selectedFilter.id, anchor: .center)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 80)
                            
                            // 拍照按钮
                            Button(action: {
                                handleCaptureButton()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                    
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                }
                            }
                        }
                        .padding(.top, 10)  // 距离取景框底部 10px
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    // 保存取景框位置信息给相机操作器
                    let viewportRect = CGRect(x: 0, y: topMargin, width: frameWidth, height: frameHeight)
                    cameraOperator.viewportRect = viewportRect
                    print("📍 取景框信息已保存: \(viewportRect)")
                }
            }
            
            // 倒计时显示
            if isCountingDown && countdownValue > 0 {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 150, height: 150)
                    
                    Text("\(countdownValue)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isCountingDown ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdownValue)
            }
            
            // 左右滑动条
            HStack {
                // 左侧：亮度调节
                VStack {
                    Spacer()
                    VixenVerticalSlider(
                        value: $brightness,
                        minValue: 0,
                        maxValue: 1,
                        icon: "sun.max.fill"
                    )
                    .onChange(of: brightness) { newValue in
                        cameraOperator.setBrightness(newValue)
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // 右侧：缩放调节
                VStack {
                    Spacer()
                    VixenVerticalSlider(
                        value: $zoomLevel,
                        minValue: 0,
                        maxValue: 1,
                        icon: "magnifyingglass"
                    )
                    .onChange(of: zoomLevel) { newValue in
                        cameraOperator.setZoom(newValue)
                    }
                    Spacer()
                }
                .padding(.trailing, 20)
            }
        }
    }
    
    // MARK: - 已拍摄照片视图
    private func capturedImageView(_ image: UIImage) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 显示已裁剪的照片（3:4 比例，和预览布局一致）
            GeometryReader { geometry in
                let frameWidth = geometry.size.width
                let frameHeight = frameWidth * 4 / 3
                let topMargin = (geometry.size.height - frameHeight) / 2
                
                VStack(spacing: 0) {
                    // 上方黑色区域
                    Color.black
                        .frame(height: topMargin)
                    
                    // 中间照片区域
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: frameWidth, height: frameHeight)
                        .clipped()
                    
                    // 下方黑色区域（延伸到底部）
                    Color.black
                        .frame(minHeight: topMargin)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            }
            .allowsHitTesting(false)  // 不拦截触摸事件（和预览一致）
            
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    // 重拍按钮
                    Button(action: {
                        cameraOperator.reset()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 28))
                            Text(VixenLanguageConfig.CaptureCanvas.retakeAction)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.5))
                        )
                    }
                    
                    // 确认按钮
                    Button(action: {
                        savePhotoToAlbum(image)
                    }) {
                        VStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28))
                            }
                            Text(isSaving ? VixenLanguageConfig.CaptureCanvas.saving : VixenLanguageConfig.CaptureCanvas.confirmAction)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(VixenColorConfig.primaryColor)
                        )
                    }
                    .disabled(isSaving)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - 权限未授予视图
    private var permissionDeniedView: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(VixenColorConfig.secondaryTextColor)
            
            Text(VixenLanguageConfig.CaptureCanvas.cameraPermissionDenied)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(VixenColorConfig.primaryTextColor)
            
            Text(VixenLanguageConfig.CaptureCanvas.cameraPermissionMessage)
                .font(.system(size: 16))
                .foregroundColor(VixenColorConfig.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showPermissionAlert = true
            }) {
                Text(VixenLanguageConfig.CaptureCanvas.openSettings)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(VixenColorConfig.primaryColor)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VixenColorConfig.backgroundColor)
    }
    
    // MARK: - 保存照片到相册
    private func savePhotoToAlbum(_ image: UIImage) {
        isSaving = true
        
        // 确保保存的图片和显示的图片一致（使用 .fill 模式裁剪为精确的 3:4）
        let finalImage = cropImageToFillMode(image)
        
        VixenPhotoOperator.shared.saveImageToPhotos(finalImage) { [self] result in
            isSaving = false
            
            switch result {
            case .success:
                showSaveSuccessAlert = true
                // 延迟关闭界面
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
                
            case .failure(let error):
                saveErrorMessage = error.localizedDescription
                showSaveErrorAlert = true
                
            case .permissionDenied:
                saveErrorMessage = VixenLanguageConfig.CaptureCanvas.photoPermissionMessage
                showSaveErrorAlert = true
            }
        }
    }
    
    // MARK: - 裁剪图片为 .fill 模式（和显示一致）
    private func cropImageToFillMode(_ image: UIImage) -> UIImage {
        print("🔍 开始裁剪为 .fill 模式（3:4 比例）")
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        print("  - 原始尺寸: \(imageWidth) × \(imageHeight)")
        print("  - 原始比例: \(imageWidth / imageHeight)")
        
        // 目标比例 3:4（宽:高）
        let targetRatio: CGFloat = 3.0 / 4.0
        let currentRatio = imageWidth / imageHeight
        
        // .fill 模式：填满容器，多余部分裁剪
        // 如果图片比目标更宽，保留高度，裁剪宽度（左右居中）
        // 如果图片比目标更高，保留宽度，裁剪高度（上下居中）
        
        var cropX: CGFloat = 0
        var cropY: CGFloat = 0
        var cropWidth: CGFloat
        var cropHeight: CGFloat
        
        if currentRatio > targetRatio {
            // 图片比目标更宽（更扁），保留高度，裁剪两侧
            cropHeight = imageHeight
            cropWidth = cropHeight * targetRatio
            cropX = (imageWidth - cropWidth) / 2
            cropY = 0
        } else {
            // 图片比目标更高（更瘦），保留宽度，裁剪上下
            cropWidth = imageWidth
            cropHeight = cropWidth / targetRatio
            cropX = 0
            cropY = (imageHeight - cropHeight) / 2
        }
        
        print("  - 裁剪区域: x=\(cropX), y=\(cropY), w=\(cropWidth), h=\(cropHeight)")
        print("  - 裁剪后比例: \(cropWidth / cropHeight)")
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        // 使用 UIGraphics 绘制（自动处理图片方向）
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(at: CGPoint(x: -cropX, y: -cropY))
        
        guard let croppedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("  ⚠️ 裁剪失败，返回原图")
            return image
        }
        
        print("  ✅ 裁剪成功！最终尺寸: \(croppedImage.size.width) × \(croppedImage.size.height)")
        print("  - 最终比例: \(croppedImage.size.width / croppedImage.size.height)")
        
        return croppedImage
    }
    
    // MARK: - 裁剪图片为4:3比例（所见即所得）
    private func cropImageTo43Ratio(_ image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        print("📸 裁剪调试信息：")
        print("  - 原始图片尺寸: \(originalWidth) × \(originalHeight)")
        print("  - 原始比例: \(originalWidth / originalHeight)")
        
        // 获取屏幕尺寸
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("  ⚠️ 无法获取屏幕尺寸，返回原图")
            return image
        }
        
        let screenSize = window.bounds.size
        print("  - 屏幕尺寸: \(screenSize.width) × \(screenSize.height)")
        
        // 取景框尺寸（在屏幕上的显示）
        let viewportWidth = screenSize.width
        let viewportHeight = viewportWidth * 4.0 / 3.0
        let viewportRatio = viewportWidth / viewportHeight  // 0.75 (3:4)
        print("  - 取景框尺寸: \(viewportWidth) × \(viewportHeight)")
        print("  - 取景框比例: \(viewportRatio)")
        
        // 计算取景框在屏幕上的位置（垂直居中）
        let viewportTop = (screenSize.height - viewportHeight) / 2.0
        let viewportBottom = viewportTop + viewportHeight
        print("  - 取景框位置: top=\(viewportTop), bottom=\(viewportBottom)")
        
        // 计算相机预览在屏幕上的实际显示区域
        // 预览使用 resizeAspectFill，会放大以填充屏幕
        let imageRatio = originalWidth / originalHeight
        let screenRatio = screenSize.width / screenSize.height
        
        print("  - 图片比例: \(imageRatio)")
        print("  - 屏幕比例: \(screenRatio)")
        
        var previewWidth: CGFloat
        var previewHeight: CGFloat
        
        if imageRatio > screenRatio {
            // 图片相对屏幕更宽，高度填满屏幕，宽度超出
            previewHeight = screenSize.height
            previewWidth = previewHeight * imageRatio
            print("  - 预览模式: 高度填满，宽度超出")
        } else {
            // 图片相对屏幕更高，宽度填满屏幕，高度超出
            previewWidth = screenSize.width
            previewHeight = previewWidth / imageRatio
            print("  - 预览模式: 宽度填满，高度超出")
        }
        
        print("  - 预览显示尺寸: \(previewWidth) × \(previewHeight)")
        
        // 计算预览在屏幕上的偏移（居中显示）
        let previewOffsetX = (screenSize.width - previewWidth) / 2.0
        let previewOffsetY = (screenSize.height - previewHeight) / 2.0
        print("  - 预览偏移: x=\(previewOffsetX), y=\(previewOffsetY)")
        
        // 计算取景框在预览中的相对位置
        // 取景框左上角相对于预览的坐标
        let viewportXInPreview = 0 - previewOffsetX  // 取景框左边缘相对于预览
        let viewportYInPreview = viewportTop - previewOffsetY  // 取景框顶部相对于预览
        
        print("  - 取景框在预览中的位置: x=\(viewportXInPreview), y=\(viewportYInPreview)")
        
        // 计算缩放比例（屏幕预览 → 原始图片）
        let scale = originalWidth / previewWidth
        print("  - 缩放比例: \(scale)")
        
        // 将取景框坐标映射到原始图片
        let cropX = viewportXInPreview * scale
        let cropY = viewportYInPreview * scale
        let cropWidth = viewportWidth * scale
        let cropHeight = viewportHeight * scale
        
        print("  - 裁剪区域（原始坐标）: x=\(cropX), y=\(cropY)")
        print("  - 裁剪尺寸: w=\(cropWidth), h=\(cropHeight)")
        print("  - 裁剪后比例: \(cropWidth / cropHeight)")
        
        // 确保裁剪区域在图片范围内
        let safeX = max(0, min(cropX, originalWidth - cropWidth))
        let safeY = max(0, min(cropY, originalHeight - cropHeight))
        let safeWidth = min(cropWidth, originalWidth - safeX)
        let safeHeight = min(cropHeight, originalHeight - safeY)
        
        let cropRect = CGRect(x: safeX, y: safeY, width: safeWidth, height: safeHeight)
        
        print("  - 安全裁剪区域: x=\(safeX), y=\(safeY), w=\(safeWidth), h=\(safeHeight)")
        
        // 裁剪图片
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("  ⚠️ 裁剪失败，返回原图")
            return image
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        print("  ✅ 裁剪成功，最终尺寸: \(croppedImage.size.width) × \(croppedImage.size.height)")
        
        return croppedImage
    }
    
    // MARK: - 获取遮罩颜色
    private func getMaskColor() -> Color {
        // 非拍摄区域使用纯黑色不透明
        return Color.black
    }
    
    // MARK: - 处理对焦点击
    private func handleFocusTap(at location: CGPoint) {
        // 保存点击位置用于显示动画
        focusPoint = location
        
        // 显示对焦动画
        withAnimation {
            showFocusAnimation = true
        }
        
        // 0.5秒后隐藏动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showFocusAnimation = false
            }
        }
        
        // 转换坐标到相机坐标系统 (0-1范围)
        // 需要获取屏幕尺寸
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let screenSize = window.bounds.size
        let x = location.x / screenSize.width
        let y = location.y / screenSize.height
        
        // 相机坐标系统需要翻转Y轴
        let cameraPoint = CGPoint(x: x, y: y)
        
        // 调用相机对焦
        cameraOperator.focusAndExposure(at: cameraPoint)
    }
    
    // MARK: - 切换定时模式
    private func cycleTimerMode() {
        let modes = [0, 3, 5, 10]
        if let currentIndex = modes.firstIndex(of: timerMode) {
            let nextIndex = (currentIndex + 1) % modes.count
            timerMode = modes[nextIndex]
        }
    }
    
    // MARK: - 处理拍照按钮
    private func handleCaptureButton() {
        if timerMode == 0 {
            // 无定时，直接拍照
            cameraOperator.capturePhoto()
        } else {
            // 启动倒计时
            startCountdown()
        }
    }
    
    // MARK: - 启动倒计时
    private func startCountdown() {
        guard !isCountingDown else { return }
        
        isCountingDown = true
        countdownValue = timerMode
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                timer.invalidate()
                isCountingDown = false
                countdownValue = 0
                // 拍照
                cameraOperator.capturePhoto()
            }
        }
    }
}

// MARK: - 相机预览层（支持实时滤镜）
struct VixenCameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    @ObservedObject var cameraOperator: VixenCameraOperator
    
    func makeUIView(context: Context) -> FilteredPreviewView {
        print("📹 [调试] makeUIView 被调用 - 创建新的 FilteredPreviewView")
        print("📹 [调试] session 存在: \(session != nil)")
        print("📹 [调试] 当前滤镜: \(cameraOperator.currentFilter)")
        
        let view = FilteredPreviewView()
        view.backgroundColor = .black
        
        // 保存视图引用到操作器
        cameraOperator.previewView = view
        
        // 设置会话和滤镜
        view.session = session
        view.filterName = cameraOperator.currentFilter
        
        print("📹 实时滤镜预览层已创建")
        
        return view
    }
    
    func updateUIView(_ uiView: FilteredPreviewView, context: Context) {
        print("📹 [调试] updateUIView 被调用，当前滤镜: \(cameraOperator.currentFilter)")
        
        // 确保会话正确设置（重拍时可能需要）
        if uiView.session == nil {
            print("⚠️ [调试] session 为 nil，重新设置")
            uiView.session = session
        }
        
        // 更新滤镜
        uiView.filterName = cameraOperator.currentFilter
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
    }
}

// MARK: - 支持滤镜的预览视图
class FilteredPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            setupPreviewLayer()
        }
    }
    
    var filterName: String = "CIPhotoEffectNone" {
        didSet {
            updateFilter()
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    // 使用 GPU 加速的 CIContext，性能更好
    private lazy var ciContext: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device)
        }
        return CIContext()
    }()
    private var filterView: UIImageView?
    private var isProcessingEnabled = false  // 控制是否处理视频帧
    
    private func setupPreviewLayer() {
        print("🔧 [调试] setupPreviewLayer 被调用")
        guard let session = session else {
            print("⚠️ [调试] session 为 nil，无法设置预览层")
            return
        }
        
        print("✅ [调试] session 存在，开始设置组件")
        
        // 🚀 优化策略：立即创建预览层（同步），videoOutput 配置异步
        // 1. 立即创建预览层（让用户立刻看到画面）⚡
        setupPreviewLayerOnly(session)
        
        // 2. 创建滤镜视图（同步，很快）⚡
        setupFilterView()
        
        // 3. 立即显示正确的预览（原图或滤镜）⚡
        let needsFilter = filterName != "CIPhotoEffectNone"
        previewLayer?.isHidden = needsFilter
        filterView?.isHidden = !needsFilter
        print("⚡ [调试] 立即显示 \(needsFilter ? "滤镜视图" : "原图预览")")
        
        // 4. 只在需要滤镜时才异步配置 videoOutput（性能优化）
        if needsFilter {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                self.setupVideoOutputIfNeeded(session)
                
                // 配置完成后启用帧处理
                DispatchQueue.main.async {
                    self.isProcessingEnabled = true
                    print("✅ [调试] 滤镜处理已启用")
                }
            }
        } else {
            print("ℹ️ [调试] 原图模式，跳过 videoOutput 配置")
        }
    }
    
    // 🚀 优化1：立即创建预览层（同步，< 10ms）
    private func setupPreviewLayerOnly(_ session: AVCaptureSession) {
        if previewLayer == nil {
            print("⚡ [调试] 立即创建 previewLayer（同步）")
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = bounds
            self.layer.insertSublayer(layer, at: 0)
            previewLayer = layer
            print("✅ [调试] previewLayer 创建完成，立即显示画面")
        } else {
            print("♻️ [调试] previewLayer 已存在")
        }
    }
    
    // 🚀 优化2：创建滤镜视图（同步，< 5ms）
    private func setupFilterView() {
        if filterView == nil {
            print("⚡ [调试] 立即创建 filterView（同步）")
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.frame = bounds
            imageView.isHidden = true  // 默认隐藏
            addSubview(imageView)
            filterView = imageView
            print("✅ [调试] filterView 创建完成")
        } else {
            print("♻️ [调试] filterView 已存在")
        }
    }
    
    // 🚀 优化3：异步配置 videoOutput（后台线程，不阻塞UI）
    private func setupVideoOutputIfNeeded(_ session: AVCaptureSession) {
        if videoOutput == nil {
            print("⚡ [调试] 异步配置 videoOutput")
            
            // 🚀 性能优化：使用 beginConfiguration/commitConfiguration 批量处理
            session.beginConfiguration()
            
            // 🔧 重要：先移除 session 中可能存在的旧 videoOutput（重拍场景）
            let existingOutputs = session.outputs.filter { $0 is AVCaptureVideoDataOutput }
            if !existingOutputs.isEmpty {
                print("🗑️ [调试] 移除 \(existingOutputs.count) 个旧的 videoOutput")
                for existingOutput in existingOutputs {
                    session.removeOutput(existingOutput)
                }
            }
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true  // 丢弃延迟帧，保持流畅
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue", qos: .userInteractive))
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                videoOutput = output
                print("✅ [调试] videoOutput 已添加到 session")
                
                // 设置视频方向为竖屏
                if let connection = output.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                        print("✅ [调试] 视频方向已设置为竖屏")
                    }
                }
            } else {
                print("❌ [调试] 无法添加 videoOutput 到 session")
            }
            
            // 🚀 提交配置（批量生效，减少卡顿）
            session.commitConfiguration()
            print("⚡ [调试] videoOutput 配置完成")
        } else {
            print("♻️ [调试] videoOutput 已存在，无需重新配置")
        }
    }
    
    // 切换显示模式（无卡顿）
    private func updateDisplayMode() {
        let useFilter = filterName != "CIPhotoEffectNone"
        
        print("🎨 [调试] updateDisplayMode - 当前滤镜: \(filterName), 使用滤镜视图: \(useFilter)")
        print("🎨 [调试] previewLayer 存在: \(previewLayer != nil), filterView 存在: \(filterView != nil)")
        
        // 切换预览层和滤镜视图的可见性
        previewLayer?.isHidden = useFilter
        filterView?.isHidden = !useFilter
        
        // 控制是否处理视频帧
        isProcessingEnabled = useFilter
        
        print("🎨 [调试] 设置 isProcessingEnabled = \(isProcessingEnabled)")
        
        // 如果切换到原图，清空滤镜视图（释放内存）
        if !useFilter {
            filterView?.image = nil
        }
    }
    
    private func updateFilter() {
        let needsFilter = filterName != "CIPhotoEffectNone"
        
        print("🔄 [调试] updateFilter 被调用，需要滤镜: \(needsFilter)")
        
        // 如果切换到滤镜模式，但 videoOutput 还没配置，立即配置
        if needsFilter && videoOutput == nil {
            print("⚠️ [调试] 需要滤镜但 videoOutput 未配置，立即配置")
            guard let session = session else {
                print("❌ [调试] session 为 nil，无法配置 videoOutput")
                return
            }
            
            // 异步配置 videoOutput（不阻塞UI）
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                self.setupVideoOutputIfNeeded(session)
                
                // 配置完成后切换显示模式并启用帧处理
                DispatchQueue.main.async {
                    self.updateDisplayMode()
                    print("✅ [调试] videoOutput 配置完成，滤镜已启用")
                }
            }
        } else {
            // videoOutput 已配置，或者不需要滤镜，直接切换显示模式
            updateDisplayMode()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        filterView?.frame = bounds
    }
}

// MARK: - 视频帧处理
extension FilteredPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 如果不需要处理滤镜，直接返回（避免无用计算）
        guard isProcessingEnabled else { return }
        guard filterName != "CIPhotoEffectNone" else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // 应用滤镜
        guard let filter = CIFilter(name: filterName) else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage else { return }
        
        // 使用 GPU 加速转换（更快）
        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // 更新UI（批量更新，减少主线程压力）
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isProcessingEnabled else { return }
            self.filterView?.image = uiImage
        }
    }
}

// MARK: - 滤镜选项视图
struct FilterItem: View {
    let filter: CameraFilter
    let isSelected: Bool
    
    var body: some View {
        // 带圆角的方形，文字在内部
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .frame(width: 60, height: 60)
            .overlay(
                Text(filter.displayName)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .yellow : .white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.3), lineWidth: isSelected ? 2.5 : 1.5)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
struct CaptureCanvas_Previews: PreviewProvider {
    static var previews: some View {
        CaptureCanvas()
    }
}

#Preview {
    CaptureCanvas()
}
