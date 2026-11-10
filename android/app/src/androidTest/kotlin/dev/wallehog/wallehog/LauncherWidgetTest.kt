package dev.wallehog.wallehog

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.widget.RemoteViews
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Loads the ordinary release widget from another application's UID. No writes. */
class LauncherWidgetTest {
    @Test fun placedWidgetLoadsInLauncher() {
        val provider = InstrumentationRegistry.getArguments().getString("placedPackage")
        org.junit.Assume.assumeNotNull(provider)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val automation = instrumentation.uiAutomation
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or android.accessibilityservice.AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        var root = automation.rootInActiveWindow
        repeat(50) {
            if (root == null) { Thread.sleep(100); root = automation.rootInActiveWindow }
        }
        val visible = root ?: error("No visible launcher")
        assertTrue("Open the launcher page containing the widget", visible.packageName.toString().contains("launcher"))
        // A widget's resource IDs belong to the provider, not the launcher's
        // Resources table used by findAccessibilityNodeInfosByViewId.
        fun hasAction(node: android.view.accessibility.AccessibilityNodeInfo): Boolean {
            if (node.viewIdResourceName == "$provider:id/widget_action") return true
            for (index in 0 until node.childCount) {
                val child = node.getChild(index) ?: continue
                if (hasAction(child)) return true
            }
            return false
        }
        assertTrue("Widget action was not inflated in the real launcher", hasAction(visible))
    }
    @Test fun crossPackageInflation() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        check(context.packageName.endsWith(".widgetuitest") || context.packageName.endsWith(".widgetcompactuitest"))
        val manager = AppWidgetManager.getInstance(context)
        var widget: AppWidgetHostView? = null
        val host = object : AppWidgetHost(context, 7302) {
            override fun onCreateView(context: android.content.Context, id: Int, info: android.appwidget.AppWidgetProviderInfo): AppWidgetHostView = object : AppWidgetHostView(context) {
                override fun updateAppWidget(remote: RemoteViews?) {
                    super.updateAppWidget(remote)
                    if (remote != null) updated.countDown()
                }
            }
        }
        var id = -1
        try {
            instrumentation.runOnMainSync {
                id = host.allocateAppWidgetId()
                assertTrue(manager.bindAppWidgetIdIfAllowed(id, ComponentName("dev.wallehog.wallehog", "dev.wallehog.wallehog.WishWidget")))
                host.startListening()
                widget = host.createView(context, id, manager.getAppWidgetInfo(id))
            }
            assertTrue("No RemoteViews update", updated.await(15, TimeUnit.SECONDS))
            instrumentation.waitForIdleSync()
            val resources = context.packageManager.getResourcesForApplication("dev.wallehog.wallehog")
            val action = resources.getIdentifier("widget_action", "id", "dev.wallehog.wallehog")
            instrumentation.runOnMainSync {
                assertNotNull("Cross-package release widget shows an error view", widget!!.findViewById<android.view.View>(action))
            }
        } finally {
            instrumentation.runOnMainSync { if (id >= 0) host.deleteAppWidgetId(id); host.stopListening() }
        }
    }
    private val updated = CountDownLatch(1)
}
