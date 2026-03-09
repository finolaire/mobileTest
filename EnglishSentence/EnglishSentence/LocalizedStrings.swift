import Foundation

struct AppStrings {
    struct Settings {
        static let title = "设置"
        static let close = "关闭"
        
        static let showPhonetics = "显示音标"
        static let showWordType = "显示词性"
        static let showPattern = "显示句型"
        static let showWordAudio = "显示单词朗读"
        
        static let accent = "口音"
        static let accentUK = "英式"
        static let accentUS = "美式"
        
        static let voice = "发音人"
        static let voiceDefault = "默认"
        static let selectVoiceTitle = "选择发音人"
        static let cancel = "取消"
        
        static let translation = "中文翻译"
        static let audio = "朗读"
        
        static let english = "英文原句"
        
        static let background = "背景图片"
        static let bg0 = "  梦  "
        static let bg1 = "  禅  "
        static let bg2 = "  忍  "
        static let bg3 = "  空  "
        
        static func maskOpacity(value: Float) -> String {
            return String(format: "遮罩透明度: %.1f", value)
        }
    }
    
    struct Immersive {
        static let title = "沉浸式阅读"
        static let close = "关闭"
        static let start = "开始播放"
        
        static let custom = "自定义"
        static let all = "全部"
        
        static let rateTitle = "播放速度调整"
        static func rateValue(value: Float) -> String {
            return String(format: "当前速度: %.2fx", value)
        }
        
        static let smallIntervalTitle = "小句子时间间隙"
        static func smallIntervalValue(value: Float) -> String {
            return String(format: "小句子间隙: %.1fs", value)
        }
        
        static let largeIntervalTitle = "大句子时间间隙"
        static func largeIntervalValue(value: Float) -> String {
            return String(format: "大句子间隙: %.1fs", value)
        }
        
        static let intervalSound = "句子间隔声音"
        
        static let lockScreen = "支持锁定屏幕播放"
        static let autoStop = "定时自动关闭播放"
        static func autoStopValue(minutes: Int) -> String {
            return "自定义: \(minutes) 分钟"
        }
        
        static let playOptionsTitle = "播放选项"
        static let playEnglish = "播放英文 "
        static let playChinese = "播放中文 "
        static let playPattern = "播放语法 "
        
        static let orderMenuTitle = "排序菜单（仅显示已开启项）"
        
        static let sentenceCountTitle = "播放句型数量"
        static func customSentenceCount(count: Int) -> String {
            return "自定义数量: \(count)"
        }
        
        static let time5Min = "5分钟"
        static let time15Min = "15分钟"
        static let time30Min = "30分钟"
    }
}
