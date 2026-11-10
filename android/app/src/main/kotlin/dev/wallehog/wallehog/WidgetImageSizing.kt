package dev.wallehog.wallehog

import android.appwidget.AppWidgetManager
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import kotlin.math.ceil
import kotlin.math.sqrt

/** Match launcher pixels, while reserving headroom in its RemoteViews budget. */
internal object WidgetImageSizing {
    @Suppress("DEPRECATION")
    fun pixelEdge(options: Bundle, density: Float): Int {
        val exact = if (Build.VERSION.SDK_INT >= 31) {
            options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
                ?.filter { it.width.isFinite() && it.height.isFinite() && it.width > 0 && it.height > 0 }
        } else null
        val edgeDp: Double
        val smallestArea: Double
        if (!exact.isNullOrEmpty()) {
            edgeDp = exact.maxOf { minOf(it.width, it.height).toDouble() }
            smallestArea = exact.minOf { it.width.toDouble() * it.height }
        } else {
            fun dimension(key: String, fallback: Int) = options.getInt(key, fallback).takeIf { it > 0 } ?: fallback
            val minW = dimension(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
            val minH = dimension(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
            val maxW = maxOf(minW, dimension(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW))
            val maxH = maxOf(minH, dimension(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH))
            // Legacy ranges do not identify the currently displayed orientation.
            // Use the upper bounds for detail, not half the smallest dimension.
            edgeDp = minOf(maxW, maxH).toDouble()
            smallestArea = minOf(minW.toDouble() * maxH, maxW.toDouble() * minH)
        }
        val scale = density.takeIf { it.isFinite() && it > 0 }?.toDouble() ?: 1.0
        // ARGB bitmap uses 4 bytes/pixel; this stays below the launcher's
        // 6*width*height limit even for the smallest advertised viewport.
        val budgetEdge = (sqrt(smallestArea) * scale).toInt().coerceAtLeast(1)
        return minOf(ceil(edgeDp * scale).toInt(), budgetEdge, 1024).coerceAtLeast(1)
    }
}
