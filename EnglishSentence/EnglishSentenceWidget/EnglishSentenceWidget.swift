//
//  EnglishSentenceWidget.swift
//  EnglishSentenceWidgetExtension
//
//  仅展示满幅图片：widget_background_1 … widget_background_31（按当月日期）。
//  点按小组件仍由系统打开宿主 App。
//

import SwiftUI
import UIKit
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
        let day = Calendar.current.component(.day, from: date)
        return EnglishSentenceEntry(date: date, dayOfMonth: day)
    }
}

struct EnglishSentenceEntry: TimelineEntry {
    let date: Date
    let dayOfMonth: Int
}

// MARK: - 资源名

private enum WidgetDayBackground {
    static func assetName(dayOfMonth: Int) -> String {
        let day = min(max(dayOfMonth, 1), 31)
        return "widget_background_\(day)"
    }
}

// MARK: - 仅图片（无图标、无文字）

private struct WidgetDayImageOnlyView: View {
    let entry: EnglishSentenceEntry

    private let fallbackColor = Color(red: 0.067, green: 0.094, blue: 0.137)

    var body: some View {
        let name = WidgetDayBackground.assetName(dayOfMonth: entry.dayOfMonth)
        Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackColor
            }
        }
    }
}

// MARK: - Widget

struct EnglishSentenceWidget: Widget {
    let kind: String = "EnglishSentenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnglishSentenceProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                // 前景不画图，只在 containerBackground 画一层（避免重复绘制）
                Color.clear
                    .containerBackground(for: .widget) {
                        WidgetDayImageOnlyView(entry: entry)
                            // Axis.Set 无 .all；同时铺满宽高用 [.horizontal, .vertical] 或默认参数
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
            } else {
                WidgetDayImageOnlyView(entry: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
        .configurationDisplayName("兔子英语")
        .description("按日期显示图片，点按打开应用。")
        .supportedFamilies([.systemSmall])
    }
}
