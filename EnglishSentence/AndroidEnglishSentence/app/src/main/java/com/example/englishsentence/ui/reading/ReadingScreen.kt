package com.example.englishsentence.ui.reading

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.englishsentence.data.model.CourseUnit
import com.example.englishsentence.data.model.Sentence
import com.example.englishsentence.data.model.WordAnalysis
import com.example.englishsentence.ui.theme.AppThemeColors
import com.example.englishsentence.ui.util.buildEnglishAnnotated
import com.example.englishsentence.ui.util.buildPatternAnnotated
import com.example.englishsentence.ui.util.buildTranslationAnnotated

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReadingScreen(
    course: CourseUnit,
    onBack: () -> Unit,
) {
    var selectedWord by remember { mutableStateOf<WordAnalysis?>(null) }

    Scaffold(
        containerColor = Color.Black,
        topBar = {
            TopAppBar(
                title = { Text(course.unitName) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "关闭")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            items(course.sentences, key = { it.id }) { sentence ->
                ReadingSentenceItem(
                    sentence = sentence,
                    onWordClick = { selectedWord = it },
                )
            }
        }
    }

    val word = selectedWord
    if (word != null) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(
            onDismissRequest = { selectedWord = null },
            sheetState = sheetState,
            containerColor = AppThemeColors.colorForTag(word.tag),
        ) {
            Column(modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)) {
                Text(
                    text = word.chineseDefinition,
                    color = Color.Black,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = word.explanation,
                    color = Color.Black.copy(alpha = 0.7f),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                )
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun ReadingSentenceItem(
    sentence: Sentence,
    onWordClick: (WordAnalysis) -> Unit,
) {
    val english = remember(sentence) {
        buildEnglishAnnotated(sentence.sentenceInfo.original, sentence.analysis)
    }
    val translation = remember(sentence) {
        buildTranslationAnnotated(sentence.sentenceInfo.translation, sentence.analysis)
    }
    val pattern = remember(sentence) {
        buildPatternAnnotated(sentence.sentenceInfo.sentencePattern)
    }
    var englishLayout by remember { mutableStateOf<TextLayoutResult?>(null) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
    ) {
        Text(
            text = english,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            softWrap = true,
            onTextLayout = { englishLayout = it },
            modifier = Modifier
                .fillMaxWidth()
                .pointerInput(sentence) {
                detectTapGestures { offset ->
                    val layout = englishLayout ?: return@detectTapGestures
                    val index = layout.getOffsetForPosition(offset)
                    val word = sentence.analysis.firstOrNull { analysis ->
                        val start = analysis.range.getOrNull(0) ?: return@firstOrNull false
                        val end = analysis.range.getOrNull(1) ?: return@firstOrNull false
                        index in start until end
                    } ?: sentence.analysis.firstOrNull { analysis ->
                        val start = sentence.sentenceInfo.original.indexOf(analysis.word)
                        if (start < 0) return@firstOrNull false
                        index in start until (start + analysis.word.length)
                    }
                    word?.let(onWordClick)
                }
            },
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = translation,
            fontSize = 16.sp,
            color = Color.LightGray,
            softWrap = true,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = pattern,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            softWrap = true,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(
            modifier = Modifier
                .padding(top = 12.dp)
                .fillMaxWidth()
                .height(1.dp)
                .background(Color.White.copy(alpha = 0.08f)),
        )
    }
}
