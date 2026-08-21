package com.example.englishsentence.ui.overlay

import android.media.MediaPlayer
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.annotation.RawRes
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.example.englishsentence.R
import java.util.concurrent.atomic.AtomicBoolean

enum class OverlayType(
    @param:RawRes val videoRes: Int,
    @param:RawRes val audioRes: Int,
) {
    Eyes(R.raw.eyes_animation, R.raw.eyes_audio),
    Sleep(R.raw.sleep_animation, R.raw.sleep_audio),
}

@Composable
fun OverlayScreen(
    type: OverlayType,
    onExit: () -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val view = LocalView.current
    var controlsVisible by remember { mutableStateOf(false) }
    val userPaused = remember { AtomicBoolean(false) }

    val exoPlayer = remember {
        ExoPlayer.Builder(context).build().apply {
            val uri = "android.resource://${context.packageName}/${type.videoRes}".toUri()
            setMediaItem(MediaItem.fromUri(uri))
            repeatMode = Player.REPEAT_MODE_ONE
            volume = 0f
            prepare()
            playWhenReady = true
        }
    }

    val audioPlayer = remember {
        MediaPlayer.create(context, type.audioRes)?.apply {
            isLooping = true
            start()
        }
    }

    fun pausePlayback() {
        userPaused.set(true)
        exoPlayer.pause()
        audioPlayer?.pause()
    }

    fun resumePlayback() {
        userPaused.set(false)
        exoPlayer.play()
        audioPlayer?.let { player ->
            if (!player.isPlaying) player.start()
        }
    }

    DisposableEffect(Unit) {
        val window = view.context.findActivityWindow()
        window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        onDispose {
            window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    DisposableEffect(lifecycleOwner, exoPlayer, audioPlayer) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> {
                    if (!userPaused.get()) {
                        exoPlayer.play()
                        audioPlayer?.let { player ->
                            if (!player.isPlaying) player.start()
                        }
                    }
                }
                Lifecycle.Event.ON_PAUSE -> {
                    if (!userPaused.get()) {
                        exoPlayer.pause()
                        audioPlayer?.pause()
                    }
                }
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            exoPlayer.release()
            audioPlayer?.runCatching {
                stop()
                release()
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black),
    ) {
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                    resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                    layoutParams = FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                    )
                }
            },
            modifier = Modifier.fillMaxSize(),
        )

        if (!controlsVisible) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable(
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() },
                    ) {
                        pausePlayback()
                        controlsVisible = true
                    },
            )
        } else {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable(
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() },
                    ) {
                        resumePlayback()
                        controlsVisible = false
                    },
            )
            Row(
                modifier = Modifier.align(Alignment.Center),
                horizontalArrangement = Arrangement.spacedBy(48.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconButton(
                    onClick = {
                        resumePlayback()
                        controlsVisible = false
                    },
                ) {
                    Icon(
                        imageVector = Icons.Filled.PlayCircle,
                        contentDescription = "继续",
                        tint = Color.White,
                        modifier = Modifier.size(64.dp),
                    )
                }
                IconButton(onClick = onExit) {
                    Icon(
                        imageVector = Icons.Filled.Cancel,
                        contentDescription = "退出",
                        tint = Color.White,
                        modifier = Modifier.size(64.dp),
                    )
                }
            }
        }
    }
}

private fun android.content.Context.findActivityWindow(): android.view.Window? {
    var current: android.content.Context? = this
    while (current is android.content.ContextWrapper) {
        if (current is android.app.Activity) return current.window
        current = current.baseContext
    }
    return null
}
