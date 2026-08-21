package com.example.englishsentence

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.englishsentence.ui.bookshelf.BookshelfScreen
import com.example.englishsentence.ui.learning.LearningScreen
import com.example.englishsentence.ui.learning.LearningViewModel
import com.example.englishsentence.ui.overlay.OverlayScreen
import com.example.englishsentence.ui.overlay.OverlayType
import com.example.englishsentence.ui.reading.ReadingScreen
import com.example.englishsentence.ui.theme.EnglishSentenceTheme

class MainActivity : ComponentActivity() {

    private val learningViewModel: LearningViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            EnglishSentenceTheme(darkTheme = true, dynamicColor = false) {
                val navController = rememberNavController()
                val learningState by learningViewModel.uiState.collectAsStateWithLifecycle()
                val sections by learningViewModel.sections.collectAsStateWithLifecycle()

                NavHost(
                    navController = navController,
                    startDestination = Routes.Learning,
                ) {
                    composable(Routes.Learning) {
                        LearningScreen(
                            viewModel = learningViewModel,
                            onOpenBookshelf = { navController.navigate(Routes.Bookshelf) },
                            onOpenEyes = {
                                learningViewModel.stopImmersivePlayback()
                                navController.navigate(Routes.OverlayEyes)
                            },
                            onOpenSleep = {
                                learningViewModel.stopImmersivePlayback()
                                navController.navigate(Routes.OverlaySleep)
                            },
                        )
                    }
                    composable(Routes.Bookshelf) {
                        BookshelfScreen(
                            sections = sections,
                            currentCourseId = learningState.course?.id,
                            onBack = { navController.popBackStack() },
                            onReload = learningViewModel::reloadBookshelf,
                            onSelectCourse = { course ->
                                learningViewModel.selectCourse(course)
                                navController.popBackStack()
                            },
                            onOpenReading = { course ->
                                navController.navigate(Routes.reading(course.id))
                            },
                        )
                    }
                    composable(
                        route = Routes.Reading,
                        arguments = listOf(
                            navArgument(Routes.CourseIdArg) { type = NavType.StringType },
                        ),
                    ) { entry ->
                        val courseId = entry.arguments?.getString(Routes.CourseIdArg)
                        val course = remember(courseId, sections) {
                            sections.flatMap { it.courses }.firstOrNull { it.id == courseId }
                        }
                        if (course != null) {
                            ReadingScreen(
                                course = course,
                                onBack = { navController.popBackStack() },
                            )
                        } else {
                            BookshelfScreen(
                                sections = sections,
                                currentCourseId = learningState.course?.id,
                                onBack = { navController.popBackStack() },
                                onReload = learningViewModel::reloadBookshelf,
                                onSelectCourse = { courseUnit ->
                                    learningViewModel.selectCourse(courseUnit)
                                    navController.popBackStack(Routes.Learning, inclusive = false)
                                },
                                onOpenReading = { courseUnit ->
                                    navController.navigate(Routes.reading(courseUnit.id)) {
                                        popUpTo(Routes.Bookshelf) { inclusive = false }
                                    }
                                },
                            )
                        }
                    }
                    composable(Routes.OverlayEyes) {
                        OverlayScreen(
                            type = OverlayType.Eyes,
                            onExit = { navController.popBackStack() },
                        )
                    }
                    composable(Routes.OverlaySleep) {
                        OverlayScreen(
                            type = OverlayType.Sleep,
                            onExit = { navController.popBackStack() },
                        )
                    }
                }
            }
        }
    }
}

private object Routes {
    const val Learning = "learning"
    const val Bookshelf = "bookshelf"
    const val CourseIdArg = "courseId"
    const val Reading = "reading/{$CourseIdArg}"
    const val OverlayEyes = "overlay/eyes"
    const val OverlaySleep = "overlay/sleep"

    fun reading(courseId: String): String = "reading/$courseId"
}
