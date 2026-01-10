//
//  VixenDateAccessory.swift
//  VixenAI
//
//  日期处理扩展工具
//

import Foundation

// MARK: - Date 扩展
extension Date {
    
    /// 转换为字符串
    func toString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    /// 转换为友好的时间描述
    func toFriendlyString() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))分钟前"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600))小时前"
        } else if timeInterval < 2592000 {
            return "\(Int(timeInterval / 86400))天前"
        } else if timeInterval < 31536000 {
            return "\(Int(timeInterval / 2592000))个月前"
        } else {
            return "\(Int(timeInterval / 31536000))年前"
        }
    }
    
    /// 是否是今天
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 获取年份
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// 获取月份
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    /// 获取日期
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /// 获取小时
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    /// 获取分钟
    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    /// 获取秒
    var second: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    /// 获取星期几
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    /// 获取星期几的中文名称
    var weekdayName: String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekday - 1]
    }
    
    /// 获取月初
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    /// 获取月末
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }
}

// MARK: - String 日期扩展
extension String {
    
    /// 转换为 Date
    func toDate(format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.date(from: self)
    }
    
    /// 转换时间戳字符串为 Date
    func timestampToDate() -> Date? {
        guard let timestamp = Double(self) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
}

// MARK: - TimeInterval 扩展
extension TimeInterval {
    
    /// 转换为友好的时长描述
    func toDurationString() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

