package com.example.to_buy

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import android.appwidget.AppWidgetManager
import  android.content.ComponentName
import android.appwidget.AppWidgetProvider
import android.content.Intent
import android.content.SharedPreferences
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel



class MainActivity : FlutterActivity() {
    private val CHANNEL = "ListifyWidgetRoutes"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getWidgetIntentExtras") {
                val extras = intent.extras
                if (extras != null) {
                    val targetPage = extras.getString("target_page")
                    val listId = extras.getString("list_id")
                    result.success(mapOf(
                        "target_page" to targetPage,
                        "list_id" to listId,
                    ))
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Met à jour l'intent pour les clics ultérieurs
    }
}
