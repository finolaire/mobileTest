package com.example.englishsentence.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.englishsentence.data.model.DisplayConfig
import com.example.englishsentence.data.model.ImmersiveReadingConfig
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "rabbit_english")

class PreferenceStore(private val context: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private val displayConfigKey = stringPreferencesKey("DisplayConfig")
    private val immersiveConfigKey = stringPreferencesKey("ImmersiveReadingConfig")
    private val lastPlayedCourseIdKey = stringPreferencesKey("LastPlayedCourseId")

    val displayConfig: Flow<DisplayConfig> = context.dataStore.data.map { prefs ->
        prefs[displayConfigKey]
            ?.let { runCatching { json.decodeFromString<DisplayConfig>(it) }.getOrNull() }
            ?: DisplayConfig()
    }

    val immersiveConfig: Flow<ImmersiveReadingConfig> = context.dataStore.data.map { prefs ->
        prefs[immersiveConfigKey]
            ?.let { runCatching { json.decodeFromString<ImmersiveReadingConfig>(it) }.getOrNull() }
            ?.normalized()
            ?: ImmersiveReadingConfig()
    }

    val lastPlayedCourseId: Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[lastPlayedCourseIdKey]
    }

    suspend fun saveDisplayConfig(config: DisplayConfig) {
        context.dataStore.edit { prefs ->
            prefs[displayConfigKey] = json.encodeToString(DisplayConfig.serializer(), config)
        }
    }

    suspend fun saveImmersiveConfig(config: ImmersiveReadingConfig) {
        context.dataStore.edit { prefs ->
            prefs[immersiveConfigKey] =
                json.encodeToString(ImmersiveReadingConfig.serializer(), config.normalized())
        }
    }

    suspend fun saveLastPlayedCourseId(id: String) {
        context.dataStore.edit { prefs ->
            prefs[lastPlayedCourseIdKey] = id
        }
    }
}
