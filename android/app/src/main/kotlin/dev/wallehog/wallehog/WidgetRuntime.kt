package dev.wallehog.wallehog

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/** One request at a time; use the application's controller whenever it exists. */
object WidgetRuntime {
    private val handler = Handler(Looper.getMainLooper())
    private var foreground: MethodChannel? = null
    private var foregroundReady = false
    private var background: MethodChannel? = null
    private var engine: FlutterEngine? = null
    private val queue = ArrayDeque<() -> Unit>()
    private var running = false
    private val shutdown = Runnable {
        if (!running && queue.isEmpty()) {
            background = null
            engine?.destroy()
            engine = null
        }
    }

    fun attach(context: Context, flutterEngine: FlutterEngine) {
        foregroundReady = false
        foreground = channel(context, flutterEngine, true)
    }

    fun detach() { foreground = null; foregroundReady = false }

    private fun channel(context: Context, engine: FlutterEngine, main: Boolean): MethodChannel {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "dev.wallehog/widget")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    // Once the activity exists, the short-lived worker cannot
                    // overwrite its newer snapshot.
                    if (main || foreground == null) {
                        WishWidget.publish(context, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    }
                    result.success(null)
                }
                "ready" -> {
                    if (!main) background = channel else foregroundReady = true
                    result.success(null)
                    drain()
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    fun request(context: Context, method: String, args: Any?, done: (Map<*, *>?) -> Unit) {
        handler.removeCallbacks(shutdown)
        var delivered = false
        val deliver: (Map<*, *>?) -> Unit = { value ->
            if (!delivered) { delivered = true; done(value) }
        }
        // Also bound cold-start failures before Dart installs its handler.
        handler.postDelayed({
            if (!delivered) {
                deliver(null)
                if (!running && !foregroundReady && background == null) {
                    queue.clear()
                    engine?.destroy()
                    engine = null
                }
            }
        }, 8500)
        queue.add {
            if (delivered) { running = false; drain(); return@add }
            var completed = false
            val finish: (Map<*, *>?) -> Unit = { value ->
                if (!completed) {
                    completed = true
                    deliver(value)
                    running = false
                    drain()
                    handler.postDelayed(shutdown, 20000)
                }
            }
            val target = if (foregroundReady) foreground else background
            target?.invokeMethod(method, args, object : MethodChannel.Result {
                override fun success(value: Any?) {
                    // The activity may have started while its worker was writing.
                    // Refresh that controller after the worker's commit as well.
                    if (target != foreground && foregroundReady) {
                        foreground?.invokeMethod("snapshot", null)
                    }
                    finish(value as? Map<*, *>)
                }
                override fun error(code: String, message: String?, details: Any?) = finish(null)
                override fun notImplemented() = finish(null)
            }) ?: finish(null)
            handler.postDelayed({ finish(null) }, 8000)
        }
        if (foreground == null && engine == null) {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context.applicationContext)
            loader.ensureInitializationComplete(context.applicationContext, null)
            engine = FlutterEngine(context.applicationContext).also {
                channel(context.applicationContext, it, false)
                it.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "widgetMain"))
            }
        }
        drain()
    }

    private fun drain() {
        if (running || queue.isEmpty() || (!foregroundReady && background == null)) return
        running = true
        queue.removeFirst().invoke()
    }
}
