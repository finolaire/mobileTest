package com.example.englishsentence.service

import android.content.Context
import android.media.MediaPlayer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

class TtsManager(context: Context) : TextToSpeech.OnInitListener {

    private val appContext = context.applicationContext
    private var tts: TextToSpeech? = null
    private val ready = AtomicBoolean(false)
    private var pending: (() -> Unit)? = null
    private var onDone: (() -> Unit)? = null
    private var intervalPlayer: MediaPlayer? = null

    init {
        tts = TextToSpeech(appContext, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            ready.set(true)
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit
                override fun onDone(utteranceId: String?) {
                    onDone?.invoke()
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    onDone?.invoke()
                }
            })
            pending?.invoke()
            pending = null
        }
    }

    fun speak(
        text: String,
        language: String = "en-US",
        voiceIdentifier: String? = null,
        rate: Float = 1.0f,
        onFinished: (() -> Unit)? = null,
    ) {
        val action: () -> Unit = {
            val engine = tts
            if (engine != null) {
                onDone = onFinished
                engine.stop()
                applyVoice(engine, language, voiceIdentifier)
                engine.setSpeechRate(rate.coerceIn(0.5f, 2.0f))
                engine.speak(
                    text,
                    TextToSpeech.QUEUE_FLUSH,
                    null,
                    "utterance-${System.currentTimeMillis()}",
                )
                Unit
            } else {
                onFinished?.invoke()
            }
        }
        if (ready.get()) {
            action()
        } else {
            pending = action
        }
    }

    fun playIntervalSound(resId: Int, onFinished: (() -> Unit)? = null) {
        stopIntervalSound()
        runCatching {
            val player = MediaPlayer.create(appContext, resId)
            if (player == null) {
                onFinished?.invoke()
                return
            }
            intervalPlayer = player
            player.setOnCompletionListener {
                stopIntervalSound()
                onFinished?.invoke()
            }
            player.start()
        }.onFailure {
            onFinished?.invoke()
        }
    }

    fun stop() {
        onDone = null
        tts?.stop()
        stopIntervalSound()
    }

    fun stopIntervalSound() {
        intervalPlayer?.runCatching {
            stop()
            release()
        }
        intervalPlayer = null
    }

    fun availableVoices(language: String): List<Voice> {
        val locale = localeFor(language)
        return tts?.voices
            ?.filter { it.locale.language.equals(locale.language, ignoreCase = true) }
            ?.sortedBy { it.name }
            .orEmpty()
    }

    fun shutdown() {
        stop()
        tts?.shutdown()
        tts = null
        ready.set(false)
    }

    private fun applyVoice(engine: TextToSpeech, language: String, voiceIdentifier: String?) {
        if (!voiceIdentifier.isNullOrBlank()) {
            val matched = engine.voices?.firstOrNull { it.name == voiceIdentifier }
            if (matched != null) {
                engine.voice = matched
                return
            }
        }
        engine.language = localeFor(language)
    }

    private fun localeFor(language: String): Locale {
        val parts = language.split("-", "_")
        return when (parts.size) {
            1 -> Locale.Builder().setLanguage(parts[0]).build()
            else -> Locale.Builder().setLanguage(parts[0]).setRegion(parts[1]).build()
        }
    }
}
