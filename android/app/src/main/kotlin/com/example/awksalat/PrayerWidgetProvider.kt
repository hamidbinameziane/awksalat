
package com.example.awksalat

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.awksalat.R
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                val hijriDate = widgetData.getString("id_hijri_date", "الجمعة، 6 رمضان 1447")
                val nextPrayerName = widgetData.getString("id_next_prayer_name", "الفجر")
                val nextPrayerTime = widgetData.getString("id_next_prayer_time", "05:12 ص")
                val timeLeft = widgetData.getString("id_time_left", "")

                setTextViewText(R.id.widget_hijri_date, hijriDate)
                setTextViewText(R.id.next_prayer_name, nextPrayerName)
                setTextViewText(R.id.next_prayer_time, nextPrayerTime)
                setTextViewText(R.id.widget_time_left, timeLeft)

                // Add PendingIntent to launch the app on tap
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
