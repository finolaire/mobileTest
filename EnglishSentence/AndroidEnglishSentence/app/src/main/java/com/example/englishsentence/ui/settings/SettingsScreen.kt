package com.example.englishsentence.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.englishsentence.data.model.DisplayConfig
import com.example.englishsentence.service.TtsManager
import kotlin.math.roundToInt

private val DialogBg = Color(0xCC262626)
private val AccentBlue = Color(0xFF0A84FF)
@Composable
private fun switchColors() = SwitchDefaults.colors(
    checkedTrackColor = Color(0xFF34C759),
    checkedThumbColor = Color.White,
    uncheckedTrackColor = Color(0xFF3A3A3C),
    uncheckedThumbColor = Color.White,
    uncheckedBorderColor = Color.Transparent,
)

@Composable
fun SettingsDialog(
    config: DisplayConfig,
    ttsManager: TtsManager,
    onConfigChange: (DisplayConfig) -> Unit,
    onDismiss: () -> Unit,
) {
    var offsetX by remember { mutableFloatStateOf(0f) }
    var offsetY by remember { mutableFloatStateOf(0f) }
    var showVoicePicker by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.6f))
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = onDismiss,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .offset { IntOffset(offsetX.roundToInt(), offsetY.roundToInt()) }
                .width(300.dp)
                .heightIn(max = 640.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(DialogBg)
                .clickable(
                    indication = null,
                    interactionSource = remember { MutableInteractionSource() },
                    onClick = {},
                )
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .pointerInput(Unit) {
                        detectDragGestures { change, dragAmount ->
                            change.consume()
                            offsetX += dragAmount.x
                            offsetY += dragAmount.y
                        }
                    },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(modifier = Modifier.height(10.dp))
                Box(
                    modifier = Modifier
                        .width(40.dp)
                        .height(5.dp)
                        .clip(RoundedCornerShape(2.5.dp))
                        .background(Color.Gray),
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = "设置",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                SwitchRow("显示音标", config.showPhonetics) {
                    onConfigChange(config.copy(showPhonetics = it))
                }
                AccentRow(config.phoneticType) { type ->
                    onConfigChange(
                        config.copy(
                            phoneticType = type,
                            selectedVoiceIdentifier = null,
                        ),
                    )
                }
                VoiceRow(
                    voiceName = voiceDisplayName(config, ttsManager),
                    onClick = { showVoicePicker = true },
                )
                SwitchRow("显示词性", config.showWordType) {
                    onConfigChange(config.copy(showWordType = it))
                }
                CombinedSwitchRow(
                    title1 = "中文翻译",
                    checked1 = config.showTranslation,
                    onChecked1 = { onConfigChange(config.copy(showTranslation = it)) },
                    title2 = "朗读",
                    checked2 = config.showTranslationAudioButton,
                    onChecked2 = { onConfigChange(config.copy(showTranslationAudioButton = it)) },
                )
                CombinedSwitchRow(
                    title1 = "英文原句",
                    checked1 = config.showEnglishSentence,
                    onChecked1 = { onConfigChange(config.copy(showEnglishSentence = it)) },
                    title2 = "朗读",
                    checked2 = config.showEnglishAudioButton,
                    onChecked2 = { onConfigChange(config.copy(showEnglishAudioButton = it)) },
                )
                CombinedSwitchRow(
                    title1 = "显示句型",
                    checked1 = config.showSentencePattern,
                    onChecked1 = { onConfigChange(config.copy(showSentencePattern = it)) },
                    title2 = "朗读",
                    checked2 = config.speakSentencePattern,
                    onChecked2 = { onConfigChange(config.copy(speakSentencePattern = it)) },
                )
                SwitchRow("显示单词朗读", config.showAudioButton) {
                    onConfigChange(config.copy(showAudioButton = it))
                }

                Spacer(modifier = Modifier.height(8.dp))
                Text("背景图片", color = Color.White, fontSize = 16.sp)
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    listOf("梦", "禅", "忍", "空").forEachIndexed { index, label ->
                        val selected = !config.useCustomBackground && config.backgroundImageIndex == index
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(if (selected) AccentBlue else Color(0xFF3A3A3C))
                                .clickable {
                                    onConfigChange(
                                        config.copy(
                                            backgroundImageIndex = index,
                                            useCustomBackground = false,
                                        ),
                                    )
                                },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(label, color = Color.White, fontSize = 14.sp)
                        }
                    }
                    Icon(
                        imageVector = Icons.Filled.AddAPhoto,
                        contentDescription = "自定义背景",
                        tint = if (config.useCustomBackground) AccentBlue else Color.White,
                        modifier = Modifier.size(28.dp),
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = String.format("背景透明度: %.1f", config.maskOpacity),
                    color = Color.White,
                    fontSize = 16.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
                Slider(
                    value = config.maskOpacity,
                    onValueChange = { onConfigChange(config.copy(maskOpacity = it)) },
                    valueRange = 0f..1f,
                    colors = SliderDefaults.colors(
                        thumbColor = Color.White,
                        activeTrackColor = AccentBlue,
                        inactiveTrackColor = Color(0xFF3A3A3C),
                    ),
                )

                Spacer(modifier = Modifier.height(8.dp))
                TextButton(onClick = onDismiss) {
                    Text("关闭", color = AccentBlue, fontSize = 16.sp)
                }
                Spacer(modifier = Modifier.height(12.dp))
            }
        }
    }

    if (showVoicePicker) {
        val voices = remember(config.phoneticType) {
            ttsManager.availableVoices(config.englishLanguageCode)
        }
        AlertDialog(
            onDismissRequest = { showVoicePicker = false },
            title = { Text("选择发音人") },
            text = {
                Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                    TextButton(
                        onClick = {
                            onConfigChange(config.copy(selectedVoiceIdentifier = null))
                            showVoicePicker = false
                        },
                    ) {
                        Text("默认", color = AccentBlue)
                    }
                    voices.forEach { voice ->
                        TextButton(
                            onClick = {
                                onConfigChange(config.copy(selectedVoiceIdentifier = voice.name))
                                showVoicePicker = false
                            },
                        ) {
                            Text(voice.name, color = AccentBlue)
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showVoicePicker = false }) {
                    Text("取消")
                }
            },
        )
    }
}

@Composable
private fun SwitchRow(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, color = Color.White, fontSize = 16.sp, modifier = Modifier.weight(1f))
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = switchColors(),
        )
    }
}

@Composable
private fun CombinedSwitchRow(
    title1: String,
    checked1: Boolean,
    onChecked1: (Boolean) -> Unit,
    title2: String,
    checked2: Boolean,
    onChecked2: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title1, color = Color.White, fontSize = 14.sp)
        Spacer(modifier = Modifier.width(6.dp))
        Switch(
            checked = checked1,
            onCheckedChange = onChecked1,
            colors = switchColors(),
        )
        Spacer(modifier = Modifier.weight(1f))
        Text(title2, color = Color.White, fontSize = 14.sp)
        Spacer(modifier = Modifier.width(6.dp))
        Switch(
            checked = checked2,
            onCheckedChange = onChecked2,
            colors = switchColors(),
        )
    }
}

@Composable
private fun AccentRow(
    phoneticType: DisplayConfig.PhoneticType,
    onChange: (DisplayConfig.PhoneticType) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("口音", color = Color.White, fontSize = 16.sp, modifier = Modifier.weight(1f))
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(8.dp))
                .background(Color(0xFF3A3A3C)),
        ) {
            AccentSegment(
                label = "英式",
                selected = phoneticType == DisplayConfig.PhoneticType.UK,
                onClick = { onChange(DisplayConfig.PhoneticType.UK) },
            )
            AccentSegment(
                label = "美式",
                selected = phoneticType == DisplayConfig.PhoneticType.US,
                onClick = { onChange(DisplayConfig.PhoneticType.US) },
            )
        }
    }
}

@Composable
private fun AccentSegment(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Text(
        text = label,
        color = Color.White,
        fontSize = 13.sp,
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(if (selected) AccentBlue else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 6.dp),
    )
}

@Composable
private fun VoiceRow(
    voiceName: String,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("发音人", color = Color.White, fontSize = 16.sp, modifier = Modifier.weight(1f))
        Text(
            text = voiceName,
            color = AccentBlue,
            fontSize = 16.sp,
            modifier = Modifier.clickable(onClick = onClick),
        )
    }
}

private fun voiceDisplayName(config: DisplayConfig, ttsManager: TtsManager): String {
    val id = config.selectedVoiceIdentifier ?: return "默认"
    return ttsManager.availableVoices(config.englishLanguageCode)
        .firstOrNull { it.name == id }
        ?.name
        ?: "默认"
}
