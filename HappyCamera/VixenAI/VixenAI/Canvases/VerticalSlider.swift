//
//  VixenVerticalSlider.swift
//  VixenAI
//
//  垂直滑动条组件 - 横向条纹样式
//

import SwiftUI

struct VixenVerticalSlider: View {
    
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let icon: String
    
    @State private var isDragging = false
    
    private let barCount = 20
    private let normalBarHeight: CGFloat = 2
    private let activeBarHeight: CGFloat = 6
    private let normalBarWidth: CGFloat = 25
    private let activeBarWidth: CGFloat = 30
    private let spacing: CGFloat = 6
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 15)
                
                // 横向条纹堆叠
                VStack(spacing: spacing) {
                    ForEach((0..<barCount).reversed(), id: \.self) { index in
                        let barProgress = Double(index) / Double(barCount - 1)
                        let isActive = barProgress <= progress
                        let isSelected = abs(barProgress - progress) < 0.05  // 当前选中的条
                        
                        Rectangle()
                            .fill(isActive ? Color.white : Color.white.opacity(0.3))
                            .frame(
                                width: isSelected ? activeBarWidth : normalBarWidth,
                                height: isSelected ? activeBarHeight : normalBarHeight
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(width: 40)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.4))
                )
            }
            .frame(width: 50)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        updateValue(at: gesture.location.y, in: geometry.size.height)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(width: 50, height: 300)
    }
    
    private var progress: Double {
        return (value - minValue) / (maxValue - minValue)
    }
    
    private func updateValue(at y: CGFloat, in height: CGFloat) {
        // 计算条纹区域的实际高度
        let iconHeight: CGFloat = 35
        let barsHeight: CGFloat = CGFloat(barCount) * (normalBarHeight + spacing)
        let totalHeight = iconHeight + barsHeight + 20
        
        // 调整Y坐标到条纹区域
        let adjustedY = y - iconHeight
        let clampedY = max(0, min(adjustedY, barsHeight))
        
        // 反转Y轴（从下往上）
        let newProgress = 1.0 - (clampedY / barsHeight)
        let newValue = minValue + (maxValue - minValue) * Double(newProgress)
        value = max(minValue, min(maxValue, newValue))
    }
}

// MARK: - Preview
struct VixenVerticalSlider_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            HStack(spacing: 100) {
                VixenVerticalSlider(
                    value: .constant(0.3),
                    minValue: 0,
                    maxValue: 1,
                    icon: "sun.max.fill"
                )
                
                VixenVerticalSlider(
                    value: .constant(0.7),
                    minValue: 0,
                    maxValue: 1,
                    icon: "magnifyingglass"
                )
            }
        }
    }
}
