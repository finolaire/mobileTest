//
//  VixenViewAccessory.swift
//  VixenAI
//
//  SwiftUI 视图扩展工具
//

import SwiftUI

// MARK: - View 扩展
extension View {
    
    /// 条件修饰符
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 隐藏键盘
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// 圆角指定边
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// 阴影效果
    func vixenShadow(color: Color = .black.opacity(0.1), radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 5) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    /// 卡片样式
    func vixenCard(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .vixenShadow()
    }
}

// MARK: - 自定义圆角形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 加载指示器修饰符
struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: VixenColorConfig.primaryColor))
                    
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(VixenColorConfig.primaryTextColor)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 10)
                )
            }
        }
    }
}

extension View {
    func loading(isLoading: Bool, message: String = "加载中...") -> some View {
        modifier(LoadingModifier(isLoading: isLoading, message: message))
    }
}

