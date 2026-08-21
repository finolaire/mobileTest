package com.example.englishsentence.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class CourseUnit(
    @SerialName("unit_name") val unitName: String,
    val description: String,
    val category: String? = null,
    val code: String? = null,
    val sentences: List<Sentence>,
) {
    val id: String get() = code ?: unitName
}

@Serializable
data class Sentence(
    val id: String,
    @SerialName("sentence_info") val sentenceInfo: SentenceInfo,
    val analysis: List<WordAnalysis>,
)

@Serializable
data class SentenceInfo(
    val original: String,
    val translation: String,
    @SerialName("sentence_pattern") val sentencePattern: String,
    @SerialName("pattern_code") val patternCode: String,
    @SerialName("difficulty_level") val difficultyLevel: Int,
    val tags: List<String> = emptyList(),
)

@Serializable
data class WordAnalysis(
    val word: String,
    @SerialName("base_form") val baseForm: String,
    val range: List<Int> = emptyList(),
    val tag: String,
    val type: String,
    @SerialName("chinese_definition") val chineseDefinition: String,
    val explanation: String,
    val phonetics: Phonetics = Phonetics(),
)

@Serializable
data class Phonetics(
    val uk: String? = null,
    val us: String? = null,
    @SerialName("audio_uk") val audioUk: String? = null,
    @SerialName("audio_us") val audioUs: String? = null,
)

@Serializable
data class CourseManifest(
    val sections: List<ManifestSection>,
)

@Serializable
data class ManifestSection(
    val id: String,
    val title: String,
    val directory: String,
    val files: List<String>,
)

data class CourseSection(
    val categoryName: String,
    val courses: List<CourseUnit>,
)
