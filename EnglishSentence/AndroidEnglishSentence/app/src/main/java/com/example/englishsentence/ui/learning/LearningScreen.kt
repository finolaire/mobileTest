package com.example.englishsentence.ui.learning

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Headset
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.RemoveRedEye
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.englishsentence.R
import com.example.englishsentence.ui.components.SentenceCard
import com.example.englishsentence.ui.components.WordChipRow
import com.example.englishsentence.ui.immersive.ImmersiveConfigSheet
import com.example.englishsentence.ui.settings.SettingsDialog

private val backgroundRes = listOf(
    R.drawable.bg_background_0,
    R.drawable.bg_background_1,
    R.drawable.bg_background_2,
    R.drawable.bg_background_3,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LearningScreen(
    viewModel: LearningViewModel,
    onOpenBookshelf: () -> Unit,
    onOpenEyes: () -> Unit,
    onOpenSleep: () -> Unit,
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val bgIndex = state.displayConfig.backgroundImageIndex.coerceIn(0, backgroundRes.lastIndex)
    val maskAlpha = state.displayConfig.maskOpacity.coerceIn(0f, 1f)
    var showImmersiveConfig by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        Image(
            painter = painterResource(backgroundRes[bgIndex]),
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = maskAlpha)),
        )

        when {
            state.isLoading -> {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center),
                    color = Color.White,
                )
            }

            state.errorMessage != null -> {
                Column(
                    modifier = Modifier
                        .align(Alignment.Center)
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(text = state.errorMessage.orEmpty(), color = Color.White)
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(onClick = viewModel::loadInitial) {
                        Text("重试")
                    }
                }
            }

            else -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .safeDrawingPadding(),
                ) {
                    TopBar(
                        immersivePlaying = state.isImmersivePlaying,
                        controlsEnabled = !state.isImmersivePlaying,
                        onOpenBookshelf = onOpenBookshelf,
                        onOpenEyes = onOpenEyes,
                        onOpenSleep = onOpenSleep,
                        onQuickPlay = { viewModel.startImmersivePlayback() },
                        onOpenImmersive = { showImmersiveConfig = true },
                        onOpenSettings = { showSettings = true },
                    )

                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState()),
                    ) {
                        WordChipRow(
                            words = state.sentence?.analysis.orEmpty(),
                            config = state.displayConfig,
                            onWordClick = viewModel::selectWord,
                            onSpeakWord = viewModel::speakWord,
                        )
                    }

                    Column(modifier = Modifier.fillMaxWidth()) {
                        if (state.displayConfig.showTranslation) {
                            SentenceCard(
                                showSpeak = state.displayConfig.showTranslationAudioButton && !state.isImmersivePlaying,
                                onSpeak = viewModel::speakTranslation,
                                maskAlpha = maskAlpha,
                            ) {
                                state.translationText?.let {
                                    Text(
                                        text = it,
                                        fontSize = 20.sp,
                                        softWrap = true,
                                        modifier = Modifier.fillMaxWidth(),
                                    )
                                }
                            }
                        }
                        if (state.displayConfig.showEnglishSentence) {
                            SentenceCard(
                                showSpeak = state.displayConfig.showEnglishAudioButton && !state.isImmersivePlaying,
                                onSpeak = viewModel::speakEnglish,
                                maskAlpha = maskAlpha,
                            ) {
                                state.englishText?.let {
                                    Text(
                                        text = it,
                                        fontSize = 20.sp,
                                        softWrap = true,
                                        modifier = Modifier.fillMaxWidth(),
                                    )
                                }
                            }
                        }
                        if (state.displayConfig.showSentencePattern) {
                            SentenceCard(
                                showSpeak = false,
                                onSpeak = {},
                                maskAlpha = maskAlpha,
                            ) {
                                state.patternText?.let {
                                    Text(
                                        text = it,
                                        fontSize = 16.sp,
                                        softWrap = true,
                                        modifier = Modifier.fillMaxWidth(),
                                    )
                                }
                            }
                        }
                    }

                    if (!state.isImmersivePlaying) {
                        BottomNav(
                            canGoPrev = state.canGoPrev,
                            canGoNext = state.canGoNext,
                            onPrev = viewModel::prevSentence,
                            onNext = viewModel::nextSentence,
                        )
                    } else {
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                }
            }
        }

        if (state.isImmersivePlaying && !state.isImmersivePaused) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable { viewModel.pauseImmersive() },
            ) {
                Row(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .safeDrawingPadding()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(Color.Red, CircleShape),
                    )
                    Spacer(modifier = Modifier.size(6.dp))
                    Text("播放中", color = Color.White, fontSize = 13.sp)
                }
            }
        }

        if (state.isImmersivePaused) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.75f)),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Button(onClick = viewModel::resumeImmersive) {
                        Text("继续播放")
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(onClick = viewModel::stopImmersivePlayback) {
                        Text("停止播放")
                    }
                }
            }
        }
    }

    val selected = state.selectedWord
    if (selected != null && !state.isImmersivePlaying) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(
            onDismissRequest = { viewModel.selectWord(null) },
            sheetState = sheetState,
            containerColor = Color(0xFF1E1E1E),
        ) {
            Column(modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)) {
                Text(
                    text = selected.word,
                    color = Color.White,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(text = selected.chineseDefinition, color = Color.White, fontSize = 16.sp)
                Spacer(modifier = Modifier.height(8.dp))
                Text(text = selected.explanation, color = Color.LightGray, fontSize = 14.sp)
                Spacer(modifier = Modifier.height(16.dp))
                TextButton(onClick = { viewModel.selectWord(null) }) {
                    Text("关闭")
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }

    if (showSettings) {
        SettingsDialog(
            config = state.displayConfig,
            ttsManager = viewModel.ttsManager,
            onConfigChange = viewModel::updateConfig,
            onDismiss = { showSettings = false },
        )
    }

    if (showImmersiveConfig) {
        ImmersiveConfigSheet(
            config = state.immersiveConfig,
            ttsManager = viewModel.ttsManager,
            onDismiss = { showImmersiveConfig = false },
            onSave = viewModel::updateImmersiveConfig,
            onStart = {
                showImmersiveConfig = false
                viewModel.startImmersivePlayback(it)
            },
        )
    }
}

@Composable
private fun TopBar(
    immersivePlaying: Boolean,
    controlsEnabled: Boolean,
    onOpenBookshelf: () -> Unit,
    onOpenEyes: () -> Unit,
    onOpenSleep: () -> Unit,
    onQuickPlay: () -> Unit,
    onOpenImmersive: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (controlsEnabled) {
            IconButton(onClick = onOpenBookshelf) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.MenuBook,
                    contentDescription = "书架",
                    tint = Color.White,
                )
            }
            IconButton(onClick = onOpenEyes) {
                Icon(
                    imageVector = Icons.Filled.RemoveRedEye,
                    contentDescription = "眼保健操",
                    tint = Color.White,
                )
            }
            IconButton(onClick = onOpenSleep) {
                Icon(
                    imageVector = Icons.Filled.NightsStay,
                    contentDescription = "睡眠",
                    tint = Color.White,
                )
            }
        }
        Spacer(modifier = Modifier.weight(1f))
        if (controlsEnabled) {
            IconButton(onClick = onQuickPlay) {
                Icon(Icons.Filled.PlayArrow, contentDescription = "快速播放", tint = Color.White)
            }
            IconButton(onClick = onOpenImmersive) {
                Icon(Icons.Filled.Headset, contentDescription = "自动播放", tint = Color.White)
            }
            IconButton(onClick = onOpenSettings) {
                Icon(Icons.Filled.Settings, contentDescription = "设置", tint = Color.White)
            }
        } else if (immersivePlaying) {
            Spacer(modifier = Modifier.size(48.dp))
        }
    }
}

@Composable
private fun BottomNav(
    canGoPrev: Boolean,
    canGoNext: Boolean,
    onPrev: () -> Unit,
    onNext: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 30.dp, top = 16.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(
                    if (canGoPrev) Color(0xFF333333) else Color(0xFF333333).copy(alpha = 0.4f),
                )
                .clickable(enabled = canGoPrev, onClick = onPrev),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = "上一句",
                tint = Color.White,
                modifier = Modifier.size(32.dp),
            )
        }
        Spacer(modifier = Modifier.size(30.dp))
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(
                    if (canGoNext) Color(0xFF007AFF) else Color(0xFF007AFF).copy(alpha = 0.4f),
                )
                .clickable(enabled = canGoNext, onClick = onNext),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = "下一句",
                tint = Color.White,
                modifier = Modifier.size(32.dp),
            )
        }
    }
}

