package dev.wallehog.wallehog

import android.appwidget.AppWidgetManager
import android.os.Bundle
import android.util.SizeF
import org.junit.Assert.*
import org.junit.Test

class WidgetImageSizingTest {
    private fun range(minW: Int, minH: Int, maxW: Int, maxH: Int) = Bundle().apply {
        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, minW)
        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, minH)
        putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, maxW)
        putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, maxH)
    }

    @Test fun phoneCardHasOneBitmapPixelPerDisplayPixel() {
        val options = range(156, 156, 156, 156)
        assertEquals(156, WidgetImageSizing.pixelEdge(options, 1f))
        assertEquals(468, WidgetImageSizing.pixelEdge(options, 3f))
    }

    @Test fun honorLegacyRangesDoNotShrinkTheLargeOrientationToAThumbnail() {
        val edge = WidgetImageSizing.pixelEdge(range(124, 124, 276, 246), 2.5f)
        assertTrue("A roughly 400px hero must not be rendered at 155px", edge >= 400)
        assertTrue(edge.toLong() * edge * 4 <= 6 * 124 * 246 * 2.5 * 2.5)
    }

    @Test fun exactLauncherViewportsPreserveTheirActualResolution() {
        org.junit.Assume.assumeTrue(android.os.Build.VERSION.SDK_INT >= 31)
        val options = range(124, 124, 276, 246).apply {
            putParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES, arrayListOf(SizeF(276f, 246f), SizeF(246f, 276f)))
        }
        assertEquals(615, WidgetImageSizing.pixelEdge(options, 2.5f))
    }

    @Test fun extremeAndSmallWidgetsStayWithinBitmapBounds() {
        assertEquals(1024, WidgetImageSizing.pixelEdge(range(5000, 5000, 5000, 5000), 4f))
        assertEquals(20, WidgetImageSizing.pixelEdge(range(20, 20, 20, 20), 1f))
        val edge = WidgetImageSizing.pixelEdge(range(50, 50, 600, 600), 3f)
        assertTrue(edge.toLong() * edge * 4 <= 6L * 50 * 600 * 9)
    }

    @Test fun missingLauncherSizesStillUseFullDensity() {
        assertEquals(330, WidgetImageSizing.pixelEdge(Bundle(), 3f))
    }
}
