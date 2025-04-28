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
    private val STORAGE_CHANNEL = "ListifyStorageWidget"
    private val WIDGET_CHANNEL = "com.example.tobuy/widget"
    private val PIP_CHANNEL = "com.example.tobuy/pip"
    private val FLOATING_WIDGET_CHANNEL = "com.example.to_buy/floating_widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialiser StorageHelper pour le widget
        StorageHelper.initialize(context)

        // Canal pour le stockage et la mise à jour du widget
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL
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

        // Canal pour ouvrir ItemFormScreen depuis le widget
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "openItemForm") {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setClassName(context, "com.example.to_buy.MainActivity")
                    putExtra("route", "/item-form")
                }
                startActivity(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // Canal pour le mode Picture-in-Picture
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PIP_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "enterPipMode") {
                enterPipMode()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // Canal pour le bouton flottant
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FLOATING_WIDGET_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startFloatingWidget" -> {
                    if (hasOverlayPermission()) {
                        startService(Intent(this, FloatingWidgetService::class.java))
                        result.success(true)
                    } else {
                        requestOverlayPermission()
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                    }
                }
                "stopFloatingWidget" -> {
                    stopService(Intent(this, FloatingWidgetService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            if (it.getStringExtra("action") == "openItemForm") {
                MethodChannel(
                    flutterEngine!!.dartExecutor.binaryMessenger,
                    WIDGET_CHANNEL
                ).invokeMethod("openItemForm", null)
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