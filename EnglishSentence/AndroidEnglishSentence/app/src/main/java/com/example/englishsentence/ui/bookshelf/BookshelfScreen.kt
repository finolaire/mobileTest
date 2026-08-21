package com.example.englishsentence.ui.bookshelf

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.englishsentence.R
import com.example.englishsentence.data.model.CourseSection
import com.example.englishsentence.data.model.CourseUnit

private val BookshelfBg = Color(0xFF111823)
private val AccentBlue = Color(0xFF258CF4)
private val PlayBg = Color(0xFF163354)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookshelfScreen(
    sections: List<CourseSection>,
    currentCourseId: String?,
    onBack: () -> Unit,
    onReload: () -> Unit,
    onSelectCourse: (CourseUnit) -> Unit,
    onOpenReading: (CourseUnit) -> Unit,
) {
    val expanded = remember {
        mutableStateMapOf<String, Boolean>().apply {
            sections.forEach { put(it.categoryName, true) }
        }
    }
    val total = sections.sumOf { it.courses.size }

    Scaffold(
        containerColor = BookshelfBg,
        topBar = {
            TopAppBar(
                title = { Text("Bookshelf ($total)") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = onReload) {
                        Icon(Icons.Filled.Refresh, contentDescription = "刷新")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BookshelfBg,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White,
                    actionIconContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            sections.forEach { section ->
                val isExpanded = expanded[section.categoryName] != false
                item(key = "header-${section.categoryName}") {
                    SectionHeader(
                        title = section.categoryName,
                        expanded = isExpanded,
                        onClick = {
                            expanded[section.categoryName] = !isExpanded
                        },
                    )
                }
                if (isExpanded) {
                    itemsIndexed(
                        items = section.courses,
                        key = { _, course -> course.id },
                    ) { _, course ->
                        CourseRow(
                            course = course,
                            selected = course.id == currentCourseId,
                            onSelect = { onSelectCourse(course) },
                            onOpenReading = { onOpenReading(course) },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    expanded: Boolean,
    onClick: () -> Unit,
) {
    val rotation by animateFloatAsState(if (expanded) 90f else 0f, label = "chevron")
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.rotate(rotation),
        )
        Spacer(modifier = Modifier.width(4.dp))
        Icon(
            imageVector = Icons.Filled.Folder,
            contentDescription = null,
            tint = Color(0xFFFFD54F),
            modifier = Modifier.size(18.dp),
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = title,
            color = Color.White,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun CourseRow(
    course: CourseUnit,
    selected: Boolean,
    onSelect: () -> Unit,
    onOpenReading: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onSelect)
            .padding(start = 50.dp, end = 12.dp, top = 8.dp, bottom = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.PlayArrow,
            contentDescription = null,
            tint = if (selected) Color.White else AccentBlue,
            modifier = Modifier
                .size(24.dp)
                .clip(CircleShape)
                .background(if (selected) AccentBlue else PlayBg)
                .padding(2.dp),
        )
        Spacer(modifier = Modifier.width(10.dp))
        Text(
            text = course.unitName,
            color = if (selected) AccentBlue else Color.White,
            fontSize = 15.sp,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
            modifier = Modifier.weight(1f),
        )
        IconButton(onClick = onOpenReading) {
            Icon(
                painter = painterResource(R.drawable.ic_book_all),
                contentDescription = "查看全文",
                tint = Color.Unspecified,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}
