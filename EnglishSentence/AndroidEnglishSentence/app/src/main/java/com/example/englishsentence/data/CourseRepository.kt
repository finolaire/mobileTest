package com.example.englishsentence.data

import android.content.Context
import com.example.englishsentence.data.model.CourseManifest
import com.example.englishsentence.data.model.CourseSection
import com.example.englishsentence.data.model.CourseUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class CourseRepository(private val context: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    @Volatile
    private var cachedSections: List<CourseSection>? = null

    suspend fun getAllCourses(forceReload: Boolean = false): List<CourseSection> =
        withContext(Dispatchers.IO) {
            if (!forceReload) {
                cachedSections?.let { return@withContext it }
            }
            val sections = loadFromManifest()
            cachedSections = sections
            sections
        }

    suspend fun getAllCourseUnits(forceReload: Boolean = false): List<CourseUnit> =
        getAllCourses(forceReload).flatMap { it.courses }

    suspend fun getCourseById(id: String): CourseUnit? =
        getAllCourseUnits().firstOrNull { it.id == id }

    private fun loadFromManifest(): List<CourseSection> {
        val assets = context.assets
        val manifestText = assets.open("SentenceJson/SentenceJsonConfig.json")
            .bufferedReader()
            .use { it.readText() }
        val manifest = json.decodeFromString<CourseManifest>(manifestText)
        val seenIds = mutableSetOf<String>()
        return manifest.sections.mapNotNull { section ->
            val courses = section.files.mapNotNull { filename ->
                val path = "SentenceJson/${section.directory}/$filename"
                runCatching {
                    val text = assets.open(path).bufferedReader().use { it.readText() }
                    json.decodeFromString<CourseUnit>(text)
                }.getOrNull()
                    ?.takeIf { it.sentences.isNotEmpty() && seenIds.add(it.id) }
            }
            if (courses.isEmpty()) null else CourseSection(section.title, courses)
        }
    }
}
