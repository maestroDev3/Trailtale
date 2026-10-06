package de.maestrodev.trailtale

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hands taps on the home screen widget “I'm here” to Flutter: a tap that
 * started the app is asked for once ("pendingRequest"), later taps arrive
 * as "capture" calls.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingRequest = false

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingRequest = savedInstanceState == null && isQuickCapture(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "pendingRequest") {
                    result.success(pendingRequest)
                    pendingRequest = false
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isQuickCapture(intent)) channel?.invokeMethod("capture", null)
    }

    private fun isQuickCapture(intent: Intent?) = intent?.action == ACTION_QUICK_CAPTURE

    companion object {
        const val CHANNEL = "trailtale/quick_capture"
        const val ACTION_QUICK_CAPTURE = "de.maestrodev.trailtale.QUICK_CAPTURE"
    }
}
