package com.example.to_buy

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.Log

/**
 * Implementation of App Widget functionality.
 */
class ListifyWidget : AppWidgetProvider() {

    @SuppressLint("RemoteViewLayout")
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
           try {
               val intentActivity = Intent(context, MainActivity::class.java).apply {
                   // Ajouter des flags pour réutiliser l'instance existante de l'app
                   addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
               }
               val pendingIntent = PendingIntent.getActivity(
                   context,
                   0,
                   intentActivity,
                   PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
               );

               var intent=Intent(context, BuyListWidgetService::class.java);
               val views = RemoteViews(context.packageName, R.layout.listify_widget);
               views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
               views.setRemoteAdapter(R.id.widget_list, intent)
               appWidgetManager.updateAppWidget(appWidgetId, views)
               Log.d("ListifyWidget", "onUpdate called: $appWidgetId");
           }catch (e: Exception){
               Log.e("ListifyWidget", "onUpdate error: ${e.message}",e);
           }
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }



}



