//
//  VixenColorConfig.swift
//  VixenAI
//
//  颜色配置管理
//

import SwiftUI

struct VixenColorConfig {
    
    // MARK: - 主题颜色
    static let primaryColor = Color(hex: "#6C5CE7")
    static let secondaryColor = Color(hex: "#A29BFE")
    static let accentColor = Color(hex: "#FD79A8")
    
    // MARK: - 背景颜色
    static let backgroundColor = Color(hex: "#FFFFFF")
    static let darkBackgroundColor = Color(hex: "#2D3436")
    static let cardBackgroundColor = Color(hex: "#F5F5F5")
    
    // MARK: - 文本颜色
    static let primaryTextColor = Color(hex: "#2D3436")
    static let secondaryTextColor = Color(hex: "#636E72")
    static let lightTextColor = Color(hex: "#B2BEC3")
    
    // MARK: - 按钮颜色
    static let buttonPrimaryColor = Color(hex: "#6C5CE7")
    static let buttonSecondaryColor = Color(hex: "#DFE6E9")
    static let buttonDangerColor = Color(hex: "#FF7675")
    
    // MARK: - 边框颜色
    static let borderColor = Color(hex: "#DFE6E9")
    static let focusBorderColor = Color(hex: "#6C5CE7")
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

