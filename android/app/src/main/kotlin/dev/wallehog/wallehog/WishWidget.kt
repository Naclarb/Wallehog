package dev.wallehog.wallehog

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import org.json.JSONObject

class WishWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, it) }
        val pending = goAsync()
        WidgetRuntime.request(context, "snapshot", null) { data ->
            if (data != null) publish(context, data)
            pending.finish()
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        render(context, id)
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        val edit = prefs(context).edit()
        ids.forEach { edit.remove("draft:$it") }
        edit.apply()
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) { super.onReceive(context, intent); return }
        val id = intent.getIntExtra("id", -1)
        if (id !in widgetIds(context)) return
        val state = draft(context, id)
        val action = intent.getStringExtra("key") ?: return
        if (!state.optBoolean("entry") && action != "open") return
        if (state.optBoolean("entry") && action == "open") return
        // Submitted requests are immutable until acknowledged, including across
        // process death/timeouts. Retrying uses the original token and date.
        if (state.optBoolean("submitted") && action != "save") return
        when (action) {
            "open" -> {
                state.put("entry", true).put("amount", "")
                state.put("message", "")
                state.put("goalId", prefs(context).getLong("goalId", -1))
                state.put("goalName", prefs(context).getString("name", ""))
            }
            "cancel" -> { prefs(context).edit().remove("draft:$id").commit(); render(context, id); return }
            "save" -> {
                val amount = minor(state.optString("amount"))
                if (amount == null) {
                    state.put("message", "invalid")
                } else {
                    if (!state.optBoolean("submitted")) {
                        state.put("token", "widget:" + UUID.randomUUID())
                        state.put("date", SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()))
                        state.put("submitted", true)
                    }
                    state.put("message", "saving")
                    store(context, id, state)
                    render(context, id)
                    val pending = goAsync()
                    val goal = state.optLong("goalId", -1)
                    WidgetRuntime.request(context, "save", mapOf(
                        "token" to state.getString("token"), "date" to state.getString("date"),
                        "amountMinor" to amount, "goalId" to if (goal < 0) null else goal
                    )) { result ->
                        when (result?.get("status")) {
                            "saved" -> {
                                store(context, id, JSONObject().put("message", "saved").put("amount", state.optString("amount")))
                                publish(context, result)
                            }
                            "changed" -> {
                                state.put("submitted", false).put("message", "changed")
                                state.put("goalId", (result["goalId"] as? Number)?.toLong() ?: -1)
                                state.put("goalName", result["name"] ?: "")
                                store(context, id, state)
                                publish(context, result)
                            }
                            else -> { state.put("message", "retry"); store(context, id, state) }
                        }
                        render(context, id)
                        pending.finish()
                    }
                    return
                }
            }
            else -> {
                if (!state.optBoolean("entry")) return
                var value = state.optString("amount")
                if (action == "delete") value = value.dropLast(1)
                else if (action == "." && !value.contains('.')) value = if (value.isEmpty()) "0." else "$value."
                else if (action.length == 1 && action[0].isDigit()) {
                    val candidate = if (value == "0") action else value + action
                    if (candidate.length <= 10 && (!candidate.contains('.') || candidate.substringAfter('.').length <= 2)) value = candidate
                }
                state.put("amount", value).put("message", "")
            }
        }
        store(context, id, state)
        render(context, id)
    }

    companion object {
        private const val ACTION = "dev.wallehog.widget.KEY"
        private fun prefs(context: Context) = context.getSharedPreferences("wallehog_widget", Context.MODE_PRIVATE)
        private fun widgetIds(context: Context) = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, WishWidget::class.java))
        private fun draft(context: Context, id: Int): JSONObject = try {
            JSONObject(prefs(context).getString("draft:$id", "{}") ?: "{}")
        } catch (_: Exception) { JSONObject() }
        private fun store(context: Context, id: Int, state: JSONObject) {
            prefs(context).edit().putString("draft:$id", state.toString()).commit()
        }
        private fun minor(value: String): Long? {
            if (!Regex("[0-9]{1,7}(\\.[0-9]{0,2})?").matches(value)) return null
            val parts = value.split('.')
            val amount = parts[0].toLong() * 100 + if (parts.size == 2) parts[1].padEnd(2, '0').toLong() else 0
            return amount.takeIf { it in 1..999999999 }
        }

        fun publish(context: Context, data: Map<*, *>) {
            prefs(context).edit()
                .putLong("goalId", (data["goalId"] as? Number)?.toLong() ?: -1)
                .putString("name", data["name"] as? String ?: "")
                .putString("style", data["style"] as? String ?: "gift")
                .putLong("target", (data["targetMinor"] as? Number)?.toLong() ?: 0)
                .putLong("progress", (data["progressMinor"] as? Number)?.toLong() ?: 0)
                .putBoolean("ready", data["ready"] == true).apply()
            widgetIds(context).forEach { render(context, it) }
        }

        fun refresh(context: Context) { widgetIds(context).forEach { render(context, it) } }

        private fun key(context: Context, id: Int, value: String): PendingIntent {
            val intent = Intent(context, WishWidget::class.java).setAction(ACTION)
                .setData(Uri.parse("wallehog://widget/$id/$value"))
                .putExtra("id", id).putExtra("key", value)
            return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        private fun hero(context: Context, style: String, fraction: Float, edgeDp: Int): Bitmap {
            // Bounded, density-aware image stays crisp without sending original
            // asset bitmaps to the launcher.
            val size = (minOf(180f, edgeDp * .5f) * context.resources.displayMetrics.density).toInt().coerceIn(48, 512)
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.scale(size / 240f, size / 240f)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; strokeWidth = 7f; this.style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND }
            paint.alpha = 90; canvas.drawCircle(120f, 120f, 111f, paint)
            paint.alpha = 255; canvas.drawArc(RectF(9f, 9f, 231f, 231f), -90f, 360 * fraction, false, paint)
            val safeStyle = if (style in listOf("gift", "ps5", "headphones", "camera")) style else "gift"
            try {
                val path = "flutter_assets/assets/characters/wish-$safeStyle-v1.png"
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                context.assets.open(path).use { BitmapFactory.decodeStream(it, null, bounds) }
                var sample = 1
                while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= size) sample *= 2
                context.assets.open(path).use { stream ->
                    val image = BitmapFactory.decodeStream(stream, null, BitmapFactory.Options().apply { inSampleSize = sample })
                    if (image != null) {
                        val scale = 174f / maxOf(image.width, image.height)
                        val w = image.width * scale; val h = image.height * scale
                        canvas.drawBitmap(image, null, RectF(120 - w / 2, 120 - h / 2, 120 + w / 2, 120 + h / 2), Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
                        image.recycle()
                    }
                }
            } catch (_: Exception) { /* Progress remains visible if an asset cannot load. */ }
            return bitmap
        }

        private fun render(context: Context, id: Int) {
            val prefs = prefs(context)
            val draft = draft(context, id)
            val english = context.getSharedPreferences("wallehog_settings", Context.MODE_PRIVATE).getString("language", "zh_CN") == "en"
            fun text(zh: String, en: String) = if (english) en else zh
            val entry = draft.optBoolean("entry")
            val submitted = draft.optBoolean("submitted")
            val views = RemoteViews(context.packageName, R.layout.wish_widget)
            views.setInt(R.id.widget_root, "setBackgroundResource", when (prefs.getString("style", "gift")) {
                "headphones" -> R.drawable.widget_card_headphones
                "camera" -> R.drawable.widget_card_camera
                else -> R.drawable.widget_card
            })
            views.setViewVisibility(R.id.widget_title, if (entry) View.GONE else View.VISIBLE)
            val name = if (entry) draft.optString("goalName") else prefs.getString("name", "") ?: ""
            views.setTextViewText(R.id.widget_title, name.ifBlank { text("给小猪一个期待", "Something to look forward to") })
            views.setViewVisibility(R.id.widget_card, if (entry) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_entry, if (entry) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widget_cancel, if (entry) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.widget_cancel, text("取消", "Cancel"))
            // Honor substitutes its own Button whose setEnabled override is not
            // RemoteViews-callable. Remove actions instead; receiver guards also
            // keep an unconfirmed submission immutable.
            views.setOnClickPendingIntent(R.id.widget_cancel, if (submitted) null else key(context, id, "cancel"))
            views.setTextViewText(R.id.widget_amount, (if (english) "$" else "¥") + draft.optString("amount").ifBlank { "0" })
            val message = when (draft.optString("message")) {
                "invalid" -> text("请输入大于零、最多两位小数的金额", "Enter a positive amount (up to 2 decimals)")
                "saving" -> text("正在保存…", "Saving…")
                "retry" -> text("尚未确认保存，请重试同一笔", "Save unconfirmed. Retry this entry")
                "changed" -> text("当前心愿已更新，请核对后确认：", "Wish changed. Review: ") + name
                "saved" -> text("已记下 ¥", "Saved $") + draft.optString("amount")
                else -> if (!entry && prefs.getLong("goalId", -1) < 0) text("在应用内创建心愿", "Create a wish in the app") else ""
            }
            views.setTextViewText(R.id.widget_message, message)
            views.setViewVisibility(R.id.widget_message, if (message.isBlank()) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.widget_action, if (!entry) "＋" else if (submitted) text("重试", "Retry") else text("存下", "Save"))
            views.setContentDescription(R.id.widget_action, if (entry) text("保存金额", "Save amount") else text("记一笔金额", "Record savings"))
            views.setOnClickPendingIntent(R.id.widget_action, key(context, id, if (entry) "save" else "open"))
            val launch = PendingIntent.getActivity(context, id, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_title, launch)
            views.setOnClickPendingIntent(R.id.widget_hero, launch)
            val progress = prefs.getLong("progress", 0)
            val target = prefs.getLong("target", 0)
            fun money(value: Long) = (if (english) "$" else "¥") + (value / 100).toString() + "." + (value % 100).toString().padStart(2, '0')
            views.setTextViewText(R.id.widget_progress, if (target > 0) "${money(progress)} / ${money(target)}" else text("记下每一个小确幸", "Every little choice counts"))
            val options = AppWidgetManager.getInstance(context).getAppWidgetOptions(id)
            val edge = minOf(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110), options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)).coerceAtLeast(48)
            views.setImageViewBitmap(R.id.widget_hero, hero(context, prefs.getString("style", "gift") ?: "gift", if (target > 0) (progress.toFloat() / target).coerceIn(0f, 1f) else 0f, edge))
            views.setContentDescription(R.id.widget_hero, text("心愿进度", "Wish progress") + if (target > 0) " ${(progress.toDouble() / target * 100).coerceIn(0.0, 100.0).toInt()}%" else "")
            views.removeAllViews(R.id.widget_keys)
            if (entry) {
                val labels = listOf(listOf("7", "8", "9", "delete"), listOf("4", "5", "6", "."), listOf("1", "2", "3", "0"))
                labels.forEach { row ->
                    val keys = RemoteViews(context.packageName, R.layout.widget_key_row)
                    row.zip(listOf(R.id.key_a, R.id.key_b, R.id.key_c, R.id.key_d)).forEach { (label, view) ->
                        keys.setTextViewText(view, if (label == "delete") "⌫" else label)
                        keys.setContentDescription(view, if (label == "delete") text("退格", "Backspace") else label)
                        keys.setOnClickPendingIntent(view, if (submitted) null else key(context, id, label))
                    }
                    views.addView(R.id.widget_keys, keys)
                }
            }
            AppWidgetManager.getInstance(context).updateAppWidget(id, views)
        }
    }
}
