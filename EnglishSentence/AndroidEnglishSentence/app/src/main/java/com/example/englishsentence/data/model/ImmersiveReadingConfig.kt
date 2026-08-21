package com.example.englishsentence.data.model

import kotlinx.serialization.Serializable

@Serializable
data class ImmersiveReadingConfig(
    val enableSound: Boolean = true,
    val playbackRate: Float = 1.0f,
    val lockScreenPlayback: Boolean = true,
    val autoStopEnabled: Boolean = false,
    val autoStopMinutes: Int = 15,
    val playSentencePattern: Boolean = false,
    val playTranslation: Boolean = true,
    val playOriginal: Boolean = true,
    val sentenceCountOption: String? = "all",
    val customSentenceCount: Int? = 10,
    val orderPattern: Int = 3,
    val orderTranslation: Int = 2,
    val orderOriginal: Int = 1,
    val enableIntervalSound: Boolean = true,
    val intervalSoundFile: String = "长",
    val smallSentenceInterval: Double = 1.0,
    val largeSentenceInterval: Double = 1.0,
) {
    fun normalized(): ImmersiveReadingConfig = copy(playOriginal = true)

    fun effectiveSentenceLimit(totalInCourse: Int): Int {
        val total = totalInCourse.coerceAtLeast(1)
        val requested = when (sentenceCountOption) {
            "three" -> 3
            "five" -> 5
            "custom" -> (customSentenceCount ?: 10).coerceIn(1, 50)
            else -> total
        }
        return requested.coerceIn(1, total)
    }
}
