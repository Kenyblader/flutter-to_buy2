package com.example.to_buy

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

object StorageHelper {
    private const val PREFERENCES_NAME = "ListifyStorageWidget"
    private lateinit var sharedPreferences: SharedPreferences

    fun initialize(context: Context) {
        print("Shared preference name create: $PREFERENCES_NAME")
        sharedPreferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    }

    fun setValue(key: String, value: Any) {
        val editor = sharedPreferences.edit()
        when (value) {
            is String -> editor.putString(key, value)
            is Int -> editor.putInt(key, value)
            is Boolean -> editor.putBoolean(key, value)
            is Float -> editor.putFloat(key, value)
            is Long -> editor.putLong(key, value)
            else -> throw IllegalArgumentException("Unsupported value type")
        }
        editor.apply ()
    }

    fun getString(key: String): String? {
        return sharedPreferences.getString(key, null)
    }

    fun getInt(key: String, defaultValue: Int = 0): Int {
        return sharedPreferences.getInt(key, defaultValue)
    }
}