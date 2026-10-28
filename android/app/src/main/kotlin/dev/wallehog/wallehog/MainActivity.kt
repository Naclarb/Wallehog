package dev.wallehog.wallehog

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction

class MainActivity : FlutterActivity() {
    private val soundPool = android.media.SoundPool.Builder().setMaxStreams(3).build()
    private val sounds = mutableMapOf<String, Int>()
    private var pending: MethodChannel.Result? = null
    private var content: String? = null
    private val limit = 10 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sounds["coin"] = soundPool.load(this, dev.wallehog.wallehog.R.raw.coin, 1)
        sounds["celebrate"] = soundPool.load(this, dev.wallehog.wallehog.R.raw.celebrate, 1)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.wallehog/sound")
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences("wallehog_sound", MODE_PRIVATE)
                when (call.method) {
                    "enabled" -> result.success(prefs.getBoolean("enabled", false))
                    "setEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: false
                        result.success(prefs.edit().putBoolean("enabled", enabled).commit())
                    }
                    "play" -> {
                        val name = call.arguments as? String
                        if (prefs.getBoolean("enabled", false)) {
                            sounds[name]?.let { soundPool.play(it, 0.45f, 0.45f, 1, 0, 1f) }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.wallehog/backup")
            .setMethodCallHandler { call, result ->
                if (call.method != "save" && call.method != "open") {
                    result.notImplemented()
                } else if (pending != null) {
                    result.error("busy", "另一个文件操作尚未完成", null)
                } else {
                    try {
                        val saving = call.method == "save"
                        content = if (saving) call.argument<String>("content") else null
                        if (saving && (content == null || content!!.toByteArray(Charsets.UTF_8).size > limit)) {
                            throw IllegalArgumentException("备份过大或为空")
                        }
                        val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = if (saving) "application/json" else "*/*"
                            if (saving) putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "wallehog.json")
                        }
                        pending = result
                        startActivityForResult(intent, if (saving) 8101 else 8102)
                    } catch (e: Exception) {
                        pending = null
                        content = null
                        result.error("file", "无法打开系统文件选择器，请重试", null)
                    }
                }
            }
    }

    override fun onDestroy() {
        soundPool.release()
        super.onDestroy()
    }

    @Deprecated("Android activity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 8101 && requestCode != 8102) return
        val reply = pending ?: return
        val payload = content
        // 保留 pending 直到文件 I/O 结束；在后台线程读写，避免大备份阻塞界面。
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            content = null
            reply.success(if (requestCode == 8101) false else null)
            return
        }
        Thread {
            try {
                val value: Any = if (requestCode == 8101) {
                    val stream = contentResolver.openOutputStream(uri, "wt") ?: error("无法写入")
                    stream.use { it.write((payload ?: error("内容丢失")).toByteArray(Charsets.UTF_8)) }
                    true
                } else {
                    val stream = contentResolver.openInputStream(uri) ?: error("无法读取")
                    val bytes = stream.use { input ->
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            if (output.size() + count > limit) error("文件超过 10 MiB")
                            output.write(buffer, 0, count)
                        }
                        output.toByteArray()
                    }
                    Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                        .decode(ByteBuffer.wrap(bytes)).toString()
                }
                runOnUiThread {
                    pending = null; content = null
                    reply.success(value)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    pending = null; content = null
                    reply.error("file", "文件操作失败，请检查文件、可用空间及 10 MiB 大小限制", null)
                }
            }
        }.start()
    }
}
