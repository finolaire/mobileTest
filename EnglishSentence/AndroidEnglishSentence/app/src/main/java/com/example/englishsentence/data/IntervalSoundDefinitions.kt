package com.example.englishsentence.data

import com.example.englishsentence.R

object IntervalSoundDefinitions {
    val allSounds = listOf("长", "中", "短", "嘀", "噔", "叮", "嘟", "咚")
    const val defaultSound = "长"

    private val soundResMapping = mapOf(
        "长" to R.raw.notification_sound_2,
        "中" to R.raw.notification_sound_4,
        "短" to R.raw.notification_sound_3,
        "嘀" to R.raw.notification_sound_1,
        "噔" to R.raw.notification_sound_6,
        "叮" to R.raw.notification_sound_7,
        "嘟" to R.raw.notification_sound_8,
        "咚" to R.raw.notification_sound_5,
    )

    fun resIdFor(displayName: String): Int? = soundResMapping[displayName]
}
