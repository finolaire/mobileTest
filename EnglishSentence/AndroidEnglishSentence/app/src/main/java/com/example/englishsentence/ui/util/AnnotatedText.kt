package com.example.englishsentence.ui.util

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import com.example.englishsentence.data.model.WordAnalysis
import com.example.englishsentence.ui.theme.AppThemeColors

fun buildPatternAnnotated(pattern: String): AnnotatedString {
    val components = pattern.split(" + ")
    return buildAnnotatedString {
        components.forEachIndexed { index, component ->
            withStyle(
                SpanStyle(
                    color = AppThemeColors.colorForKeyword(component),
                    fontWeight = FontWeight.Medium,
                ),
            ) {
                append(component)
            }
            if (index < components.lastIndex) {
                withStyle(SpanStyle(color = Color.White, fontWeight = FontWeight.Medium)) {
                    append(" + ")
                }
            }
        }
    }
}

fun buildEnglishAnnotated(original: String, analysis: List<WordAnalysis>): AnnotatedString {
    val colored = mutableListOf<IntRange>()
    val spans = mutableListOf<Pair<IntRange, Color>>()

    for (item in analysis) {
        val color = AppThemeColors.colorForTag(item.tag)
        val ranges = original.findAllRanges(item.word)
        for (range in ranges) {
            if (colored.none { it.overlaps(range) }) {
                spans += range to color
                colored += range
                break
            }
        }
    }

    return buildAnnotatedString {
        withStyle(SpanStyle(color = Color.White, fontWeight = FontWeight.Bold)) {
            append(original)
        }
        spans.forEach { (range, color) ->
            addStyle(SpanStyle(color = color), range.first, range.last + 1)
        }
    }
}

fun buildTranslationAnnotated(translation: String, analysis: List<WordAnalysis>): AnnotatedString {
    val colored = mutableListOf<IntRange>()
    val spans = mutableListOf<Pair<IntRange, Color>>()

    for (item in analysis) {
        val color = AppThemeColors.colorForTag(item.tag)
        val definitions = item.chineseDefinition.split("/")
        var found = false
        for (def in definitions) {
            if (found || def.isBlank()) continue
            val ranges = translation.findAllRanges(def)
            for (range in ranges) {
                if (colored.none { it.overlaps(range) }) {
                    spans += range to color
                    colored += range
                    found = true
                    break
                }
            }
        }
    }

    return buildAnnotatedString {
        withStyle(SpanStyle(color = Color.White, fontWeight = FontWeight.Bold)) {
            append(translation)
        }
        spans.forEach { (range, color) ->
            addStyle(SpanStyle(color = color), range.first, range.last + 1)
        }
    }
}

private fun String.findAllRanges(needle: String): List<IntRange> {
    if (needle.isEmpty()) return emptyList()
    val result = mutableListOf<IntRange>()
    var start = 0
    while (true) {
        val index = indexOf(needle, startIndex = start)
        if (index < 0) break
        result += index until (index + needle.length)
        start = index + needle.length
    }
    return result
}

private fun IntRange.overlaps(other: IntRange): Boolean {
    return first <= other.last && other.first <= last
}
