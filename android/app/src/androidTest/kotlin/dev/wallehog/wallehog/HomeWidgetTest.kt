package dev.wallehog.wallehog

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.widget.TextView
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(JUnit4::class)
class HomeWidgetTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private lateinit var host: AppWidgetHost
    private lateinit var view: AppWidgetHostView
    private fun main(action: () -> Unit) = instrumentation.runOnMainSync(action)
    private fun waitFor(description: String, condition: () -> Boolean) {
        repeat(150) {
            var ready = false
            main { ready = condition() }
            if (ready) return
            Thread.sleep(100)
        }
        fail("Timed out: $description")
    }
    private fun click(id: Int) { main { assertTrue(view.findViewById<View>(id).performClick()) }; instrumentation.waitForIdleSync() }
    private fun text(id: Int): String = view.findViewById<TextView>(id).text.toString()
    private fun snapshot(): Map<*, *> {
        val latch = CountDownLatch(1)
        var response: Map<*, *>? = null
        main { WidgetRuntime.request(context, "snapshot", null) { response = it; latch.countDown() } }
        assertTrue(latch.await(12, TimeUnit.SECONDS))
        return response ?: error("No Dart snapshot")
    }
    private fun totals(): Pair<Int, Int> {
        val db = context.getDatabasePath("wallehog.db")
        android.database.sqlite.SQLiteDatabase.openDatabase(db.path, null, android.database.sqlite.SQLiteDatabase.OPEN_READONLY).use { sql ->
            sql.rawQuery("SELECT COUNT(*), COALESCE(SUM(saved_minor),0) FROM saving_records WHERE client_token LIKE 'widget:%'", null).use { cursor ->
                assertTrue(cursor.moveToFirst())
                return cursor.getInt(0) to cursor.getInt(1)
            }
        }
    }
    private fun capture(name: String) {
        main {
            val density = context.resources.displayMetrics.density
            val width = (156 * density).toInt()
            val height = (156 * density).toInt()
            view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
            view.layout(0, 0, width, height)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            view.draw(Canvas(bitmap))
            File(context.getExternalFilesDir(null), "$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
        }
    }

    @Test fun coldWorkerAndRemoteViewsEntry() {
        check(context.packageName.endsWith(".widgetuitest") || context.packageName.endsWith(".widgetcompactuitest")) { "Requires isolated widget test package" }
        val manager = AppWidgetManager.getInstance(context)
        val monitor = instrumentation.addMonitor(MainActivity::class.java.name, null, false)
        var activity: android.app.Activity? = null
        val settings = context.getSharedPreferences("wallehog_settings", 0)
        val originalLanguage = settings.getString("language", "zh_CN")
        settings.edit().putString("language", "zh_CN").commit()
        var id = -1
        main {
            host = AppWidgetHost(context, 7301)
            id = host.allocateAppWidgetId()
            assertTrue("Grant appwidget bind permission to isolated package first", manager.bindAppWidgetIdIfAllowed(id, ComponentName(context, WishWidget::class.java)))
            host.startListening()
            view = host.createView(context, id, manager.getAppWidgetInfo(id))
            assertEquals(2, manager.getAppWidgetInfo(id).targetCellWidth)
            assertEquals(2, manager.getAppWidgetInfo(id).targetCellHeight)
            view.updateAppWidgetOptions(android.os.Bundle().apply {
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 156)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 156)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 156)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 156)
            })
        }
        try {
            val initial = snapshot()
            assertTrue(initial["ready"] == true)
            assertNull(initial["goalId"])
            val before = totals()
            waitFor("card") { view.findViewById<View>(R.id.widget_action) != null }
            // Binding sends an additional asynchronous provider refresh; let it
            // finish before deliberately publishing fictional preview data.
            Thread.sleep(1500)
            // Preview the real native layout using fictional data, without adding
            // a test wish or changing the user's ordinary database.
            main { WishWidget.publish(context, mapOf("goalId" to 999, "name" to "PS5", "style" to "ps5", "targetMinor" to 400000, "progressMinor" to 125000, "ready" to true)) }
            waitFor("preview") { text(R.id.widget_title) == "PS5" }
            capture("widget-native-card")
            click(R.id.widget_action)
            waitFor("keyboard") { view.findViewById<View>(R.id.widget_entry).visibility == View.VISIBLE }
            // 7 -> . -> 5 = 7.50, using the actual PendingIntent buttons.
            click(R.id.key_a)
            waitFor("7") { text(R.id.widget_amount).endsWith("7") }
            // Each row reuses IDs; find the second row explicitly.
            main { val rows = view.findViewById<android.view.ViewGroup>(R.id.widget_keys); rows.getChildAt(1).findViewById<View>(R.id.key_d).performClick() }
            waitFor("decimal") { text(R.id.widget_amount).endsWith("7.") }
            main { val rows = view.findViewById<android.view.ViewGroup>(R.id.widget_keys); rows.getChildAt(1).findViewById<View>(R.id.key_b).performClick() }
            waitFor("amount") { text(R.id.widget_amount).endsWith("7.5") }
            capture("widget-native-entry")
            click(R.id.widget_action)
            waitFor("changed wish review") { text(R.id.widget_message).contains("心愿已更新") }
            assertEquals(0L, (snapshot()["progressMinor"] as Number).toLong())
            click(R.id.widget_action)
            waitFor("saved card") { view.findViewById<View>(R.id.widget_entry).visibility == View.GONE }
            // A stale save PendingIntent must not replay the just-acknowledged entry.
            val stale = android.content.Intent(context, WishWidget::class.java).setAction("dev.wallehog.widget.KEY").putExtra("id", id).putExtra("key", "save")
            context.sendBroadcast(stale)
            assertEquals(before.first + 1 to before.second + 750, totals())
            assertEquals("Widget entry must not launch the app", 0, monitor.hits)
            activity = instrumentation.startActivitySync(android.content.Intent(context, MainActivity::class.java).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK))
            // A new foreground controller can coexist with an idle worker and
            // the next widget entry still updates the same database exactly once.
            snapshot()
            click(R.id.widget_action)
            waitFor("foreground keypad") { view.findViewById<View>(R.id.widget_entry).visibility == View.VISIBLE }
            click(R.id.key_a)
            waitFor("foreground amount") { text(R.id.widget_amount).endsWith("7") }
            click(R.id.widget_action)
            waitFor("foreground save") { view.findViewById<View>(R.id.widget_entry).visibility == View.GONE }
            assertEquals(before.first + 2 to before.second + 1450, totals())
            main { settings.edit().putString("language", "en").commit(); WishWidget.refresh(context) }
            waitFor("English card") { text(R.id.widget_title) == "Something to look forward to" }
            click(R.id.widget_action)
            waitFor("English entry") { text(R.id.widget_amount) == "$" + "0" }
            capture("widget-native-en-entry")
            click(R.id.widget_cancel)
            waitFor("cancel") { view.findViewById<View>(R.id.widget_entry).visibility == View.GONE }
            assertEquals(before.first + 2 to before.second + 1450, totals())
            Thread.sleep(21000)
            assertTrue("Foreground survives idle worker teardown", snapshot()["ready"] == true)
        } finally {
            settings.edit().putString("language", originalLanguage).commit()
            main { activity?.finish(); host.deleteAppWidgetId(id); host.stopListening() }
            instrumentation.removeMonitor(monitor)
        }
    }
}
