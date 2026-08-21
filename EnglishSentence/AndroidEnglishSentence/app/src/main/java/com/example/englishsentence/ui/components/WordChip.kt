package com.example.englishsentence.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.englishsentence.data.model.DisplayConfig
import com.example.englishsentence.data.model.WordAnalysis
import com.example.englishsentence.ui.theme.AppThemeColors

private val VolumeIcon = Icons.AutoMirrored.Filled.VolumeUp

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun WordChipRow(
    words: List<WordAnalysis>,
    config: DisplayConfig,
    onWordClick: (WordAnalysis) -> Unit,
    onSpeakWord: (WordAnalysis) -> Unit,
) {
    FlowRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        words.forEach { word ->
            WordChip(
                analysis = word,
                config = config,
                onClick = { onWordClick(word) },
                onSpeak = { onSpeakWord(word) },
            )
        }
    }
}

@Composable
fun WordChip(
    analysis: WordAnalysis,
    config: DisplayConfig,
    onClick: () -> Unit,
    onSpeak: () -> Unit,
) {
    val phonetic = when (config.phoneticType) {
        DisplayConfig.PhoneticType.UK -> analysis.phonetics.uk.orEmpty()
        DisplayConfig.PhoneticType.US -> analysis.phonetics.us.orEmpty()
    }

    Column(
        modifier = Modifier
            .widthIn(min = 72.dp)
            .clickable(onClick = onClick)
            .padding(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = analysis.word,
            color = AppThemeColors.colorForTag(analysis.tag),
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Visible,
        )
        if (config.showPhonetics && phonetic.isNotBlank()) {
            Text(
                text = phonetic,
                color = Color.LightGray,
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                maxLines = 1,
                softWrap = false,
                overflow = TextOverflow.Visible,
            )
        }
        if (config.showWordType) {
            Text(
                text = analysis.type,
                color = Color(0xFFFFA500),
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center,
                maxLines = 1,
                softWrap = false,
                overflow = TextOverflow.Visible,
            )
        }
        if (config.showAudioButton) {
            IconButton(onClick = onSpeak) {
                Icon(
                    imageVector = VolumeIcon,
                    contentDescription = "朗读单词",
                    tint = Color.White.copy(alpha = 0.75f),
                )
            }
        }
    }
}

@Composable
fun SentenceCard(
    showSpeak: Boolean,
    onSpeak: () -> Unit,
    maskAlpha: Float,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp)
            .background(Color(0xFF172033).copy(alpha = maskAlpha.coerceIn(0f, 1f)), RoundedCornerShape(8.dp))
            .padding(horizontal = 12.dp, vertical = 12.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(end = if (showSpeak) 40.dp else 0.dp),
        ) {
            content()
        }
        if (showSpeak) {
            IconButton(
                onClick = onSpeak,
                modifier = Modifier.align(Alignment.CenterEnd),
            ) {
                Icon(
                    imageVector = VolumeIcon,
                    contentDescription = "朗读",
                    tint = Color.White,
                )
            }
        }
    }
}
