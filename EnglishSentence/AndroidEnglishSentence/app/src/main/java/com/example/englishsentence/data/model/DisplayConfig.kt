package com.example.englishsentence.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class DisplayConfig(
    val phoneticType: PhoneticType = PhoneticType.US,
    val showPhonetics: Boolean = true,
    val showWordType: Boolean = true,
    val showSentencePattern: Boolean = true,
    val speakSentencePattern: Boolean = false,
    val showTranslation: Boolean = true,
    val showEnglishSentence: Boolean = true,
    val showAudioButton: Boolean = true,
    val showTranslationAudioButton: Boolean = true,
    val showEnglishAudioButton: Boolean = true,
    val backgroundImageIndex: Int = 0,
    val useCustomBackground: Boolean = false,
    val selectedVoiceIdentifier: String? = null,
    val maskOpacity: Float = 0.8f,
) {
    @Serializable
    enum class PhoneticType {
        @SerialName("uk")
        UK,

        @SerialName("us")
        US,
    }

    val englishLanguageCode: String
        get() = when (phoneticType) {
            PhoneticType.UK -> "en-GB"
            PhoneticType.US -> "en-US"
        }
}
