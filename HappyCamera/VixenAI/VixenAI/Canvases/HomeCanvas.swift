//
//  HomeCanvas.swift
//  VixenAI
//
//  首页视图
//

import SwiftUI

struct HomeCanvas: View {
    
    @State private var selectedCamera: CarouselItem?
    @State private var currentTemplates: [TemplateModel] = []
    @State private var columnCount: Int = 3 // 默认3列
    @State private var showCaptureCanvas = false
    @State private var selectedTemplateImageName: String?
    @State private var selectedTemplatePicModel: TemplatePicModel?
    
    // 从配置管理器获取拍摄模式数据
    private var captureModels: [CarouselItem] {
        guard let config = VixenConfigManager.shared.cameraConfig?.CameraType else {
            return []
        }
        return config.map { type in
            CarouselItem(
                imageName: type.pic ?? "",
                title: type.name ?? "未知模式"
            )
        }
    }
    
    // 获取当前选中相机的 Template 数据
    private func getTemplates(for cameraItem: CarouselItem?) -> [TemplateModel] {
        guard let cameraItem = cameraItem,
              let config = VixenConfigManager.shared.cameraConfig?.CameraType else {
            return []
        }
        
        // 找到对应的相机配置
        if let cameraType = config.first(where: { $0.name == cameraItem.title }) {
            return cameraType.Template ?? []
        }
        return []
    }
    
    // 判断系统是否使用中文
    private var isChinese: Bool {
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLanguage.hasPrefix("zh")
    }
    
    // 根据语言获取图片名称
    private func getImageName(for picModel: TemplatePicModel) -> String {
        if isChinese {
            return picModel.pic_zh ?? picModel.pic_en ?? ""
        } else {
            return picModel.pic_en ?? picModel.pic_zh ?? ""
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                    // 列表视图 - 显示当前选中相机的 Template 数据
                    if !currentTemplates.isEmpty {
                        VStack(spacing: 0) {
                            // 顶部标题栏（包含分列按钮）
                            HStack {
                                Text("模板列表")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                                
                                Spacer()
                                
                                // 分列按钮
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if columnCount >= 6 {
                                            columnCount = 1
                                        } else {
                                            columnCount += 1
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.grid.2x2")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("\(columnCount)列")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 15) {
                                ForEach(Array(currentTemplates.enumerated()), id: \.offset) { index, template in
                                    TemplateGroupView(
                                        groupTitle: template.group ?? "",
                                        pics: template.pic ?? [],
                                        getImageName: getImageName,
                                        columnCount: $columnCount,
                                        onPicSelected: { picModel in
                                            // 处理照片点击，进入拍摄页面
                                            let imageName = getImageName(for: picModel)
                                            print("🏠 [调试] 选中照片: \(imageName)")
                                            selectedTemplateImageName = imageName
                                            selectedTemplatePicModel = picModel
                                            showCaptureCanvas = true
                                        }
                                    )
                                }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                .padding(.bottom, 20)
                            }
                        }
                        .frame(maxHeight: geometry.size.height - 100 - geometry.safeAreaInsets.bottom - 20)
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // 3D 轮播选择器
                    CarouselSelector(
                        items: captureModels,
                        onItemSelected: { selectedItem in
                            print("🏠 [调试] HomeCanvas 选中模式: \(selectedItem.title)")
                        },
                        onCenterItemChanged: { centerItem in
                            selectedCamera = centerItem
                            currentTemplates = getTemplates(for: centerItem)
                            print("🏠 [调试] HomeCanvas 居中相机变化: \(centerItem.title), Template数量: \(currentTemplates.count)")
                        }
                    )
                    .frame(height: 100)
                    .padding(.horizontal, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        .fullScreenCover(isPresented: $showCaptureCanvas) {
            CaptureCanvas(
                captureMode: selectedCamera,
                templateImageName: selectedTemplateImageName
            )
        }
    }
}

// MARK: - Template Group View
struct TemplateGroupView: View {
    let groupTitle: String
    let pics: [TemplatePicModel]
    let getImageName: (TemplatePicModel) -> String
    @Binding var columnCount: Int
    let onPicSelected: (TemplatePicModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 组标题
            Text(groupTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            
            // 瀑布流图片布局
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount), spacing: 8) {
                    ForEach(Array(pics.enumerated()), id: \.offset) { picIndex, picModel in
                        let imageName = getImageName(picModel)
                        let isLocked = picModel.isLock
                        
                        ZStack {
                            // 图片
                            Group {
                                if UIImage(named: imageName) != nil {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 30))
                                                .foregroundColor(.white.opacity(0.5))
                                        )
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            // 加锁蒙版
                            if isLocked {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        .onTapGesture {
                            if !isLocked {
                                // 未加锁：进入拍摄页面
                                onPicSelected(picModel)
                            } else {
                                // 加锁：点击无效，可以添加提示
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(minHeight: 200) // 最小高度，内容会自动扩展
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview
struct HomeCanvas_Previews: PreviewProvider {
    static var previews: some View {
        HomeCanvas()
    }
}

