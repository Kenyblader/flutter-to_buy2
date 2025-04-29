package com.example.to_buy

import android.app.PictureInPictureParams
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// A communication channel identifier used by Flutter and the native code to exchange messages. In this case, it is called storageChannel and is used for widget storage and update operations.
    private val storageChannel = "ListifyStorageWidget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        StorageHelper.initialize(context)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            storageChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setValue" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Any>("value")

                    if (key != null && value != null) {
                        try {
                            StorageHelper.setValue(key, value)
                            updateWidget(context)
                            result.success(null)
                        } catch (e: IllegalArgumentException) {
                            result.error("INVALID_VALUE", "Unsupported value type", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Key or value is missing", null)
                    }
                }
                else -> {
                    result.error("UNKNOWN_METHOD", "Method not implemented", null)
                }
            }
        }
    }

    private fun updateWidget(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, ListifyWidget::class.java)

        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        if (appWidgetIds.isNotEmpty()) {
            val intent = Intent(context, ListifyWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }

            context.sendBroadcast(intent)
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16)) // Ratio 9:16 pour mobile
                .build()
            try {
                enterPictureInPictureMode(params)
                Log.d("MainActivity", "Mode PiP activé")
            } catch (e: Exception) {
                Log.e("MainActivity", "Erreur PiP: ${e.message}")
            }
        } else {
            Log.w("MainActivity", "PiP non supporté sur cette version d'Android")
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, 123)
        }
    }
}