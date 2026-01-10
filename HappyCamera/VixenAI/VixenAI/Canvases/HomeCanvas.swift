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
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 15) {
                                ForEach(Array(currentTemplates.enumerated()), id: \.offset) { index, template in
                                    TemplateGroupView(
                                        groupTitle: template.group ?? "",
                                        pics: template.pic ?? [],
                                        getImageName: getImageName
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
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
    }
}

// MARK: - Template Group View
struct TemplateGroupView: View {
    let groupTitle: String
    let pics: [TemplatePicModel]
    let getImageName: (TemplatePicModel) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 组标题
            Text(groupTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                .padding(.horizontal, 10)
            
            // 图片列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(pics.enumerated()), id: \.offset) { picIndex, picModel in
                        let imageName = getImageName(picModel)
                        
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
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 10)
            }
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

