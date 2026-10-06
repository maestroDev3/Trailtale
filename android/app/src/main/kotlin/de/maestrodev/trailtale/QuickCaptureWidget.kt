package de.maestrodev.trailtale

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home screen widget “I'm here”: one tap opens Trailtale's quick capture,
 * which saves the current place into the running trip.
 */
class QuickCaptureWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(MainActivity.ACTION_QUICK_CAPTURE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val tap = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_capture_widget)
            views.setOnClickPendingIntent(R.id.quick_capture_root, tap)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
