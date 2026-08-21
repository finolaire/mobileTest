package com.example.englishsentence.ui.immersive

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.englishsentence.data.IntervalSoundDefinitions
import com.example.englishsentence.data.model.ImmersiveReadingConfig
import com.example.englishsentence.service.TtsManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImmersiveConfigSheet(
    config: ImmersiveReadingConfig,
    ttsManager: TtsManager,
    onDismiss: () -> Unit,
    onSave: (ImmersiveReadingConfig) -> Unit,
    onStart: (ImmersiveReadingConfig) -> Unit,
) {
    var draft by remember(config) { mutableStateOf(config.normalized()) }
    var showSoundPicker by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    fun persist(updated: ImmersiveReadingConfig) {
        draft = updated.normalized()
        onSave(draft)
    }

    ModalBottomSheet(
        onDismissRequest = {
            onSave(draft)
            onDismiss()
        },
        sheetState = sheetState,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 640.dp)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 8.dp),
        ) {
            Text("自动播放", fontSize = 20.sp)
            Spacer(modifier = Modifier.height(12.dp))

            Text("播放速度调整")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(0.5f, 1.0f, 1.5f).forEach { rate ->
                    FilterChip(
                        selected = draft.playbackRate == rate,
                        onClick = { persist(draft.copy(playbackRate = rate)) },
                        label = { Text("${rate}x") },
                    )
                }
            }
            Text(String.format("当前速度: %.2fx", draft.playbackRate))
            Slider(
                value = draft.playbackRate,
                onValueChange = { persist(draft.copy(playbackRate = it)) },
                valueRange = 0.5f..2.0f,
            )

            Text("小句子时间间隙")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(1.0, 2.0, 3.0).forEach { seconds ->
                    FilterChip(
                        selected = draft.smallSentenceInterval == seconds,
                        onClick = { persist(draft.copy(smallSentenceInterval = seconds)) },
                        label = { Text("${seconds.toInt()}s") },
                    )
                }
            }
            Text(String.format("小句子间隙: %.1fs", draft.smallSentenceInterval))
            Slider(
                value = draft.smallSentenceInterval.toFloat(),
                onValueChange = { persist(draft.copy(smallSentenceInterval = it.toDouble())) },
                valueRange = 0.5f..5f,
            )

            Text("大句子时间间隙")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(1.0, 2.0, 3.0).forEach { seconds ->
                    FilterChip(
                        selected = draft.largeSentenceInterval == seconds,
                        onClick = { persist(draft.copy(largeSentenceInterval = seconds)) },
                        label = { Text("${seconds.toInt()}s") },
                    )
                }
            }
            Text(String.format("大句子间隙: %.1fs", draft.largeSentenceInterval))
            Slider(
                value = draft.largeSentenceInterval.toFloat(),
                onValueChange = { persist(draft.copy(largeSentenceInterval = it.toDouble())) },
                valueRange = 0.5f..5f,
            )

            SettingRow("句子间隔提示音", draft.enableIntervalSound) {
                persist(draft.copy(enableIntervalSound = it))
            }
            if (draft.enableIntervalSound) {
                TextButton(onClick = { showSoundPicker = true }) {
                    Text("间隔音：${draft.intervalSoundFile}")
                }
            }

            SettingRow("支持锁定屏幕播放", draft.lockScreenPlayback) {
                persist(draft.copy(lockScreenPlayback = it))
            }
            SettingRow("定时自动关闭播放", draft.autoStopEnabled) {
                persist(draft.copy(autoStopEnabled = it))
            }
            if (draft.autoStopEnabled) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(5, 15, 30).forEach { minutes ->
                        FilterChip(
                            selected = draft.autoStopMinutes == minutes,
                            onClick = { persist(draft.copy(autoStopMinutes = minutes)) },
                            label = { Text("${minutes}分钟") },
                        )
                    }
                }
                Text("自定义: ${draft.autoStopMinutes} 分钟")
                Slider(
                    value = draft.autoStopMinutes.toFloat(),
                    onValueChange = { persist(draft.copy(autoStopMinutes = it.toInt())) },
                    valueRange = 1f..120f,
                )
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text("播放选项")
            SettingRow("播放英文 ", true, enabled = false) {}
            SettingRow("播放中文 ", draft.playTranslation) {
                persist(draft.copy(playTranslation = it))
            }
            SettingRow("播放语法 ", draft.playSentencePattern) {
                persist(draft.copy(playSentencePattern = it))
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text("排序菜单（仅显示已开启项）")
            PlayOrderEditor(draft) { persist(it) }

            Spacer(modifier = Modifier.height(8.dp))
            Text("播放句型数量")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("three" to "3", "five" to "5", "all" to "全部", "custom" to "自定义").forEach { (key, label) ->
                    FilterChip(
                        selected = (draft.sentenceCountOption ?: "all") == key,
                        onClick = { persist(draft.copy(sentenceCountOption = key)) },
                        label = { Text(label) },
                    )
                }
            }
            if (draft.sentenceCountOption == "custom") {
                Text("自定义数量: ${draft.customSentenceCount ?: 10}")
                Slider(
                    value = (draft.customSentenceCount ?: 10).toFloat(),
                    onValueChange = { persist(draft.copy(customSentenceCount = it.toInt())) },
                    valueRange = 1f..50f,
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = {
                    onSave(draft)
                    onStart(draft)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
            ) {
                Text("开始播放")
            }
            TextButton(
                onClick = {
                    onSave(draft)
                    onDismiss()
                },
                modifier = Modifier.align(Alignment.CenterHorizontally),
            ) {
                Text("关闭")
            }
            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    if (showSoundPicker) {
        IntervalSoundPickerSheet(
            selected = draft.intervalSoundFile,
            ttsManager = ttsManager,
            onSelect = {
                persist(draft.copy(intervalSoundFile = it))
                showSoundPicker = false
            },
            onDismiss = { showSoundPicker = false },
        )
    }
}

@Composable
private fun SettingRow(
    title: String,
    checked: Boolean,
    enabled: Boolean = true,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onCheckedChange, enabled = enabled)
    }
}

@Composable
private fun PlayOrderEditor(
    config: ImmersiveReadingConfig,
    onChange: (ImmersiveReadingConfig) -> Unit,
) {
    data class OrderItem(val key: String, val label: String, val order: Int)

    val items = remember(config) {
        buildList {
            add(OrderItem("original", "播放英文 ", config.orderOriginal))
            if (config.playTranslation) {
                add(OrderItem("translation", "播放中文 ", config.orderTranslation))
            }
            if (config.playSentencePattern) {
                add(OrderItem("pattern", "播放语法 ", config.orderPattern))
            }
        }.sortedBy { it.order }
    }

    Column {
        items.forEachIndexed { index, item ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("${index + 1}. ${item.label}", modifier = Modifier.weight(1f))
                if (index > 0) {
                    TextButton(onClick = {
                        val reordered = items.toMutableList()
                        val prev = reordered[index - 1]
                        reordered[index - 1] = item
                        reordered[index] = prev
                        onChange(applyOrder(config, reordered.map { it.key }))
                    }) { Text("上移") }
                }
                if (index < items.lastIndex) {
                    TextButton(onClick = {
                        val reordered = items.toMutableList()
                        val next = reordered[index + 1]
                        reordered[index + 1] = item
                        reordered[index] = next
                        onChange(applyOrder(config, reordered.map { it.key }))
                    }) { Text("下移") }
                }
            }
        }
    }
}

private fun applyOrder(config: ImmersiveReadingConfig, keys: List<String>): ImmersiveReadingConfig {
    var orderOriginal = config.orderOriginal
    var orderTranslation = config.orderTranslation
    var orderPattern = config.orderPattern
    keys.forEachIndexed { index, key ->
        when (key) {
            "original" -> orderOriginal = index + 1
            "translation" -> orderTranslation = index + 1
            "pattern" -> orderPattern = index + 1
        }
    }
    return config.copy(
        orderOriginal = orderOriginal,
        orderTranslation = orderTranslation,
        orderPattern = orderPattern,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IntervalSoundPickerSheet(
    selected: String,
    ttsManager: TtsManager,
    onSelect: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
            Text("选择间隔声音", fontSize = 18.sp)
            Spacer(modifier = Modifier.height(8.dp))
            IntervalSoundDefinitions.allSounds.forEach { name ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onSelect(name) }
                        .padding(vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = if (name == selected) "✓  $name" else name,
                        modifier = Modifier.weight(1f),
                    )
                    TextButton(onClick = {
                        IntervalSoundDefinitions.resIdFor(name)?.let { resId ->
                            ttsManager.playIntervalSound(resId)
                        }
                    }) {
                        Text("试听")
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
