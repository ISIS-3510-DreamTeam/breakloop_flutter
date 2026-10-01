package com.example.breakloop_flutter

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    companion object {
        // Must match the channel name used by UsageStatsScreenTimeRepository in Dart
        private const val CHANNEL = "breakloop/usage_stats"
        private const val HISTORY_PREFS = "screen_time_history"
        // Android only keeps a few days of usage events, so we ask for more than it can give
        private const val QUERY_DAYS = 30
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsagePermission" -> result.success(hasUsagePermission())
                "openUsageSettings" -> {
                    // PACKAGE_USAGE_STATS cannot be requested with a dialog, the user must enable it in the settings
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "getDailyUsage" -> {
                    // Reading thousands of events can be slow, so we do it outside the main thread
                    Thread {
                        try {
                            val usage = getDailyUsage()
                            runOnUiThread { result.success(usage) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_ERROR", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    // Returns the minutes of screen time of each day ("yyyy-MM-dd" -> minutes).
    // Android forgets old usage events, so every result is merged into a local history to keep the first weeks of use.
    private fun getDailyUsage(): Map<String, Int> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val begin = startOfDay(end).apply { add(Calendar.DAY_OF_YEAR, -QUERY_DAYS) }.timeInMillis

        // The screen time is the time with an activity of any app in the foreground
        val events = usageStatsManager.queryEvents(begin, end)
        val event = UsageEvents.Event()
        val resumedAt = HashMap<String, Long>()
        val millisByDay = HashMap<String, Long>()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val activity = "${event.packageName}/${event.className}"
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> resumedAt[activity] = event.timeStamp
                UsageEvents.Event.ACTIVITY_PAUSED ->
                    resumedAt.remove(activity)?.let { addSession(millisByDay, it, event.timeStamp) }
            }
        }
        // The activity that is still in the foreground right now is counted up to now.
        // Only the latest one is used, so an activity that never reported its pause is not counted until now.
        resumedAt.values.maxOrNull()?.let { addSession(millisByDay, it, end) }

        // Usage only grows during a day, so keeping the maximum protects the days Android already started to forget
        val prefs = getSharedPreferences(HISTORY_PREFS, Context.MODE_PRIVATE)
        val history = HashMap<String, Int>()
        for ((day, minutes) in prefs.all) {
            history[day] = minutes as Int
        }
        for ((day, millis) in millisByDay) {
            val minutes = (millis / 60000).toInt()
            if (minutes > (history[day] ?: 0)) {
                history[day] = minutes
            }
        }
        val editor = prefs.edit()
        for ((day, minutes) in history) {
            editor.putInt(day, minutes)
        }
        editor.apply()

        return history
    }

    // Adds the time between start and end to the day(s) it belongs to, splitting it at midnight
    private fun addSession(millisByDay: MutableMap<String, Long>, start: Long, end: Long) {
        var segmentStart = start
        while (segmentStart < end) {
            val dayStart = startOfDay(segmentStart)
            val nextDayStart = (dayStart.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }.timeInMillis
            val segmentEnd = minOf(end, nextDayStart)
            val day = dayKey(dayStart)
            millisByDay[day] = (millisByDay[day] ?: 0L) + (segmentEnd - segmentStart)
            segmentStart = segmentEnd
        }
    }

    private fun startOfDay(millis: Long): Calendar {
        return Calendar.getInstance().apply {
            timeInMillis = millis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    private fun dayKey(day: Calendar): String {
        return String.format("%04d-%02d-%02d", day.get(Calendar.YEAR), day.get(Calendar.MONTH) + 1, day.get(Calendar.DAY_OF_MONTH))
    }

}
