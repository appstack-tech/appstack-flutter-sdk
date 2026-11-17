package com.appstack.plugin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import kotlin.ResultKt;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import org.junit.Test;

/**
 * getAttributionParams must wait for the native attribution match instead of
 * returning whatever is cached at call time.
 */
public class AppstackPluginAttributionParamsTest {

  private final Map<String, String> matched = new HashMap<>();
  {
    matched.put("appstack_adnetwork", "meta");
    matched.put("appstack_campaign", "summer");
  }

  // The "match": the test decides when it completes, and how.
  private AppstackPlugin.Callback<Map<String, String>> pending;
  private final List<Runnable> mainThread = new ArrayList<>();

  // Background work runs inline; main-thread posts are queued and drained
  // explicitly to check that replies go through the platform thread.
  private final AppstackPlugin plugin = new AppstackPlugin(
      callback -> pending = callback,
      Runnable::run,
      mainThread::add);

  private void drainMainThread() {
    while (!mainThread.isEmpty()) mainThread.remove(0).run();
  }

  @Test
  public void repliesOnlyAfterTheMatchCompletes() {
    FakeResult result = new FakeResult();
    plugin.onMethodCall(new MethodCall("getAttributionParams", null), result);

    drainMainThread();
    assertFalse("must not reply before the match completes", result.replied);

    pending.onResult(matched, null);
    assertFalse("reply must be posted to the main thread", result.replied);

    drainMainThread();
    assertEquals(matched, result.success);
  }

  @Test
  public void reportsNativeErrors() {
    FakeResult result = new FakeResult();
    plugin.onMethodCall(new MethodCall("getAttributionParams", null), result);

    pending.onResult(null, new IllegalStateException("boom"));
    drainMainThread();

    assertEquals("GET_ATTRIBUTION_PARAMS_ERROR", result.errorCode);
    assertTrue(result.errorMessage.contains("boom"));
  }

  @Test
  public void sendsNoReplyAfterTheEngineDetaches() {
    FakeResult result = new FakeResult();
    plugin.onMethodCall(new MethodCall("getAttributionParams", null), result);

    plugin.onDetachedFromEngine(null);
    pending.onResult(matched, null);
    drainMainThread();

    assertFalse(result.replied);
  }

  @Test
  public void callSuspendHandlesImmediateReturnAndSynchronousThrow() {
    List<Object> seen = new ArrayList<>();
    // Returns without suspending.
    AppstackPlugin.<String>callSuspend(c -> "now", (v, e) -> seen.add(v));
    // Throws synchronously.
    AppstackPlugin.<String>callSuspend(c -> { throw new IllegalStateException("x"); },
        (v, e) -> seen.add(e.getMessage()));
    assertEquals(2, seen.size());
    assertEquals("now", seen.get(0));
    assertEquals("x", seen.get(1));
  }

  @Test
  public void callSuspendDeliversAValueResumedLater() {
    // A suspend function that suspends, as the SDK's awaitAttributionParams does
    // until the match finishes, and is resumed later by the test.
    List<Continuation<String>> suspended = new ArrayList<>();
    List<Object> seen = new ArrayList<>();
    AppstackPlugin.<String>callSuspend(c -> {
      suspended.add(c);
      return IntrinsicsKt.getCOROUTINE_SUSPENDED();
    }, (v, e) -> seen.add(e == null ? v : e));

    assertTrue("must not call back while suspended", seen.isEmpty());
    suspended.get(0).resumeWith("matched");
    assertEquals(1, seen.size());
    assertEquals("matched", seen.get(0));
  }

  @Test
  public void callSuspendDeliversAFailureResumedLater() {
    List<Continuation<String>> suspended = new ArrayList<>();
    List<Throwable> errors = new ArrayList<>();
    AppstackPlugin.<String>callSuspend(c -> {
      suspended.add(c);
      return IntrinsicsKt.getCOROUTINE_SUSPENDED();
    }, (v, e) -> errors.add(e));

    suspended.get(0).resumeWith(ResultKt.createFailure(new IllegalStateException("late")));
    assertEquals(1, errors.size());
    assertEquals("late", errors.get(0).getMessage());
  }

  @Test
  public void callSuspendCallsBackOnceEvenIfTheCallbackThrows() {
    int[] calls = {0};
    AppstackPlugin.Callback<String> throwing = (v, e) -> {
      calls[0]++;
      throw new IllegalStateException("callback failed");
    };

    // Immediate return path.
    try {
      AppstackPlugin.<String>callSuspend(c -> "now", throwing);
    } catch (IllegalStateException expected) {
      // The callback's own exception propagates; it is not fed back as an error.
    }
    assertEquals(1, calls[0]);

    // Resumed path.
    List<Continuation<String>> suspended = new ArrayList<>();
    AppstackPlugin.<String>callSuspend(c -> {
      suspended.add(c);
      return IntrinsicsKt.getCOROUTINE_SUSPENDED();
    }, throwing);
    try {
      suspended.get(0).resumeWith("later");
    } catch (IllegalStateException expected) {
      // Same: propagates once, no second call.
    }
    assertEquals(2, calls[0]);
  }

  private static final class FakeResult implements MethodChannel.Result {
    boolean replied;
    Object success;
    String errorCode;
    String errorMessage;

    @Override public void success(Object value) { replied = true; success = value; }

    @Override public void error(String code, String message, Object details) {
      replied = true; errorCode = code; errorMessage = message;
    }

    @Override public void notImplemented() { replied = true; }
  }
}
