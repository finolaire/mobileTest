package com.example.englishsentence.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.englishsentence.MainActivity
import com.example.englishsentence.R
import java.util.Calendar

/**
 * 按星期几换背景图（与 iOS 一致：1=周日 … 7=周六）。
 * 每天 0 点刷新。
 */
class DayBackgroundWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id -> updateWidget(context, appWidgetManager, id) }
        scheduleMidnightUpdate(context)
    }

    override fun onEnabled(context: Context) {
        scheduleMidnightUpdate(context)
    }

    override fun onDisabled(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(midnightPendingIntent(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_MIDNIGHT_UPDATE,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, DayBackgroundWidgetProvider::class.java),
                )
                if (ids.isNotEmpty()) {
                    onUpdate(context, manager, ids)
                } else {
                    scheduleMidnightUpdate(context)
                }
            }
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        const val ACTION_MIDNIGHT_UPDATE =
            "com.example.englishsentence.widget.ACTION_MIDNIGHT_UPDATE"

        private val weekdayBackgrounds = intArrayOf(
            R.drawable.widget_bg_1, // Sunday
            R.drawable.widget_bg_2, // Monday
            R.drawable.widget_bg_3,
            R.drawable.widget_bg_4,
            R.drawable.widget_bg_5,
            R.drawable.widget_bg_6,
            R.drawable.widget_bg_7, // Saturday
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val weekday = Calendar.getInstance().get(Calendar.DAY_OF_WEEK) // 1=Sun … 7=Sat
            val bgRes = weekdayBackgrounds[(weekday - 1).coerceIn(0, 6)]
            val views = RemoteViews(context.packageName, R.layout.widget_day_background).apply {
                setImageViewResource(R.id.widget_background, bgRes)
                setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent(context))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun openAppPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun midnightPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, DayBackgroundWidgetProvider::class.java).apply {
                action = ACTION_MIDNIGHT_UPDATE
            }
            return PendingIntent.getBroadcast(
                context,
                2001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun scheduleMidnightUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val calendar = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 5)
                set(Calendar.MILLISECOND, 0)
            }
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC,
                calendar.timeInMillis,
                midnightPendingIntent(context),
            )
        }
    }
}
