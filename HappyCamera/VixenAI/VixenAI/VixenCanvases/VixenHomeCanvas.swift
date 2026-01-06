//
//  VixenHomeCanvas.swift
//  VixenAI
//
//  首页视图
//

import SwiftUI

struct VixenHomeCanvas: View {
    
    @State private var navigateToCaptureCanvas = false
    @State private var selectedMode: VixenCarouselItem?
    
    // 拍摄模式数据
    private let captureModels = [
        VixenCarouselItem(imageName: "v_01", title: "标准拍摄"),
        VixenCarouselItem(imageName: "v_02", title: "人像模式"),
        VixenCarouselItem(imageName: "v_03", title: "夜景模式"),
        VixenCarouselItem(imageName: "v_04", title: "卡通模式")
    ]
    
    var body: some View {
        NavigationView {
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
                    // Logo 或标题区域
                    VStack(spacing: 15) {
                        Image(systemName: "viewfinder.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        
                        Text(VixenLanguageConfig.VixenHomeCanvas.title)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(VixenLanguageConfig.VixenHomeCanvas.welcomeMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 80)
                    
                    Spacer()
                    
                    // 3D 轮播选择器
                    VixenCarouselSelector(items: captureModels) { selectedItem in
                        print("🏠 [调试] VixenHomeCanvas 收到选中项: \(selectedItem.title)")
                        selectedMode = selectedItem
                        print("🏠 [调试] selectedMode 已设置为: \(selectedMode?.title ?? "nil")")
                        
                        // 添加震动反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // 延迟一下再跳转，让用户看到选中效果
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            print("🏠 [调试] 准备跳转到拍照界面")
                            navigateToCaptureCanvas = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $navigateToCaptureCanvas) {
                VixenCaptureCanvas(captureMode: selectedMode)  // 传入选中的模式 ✅
            }
            .onChange(of: navigateToCaptureCanvas) { newValue in
                print("🔍 [调试] navigateToCaptureCanvas 改变为: \(newValue)")
                print("🔍 [调试] selectedMode 当前值: \(selectedMode?.title ?? "nil")")
                print("🔍 [调试] selectedMode imageName: \(selectedMode?.imageName ?? "nil")")
            }
            .onChange(of: selectedMode) { newValue in
                print("✅ [调试] selectedMode 被更新为: \(newValue?.title ?? "nil")")
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

