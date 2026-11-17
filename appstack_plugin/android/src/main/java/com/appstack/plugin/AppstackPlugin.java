package com.appstack.plugin;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.appstack.attribution.AppLinkResult;
import com.appstack.attribution.AppstackAttributionSdk;
import com.appstack.attribution.EventType;
import com.appstack.attribution.LinkOptions;
import com.appstack.attribution.LogLevel;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlin.coroutines.EmptyCoroutineContext;
import kotlin.coroutines.intrinsics.IntrinsicsKt;

/**
 * AppstackPlugin, written in Java so the plugin needs no Kotlin compiler in the
 * host app's build. The Android SDK stays Kotlin: it ships precompiled, and its
 * suspend functions are called here through a Continuation.
 */
public class AppstackPlugin implements FlutterPlugin, MethodCallHandler {

  /** Delivers the attribution params once the native match phase is done. */
  interface AttributionParamsSource {
    void await(Callback<Map<String, String>> callback);
  }

  interface Callback<T> {
    void onResult(@Nullable T value, @Nullable Throwable error);
  }

  private final AttributionParamsSource attributionParams;
  private final Executor background;
  private final Executor mainThread;

  // Bumped on detach so replies for a dead engine are dropped.
  private final AtomicInteger engineGeneration = new AtomicInteger();

  @Nullable private MethodChannel channel;
  @Nullable private Context context;

  /** Used by Flutter's plugin registrant. */
  public AppstackPlugin() {
    this(
        callback -> AppstackPlugin.<Map<String, String>>callSuspend(
            continuation -> AppstackAttributionSdk.awaitAttributionParams(null, continuation),
            callback),
        Executors.newCachedThreadPool(),
        new MainThreadExecutor());
  }

  AppstackPlugin(AttributionParamsSource attributionParams, Executor background, Executor mainThread) {
    this.attributionParams = attributionParams;
    this.background = background;
    this.mainThread = mainThread;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    context = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), "appstack_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
    }
    engineGeneration.incrementAndGet();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "configure": handleConfigure(call, result); break;
      case "setCustomerUserId": handleSetCustomerUserId(call, result); break;
      case "deleteUserData": handleDeleteUserData(result); break;
      case "sendEvent": handleSendEvent(call, result); break;
      // Apple Ads Attribution is iOS-only, return false on Android
      case "enableAppleAdsAttribution": result.success(false); break;
      case "getAppstackId": handleGetAppstackId(result); break;
      case "isSdkDisabled": handleIsSdkDisabled(result); break;
      case "getAttributionParams": handleGetAttributionParams(result); break;
      case "handleUniversalLink": handleUniversalLink(call, result); break;
      default: result.notImplemented();
    }
  }

  private void handleConfigure(MethodCall call, Result result) {
    try {
      String apiKey = call.argument("apiKey");
      if (apiKey == null || apiKey.isEmpty()) {
        result.error("INVALID_ARGUMENTS", "API key is required", null);
        return;
      }
      Integer logLevelArg = call.argument("logLevel");
      int logLevelInt = logLevelArg != null ? logLevelArg : 1;
      String customerUserId = call.argument("customerUserId");
      String wrapperVersion = call.argument("wrapperVersion");
      if (wrapperVersion == null) wrapperVersion = "flutter-0.0.1";

      LogLevel logLevel;
      switch (logLevelInt) {
        case 0: logLevel = LogLevel.DEBUG; break;
        case 2: logLevel = LogLevel.WARN; break;
        case 3: logLevel = LogLevel.ERROR; break;
        default: logLevel = LogLevel.INFO;
      }

      // Testing-only proxy override from the host app's manifest (repo-only key).
      String devProxyUrl = readDevProxyUrl();
      if (devProxyUrl != null && !devProxyUrl.isEmpty()) {
        AppstackAttributionSdk.setProxyUrl(devProxyUrl);
      }

      AppstackAttributionSdk.configureWrapper(
          context, apiKey, wrapperVersion, logLevel, /* listener= */ null, customerUserId);
      result.success(true);
    } catch (Exception e) {
      result.error("CONFIGURATION_ERROR", "Failed to configure SDK: " + e.getMessage(), null);
    }
  }

  /** Forwarded verbatim: a null or blank id is an explicit clear here. */
  private void handleSetCustomerUserId(MethodCall call, Result result) {
    try {
      AppstackAttributionSdk.setCustomerUserId(call.argument("customerUserId"));
      result.success(null);
    } catch (Exception e) {
      result.error("SET_CUSTOMER_USER_ID_ERROR", "Failed to set customer user ID: " + e.getMessage(), null);
    }
  }

  private void handleDeleteUserData(Result result) {
    int generation = engineGeneration.get();
    background.execute(() -> AppstackPlugin.<Unit>callSuspend(
        AppstackAttributionSdk::deleteUserData,
        (Unit ignored, Throwable error) -> reply(generation, () -> {
          if (error == null) {
            result.success(null);
          } else {
            result.error("DELETE_USER_DATA_ERROR", "Failed to delete user data: " + error.getMessage(), null);
          }
        })));
  }

  private void handleSendEvent(MethodCall call, Result result) {
    try {
      String eventTypeString = call.argument("eventType");
      if (eventTypeString == null || eventTypeString.isEmpty()) {
        result.error("INVALID_ARGUMENTS", "Event type is required", null);
        return;
      }
      EventType eventType = stringToEventType(eventTypeString);
      if (eventType == null) {
        result.error("INVALID_EVENT_TYPE", "Invalid event type: " + eventTypeString, null);
        return;
      }
      String eventName = call.argument("eventName");
      Map<String, Object> parameters = call.argument("parameters");
      AppstackAttributionSdk.sendEvent(eventType, eventName, parameters);
      result.success(null);
    } catch (Exception e) {
      result.error("EVENT_SEND_ERROR", "Failed to send event: " + e.getMessage(), null);
    }
  }

  private void handleGetAppstackId(Result result) {
    try {
      result.success(AppstackAttributionSdk.getAppstackId());
    } catch (Exception e) {
      result.error("GET_ID_ERROR", "Failed to get Appstack ID: " + e.getMessage(), null);
    }
  }

  private void handleIsSdkDisabled(Result result) {
    try {
      result.success(AppstackAttributionSdk.isSdkDisabled());
    } catch (Exception e) {
      result.error("IS_SDK_DISABLED_ERROR", "Failed to check SDK disabled status: " + e.getMessage(), null);
    }
  }

  /**
   * Waits for the native match phase, like the iOS plugin. Runs off the platform
   * thread and replies on it.
   */
  private void handleGetAttributionParams(Result result) {
    int generation = engineGeneration.get();
    background.execute(() -> attributionParams.await((params, error) -> reply(generation, () -> {
      if (error == null) {
        result.success(params);
      } else {
        result.error("GET_ATTRIBUTION_PARAMS_ERROR", "Failed to get attribution params: " + error.getMessage(), null);
      }
    })));
  }

  private void handleUniversalLink(MethodCall call, Result result) {
    try {
      String url = call.argument("url");
      if (url == null || url.trim().isEmpty()) {
        result.error("INVALID_ARGUMENTS", "A valid URL is required", null);
        return;
      }
      List<String> hosts = call.argument("allowedHosts");
      LinkOptions options = new LinkOptions(hosts == null ? null : new HashSet<>(hosts));
      AppLinkResult parsed = AppstackAttributionSdk.handleAppLink(Uri.parse(url), options);
      if (parsed == null) {
        result.success(null);
        return;
      }
      Map<String, Object> response = new HashMap<>();
      response.put("deeplinkId", parsed.getDeeplinkId());
      response.put("queryParams", parsed.getQueryParams());
      response.put("url", parsed.getUri().toString());
      result.success(response);
    } catch (Exception e) {
      result.error("UNIVERSAL_LINK_ERROR", "Failed to parse universal link: " + e.getMessage(), null);
    }
  }

  /** Posts a reply to the main thread unless the engine has detached since. */
  private void reply(int generation, Runnable send) {
    mainThread.execute(() -> {
      if (engineGeneration.get() == generation) {
        send.run();
      }
    });
  }

  @Nullable
  private String readDevProxyUrl() {
    try {
      ApplicationInfo info = context.getPackageManager()
          .getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
      return info.metaData != null ? info.metaData.getString("APPSTACK_DEV_PROXY_URL") : null;
    } catch (Exception e) {
      return null;
    }
  }

  @Nullable
  private static EventType stringToEventType(String value) {
    switch (value) {
      case "INSTALL": return EventType.INSTALL;
      case "LOGIN": return EventType.LOGIN;
      case "SIGN_UP": return EventType.SIGN_UP;
      case "REGISTER": return EventType.REGISTER;
      case "PURCHASE": return EventType.PURCHASE;
      case "ADD_TO_CART": return EventType.ADD_TO_CART;
      case "ADD_TO_WISHLIST": return EventType.ADD_TO_WISHLIST;
      case "INITIATE_CHECKOUT": return EventType.INITIATE_CHECKOUT;
      case "START_TRIAL": return EventType.START_TRIAL;
      case "SUBSCRIBE": return EventType.SUBSCRIBE;
      case "LEVEL_START": return EventType.LEVEL_START;
      case "LEVEL_COMPLETE": return EventType.LEVEL_COMPLETE;
      case "TUTORIAL_COMPLETE": return EventType.TUTORIAL_COMPLETE;
      case "SEARCH": return EventType.SEARCH;
      case "VIEW_ITEM": return EventType.VIEW_ITEM;
      case "VIEW_CONTENT": return EventType.VIEW_CONTENT;
      case "SHARE": return EventType.SHARE;
      case "CUSTOM": return EventType.CUSTOM;
      default: return null;
    }
  }

  /** A Kotlin suspend function as seen from Java: it takes a trailing Continuation. */
  interface SuspendCall<T> {
    Object invoke(Continuation<T> continuation);
  }

  /**
   * Calls a suspend function from Java. The callback runs exactly once: on the
   * calling thread if the function returns without suspending, otherwise on the
   * thread that resumes it, which may be one of the SDK's background threads.
   * Callbacks must therefore not reply to Flutter directly; go through reply().
   *
   * Only the suspend call itself is guarded: the callback is invoked outside the
   * try/catch, so an exception thrown by the callback can never trigger a second
   * call with that exception as the error.
   */
  @SuppressWarnings("unchecked")
  static <T> void callSuspend(SuspendCall<T> call, Callback<T> callback) {
    Continuation<T> continuation = new Continuation<T>() {
      @NonNull
      @Override
      public CoroutineContext getContext() {
        return EmptyCoroutineContext.INSTANCE;
      }

      @Override
      public void resumeWith(@NonNull Object outcome) {
        Throwable failure = null;
        try {
          ResultKt.throwOnFailure(outcome);
        } catch (Throwable error) {
          failure = error;
        }
        if (failure == null) {
          callback.onResult((T) outcome, null);
        } else {
          callback.onResult(null, failure);
        }
      }
    };
    Object value;
    try {
      value = call.invoke(continuation);
    } catch (Throwable error) {
      callback.onResult(null, error);
      return;
    }
    if (value != IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
      callback.onResult((T) value, null);
    }
  }

  private static final class MainThreadExecutor implements Executor {
    private final Handler handler = new Handler(Looper.getMainLooper());

    @Override
    public void execute(Runnable command) {
      handler.post(command);
    }
  }
}
