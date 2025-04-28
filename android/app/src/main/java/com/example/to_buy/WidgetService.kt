package com.example.to_buy

import android.content.Intent
import android.widget.RemoteViewsService
import android.content.Context
import android.util.Log
import org.json.JSONArray
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class BuyListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return BuyListRemoteViewsFactory(applicationContext)
    }
}

class BuyListRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var buyListNames: List<String> = emptyList()

    override fun onCreate() {
        loadBuyLists()
    }

    override fun onDataSetChanged() {
        loadBuyLists()
    }

    override fun onDestroy() {
        buyListNames = emptyList()
    }

    override fun getCount(): Int = buyListNames.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.item_buy_list)
        views.setTextViewText(R.id.item_text, buyListNames[position])
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true

    private fun loadBuyLists() {
        val prefs = HomeWidgetPlugin.getData(context);
        val jsonString = prefs.getString("names", "[]")
        Log.d("ListifyWidget", "Chargement des listes : $jsonString")
        val names = mutableListOf<String>()
        jsonString?.let {
            val jsonArray = JSONArray(it)
            for (i in 0 until jsonArray.length()) {
                names.add(jsonArray.getString(i))
            }
        }
        buyListNames = names
    }
}

