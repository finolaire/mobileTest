package com.example.englishsentence.ui.theme

import androidx.compose.ui.graphics.Color

object AppThemeColors {
    val lightBlue = Color(0.2f, 0.6f, 1.0f)
    val lightRed = Color(1.0f, 0.4f, 0.4f)
    val lightGreen = Color(0.4f, 0.8f, 0.4f)
    val yellowOrange = Color(1.0f, 0.8f, 0.2f)
    val lightPurple = Color(0.8f, 0.4f, 1.0f)
    val lightGray = Color(0.7f, 0.7f, 0.7f)
    val white = Color.White

    fun colorForTag(tag: String): Color = when (tag) {
        "pronoun_subject", "noun_subject", "clause_subject", "noun_proper", "phrase_emphasis_head" -> lightBlue
        "verb_be", "verb_intransitive", "verb_transitive", "verb_linking", "verb_phrase",
        "verb_auxiliary", "verb_base", "verb_past", "verb_past_participle", "verb_present_participle",
        "verb_imperative", "verb_auxiliary_negative", "phrase_verb",
        -> lightRed
        "noun_object", "pronoun_object", "noun_object_direct", "noun_object_indirect",
        "noun_predicative", "noun_complement", "clause_object", "clause_remaining", "clause_main",
        -> yellowOrange
        "article_indefinite", "article_definite", "adjective_predicative", "adjective_complement",
        "adverb_guide", "adverb_frequency", "adverb_time", "adverb_place", "adverb_negative", "adverb_politeness",
        "phrase_prepositional", "phrase_time", "phrase_future", "clause_adverbial", "clause_attributive",
        "numeral_cardinal", "phrase_noun",
        -> lightGreen
        "conjunction_emphasis", "conjunction_subordinating" -> lightPurple
        "ellipsis_subject", "ellipsis_clause_subject_verb" -> lightGray
        else -> white
    }

    fun colorForKeyword(keyword: String): Color = when {
        keyword.contains("主语") -> lightBlue
        keyword.contains("动词") || keyword.contains("谓语") -> lightRed
        keyword.contains("宾语") || keyword.contains("表语") || keyword.contains("补足语") -> yellowOrange
        keyword.contains("状语") || keyword.contains("定语") || keyword.contains("冠词") ||
            keyword.contains("形容词") || keyword.contains("副词") -> lightGreen
        else -> white
    }
}
