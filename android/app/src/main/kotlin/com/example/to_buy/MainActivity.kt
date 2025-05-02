package com.example.to_buy

import android.app.PictureInPictureParams
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Canaux de communication
    private val BUBBLE_CHANNEL = "com.example.to_buy/floating_bubble"
    private val STORAGE_CHANNEL = "ListifyStorageWidget"
    private val OVERLAY_PERMISSION_REQ_CODE = 1234

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialisation du stockage
        StorageHelper.initialize(context)

        // Configuration du canal pour la bulle flottante
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BUBBLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showBubble" -> {
                    if (checkOverlayPermission()) {
                        startBubbleService()
                        result.success(null)
                    } else {
                        result.error("PERMISSION_DENIED", "L'autorisation d'overlay est requise", null)
                    }
                }
                "hideBubble" -> {
                    stopBubbleService()
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Configuration du canal pour le widget
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
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

    // Méthodes pour la bulle flottante
    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
        }
    }

    private fun startBubbleService() {
        val intent = Intent(this, FloatingWidgetService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopBubbleService() {
        val intent = Intent(this, FloatingWidgetService::class.java)
        stopService(intent)
    }

    // Méthodes pour le widget
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

    // Méthode pour le mode Picture-in-Picture
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQ_CODE) {
            if (checkOverlayPermission()) {
                startBubbleService()
            }
        }
    }
}