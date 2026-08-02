import Foundation

struct IntervalSoundDefinitions {
    /// 间隔声音文件名称列表
    /// 用户可以在此处修改、添加或删除声音文件名称
    /// 请确保 Bundle 中包含对应的 .mp3 文件
    static let allSounds: [String] = [
        "长",
        "中",
        "短",
        "嘀",
        "噔",
        "叮",
        "嘟",
        "咚"
    ]
    
    /// 显示名称到文件名的映射
    static let soundFileMapping: [String: String] = [
        "长": "NotificationSound2",
        "中": "NotificationSound4",
        "短": "NotificationSound3",
        "嘀": "NotificationSound1",
        "噔": "NotificationSound6",
        "叮": "NotificationSound7",
        "嘟": "NotificationSound8",
        "咚": "NotificationSound5"
         // Fallback or add more files if needed
    ]
    
    /// 默认使用的间隔声音
    static let defaultSound = "长"
}
