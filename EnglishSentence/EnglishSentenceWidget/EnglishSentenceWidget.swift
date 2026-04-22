//
//  EnglishSentenceWidget.swift
//  EnglishSentenceWidgetExtension
//
//  按「星期几」展示图：widget_background_1 … widget_background_7
//  （Calendar.weekday：1=周日 … 7=周六）。点按小组件由系统打开宿主 App。
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct EnglishSentenceProvider: TimelineProvider {
    func placeholder(in context: Context) -> EnglishSentenceEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EnglishSentenceEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EnglishSentenceEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let entry = makeEntry(for: now)

        let startOfToday = calendar.startOfDay(for: now)
        let policy: TimelineReloadPolicy
        if let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfToday) {
            policy = .after(nextMidnight)
        } else {
            policy = .never
        }

        completion(Timeline(entries: [entry], policy: policy))
    }

    private func makeEntry(for date: Date) -> EnglishSentenceEntry {
        let weekday = Calendar.current.component(.weekday, from: date)
        return EnglishSentenceEntry(date: date, weekday: weekday)
    }
}

struct EnglishSentenceEntry: TimelineEntry {
    let date: Date
    /// `Calendar.Component.weekday`：1=周日 … 7=周六
    let weekday: Int
}

// MARK: - 资源名

private enum WidgetDayBackground {
    static func assetName(weekday: Int) -> String {
        let w = min(max(weekday, 1), 7)
//        return "widget_background_\(w)"
        return "widget_background_1"
    }
}

// MARK: - 满幅背景图

/// iOS 17+ 主内容区会被系统缩小一圈，露出 `containerBackground` 的底色，看起来像黑边。
/// 做法：把真正要铺满的图放在 `containerBackground` 里；前景用 `Color.clear`。
/// `overscan` 略大于 1，再裁切，可吃掉系统隐式边距 / 抗锯齿缝隙。
private struct WidgetDayFullBleedBackground: View {
    let entry: EnglishSentenceEntry
    /// 相对小组件区域放大倍数，建议 1.08～1.15
    var overscan: CGFloat = 1//1.12

    private let fallbackColor = Color(red: 0.067, green: 0.094, blue: 0.137)

    var body: some View {
        let name = WidgetDayBackground.assetName(weekday: entry.weekday)
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let ow = w * overscan
            let oh = h * overscan
            ZStack {
                fallbackColor
                Image(name, bundle: .main)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
                    .frame(width: ow, height: oh)
                    .position(x: w * 0.5, y: h * 0.5)
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }
}

// MARK: - Widget

struct EnglishSentenceWidget: Widget {
    let kind: String = "EnglishSentenceWidget"
    
    let overscan1 = 1.0//1.12
    let overscan2 = 1.0//1.06

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnglishSentenceProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                Color.clear
                    .containerBackground(for: .widget) {
                        WidgetDayFullBleedBackground(entry: entry, overscan: overscan1)
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
            } else {
                WidgetDayFullBleedBackground(entry: entry, overscan: overscan2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .configurationDisplayName("兔子英语")
        .description("按星期几显示图片（周日～周六对应 1～7），点按打开应用。")
        .supportedFamilies([.systemSmall])
    }
}
