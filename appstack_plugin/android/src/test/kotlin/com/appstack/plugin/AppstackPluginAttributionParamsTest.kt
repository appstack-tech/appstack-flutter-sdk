package com.appstack.plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * getAttributionParams must wait for the native attribution match instead of
 * returning whatever is cached at call time.
 */
class AppstackPluginAttributionParamsTest {

  private val matched = mapOf("appstack_adnetwork" to "meta", "appstack_campaign" to "summer")

  private val match = CompletableDeferred<Map<String, String>>()
  private val mainThread = mutableListOf<Runnable>()

  // Unconfined runs the coroutine inline up to its first suspension, so the test
  // controls exactly when the "match" completes. Main-thread posts are queued and
  // drained explicitly to check that replies go through the platform thread.
  private val plugin = AppstackPlugin(
    awaitAttributionParams = { match.await() },
    postToMainThread = { mainThread.add(it) },
    backgroundDispatcher = Dispatchers.Unconfined,
  )

  private fun drainMainThread() {
    while (mainThread.isNotEmpty()) mainThread.removeAt(0).run()
  }

  @Test
  fun `getAttributionParams replies only after the match completes`() {
    val result = FakeResult()
    plugin.onMethodCall(MethodCall("getAttributionParams", null), result)

    drainMainThread()
    assertFalse("must not reply before the match completes", result.replied)

    match.complete(matched)
    assertFalse("reply must be posted to the main thread", result.replied)

    drainMainThread()
    assertEquals(matched, result.success)
  }

  @Test
  fun `getAttributionParams reports native errors`() {
    val result = FakeResult()
    plugin.onMethodCall(MethodCall("getAttributionParams", null), result)

    match.completeExceptionally(IllegalStateException("boom"))
    drainMainThread()

    assertEquals("GET_ATTRIBUTION_PARAMS_ERROR", result.errorCode)
    assertTrue(result.errorMessage!!.contains("boom"))
  }

  @Test
  fun `getAttributionParams sends no reply when the await is cancelled`() {
    val result = FakeResult()
    plugin.onMethodCall(MethodCall("getAttributionParams", null), result)

    // Cancellation (plugin detached from its engine) is not an error to report.
    match.cancel()
    drainMainThread()

    assertFalse(result.replied)
  }

  private class FakeResult : MethodChannel.Result {
    var replied = false
    var success: Any? = null
    var errorCode: String? = null
    var errorMessage: String? = null

    override fun success(result: Any?) {
      replied = true
      success = result
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      replied = true
      this.errorCode = errorCode
      this.errorMessage = errorMessage
    }

    override fun notImplemented() {
      replied = true
    }
  }

}
