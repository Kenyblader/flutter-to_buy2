package com.example.to_buy

import android.content.Intent
import android.widget.RemoteViewsService
import android.content.Context
import android.util.Log
import org.json.JSONArray
import android.widget.RemoteViews
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.log

class BuyListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return BuyListRemoteViewsFactory(applicationContext)
    }
}

class BuyListRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var buyListNames: List<BuyList> = emptyList()

    override fun onCreate() {
        var x=loadBuyLists();
        Log.d("BuyListFactory",x[0].name);
        buyListNames=x;
    }

    override fun onDataSetChanged() {
        var x=loadBuyLists();
        Log.d("BuyListFactory",x[0].name);
        buyListNames=x;
    }

    override fun onDestroy() {
        buyListNames = emptyList()
    }

    override fun getCount(): Int = buyListNames.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.item_buy_list);
        views.setTextViewText(R.id.item_title, buyListNames[position].name);
        views.setTextViewText(R.id.item_description, buyListNames[position].description);
        try{
            val fillInIntent = Intent().apply {
                putExtra("target_page", "list_details")
                putExtra("list_id", buyListNames[position].id.toString())
            }
            views.setOnClickFillInIntent(R.id.item_title, fillInIntent);
            views.setOnClickFillInIntent(R.id.item_icon, fillInIntent);
        }catch (e: Exception){
            Log.e("BuyListRemoteViewsFactory", "getViewAt error: ${e.message}",e);
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true

    private fun loadBuyLists(): List<BuyList> {
        Log.d("BuyListRemoteViewsFactory", "loadBuyLists called")
        val data = HomeWidgetPlugin.getData(context);
        val names=data.getString("names", "[]");
        val gson=Gson();
        val type=object: TypeToken<List<BuyList>>(){}.type;
        Log.d("BuyListRemoteViewsFactory", "names: $names");
        return gson.fromJson(names,type);
    }
}

