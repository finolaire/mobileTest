//
//  EnglishSentenceWidget2.swift
//  EnglishSentenceWidget2Extension
//
//  与主小组件相同：仅 systemSmall、按当月日期展示满幅图片。
//

import SwiftUI
import UIKit
import WidgetKit

// MARK: - Timeline

struct EnglishSentenceWidget2Provider: TimelineProvider {
    func placeholder(in context: Context) -> EnglishSentenceWidget2Entry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EnglishSentenceWidget2Entry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EnglishSentenceWidget2Entry>) -> Void) {
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

    private func makeEntry(for date: Date) -> EnglishSentenceWidget2Entry {
        let day = Calendar.current.component(.day, from: date)
        return EnglishSentenceWidget2Entry(date: date, dayOfMonth: day)
    }
}

struct EnglishSentenceWidget2Entry: TimelineEntry {
    let date: Date
    let dayOfMonth: Int
}

// MARK: - 资源名

private enum EnglishSentenceWidget2DayBackground {
    static func assetName(dayOfMonth: Int) -> String {
        let day = min(max(dayOfMonth, 1), 31)
        return "widget_background_\(day)"
    }
}

// MARK: - 仅图片（无图标、无文字）

private struct EnglishSentenceWidget2ImageOnlyView: View {
    let entry: EnglishSentenceWidget2Entry

    private let fallbackColor = Color(red: 0.067, green: 0.094, blue: 0.137)

    var body: some View {
        let name = EnglishSentenceWidget2DayBackground.assetName(dayOfMonth: entry.dayOfMonth)
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

struct EnglishSentenceWidget2: Widget {
    let kind: String = "EnglishSentenceWidget2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnglishSentenceWidget2Provider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                Color.clear
                    .containerBackground(for: .widget) {
                        EnglishSentenceWidget2ImageOnlyView(entry: entry)
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
            } else {
                EnglishSentenceWidget2ImageOnlyView(entry: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
        .configurationDisplayName("兔子英语（二）")
        .description("与主小组件相同尺寸与图片逻辑，独立扩展。")
        .supportedFamilies([.systemSmall])
    }
}
