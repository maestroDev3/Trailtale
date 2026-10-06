package de.maestrodev.trailtale

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands requests from outside the app to Flutter:
 * - taps on the home screen widget “I'm here” ("trailtale/quick_capture"),
 * - photos shared by other apps ("trailtale/shared_photos"); they are copied
 *   into the app cache first, because the shared content URIs are readable
 *   only for a short time.
 * A request that started the app is asked for once by Flutter ("pending…"),
 * later ones are pushed as calls.
 */
class MainActivity : FlutterActivity() {
    private var quickCaptureChannel: MethodChannel? = null
    private var pendingQuickCapture = false

    private var sharedPhotosChannel: MethodChannel? = null
    private var pendingPhotos: List<String>? = null
    private var waitingForPhotos: MethodChannel.Result? = null
    private var copyingInitialShare = false

    override fun onCreate(savedInstanceState: Bundle?) {
        if (savedInstanceState == null) {
            pendingQuickCapture = isQuickCapture(intent)
            if (isPhotoShare(intent)) copySharedPhotos(intent, initial = true)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        quickCaptureChannel = MethodChannel(messenger, QUICK_CAPTURE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "pendingRequest") {
                    result.success(pendingQuickCapture)
                    pendingQuickCapture = false
                } else {
                    result.notImplemented()
                }
            }
        }
        sharedPhotosChannel = MethodChannel(messenger, SHARED_PHOTOS_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "pendingPhotos") {
                    if (copyingInitialShare) {
                        waitingForPhotos = result
                    } else {
                        result.success(pendingPhotos ?: emptyList<String>())
                        pendingPhotos = null
                    }
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isQuickCapture(intent)) quickCaptureChannel?.invokeMethod("capture", null)
        if (isPhotoShare(intent)) copySharedPhotos(intent, initial = false)
    }

    private fun isQuickCapture(intent: Intent?) = intent?.action == ACTION_QUICK_CAPTURE

    private fun isPhotoShare(intent: Intent?) =
        (intent?.action == Intent.ACTION_SEND || intent?.action == Intent.ACTION_SEND_MULTIPLE) &&
            intent.type?.startsWith("image/") == true

    /** Copies the shared photos off the main thread, then hands their paths to Flutter. */
    private fun copySharedPhotos(intent: Intent, initial: Boolean) {
        val uris = sharedUris(intent)
        if (initial) copyingInitialShare = true
        Thread {
            val paths = uris.mapIndexedNotNull { index, uri -> copyToCache(uri, index) }
            runOnUiThread {
                if (initial) {
                    copyingInitialShare = false
                    val waiting = waitingForPhotos
                    if (waiting != null) {
                        waiting.success(paths)
                        waitingForPhotos = null
                    } else {
                        pendingPhotos = paths
                    }
                } else {
                    sharedPhotosChannel?.invokeMethod("photos", paths)
                }
            }
        }.start()
    }

    @Suppress("DEPRECATION")
    private fun sharedUris(intent: Intent): List<Uri> {
        val uris = when (intent.action) {
            Intent.ACTION_SEND_MULTIPLE ->
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty()
            else -> listOfNotNull(intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))
        }
        if (uris.isNotEmpty()) return uris
        val clip = intent.clipData ?: return emptyList()
        return (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
    }

    private fun copyToCache(uri: Uri, index: Int): String? = try {
        val directory = File(cacheDir, "shared_photos").apply { mkdirs() }
        val extension = when (contentResolver.getType(uri)) {
            "image/png" -> "png"
            "image/webp" -> "webp"
            "image/heic", "image/heif" -> "heic"
            else -> "jpg"
        }
        val file = File(directory, "shared_${System.currentTimeMillis()}_$index.$extension")
        contentResolver.openInputStream(withOriginalLocation(uri))?.use { input ->
            file.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        file.absolutePath
    } catch (error: Exception) {
        null
    }

    /** Keeps the GPS position of gallery photos (needs ACCESS_MEDIA_LOCATION, #7). */
    private fun withOriginalLocation(uri: Uri): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && uri.authority == MediaStore.AUTHORITY) {
            try {
                MediaStore.setRequireOriginal(uri)
            } catch (error: Exception) {
                uri
            }
        } else {
            uri
        }

    companion object {
        const val QUICK_CAPTURE_CHANNEL = "trailtale/quick_capture"
        const val SHARED_PHOTOS_CHANNEL = "trailtale/shared_photos"
        const val ACTION_QUICK_CAPTURE = "de.maestrodev.trailtale.QUICK_CAPTURE"
    }
}
