//
//  VixenCarouselSelector.swift
//  VixenAI
//
//  3D 轮播选择器
//

import SwiftUI

// MARK: - 轮播项数据模型
struct VixenCarouselItem: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let title: String
    
    // 实现 Equatable 协议，基于 imageName 和 title 判断相等性
    static func == (lhs: VixenCarouselItem, rhs: VixenCarouselItem) -> Bool {
        return lhs.imageName == rhs.imageName && lhs.title == rhs.title
    }
}

// MARK: - 3D 轮播选择器
struct VixenCarouselSelector: View {
    
    let items: [VixenCarouselItem]
    let onItemSelected: (VixenCarouselItem) -> Void
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 30) {
            
            // TabView 轮播 - 固定大小无缩放
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    carouselItemView(item: item)
                        .tag(index)
                        .onTapGesture {
                            print("🎯 [调试] 用户点击了轮播项: \(item.title)")
                            
                            // 添加震动反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // 延迟跳转
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                print("🎯 [调试] 调用 onItemSelected: \(item.title)")
                                onItemSelected(item)
                            }
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
        }
    }
    
    // MARK: - 轮播项视图
    @ViewBuilder
    private func carouselItemView(item: VixenCarouselItem) -> some View {
        VStack(spacing: 20) {
            // 上方：正方形图片区域（1:1）
            if UIImage(named: item.imageName) != nil {
                // 显示真实图片 - 1:1正方形，不拉伸
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)  // 1:1比例，fit模式不拉伸
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            } else {
                // 没有图片时显示渐变占位 - 1:1正方形
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors(for: items.firstIndex(where: { $0.id == item.id }) ?? 0)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    .overlay(
                        Image(systemName: cameraIcon(for: items.firstIndex(where: { $0.id == item.id }) ?? 0))
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.white)
                    )
            }
            
            // 下方：文字信息
            Text(item.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Preview
struct VixenCarouselSelector_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VixenCarouselSelector(
                items: [
                    VixenCarouselItem(imageName: "v_01", title: "标准拍摄"),
                    VixenCarouselItem(imageName: "v_02", title: "人像模式"),
                    VixenCarouselItem(imageName: "v_03", title: "夜景模式"),
                    VixenCarouselItem(imageName: "v_04", title: "卡通模式")
                ],
                onItemSelected: { item in
                    print("选中: \(item.imageName)")
                }
            )
        }
    }
}
