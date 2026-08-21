package com.example.englishsentence.ui.learning

import android.app.Application
import android.os.Handler
import android.os.Looper
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.englishsentence.data.CourseRepository
import com.example.englishsentence.data.IntervalSoundDefinitions
import com.example.englishsentence.data.PreferenceStore
import com.example.englishsentence.data.model.CourseSection
import com.example.englishsentence.data.model.CourseUnit
import com.example.englishsentence.data.model.DisplayConfig
import com.example.englishsentence.data.model.ImmersiveReadingConfig
import com.example.englishsentence.data.model.Sentence
import com.example.englishsentence.data.model.WordAnalysis
import com.example.englishsentence.service.TtsManager
import com.example.englishsentence.ui.util.buildEnglishAnnotated
import com.example.englishsentence.ui.util.buildPatternAnnotated
import com.example.englishsentence.ui.util.buildTranslationAnnotated
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LearningUiState(
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
    val course: CourseUnit? = null,
    val sentence: Sentence? = null,
    val sentenceIndex: Int = 0,
    val courseIndex: Int = 0,
    val totalCourses: Int = 0,
    val displayConfig: DisplayConfig = DisplayConfig(),
    val immersiveConfig: ImmersiveReadingConfig = ImmersiveReadingConfig(),
    val selectedWord: WordAnalysis? = null,
    val canGoPrev: Boolean = false,
    val canGoNext: Boolean = false,
    val isImmersivePlaying: Boolean = false,
    val isImmersivePaused: Boolean = false,
) {
    val patternText get() = sentence?.let { buildPatternAnnotated(it.sentenceInfo.sentencePattern) }
    val englishText get() = sentence?.let { buildEnglishAnnotated(it.sentenceInfo.original, it.analysis) }
    val translationText get() = sentence?.let { buildTranslationAnnotated(it.sentenceInfo.translation, it.analysis) }
}

private data class ImmersiveItem(val text: String, val language: String)

private enum class ImmersivePart { PATTERN, TRANSLATION, ORIGINAL }

class LearningViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = CourseRepository(application)
    private val preferenceStore = PreferenceStore(application)
    val ttsManager = TtsManager(application)

    private val allCourses = mutableListOf<CourseUnit>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var immersiveQueue: List<ImmersiveItem> = emptyList()
    private var immersiveQueueIndex = 0
    private var delayJob: Job? = null
    private var autoStopJob: Job? = null

    private val _uiState = MutableStateFlow(LearningUiState())
    val uiState: StateFlow<LearningUiState> = _uiState.asStateFlow()

    private val _sections = MutableStateFlow<List<CourseSection>>(emptyList())
    val sections: StateFlow<List<CourseSection>> = _sections.asStateFlow()

    init {
        viewModelScope.launch {
            preferenceStore.displayConfig.collect { config ->
                _uiState.update { it.copy(displayConfig = config) }
            }
        }
        viewModelScope.launch {
            preferenceStore.immersiveConfig.collect { config ->
                _uiState.update { it.copy(immersiveConfig = config) }
            }
        }
        loadInitial()
    }

    fun loadInitial() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            runCatching {
                refreshCourses()
                val lastId = preferenceStore.lastPlayedCourseId.first()
                val course = allCourses.firstOrNull { it.id == lastId } ?: allCourses.firstOrNull()
                if (course == null) {
                    _uiState.update {
                        it.copy(isLoading = false, errorMessage = "未找到课程数据")
                    }
                } else {
                    applyCourse(course, sentenceIndex = 0, persist = lastId == null)
                }
            }.onFailure { error ->
                _uiState.update {
                    it.copy(isLoading = false, errorMessage = error.message ?: "加载失败")
                }
            }
        }
    }

    fun reloadBookshelf() {
        viewModelScope.launch {
            runCatching { refreshCourses(forceReload = true) }
        }
    }

    fun selectCourse(course: CourseUnit) {
        stopImmersivePlayback()
        applyCourse(course, sentenceIndex = 0, persist = true)
    }

    fun nextSentence() {
        if (_uiState.value.isImmersivePlaying) return
        val state = _uiState.value
        val course = state.course ?: return
        if (state.sentenceIndex < course.sentences.lastIndex) {
            applyCourse(course, state.sentenceIndex + 1, persist = false)
            return
        }
        val nextIndex = state.courseIndex + 1
        if (nextIndex <= allCourses.lastIndex) {
            applyCourse(allCourses[nextIndex], 0, persist = true)
        }
    }

    fun prevSentence() {
        if (_uiState.value.isImmersivePlaying) return
        val state = _uiState.value
        if (state.sentenceIndex > 0) {
            val course = state.course ?: return
            applyCourse(course, state.sentenceIndex - 1, persist = false)
            return
        }
        val prevIndex = state.courseIndex - 1
        if (prevIndex >= 0) {
            val prevCourse = allCourses[prevIndex]
            applyCourse(prevCourse, prevCourse.sentences.lastIndex.coerceAtLeast(0), persist = true)
        }
    }

    fun selectWord(word: WordAnalysis?) {
        _uiState.update { it.copy(selectedWord = word) }
    }

    fun updateConfig(config: DisplayConfig) {
        _uiState.update { it.copy(displayConfig = config) }
        viewModelScope.launch {
            preferenceStore.saveDisplayConfig(config)
            val immersive = _uiState.value.immersiveConfig.copy(
                playSentencePattern = config.speakSentencePattern,
            )
            preferenceStore.saveImmersiveConfig(immersive)
        }
    }

    fun updateImmersiveConfig(config: ImmersiveReadingConfig) {
        viewModelScope.launch {
            val normalized = config.normalized()
            preferenceStore.saveImmersiveConfig(normalized)
            val display = _uiState.value.displayConfig.copy(
                speakSentencePattern = normalized.playSentencePattern,
            )
            preferenceStore.saveDisplayConfig(display)
        }
    }

    fun speakWord(word: WordAnalysis) {
        if (_uiState.value.isImmersivePlaying) return
        val config = _uiState.value.displayConfig
        ttsManager.speak(
            text = word.word,
            language = config.englishLanguageCode,
            voiceIdentifier = config.selectedVoiceIdentifier,
        )
    }

    fun speakTranslation() {
        if (_uiState.value.isImmersivePlaying) return
        val text = _uiState.value.sentence?.sentenceInfo?.translation ?: return
        ttsManager.speak(text, language = "zh-CN")
    }

    fun speakEnglish() {
        if (_uiState.value.isImmersivePlaying) return
        val state = _uiState.value
        val text = state.sentence?.sentenceInfo?.original ?: return
        ttsManager.speak(
            text = text,
            language = state.displayConfig.englishLanguageCode,
            voiceIdentifier = state.displayConfig.selectedVoiceIdentifier,
        )
    }

    fun speakPattern() {
        if (_uiState.value.isImmersivePlaying) return
        val text = _uiState.value.sentence?.sentenceInfo?.sentencePattern ?: return
        ttsManager.speak(text, language = "zh-CN")
    }

    fun startImmersivePlayback(config: ImmersiveReadingConfig = _uiState.value.immersiveConfig) {
        stopImmersivePlayback(clearUi = false)
        viewModelScope.launch {
            preferenceStore.saveImmersiveConfig(config.normalized())
            val display = _uiState.value.displayConfig.copy(
                speakSentencePattern = config.playSentencePattern,
            )
            preferenceStore.saveDisplayConfig(display)
        }
        _uiState.update {
            it.copy(
                immersiveConfig = config.normalized(),
                isImmersivePlaying = true,
                isImmersivePaused = false,
            )
        }
        if (config.autoStopEnabled) {
            autoStopJob = viewModelScope.launch {
                delay(config.autoStopMinutes.coerceIn(1, 120) * 60_000L)
                stopImmersivePlayback()
            }
        }
        immersiveQueue = buildImmersiveQueue()
        immersiveQueueIndex = 0
        if (immersiveQueue.isEmpty()) {
            stopImmersivePlayback()
            return
        }
        playCurrentImmersiveItem()
    }

    fun pauseImmersive() {
        if (!_uiState.value.isImmersivePlaying || _uiState.value.isImmersivePaused) return
        delayJob?.cancel()
        ttsManager.stop()
        _uiState.update { it.copy(isImmersivePaused = true) }
    }

    fun resumeImmersive() {
        if (!_uiState.value.isImmersivePlaying || !_uiState.value.isImmersivePaused) return
        _uiState.update { it.copy(isImmersivePaused = false) }
        playCurrentImmersiveItem()
    }

    fun stopImmersivePlayback(clearUi: Boolean = true) {
        delayJob?.cancel()
        autoStopJob?.cancel()
        delayJob = null
        autoStopJob = null
        immersiveQueue = emptyList()
        immersiveQueueIndex = 0
        ttsManager.stop()
        if (clearUi) {
            _uiState.update {
                it.copy(isImmersivePlaying = false, isImmersivePaused = false)
            }
        }
    }

    override fun onCleared() {
        stopImmersivePlayback()
        ttsManager.shutdown()
        super.onCleared()
    }

    private suspend fun refreshCourses(forceReload: Boolean = false) {
        val sections = repository.getAllCourses(forceReload)
        _sections.value = sections
        allCourses.clear()
        allCourses += sections.flatMap { it.courses }
        _uiState.update { it.copy(totalCourses = allCourses.size) }
    }

    private fun applyCourse(course: CourseUnit, sentenceIndex: Int, persist: Boolean) {
        val safeIndex = sentenceIndex.coerceIn(0, (course.sentences.size - 1).coerceAtLeast(0))
        val courseIndex = allCourses.indexOfFirst { it.id == course.id }.coerceAtLeast(0)
        val sentence = course.sentences.getOrNull(safeIndex)
        val canGoPrev = safeIndex > 0 || courseIndex > 0
        val canGoNext = safeIndex < course.sentences.lastIndex || courseIndex < allCourses.lastIndex

        _uiState.update {
            it.copy(
                isLoading = false,
                errorMessage = null,
                course = course,
                sentence = sentence,
                sentenceIndex = safeIndex,
                courseIndex = courseIndex,
                totalCourses = allCourses.size,
                canGoPrev = canGoPrev,
                canGoNext = canGoNext,
                selectedWord = null,
            )
        }

        if (persist) {
            viewModelScope.launch {
                preferenceStore.saveLastPlayedCourseId(course.id)
            }
        }
    }

    private fun buildImmersiveQueue(): List<ImmersiveItem> {
        val state = _uiState.value
        val sentence = state.sentence ?: return emptyList()
        val config = state.immersiveConfig
        if (!config.enableSound) return emptyList()

        val candidates = mutableListOf<Pair<Int, ImmersivePart>>()
        if (state.displayConfig.speakSentencePattern) {
            candidates += config.orderPattern to ImmersivePart.PATTERN
        }
        if (config.playTranslation) {
            candidates += config.orderTranslation to ImmersivePart.TRANSLATION
        }
        candidates += config.orderOriginal to ImmersivePart.ORIGINAL
        candidates.sortWith(compareBy({ it.first }, { it.second.name }))

        return candidates.map { (_, part) ->
            when (part) {
                ImmersivePart.PATTERN -> ImmersiveItem(sentence.sentenceInfo.sentencePattern, "zh-CN")
                ImmersivePart.TRANSLATION -> ImmersiveItem(sentence.sentenceInfo.translation, "zh-CN")
                ImmersivePart.ORIGINAL -> ImmersiveItem(
                    sentence.sentenceInfo.original,
                    state.displayConfig.englishLanguageCode,
                )
            }
        }.filter { it.text.isNotBlank() }
    }

    private fun playCurrentImmersiveItem() {
        val state = _uiState.value
        if (!state.isImmersivePlaying || state.isImmersivePaused) return
        val item = immersiveQueue.getOrNull(immersiveQueueIndex) ?: run {
            afterSentenceFinished()
            return
        }
        ttsManager.speak(
            text = item.text,
            language = item.language,
            voiceIdentifier = state.displayConfig.selectedVoiceIdentifier,
            rate = state.immersiveConfig.playbackRate,
            onFinished = {
                mainHandler.post { onImmersiveItemFinished() }
            },
        )
    }

    private fun onImmersiveItemFinished() {
        val state = _uiState.value
        if (!state.isImmersivePlaying || state.isImmersivePaused) return
        immersiveQueueIndex += 1
        if (immersiveQueueIndex < immersiveQueue.size) {
            delayJob = viewModelScope.launch {
                delay((state.immersiveConfig.smallSentenceInterval * 1000).toLong().coerceAtLeast(0))
                playCurrentImmersiveItem()
            }
        } else {
            delayJob = viewModelScope.launch {
                delay((state.immersiveConfig.largeSentenceInterval * 1000).toLong().coerceAtLeast(0))
                if (state.immersiveConfig.enableIntervalSound) {
                    val resId = IntervalSoundDefinitions.resIdFor(state.immersiveConfig.intervalSoundFile)
                    if (resId != null) {
                        ttsManager.playIntervalSound(resId) {
                            mainHandler.post { proceedToNextSentence() }
                        }
                    } else {
                        proceedToNextSentence()
                    }
                } else {
                    proceedToNextSentence()
                }
            }
        }
    }

    private fun afterSentenceFinished() {
        proceedToNextSentence()
    }

    private fun proceedToNextSentence() {
        val state = _uiState.value
        if (!state.isImmersivePlaying || state.isImmersivePaused) return
        val course = state.course ?: run {
            stopImmersivePlayback()
            return
        }
        val limit = state.immersiveConfig.effectiveSentenceLimit(course.sentences.size)
        val currentPos = state.sentenceIndex
        if (currentPos + 1 < limit && currentPos < course.sentences.lastIndex) {
            applyCourse(course, currentPos + 1, persist = false)
            immersiveQueue = buildImmersiveQueue()
            immersiveQueueIndex = 0
            if (immersiveQueue.isEmpty()) {
                stopImmersivePlayback()
            } else {
                playCurrentImmersiveItem()
            }
            return
        }
        val nextCourseIndex = state.courseIndex + 1
        if (nextCourseIndex <= allCourses.lastIndex) {
            applyCourse(allCourses[nextCourseIndex], 0, persist = true)
            immersiveQueue = buildImmersiveQueue()
            immersiveQueueIndex = 0
            if (immersiveQueue.isEmpty()) {
                stopImmersivePlayback()
            } else {
                playCurrentImmersiveItem()
            }
        } else {
            stopImmersivePlayback()
        }
    }
}
