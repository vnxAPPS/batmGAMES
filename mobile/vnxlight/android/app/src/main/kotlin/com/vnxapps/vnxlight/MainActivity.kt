package com.vnxapps.vnxlight

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Мост к вспышке. Канал `vnxlight/torch`:
 *  - `info` → {available, maxLevel}: есть ли вспышка и сколько у неё ступеней
 *    яркости (1 — только вкл/выкл);
 *  - `set` {level} → 0 выключает, 1..maxLevel включает с этой яркостью;
 *  - из Kotlin в Dart `changed` {on} — вспышку переключили извне (шторка).
 *
 * Разрешение CAMERA не нужно: setTorchMode и turnOnTorchWithStrengthLevel
 * работают без него.
 */
class MainActivity : FlutterActivity() {
    private var torch: Torch? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vnxlight/torch")
        val torch = Torch(this) { on -> channel.invokeMethod("changed", mapOf("on" to on)) }
        this.torch = torch
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> result.success(mapOf("available" to torch.available, "maxLevel" to torch.maxLevel))
                "set" -> {
                    val level = call.argument<Int>("level") ?: 0
                    try {
                        torch.set(level)
                        result.success(true)
                    } catch (e: Exception) {
                        // Камеру заняло другое приложение, или вспышка перегрелась.
                        result.error("TORCH", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        torch?.release()
        torch = null
        super.onDestroy()
    }
}

class Torch(context: Context, private val onChange: (Boolean) -> Unit) {
    private val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    /** Вспышка задней камеры, иначе любая со вспышкой; null — вспышки нет. */
    private val cameraId: String? = runCatching {
        val withFlash = manager.cameraIdList.filter { id ->
            manager.getCameraCharacteristics(id).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        }
        withFlash.firstOrNull { id ->
            manager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) ==
                CameraCharacteristics.LENS_FACING_BACK
        } ?: withFlash.firstOrNull()
    }.getOrNull()

    val available: Boolean get() = cameraId != null

    val maxLevel: Int = run {
        val id = cameraId ?: return@run 1
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.FLASH_INFO_STRENGTH_MAXIMUM_LEVEL) ?: 1
        } else {
            1
        }
    }

    private val callback = object : CameraManager.TorchCallback() {
        override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
            if (cameraId == this@Torch.cameraId) onChange(enabled)
        }
    }

    init {
        if (cameraId != null) manager.registerTorchCallback(callback, Handler(Looper.getMainLooper()))
    }

    fun set(level: Int) {
        val id = cameraId ?: return
        when {
            level <= 0 -> manager.setTorchMode(id, false)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && maxLevel > 1 ->
                manager.turnOnTorchWithStrengthLevel(id, level.coerceIn(1, maxLevel))
            else -> manager.setTorchMode(id, true)
        }
    }

    fun release() {
        runCatching { manager.unregisterTorchCallback(callback) }
    }
}
