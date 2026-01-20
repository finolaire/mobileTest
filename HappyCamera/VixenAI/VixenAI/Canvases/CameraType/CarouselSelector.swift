//
//  CarouselSelector.swift
//  VixenAI
//
//  3D 轮播选择器
//

import SwiftUI

// MARK: - 轮播项数据模型
struct CarouselItem: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let title: String
    
    // 实现 Equatable 协议，基于 imageName 和 title 判断相等性
    static func == (lhs: CarouselItem, rhs: CarouselItem) -> Bool {
        return lhs.imageName == rhs.imageName && lhs.title == rhs.title
    }
}

// MARK: - 3D 轮播选择器
struct CarouselSelector: View {
    
    let items: [CarouselItem]
    let onItemSelected: (CarouselItem) -> Void
    let onCenterItemChanged: ((CarouselItem) -> Void)? // 新增：居中项变化回调
    
    init(items: [CarouselItem], onItemSelected: @escaping (CarouselItem) -> Void, onCenterItemChanged: ((CarouselItem) -> Void)? = nil) {
        self.items = items
        self.onItemSelected = onItemSelected
        self.onCenterItemChanged = onCenterItemChanged
    }
    
    @State private var currentIndex: Int = 0
    @State private var centerItemIndex: Int? = nil
    
    // 创建无限循环的数据源（复制多次以实现无限循环效果）
    private var infiniteItems: [(id: UUID, item: CarouselItem, originalIndex: Int)] {
        guard !items.isEmpty else { return [] }
        var result: [(id: UUID, item: CarouselItem, originalIndex: Int)] = []
        // 复制5次以确保无限循环
        for repeatIndex in 0..<5 {
            for (index, item) in items.enumerated() {
                result.append((id: UUID(), item: item, originalIndex: index))
            }
        }
        return result
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(infiniteItems.enumerated()), id: \.element.id) { globalIndex, data in
                            let item = data.item
                            let originalIndex = data.originalIndex
                            
                            GeometryReader { itemGeometry in
                                let centerX = itemGeometry.frame(in: .named("scroll")).midX
                                let screenCenterX = geometry.size.width / 2
                                let distance = abs(centerX - screenCenterX)
                                let isCenter = centerItemIndex == globalIndex
                                let size: CGFloat = isCenter ? 100 : 80
                                
                                carouselItemView(
                                    item: item,
                                    index: originalIndex,
                                    size: size,
                                    isCenter: isCenter
                                )
                                .onTapGesture {
                                    print("🎯 [调试] 用户点击了轮播项: \(item.title), 是否居中: \(isCenter)")
                                    
                                    // 添加震动反馈
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    if isCenter {
                                        // 居中的项：进入拍摄页面
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            print("🎯 [调试] 调用 onItemSelected: \(item.title)")
                                            onItemSelected(item)
                                        }
                                    } else {
                                        // 非居中的项：滚动到居中位置
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            proxy.scrollTo(globalIndex, anchor: .center)
                                        }
                                    }
                                }
                                .preference(
                                    key: ItemPositionPreferenceKey.self,
                                    value: [ItemPosition(index: globalIndex, originalIndex: originalIndex, distance: distance)]
                                )
                            }
                            .frame(width: 100)
                            .id(globalIndex)
                        }
                    }
                    .padding(.horizontal, geometry.size.width / 2 - 50)
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeometry.frame(in: .named("scroll")).minX
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ItemPositionPreferenceKey.self) { positions in
                    // 找到距离屏幕中心最近的项
                    if let closestItem = positions.min(by: { $0.distance < $1.distance }) {
                        if centerItemIndex != closestItem.index {
                            centerItemIndex = closestItem.index
                            // 通知居中项变化
                            if let onCenterItemChanged = onCenterItemChanged {
                                let originalIndex = closestItem.originalIndex
                                if originalIndex < items.count {
                                    onCenterItemChanged(items[originalIndex])
                                }
                            }
                        }
                    }
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    // 实现无限循环：当滚动到边界时，重置位置
                    let itemWidth: CGFloat = 100 + 15
                    let totalItems = infiniteItems.count
                    let totalWidth = CGFloat(totalItems) * itemWidth
                    let currentOffset = -offset
                    
                    // 如果滚动到开头附近，跳转到中间组
                    if currentOffset < itemWidth * 2 {
                        let targetIndex = items.count * 2
                        if targetIndex < totalItems {
                            DispatchQueue.main.async {
                                withAnimation(.none) {
                                    proxy.scrollTo(targetIndex, anchor: .center)
                                }
                            }
                        }
                    }
                    // 如果滚动到结尾附近，跳转到中间组
                    else if currentOffset > totalWidth - geometry.size.width - itemWidth * 2 {
                        let targetIndex = items.count * 3 - 1
                        if targetIndex < totalItems {
                            DispatchQueue.main.async {
                                withAnimation(.none) {
                                    proxy.scrollTo(targetIndex, anchor: .center)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    // 初始位置设置为中间组（第3组）
                    let startIndex = items.count * 2
                    if startIndex < infiniteItems.count {
                        centerItemIndex = startIndex
                        DispatchQueue.main.async {
                            proxy.scrollTo(startIndex, anchor: .center)
                            // 通知初始选中项
                            if let onCenterItemChanged = onCenterItemChanged, startIndex < infiniteItems.count {
                                let originalIndex = infiniteItems[startIndex].originalIndex
                                if originalIndex < items.count {
                                    onCenterItemChanged(items[originalIndex])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 轮播项视图
    @ViewBuilder
    private func carouselItemView(item: CarouselItem, index: Int, size: CGFloat, isCenter: Bool) -> some View {
        VStack(spacing: isCenter ? 10 : 6) {
            // 上方：正方形图片区域（1:1）
            if UIImage(named: item.imageName) != nil {
                // 显示真实图片 - 1:1正方形，不拉伸
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)  // 1:1比例，fit模式不拉伸
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: isCenter ? 12 : 8))
                    .shadow(color: .black.opacity(0.3), radius: isCenter ? 8 : 4, x: 0, y: isCenter ? 4 : 2)
            } else {
                // 没有图片时显示渐变占位 - 1:1正方形
                RoundedRectangle(cornerRadius: isCenter ? 12 : 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors(for: index)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.3), radius: isCenter ? 8 : 4, x: 0, y: isCenter ? 4 : 2)
                    .overlay(
                        Image(systemName: cameraIcon(for: index))
                            .font(.system(size: isCenter ? 40 : 30, weight: .light))
                            .foregroundColor(.white)
                    )
            }
            
            // 下方：文字信息
            Text(item.title)
                .font(.system(size: isCenter ? 14 : 11, weight: isCenter ? .semibold : .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                .lineLimit(1)
        }
        .frame(width: size)
        .scaleEffect(isCenter ? 1.0 : 0.8)
        .opacity(isCenter ? 1.0 : 0.7)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCenter)
    }
    
    // MARK: - 辅助方法
    
    private func gradientColors(for index: Int) -> [Color] {
        switch index {
        case 0:
            return [Color(hex: "#667eea"), Color(hex: "#764ba2")]
        case 1:
            return [Color(hex: "#f093fb"), Color(hex: "#f5576c")]
        case 2:
            return [Color(hex: "#4facfe"), Color(hex: "#00f2fe")]
        case 3:
            return [Color(hex: "#43e97b"), Color(hex: "#38f9d7")]
        default:
            return [Color.blue, Color.purple]
        }
    }
    
    private func cameraIcon(for index: Int) -> String {
        switch index {
        case 0:
            return "camera.fill"
        case 1:
            return "camera.circle.fill"
        case 2:
            return "camera.metering.matrix"
        case 3:
            return "camera.aperture"
        default:
            return "camera.fill"
        }
    }
}

// MARK: - ItemPosition PreferenceKey
struct ItemPosition: Equatable {
    let index: Int
    let originalIndex: Int
    let distance: CGFloat
}

struct ItemPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [ItemPosition] = []
    static func reduce(value: inout [ItemPosition], nextValue: () -> [ItemPosition]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - ScrollOffset PreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct CarouselSelector_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            CarouselSelector(
                items: [
                    CarouselItem(imageName: "v_01", title: "标准拍摄"),
                    CarouselItem(imageName: "v_02", title: "人像模式"),
                    CarouselItem(imageName: "v_03", title: "夜景模式"),
                    CarouselItem(imageName: "v_04", title: "卡通模式")
                ],
                onItemSelected: { item in
                    print("选中: \(item.imageName)")
                }
            )
        }
    }
}
