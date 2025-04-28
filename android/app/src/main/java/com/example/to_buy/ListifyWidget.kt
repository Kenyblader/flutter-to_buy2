package com.example.to_buy

import android.annotation.SuppressLint
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Implementation of App Widget functionality.
 */
class ListifyWidget : AppWidgetProvider() {

    fun getViewAt(context: Context,buyListNames: String): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.item_buy_list)
        views.setTextViewText(R.id.item_text, buyListNames)
        return views
    }

    @SuppressLint("RemoteViewLayout")
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.listify_widget)
            // ATTENTION : setRemoteAdapter nécessite un Intent vers un Service
//            val intent = Intent(context, BuyListWidgetService::class.java)
            var names= HomeWidgetPlugin.getData(context).getString("names","aucune Liste Pour l'intant");
//            views.setRemoteAdapter(R.id.widget_list_view, intent)
            views.setTextViewText(R.id.names, names)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }



}



