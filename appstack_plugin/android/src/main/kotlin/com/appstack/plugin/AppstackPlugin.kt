package com.appstack.plugin

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.appstack.attribution.AppstackAttributionSdk
import com.appstack.attribution.EventType
import com.appstack.attribution.LogLevel
import com.appstack.attribution.LinkOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.launch

/** AppstackPlugin */
class AppstackPlugin internal constructor(
  private val awaitAttributionParams: suspend () -> Map<String, String>,
  private val postToMainThread: (Runnable) -> Unit,
  backgroundDispatcher: CoroutineDispatcher,
) : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

  /** Used by Flutter's plugin registrant. */
  constructor() : this(
    awaitAttributionParams = { AppstackAttributionSdk.awaitAttributionParams(rawReferrer = null) },
    postToMainThread = { runnable -> Handler(Looper.getMainLooper()).post(runnable) },
    backgroundDispatcher = Dispatchers.IO,
  )

  private lateinit var channel: MethodChannel
  private lateinit var attributionEventChannel: EventChannel
  private lateinit var context: Context

  // Work that outlives a single platform-channel call. Children are cancelled
  // when the plugin detaches from its engine, so no reply is sent to a dead
  // messenger. SupervisorJob: one failed request doesn't cancel the others.
  private val scope = CoroutineScope(SupervisorJob() + backgroundDispatcher)

  // Read and written on the platform (main) thread only.
  private var attributionEventSink: EventChannel.EventSink? = null
  private var attributionStreamJob: Job? = null

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
      "setCustomerUserId" -> handleSetCustomerUserId(call, result)
      "deleteUserData" -> handleDeleteUserData(result)
      "sendEvent" -> handleSendEvent(call, result)
      "enableAppleAdsAttribution" -> {
        // Apple Ads Attribution is iOS-only, return false on Android
        result.success(false)
      }
      "getAppstackId" -> handleGetAppstackId(result)
      "isSdkDisabled" -> handleIsSdkDisabled(result)
      "getAttributionParams" -> handleGetAttributionParams(result)
      "handleUniversalLink" -> handleUniversalLink(call, result)
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
   * Sets — or clears — the customer user id after configure(). Forwarded verbatim:
   * unlike the configure path, a null or blank id is an explicit clear here.
   */
  private fun handleSetCustomerUserId(call: MethodCall, result: Result) {
    try {
      AppstackAttributionSdk.setCustomerUserId(call.argument<String>("customerUserId"))
      result.success(null)
    } catch (e: Exception) {
      result.error(
        "SET_CUSTOMER_USER_ID_ERROR",
        "Failed to set customer user ID: ${e.message}",
        null
      )
    }
  }

  private fun handleDeleteUserData(result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        AppstackAttributionSdk.deleteUserData()
        result.success(null)
      } catch (e: Exception) {
        result.error(
          "DELETE_USER_DATA_ERROR",
          "Failed to delete user data: ${e.message}",
          null
        )
      }
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

  /**
   * awaitAttributionParams waits for the native match phase, like the iOS
   * plugin's async getAttributionParams. The non-suspending getAttributionParams
   * returns an empty map when called before the /match response is cached, which
   * is the case right after configure(). Runs off the platform thread and
   * replies on it.
   */
  private fun handleGetAttributionParams(result: Result) {
    scope.launch {
      try {
        val params = awaitAttributionParams()
        postToMainThread { result.success(params) }
      } catch (e: CancellationException) {
        // The plugin detached from its engine: there is no one left to reply to.
        throw e
      } catch (e: Exception) {
        postToMainThread {
          result.error("GET_ATTRIBUTION_PARAMS_ERROR", "Failed to get attribution params: ${e.message}", null)
        }
      }
    }
  }

  private fun handleUniversalLink(call: MethodCall, result: Result) {
    try {
      val url = call.argument<String>("url")
      if (url.isNullOrBlank()) {
        result.error("INVALID_ARGUMENTS", "A valid URL is required", null)
        return
      }
      val allowedHosts = call.argument<List<String>>("allowedHosts")?.toSet()
      val parsed = AppstackAttributionSdk.handleAppLink(Uri.parse(url), LinkOptions(allowedHosts))
      if (parsed == null) {
        result.success(null)
        return
      }
      result.success(mapOf(
        "deeplinkId" to parsed.deeplinkId,
        "queryParams" to parsed.queryParams,
        "url" to parsed.uri.toString()
      ))
    } catch (e: Exception) {
      result.error("UNIVERSAL_LINK_ERROR", "Failed to parse universal link: ${e.message}", null)
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

  /**
   * One-shot stream behind getAttributionParamsWithCallback: emits the params
   * once the native match phase is done, then ends. Called on the platform thread.
   */
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    attributionStreamJob?.cancel()
    attributionEventSink = events
    attributionStreamJob = scope.launch {
      try {
        val params = awaitAttributionParams()
        postToMainThread {
          // Skip if Dart cancelled or re-listened while we were waiting.
          if (attributionEventSink === events) {
            events?.success(params)
            events?.endOfStream()
            attributionEventSink = null
            attributionStreamJob = null
          }
        }
      } catch (e: CancellationException) {
        // onCancel or detach: Dart is no longer listening.
        throw e
      } catch (e: Exception) {
        postToMainThread {
          if (attributionEventSink === events) {
            events?.error("GET_ATTRIBUTION_PARAMS_ERROR", "Failed to get attribution params: ${e.message}", null)
            attributionEventSink = null
            attributionStreamJob = null
          }
        }
      }
    }
  }

  override fun onCancel(arguments: Any?) {
    attributionStreamJob?.cancel()
    attributionStreamJob = null
    attributionEventSink = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    attributionEventChannel.setStreamHandler(null)
    attributionStreamJob = null
    attributionEventSink = null
    scope.coroutineContext.cancelChildren()
  }
}
