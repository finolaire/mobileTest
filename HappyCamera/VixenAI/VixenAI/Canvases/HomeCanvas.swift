//
//  HomeCanvas.swift
//  VixenAI
//
//  首页视图
//

import SwiftUI

// MARK: - 渐变主题枚举
enum GradientTheme: String, CaseIterable {
    case defaultPurple = "默认紫"
    case oceanBlue = "海洋蓝"
    case sunsetOrange = "日落橙"
    case forestGreen = "森林绿"
    case nightPurple = "暗夜紫"
    case fireRed = "火焰红"
    // 深色主题
    case deepBlack = "深邃黑"
    case deepOcean = "深海蓝"
    case deepPurple = "深灰紫"
    case deepGreen = "深墨绿"
    case deepWine = "深酒红"
    case midnight = "午夜黑"
    
    var colors: [Color] {
        switch self {
        case .defaultPurple:
            return [
                Color(hex: "#6C5CE7").opacity(0.8),
                Color(hex: "#A29BFE").opacity(0.6),
                Color(hex: "#FD79A8").opacity(0.4)
            ]
        case .oceanBlue:
            return [
                Color(hex: "#0984E3").opacity(0.9),
                Color(hex: "#74B9FF").opacity(0.7),
                Color(hex: "#00CEC9").opacity(0.5)
            ]
        case .sunsetOrange:
            return [
                Color(hex: "#E17055").opacity(0.9),
                Color(hex: "#FDCB6E").opacity(0.7),
                Color(hex: "#FFA502").opacity(0.5)
            ]
        case .forestGreen:
            return [
                Color(hex: "#00B894").opacity(0.9),
                Color(hex: "#55EFC4").opacity(0.7),
                Color(hex: "#81ECEC").opacity(0.5)
            ]
        case .nightPurple:
            return [
                Color(hex: "#2D3436").opacity(0.95),
                Color(hex: "#6C5CE7").opacity(0.8),
                Color(hex: "#A29BFE").opacity(0.6)
            ]
        case .fireRed:
            return [
                Color(hex: "#D63031").opacity(0.9),
                Color(hex: "#FF7675").opacity(0.7),
                Color(hex: "#FD79A8").opacity(0.5)
            ]
        // 深色主题
        case .deepBlack:
            return [
                Color(hex: "#000000"),
                Color(hex: "#1a1a1a"),
                Color(hex: "#2d2d2d")
            ]
        case .deepOcean:
            return [
                Color(hex: "#001f3f"),
                Color(hex: "#003d7a"),
                Color(hex: "#005a99")
            ]
        case .deepPurple:
            return [
                Color(hex: "#1a1a2e"),
                Color(hex: "#16213e"),
                Color(hex: "#533483")
            ]
        case .deepGreen:
            return [
                Color(hex: "#0a3d2c"),
                Color(hex: "#0d5940"),
                Color(hex: "#107050")
            ]
        case .deepWine:
            return [
                Color(hex: "#3d0814"),
                Color(hex: "#5c0f1f"),
                Color(hex: "#7a1d2e")
            ]
        case .midnight:
            return [
                Color(hex: "#0c0c1e"),
                Color(hex: "#1a1a3e"),
                Color(hex: "#2d2d5e")
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .defaultPurple: return "sparkles"
        case .oceanBlue: return "drop.fill"
        case .sunsetOrange: return "sun.max.fill"
        case .forestGreen: return "leaf.fill"
        case .nightPurple: return "moon.stars.fill"
        case .fireRed: return "flame.fill"
        // 深色主题图标
        case .deepBlack: return "circle.fill"
        case .deepOcean: return "water.waves"
        case .deepPurple: return "moon.fill"
        case .deepGreen: return "tree.fill"
        case .deepWine: return "wineglass.fill"
        case .midnight: return "moon.zzz.fill"
        }
    }
}

struct HomeCanvas: View {
    
    @State private var selectedCamera: CarouselItem?
    @State private var currentTemplates: [TemplateModel] = []
    @State private var columnCount: Int = 3 // 默认3列
    @State private var showCaptureCanvas = false
    @State private var selectedTemplateImageName: String?
    @State private var selectedTemplatePic: TemplatePicItem?
    @State private var viewerImageItem: ViewerImageItem?
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = GradientTheme.deepPurple.rawValue // 保存主题设置，默认深灰紫
    @State private var showThemeSelector = false // 是否显示主题选择器
    
    // 计算属性：从保存的字符串恢复主题
    private var selectedTheme: GradientTheme {
        get {
            GradientTheme(rawValue: selectedThemeRawValue) ?? .deepPurple
        }
    }
    
    // 设置主题的方法
    private func setTheme(_ theme: GradientTheme) {
        selectedThemeRawValue = theme.rawValue
    }
    
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
    
    // 从Template获取图片项（默认使用pic_zh，如果为空则使用pic_en）
    private func getPicItems(from template: TemplateModel) -> [TemplatePicItem] {
        // 默认使用中文图片数组
        if let picZhArray = template.pic_zh, !picZhArray.isEmpty {
            return picZhArray.map { TemplatePicItem(from: $0) }
        }
        // 如果中文图片为空，使用英文图片
        if let picEnArray = template.pic_en, !picEnArray.isEmpty {
            return picEnArray.map { TemplatePicItem(from: $0) }
        }
        return []
    }
    
    // 判断系统是否使用中文
    private var isChinese: Bool {
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLanguage.hasPrefix("zh")
    }
    
    // 根据语言获取图片名称
    private func getImageName(for picItem: TemplatePicItem) -> String {
        return picItem.imageName
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变 - 使用选中的主题
                LinearGradient(
                    gradient: Gradient(colors: selectedTheme.colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: selectedTheme)
                
                VStack(spacing: 0) {
                    // 主题选择器
                    if showThemeSelector {
                        ThemeSelectorView(
                            selectedTheme: selectedTheme,
                            showThemeSelector: $showThemeSelector,
                            onThemeSelected: { theme in
                                setTheme(theme)
                            }
                        )
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
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
                                
                                HStack(spacing: 8) {
                                    // 主题选择按钮
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showThemeSelector.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: selectedTheme.icon)
                                                .font(.system(size: 16, weight: .medium))
                                            Text("主题")
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
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 15) {
                                ForEach(Array(currentTemplates.enumerated()), id: \.offset) { index, template in
                                    TemplateGroupView(
                                        groupTitle: template.group ?? "",
                                        pics: getPicItems(from: template),
                                        getImageName: getImageName,
                                        columnCount: $columnCount,
                                        onCameraButtonTapped: { picItem in
                                            // 处理相机按钮点击，进入拍摄页面
                                            let imageName = getImageName(for: picItem)
                                            print("🏠 [调试] 点击相机按钮，选中照片: \(imageName)")
                                            selectedTemplateImageName = imageName
                                            selectedTemplatePic = picItem
                                            showCaptureCanvas = true
                                        },
                                        onImagePreview: { imageName in
                                            // 处理图片点击，查看大图
                                            print("🏠 [调试] 查看大图: \(imageName)")
                                            viewerImageItem = ViewerImageItem(imageName: imageName)
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
        .fullScreenCover(item: $viewerImageItem) { item in
            ImageViewer(imageName: item.imageName)
        }
    }
}

// MARK: - 图片查看器数据结构（用于 fullScreenCover item 传值）
struct ViewerImageItem: Identifiable {
    let id = UUID()
    let imageName: String
}

// MARK: - 统一的图片项数据结构
struct TemplatePicItem {
    let imageName: String
    let cameraCode: Int
    let isLock: Bool
    
    init(from picZh: PicZhModel) {
        self.imageName = picZh.pic ?? ""
        self.cameraCode = picZh.cameraCode
        self.isLock = picZh.isLock
    }
    
    init(from picEn: PicEnModel) {
        self.imageName = picEn.pic_en ?? ""
        self.cameraCode = picEn.cameraCode
        self.isLock = picEn.isLock
    }
}

// MARK: - Template Group View
struct TemplateGroupView: View {
    let groupTitle: String
    let pics: [TemplatePicItem]
    let getImageName: (TemplatePicItem) -> String
    @Binding var columnCount: Int
    let onCameraButtonTapped: (TemplatePicItem) -> Void  // 相机按钮点击 - 进入拍摄
    let onImagePreview: (String) -> Void  // 图片点击 - 查看大图
    
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
                    ForEach(Array(pics.enumerated()), id: \.offset) { picIndex, picItem in
                        let imageName = getImageName(picItem)
                        let isLocked = picItem.isLock
                        
                        ZStack(alignment: .topTrailing) {
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
                            .onTapGesture {
                                // 点击图片查看大图
                                if UIImage(named: imageName) != nil {
                                    onImagePreview(imageName)
                                }
                            }
                            
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
                            
                            // 右上角相机按钮（未加锁时显示）
                            if !isLocked {
                                Button(action: {
                                    // 点击相机按钮进入拍摄页面
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    onCameraButtonTapped(picItem)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(6)
                            }
                        }
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
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

// MARK: - 主题选择器视图
struct ThemeSelectorView: View {
    let selectedTheme: GradientTheme
    @Binding var showThemeSelector: Bool
    let onThemeSelected: (GradientTheme) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题
            HStack {
                Text("选择主题背景")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showThemeSelector = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // 主题网格
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(GradientTheme.allCases, id: \.self) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        onSelect: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                onThemeSelected(theme)
                            }
                            // 添加触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 主题卡片
struct ThemeCard: View {
    let theme: GradientTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // 主题预览
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: theme.colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 选中标记
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 3)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    
                    // 主题图标
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: theme.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                )
                                .padding(6)
                        }
                    }
                }
                
                // 主题名称
                Text(theme.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct HomeCanvas_Previews: PreviewProvider {
    static var previews: some View {
        HomeCanvas()
    }
}

