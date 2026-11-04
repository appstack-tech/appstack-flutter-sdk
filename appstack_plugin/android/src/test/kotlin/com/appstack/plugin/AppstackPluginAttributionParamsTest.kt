package com.appstack.plugin

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * getAttributionParams and the attribution event channel must wait for the
 * native attribution match instead of returning whatever is cached at call time.
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

  @Test
  fun `stream emits once after the match completes, then ends`() {
    val sink = FakeSink()
    plugin.onListen(null, sink)

    drainMainThread()
    assertTrue(sink.events.isEmpty())

    match.complete(matched)
    drainMainThread()

    assertEquals(listOf<Any?>(matched), sink.events)
    assertTrue(sink.ended)
  }

  @Test
  fun `stream sends nothing after Dart cancels`() {
    val sink = FakeSink()
    plugin.onListen(null, sink)
    plugin.onCancel(null)

    match.complete(matched)
    drainMainThread()

    assertTrue(sink.events.isEmpty())
    assertFalse(sink.ended)
    assertNull(sink.errorCode)
  }

  @Test
  fun `stream re-listen only delivers to the latest sink`() {
    val first = FakeSink()
    val second = FakeSink()
    plugin.onListen(null, first)
    plugin.onListen(null, second)

    match.complete(matched)
    drainMainThread()

    assertTrue(first.events.isEmpty())
    assertEquals(listOf<Any?>(matched), second.events)
  }

  @Test
  fun `stream reports native errors`() {
    val sink = FakeSink()
    plugin.onListen(null, sink)

    match.completeExceptionally(IllegalStateException("boom"))
    drainMainThread()

    assertEquals("GET_ATTRIBUTION_PARAMS_ERROR", sink.errorCode)
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

  private class FakeSink : EventChannel.EventSink {
    val events = mutableListOf<Any?>()
    var ended = false
    var errorCode: String? = null

    override fun success(event: Any?) {
      events.add(event)
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      this.errorCode = errorCode
    }

    override fun endOfStream() {
      ended = true
    }
  }
}
