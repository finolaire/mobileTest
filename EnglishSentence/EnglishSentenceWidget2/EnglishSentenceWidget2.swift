//
//  EnglishSentenceWidget2.swift
//  EnglishSentenceWidget2Extension
//
//  暂时占位：黑底 + 提示文案（systemSmall）。
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct EnglishSentenceWidget2Provider: TimelineProvider {
    func placeholder(in context: Context) -> EnglishSentenceWidget2Entry {
        EnglishSentenceWidget2Entry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EnglishSentenceWidget2Entry) -> Void) {
        completion(EnglishSentenceWidget2Entry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EnglishSentenceWidget2Entry>) -> Void) {
        let entry = EnglishSentenceWidget2Entry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct EnglishSentenceWidget2Entry: TimelineEntry {
    let date: Date
}

// MARK: - 占位界面

private struct EnglishSentenceWidget2PlaceholderView: View {
    private let lineFont = Font.system(size: 22, weight: .bold, design: .rounded)
    /// #2cc15f
    private let lineGreen = Color(red: 44 / 255, green: 193 / 255, blue: 95 / 255)
    /// #6367ef
    private let linePurple = Color(red: 99 / 255, green: 103 / 255, blue: 239 / 255)

    var body: some View {
        ZStack {
            Color.black
            GeometryReader { geo in
                // 中间一块较窄区域：上行靠左、下行靠右，整体相对小组件水平垂直居中
                let innerWidth = min(geo.size.width * 0.72, 148)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 13) {
                            HStack {
                                Text("学习英语")
                                    .font(lineFont)
                                    .foregroundStyle(lineGreen)
                                Spacer(minLength: 0)
                            }
                            HStack {
                                Spacer(minLength: 0)
                                Text("保护眼睛")
                                    .font(lineFont)
                                    .foregroundStyle(linePurple)
                            }
                        }
                        .frame(width: innerWidth)
                        Spacer()
                    }
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Widget

struct EnglishSentenceWidget2: Widget {
    let kind: String = "EnglishSentenceWidget2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnglishSentenceWidget2Provider()) { _ in
            if #available(iOSApplicationExtension 17.0, *) {
                Color.clear
                    .containerBackground(for: .widget) {
                        EnglishSentenceWidget2PlaceholderView()
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
            } else {
                EnglishSentenceWidget2PlaceholderView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .configurationDisplayName("学习英语，报护眼睛")
        .description("学习英语要坚持，也要报护好眼睛哦～")
        .supportedFamilies([.systemSmall])
    }
}
