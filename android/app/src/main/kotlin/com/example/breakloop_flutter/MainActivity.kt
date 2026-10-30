package com.example.breakloop_flutter

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

class MainActivity : FlutterActivity() {

    companion object {
        // Must match the channel name used by UsageStatsScreenTimeRepository in Dart
        private const val CHANNEL = "breakloop/usage_stats"
        // Must match the channel name used by InstalledAppsDataSource in Dart
        private const val APPS_CHANNEL = "breakloop/installed_apps"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> runInBackground(result) { getInstalledApps() }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")!!
                    val sizePx = call.argument<Int>("sizePx")!!
                    runInBackground(result) { getAppIcon(packageName, sizePx) }
                }
                "getTodayAppUsage" -> runInBackground(result) { getTodayAppUsage() }
                else -> result.notImplemented()
            }
        }
    }

    // Querying the package manager and the usage events can be slow, so it runs outside the main thread
    private fun runInBackground(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("APPS_ERROR", e.message, null) }
            }
        }.start()
    }

    // Apps shown in the launcher, without BreakLoop itself (same as InstalledAppsDataSource in the Kotlin app)
    private fun getInstalledApps(): List<Map<String, String>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = HashMap<String, String>()
        for (info in packageManager.queryIntentActivities(launcherIntent, 0)) {
            val appPackage = info.activityInfo.packageName
            if (appPackage != packageName) {
                apps[appPackage] = info.loadLabel(packageManager).toString()
            }
        }
        return apps.map { (appPackage, label) -> mapOf("packageName" to appPackage, "label" to label) }
    }

    // Icon of an app as PNG bytes, or null if it cannot be loaded
    private fun getAppIcon(appPackage: String, sizePx: Int): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(appPackage)
            val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, sizePx, sizePx)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    // Milliseconds in the foreground of each app today (package -> ms). Empty without the usage permission
    private fun getTodayAppUsage(): Map<String, Long> {
        if (!hasUsagePermission()) {
            return emptyMap()
        }
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val begin = startOfDay(end).timeInMillis

        val events = usageStatsManager.queryEvents(begin, end)
        val event = UsageEvents.Event()
        val resumedAt = HashMap<String, Long>()
        val millisByPackage = HashMap<String, Long>()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val activity = "${event.packageName}/${event.className}"
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> resumedAt[activity] = event.timeStamp
                UsageEvents.Event.ACTIVITY_PAUSED -> resumedAt.remove(activity)?.let { start ->
                    millisByPackage[event.packageName] = (millisByPackage[event.packageName] ?: 0L) + (event.timeStamp - start)
                }
            }
        }
        // The activity that is still in the foreground right now is counted up to now
        resumedAt.maxByOrNull { it.value }?.let { (activity, start) ->
            val appPackage = activity.substringBefore("/")
            millisByPackage[appPackage] = (millisByPackage[appPackage] ?: 0L) + (end - start)
        }
        return millisByPackage
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
