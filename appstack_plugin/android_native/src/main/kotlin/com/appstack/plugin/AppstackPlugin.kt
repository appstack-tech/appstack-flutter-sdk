package com.appstack.plugin

import android.content.Context
import androidx.annotation.NonNull
import com.appstack.attribution.AppstackAttributionSdk
import com.appstack.attribution.EventType
import com.appstack.attribution.LogLevel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AppstackPlugin */
class AppstackPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appstack_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "configure" -> handleConfigure(call, result)
      "sendEvent" -> handleSendEvent(call, result)
      "enableAppleAdsAttribution" -> {
        // Apple Ads Attribution is iOS-only, return false on Android
        result.success(false)
      }
      else -> result.notImplemented()
    }
  }

  private fun handleConfigure(call: MethodCall, result: Result) {
    try {
      val apiKey = call.argument<String>("apiKey")
      if (apiKey.isNullOrEmpty()) {
        result.error("INVALID_ARGUMENTS", "API key is required", null)
        return
      }

      val isDebug = call.argument<Boolean>("isDebug") ?: false
      val endpointBaseUrl = call.argument<String>("endpointBaseUrl")
      val logLevelInt = call.argument<Int>("logLevel") ?: 1

      // Map log level to LogLevel enum
      val logLevel = when (logLevelInt) {
        0 -> LogLevel.DEBUG
        1 -> LogLevel.INFO
        2 -> LogLevel.WARN
        3 -> LogLevel.ERROR
        else -> LogLevel.INFO
      }

      // Configure the SDK
      if (endpointBaseUrl != null) {
        AppstackAttributionSdk.configure(
          context = context,
          apiKey = apiKey,
          isDebug = isDebug,
          endpointBaseUrl = endpointBaseUrl,
          logLevel = logLevel
        )
      } else {
        AppstackAttributionSdk.configure(
          context = context,
          apiKey = apiKey,
          isDebug = isDebug,
          logLevel = logLevel
        )
      }

      result.success(true)
    } catch (e: Exception) {
      result.error("CONFIGURATION_ERROR", "Failed to configure SDK: ${e.message}", null)
    }
  }

  private fun handleSendEvent(call: MethodCall, result: Result) {
    try {
      val eventTypeString = call.argument<String>("eventType")
      if (eventTypeString.isNullOrEmpty()) {
        result.error("INVALID_ARGUMENTS", "Event type is required", null)
        return
      }

      val eventName = call.argument<String>("eventName")
      val revenue = call.argument<Double>("revenue")

      // Convert string to EventType
      val eventType = stringToEventType(eventTypeString)
      if (eventType == null) {
        result.error("INVALID_EVENT_TYPE", "Invalid event type: $eventTypeString", null)
        return
      }

      // Send the event
      AppstackAttributionSdk.sendEvent(eventType, eventName, revenue)

      result.success(true)
    } catch (e: Exception) {
      result.error("EVENT_SEND_ERROR", "Failed to send event: ${e.message}", null)
    }
  }

  private fun stringToEventType(string: String): EventType? {
    return when (string) {
      "INSTALL" -> EventType.INSTALL
      "LOGIN" -> EventType.LOGIN
      "SIGN_UP" -> EventType.SIGN_UP
      "REGISTER" -> EventType.REGISTER
      "PURCHASE" -> EventType.PURCHASE
      "ADD_TO_CART" -> EventType.ADD_TO_CART
      "ADD_TO_WISHLIST" -> EventType.ADD_TO_WISHLIST
      "INITIATE_CHECKOUT" -> EventType.INITIATE_CHECKOUT
      "START_TRIAL" -> EventType.START_TRIAL
      "SUBSCRIBE" -> EventType.SUBSCRIBE
      "LEVEL_START" -> EventType.LEVEL_START
      "LEVEL_COMPLETE" -> EventType.LEVEL_COMPLETE
      "TUTORIAL_COMPLETE" -> EventType.TUTORIAL_COMPLETE
      "SEARCH" -> EventType.SEARCH
      "VIEW_ITEM" -> EventType.VIEW_ITEM
      "VIEW_CONTENT" -> EventType.VIEW_CONTENT
      "SHARE" -> EventType.SHARE
      "CUSTOM" -> EventType.CUSTOM
      else -> null
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
