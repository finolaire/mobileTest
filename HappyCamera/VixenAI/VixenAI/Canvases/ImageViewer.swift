//
//  ImageViewer.swift
//  VixenAI
//
//  图片查看器 - 支持双指缩放、单指拖动
//

import SwiftUI

struct ImageViewer: View {
    let imageName: String
    @Environment(\.dismiss) private var dismiss
    
    // 缩放相关状态
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // 拖动相关状态
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // 最小和最大缩放比例
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 黑色背景
                Color.black.ignoresSafeArea()
                
                // 图片内容
                imageContent
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(combinedGesture(in: geometry))
                    .onTapGesture(count: 2) {
                        // 双击缩放
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if scale > 1.0 {
                                // 缩小到原始大小
                                scale = 1.0
                                offset = .zero
                            } else {
                                // 放大到2倍
                                scale = 2.0
                            }
                            lastScale = scale
                            lastOffset = offset
                        }
                    }
                
                // 关闭按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 50)
                    }
                    Spacer()
                }
            }
        }
        .statusBar(hidden: true)
    }
    
    // 图片内容视图
    @ViewBuilder
    private var imageContent: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // 图片不存在时显示占位符
            VStack(spacing: 20) {
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.5))
                Text("无法加载图片")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // 组合手势：缩放 + 拖动
    private func combinedGesture(in geometry: GeometryProxy) -> some Gesture {
        SimultaneousGesture(
            magnificationGesture(in: geometry),
            dragGesture(in: geometry)
        )
    }
    
    // 双指缩放手势
    private func magnificationGesture(in geometry: GeometryProxy) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { value in
                lastScale = scale
                // 如果缩放回到1，重置偏移
                if scale <= 1.0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                    lastScale = 1.0
                } else {
                    // 限制拖动范围
                    limitOffset(in: geometry)
                }
            }
    }
    
    // 单指拖动手势
    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // 只有放大时才能拖动
                if scale > 1.0 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { value in
                if scale > 1.0 {
                    lastOffset = offset
                    // 限制拖动范围
                    limitOffset(in: geometry)
                } else {
                    // 如果是原始大小，检查是否是向下滑动关闭
                    if value.translation.height > 100 && abs(value.translation.width) < 50 {
                        dismiss()
                    }
                }
            }
    }
    
    // 限制偏移范围，防止图片拖出可视区域
    private func limitOffset(in geometry: GeometryProxy) {
        let imageSize = geometry.size
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // 计算最大允许偏移
        let maxOffsetX = max((scaledWidth - imageSize.width) / 2, 0)
        let maxOffsetY = max((scaledHeight - imageSize.height) / 2, 0)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
            offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
        }
        lastOffset = offset
    }
}

// MARK: - Preview
struct ImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewer(imageName: "sample_image")
    }
}
