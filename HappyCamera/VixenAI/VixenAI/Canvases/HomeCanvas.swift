//
//  VixenHomeCanvas.swift
//  VixenAI
//
//  首页视图
//

import SwiftUI

struct VixenHomeCanvas: View {
    
    // 从配置管理器获取拍摄模式数据
    private var captureModels: [VixenCarouselItem] {
        guard let config = VixenConfigManager.shared.cameraConfig?.CameraType else {
            return []
        }
        return config.map { type in
            VixenCarouselItem(
                imageName: type.pic ?? "",
                title: type.name ?? "未知模式"
            )
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    VixenColorConfig.primaryColor.opacity(0.8),
                    VixenColorConfig.secondaryColor.opacity(0.6),
                    VixenColorConfig.accentColor.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 3D 轮播选择器
                VixenCarouselSelector(items: captureModels) { selectedItem in
                    print("🏠 [调试] VixenHomeCanvas 选中模式: \(selectedItem.title)")
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview
struct VixenHomeCanvas_Previews: PreviewProvider {
    static var previews: some View {
        VixenHomeCanvas()
    }
}

