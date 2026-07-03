package com.appstack.plugin

import android.content.Context
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import com.appstack.attribution.AppstackAttributionSdk
import com.appstack.attribution.EventType
import com.appstack.attribution.LogLevel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AppstackPlugin */
class AppstackPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel: MethodChannel
  private lateinit var attributionEventChannel: EventChannel
  private lateinit var context: Context
  private var attributionEventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appstack_plugin")
    channel.setMethodCallHandler(this)
    attributionEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "appstack_plugin/attribution_params")
    attributionEventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "configure" -> handleConfigure(call, result)
      "sendEvent" -> handleSendEvent(call, result)
      "enableAppleAdsAttribution" -> {
        // Apple Ads Attribution is iOS-only, return false on Android
        result.success(false)
      }
      "getAppstackId" -> handleGetAppstackId(result)
      "isSdkDisabled" -> handleIsSdkDisabled(result)
      "getAttributionParams" -> handleGetAttributionParams(result)
      else -> result.notImplemented()
    }
  }

  @OptIn(com.appstack.attribution.InternalAppstackApi::class)
  private fun handleConfigure(call: MethodCall, result: Result) {
    try {
      val apiKey = call.argument<String>("apiKey")
      if (apiKey.isNullOrEmpty()) {
        result.error("INVALID_ARGUMENTS", "API key is required", null)
        return
      }

      val logLevelInt = call.argument<Int>("logLevel") ?: 1
      val customerUserId = call.argument<String>("customerUserId")
      val wrapperVersion = call.argument<String>("wrapperVersion") ?: "flutter-0.0.1"

      // Map log level to LogLevel enum.
      val logLevel = when (logLevelInt) {
        0 -> LogLevel.DEBUG
        1 -> LogLevel.INFO
        2 -> LogLevel.WARN
        3 -> LogLevel.ERROR
        else -> LogLevel.INFO
      }

      // Testing-only proxy override, read from the app's manifest metadata. This
      // is NOT exposed through the public configure() API: a proxy URL is applied
      // only if the host app deliberately ships an APPSTACK_DEV_PROXY_URL
      // <meta-data> entry (our sample_app does; published-plugin consumers do
      // not). Routed through the SDK's internal setProxyUrl(_) hook and applied
      // BEFORE configure so the SDK's initial requests target it.
      val devProxyUrl = readDevProxyUrl()
      if (!devProxyUrl.isNullOrEmpty()) {
        AppstackAttributionSdk.setProxyUrl(devProxyUrl)
      }

      // Configure the SDK. This plugin reports a wrapper version, so it uses
      // the internal `configureWrapper` entry point.
      AppstackAttributionSdk.configureWrapper(
        context = context,
        apiKey = apiKey,
        wrapperVersion = wrapperVersion,
        logLevel = logLevel,
        customerUserId = customerUserId
      )

      result.success(true)
    } catch (e: Exception) {
      result.error("CONFIGURATION_ERROR", "Failed to configure SDK: ${e.message}", null)
    }
  }

  /**
   * Reads the repo-only APPSTACK_DEV_PROXY_URL <meta-data> value from the host
   * app's manifest, mirroring the iOS Info.plist key of the same name. Returns
   * null when the key is absent (the published-plugin case).
   */
  private fun readDevProxyUrl(): String? {
    return try {
      val appInfo = context.packageManager.getApplicationInfo(
        context.packageName,
        PackageManager.GET_META_DATA
      )
      appInfo.metaData?.getString("APPSTACK_DEV_PROXY_URL")
    } catch (e: Exception) {
      null
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
      val parameters = call.argument<Map<String, Any>>("parameters")

      // Convert string to EventType
      val eventType = stringToEventType(eventTypeString)
      if (eventType == null) {
        result.error("INVALID_EVENT_TYPE", "Invalid event type: $eventTypeString", null)
        return
      }

      // Send the event
      AppstackAttributionSdk.sendEvent(eventType, eventName, parameters)

      result.success(true)
    } catch (e: Exception) {
      result.error("EVENT_SEND_ERROR", "Failed to send event: ${e.message}", null)
    }
  }

  private fun handleGetAppstackId(result: Result) {
    try {
      val appstackId = AppstackAttributionSdk.getAppstackId()
      result.success(appstackId)
    } catch (e: Exception) {
      result.error("GET_ID_ERROR", "Failed to get Appstack ID: ${e.message}", null)
    }
  }

  private fun handleIsSdkDisabled(result: Result) {
    try {
      val isSdkDisabled = AppstackAttributionSdk.isSdkDisabled()
      result.success(isSdkDisabled)
    } catch (e: Exception) {
      result.error("IS_SDK_DISABLED_ERROR", "Failed to check SDK disabled status: ${e.message}", null)
    }
  }

  private fun handleGetAttributionParams(result: Result) {
    try {
      val attributionParams = AppstackAttributionSdk.getAttributionParams(rawReferrer = null)
      result.success(attributionParams)
    } catch (e: Exception) {
      result.error("GET_ATTRIBUTION_PARAMS_ERROR", "Failed to get attribution params: ${e.message}", null)
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

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    attributionEventSink = events
    Thread {
      try {
        val params = AppstackAttributionSdk.getAttributionParams(rawReferrer = null)
        android.os.Handler(android.os.Looper.getMainLooper()).post {
          events?.success(params)
          events?.endOfStream()
          attributionEventSink = null
        }
      } catch (e: Exception) {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
          events?.error("GET_ATTRIBUTION_PARAMS_ERROR", "Failed to get attribution params: ${e.message}", null)
          attributionEventSink = null
        }
      }
    }.start()
  }

  override fun onCancel(arguments: Any?) {
    attributionEventSink = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    attributionEventChannel.setStreamHandler(null)
  }
}
