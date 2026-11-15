package com.shotbook.shotbook

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.hardware.camera2.CaptureResult
import android.hardware.camera2.DngCreator
import android.hardware.camera2.TotalCaptureResult
import android.media.ExifInterface
import android.media.Image
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.provider.MediaStore
import android.util.Range
import android.util.Size
import android.view.Surface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max

/**
 * SHOTBOOK's own photo camera on Camera2: manual ISO, shutter, exposure
 * compensation, white balance presets, manual focus, zoom across the
 * phone's lenses, and JPEG + optional RAW (DNG) capture to the gallery.
 *
 * Channel "shotbook/pro_camera". Every control the device does not support
 * is reported as unavailable in `capabilities`, so the UI can disable it.
 */
class ProCameraPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var textures: TextureRegistry
    private val main = Handler(Looper.getMainLooper())

    private var thread: HandlerThread? = null
    private var handler: Handler? = null

    private var cameraId: String? = null
    private var characteristics: CameraCharacteristics? = null
    private var device: CameraDevice? = null
    private var session: CameraCaptureSession? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var previewSurface: Surface? = null
    private var jpegReader: ImageReader? = null
    private var rawReader: ImageReader? = null
    private var rawInSession = false

    // Current controls. Applied to the preview and to every capture.
    private var autoExposure = true
    private var iso = 100
    private var exposureNs = 8_000_000L
    private var evSteps = 0
    private var awbAuto = true
    private var kelvin = 5500
    private var autoFocus = true
    private var focusDiopters = 0f
    private var zoom = 1f
    private var flash = "off" // off | auto | on
    @Volatile private var lookMatrix: FloatArray? = null
    @Volatile private var lookVignette = 0f
    @Volatile private var lookGrain = 0f
    @Volatile private var lastAeState: Int? = null
    @Volatile private var lastResult: TotalCaptureResult? = null

    // One preview request reused for every change, so the camera's
    // autofocus and exposure loops are not restarted on each dial move.
    private var previewBuilder: CaptureRequest.Builder? = null
    private var applyScheduled = false
    private var lastApplyAt = 0L

    // Colour transform and gains the camera chose in auto white balance;
    // manual Kelvin keeps the transform and replaces only the gains.
    private var lastTransform: android.hardware.camera2.params.ColorSpaceTransform? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        textures = binding.textureRegistry
        channel = MethodChannel(binding.binaryMessenger, "shotbook/pro_camera")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        closeCamera()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "capabilities" -> result.success(capabilities())
                "diagnostics" -> result.success(diagnostics())
                "open" -> openCamera(result)
                "setControls" -> {
                    // Values are read now; the request is applied on the
                    // camera thread, at most ~30 times a second.
                    readControls(call)
                    scheduleApply()
                    result.success(null)
                }
                "capture" -> {
                    // Look (colour matrix, vignette, grain) for this shot.
                    lookMatrix = call.argument<List<Number>>("colorMatrix")
                        ?.map { it.toFloat() }?.toFloatArray()
                    lookVignette = call.argument<Number>("vignette")?.toFloat() ?: 0f
                    lookGrain = call.argument<Number>("grain")?.toFloat() ?: 0f
                    capture(call.argument<Boolean>("raw") == true, result)
                }

                "close" -> {
                    closeCamera()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: CameraAccessException) {
            result.error("camera_access", e.message, null)
        } catch (e: SecurityException) {
            result.error("permission", e.message, null)
        } catch (e: Exception) {
            result.error("camera_error", e.message, null)
        }
    }

    // ---- Capabilities -------------------------------------------------

    private val manager: CameraManager
        get() = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    /** The main back camera. On multi-camera phones this is the logical
     *  camera that switches lenses with the zoom ratio. */
    private fun pickBackCamera(): String? {
        val ids = manager.cameraIdList
        return ids.firstOrNull {
            manager.getCameraCharacteristics(it)
                .get(CameraCharacteristics.LENS_FACING) == CameraMetadata.LENS_FACING_BACK
        } ?: ids.firstOrNull()
    }

    private fun capabilities(): Map<String, Any?> {
        val id = pickBackCamera() ?: return mapOf("available" to false)
        val c = manager.getCameraCharacteristics(id)
        val caps = c.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)?.toSet() ?: emptySet()
        val manualSensor = caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR)
        val raw = caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_RAW) &&
            (c.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                ?.getOutputSizes(ImageFormat.RAW_SENSOR)?.isNotEmpty() == true)
        val isoRange = c.get(CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE)
        val expRange = c.get(CameraCharacteristics.SENSOR_INFO_EXPOSURE_TIME_RANGE)
        val evRange = c.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE)
        val evStep = c.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP)
        val minFocus = c.get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE) ?: 0f
        val awbModes = c.get(CameraCharacteristics.CONTROL_AWB_AVAILABLE_MODES)?.toList() ?: emptyList()
        val zoomRange: Range<Float>? = if (Build.VERSION.SDK_INT >= 30) {
            c.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)
        } else null
        val maxDigital = c.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1f
        val wbMode = whiteBalanceMode(c)
        val focal = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.firstOrNull()
        val sensor = c.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
        // 35 mm equivalent of the main lens, from the sensor diagonal.
        val equivalent = if (focal != null && sensor != null) {
            val diag = Math.hypot(sensor.width.toDouble(), sensor.height.toDouble())
            focal * 43.27 / diag
        } else null
        return mapOf(
            "available" to true,
            "cameraId" to id,
            "hardwareLevel" to c.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL),
            "manualSensor" to manualSensor,
            "raw" to raw,
            "isoMin" to isoRange?.lower,
            "isoMax" to isoRange?.upper,
            "exposureMinNs" to expRange?.lower,
            // Very long exposures freeze the preview; cap the dial at 1 s.
            "exposureMaxNs" to expRange?.upper?.coerceAtMost(1_000_000_000L),
            "evMin" to evRange?.lower,
            "evMax" to evRange?.upper,
            "evStep" to evStep?.toDouble(),
            "manualFocus" to (minFocus > 0f),
            "minFocusDiopters" to minFocus.toDouble(),
            "awbModes" to awbModes.mapNotNull { awbName(it) },
            // "cct" (Android 15 colour temperature), "gains" (manual
            // post-processing) or "presets" (nearest preset only).
            "wbMode" to wbMode,
            "kelvinMin" to 2000,
            "kelvinMax" to 10000,
            "zoomMin" to (zoomRange?.lower ?: 1f).toDouble(),
            "zoomMax" to (zoomRange?.upper ?: maxDigital).toDouble(),
            "mainEquivalentMm" to equivalent,
            "flash" to (c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true),
        )
    }

    /**
     * Everything needed to debug the camera from a screenshot: the phone,
     * every camera it exposes to apps, what we asked for and what the
     * sensor actually did on the latest preview frame.
     */
    private fun diagnostics(): Map<String, Any?> {
        val cameras = manager.cameraIdList.map { id ->
            val c = manager.getCameraCharacteristics(id)
            val caps = c.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)?.toSet() ?: emptySet()
            val zoom = if (Build.VERSION.SDK_INT >= 30) c.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE) else null
            val sensor = c.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
            val focals = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.toList() ?: emptyList()
            val diag = if (sensor != null) Math.hypot(sensor.width.toDouble(), sensor.height.toDouble()) else null
            mapOf(
                "id" to id,
                "facing" to when (c.get(CameraCharacteristics.LENS_FACING)) {
                    CameraMetadata.LENS_FACING_BACK -> "back"
                    CameraMetadata.LENS_FACING_FRONT -> "front"
                    else -> "external"
                },
                "level" to when (c.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL)) {
                    CameraMetadata.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY -> "LEGACY"
                    CameraMetadata.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED -> "LIMITED"
                    CameraMetadata.INFO_SUPPORTED_HARDWARE_LEVEL_FULL -> "FULL"
                    CameraMetadata.INFO_SUPPORTED_HARDWARE_LEVEL_3 -> "LEVEL_3"
                    else -> "EXTERNAL"
                },
                "manualSensor" to caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR),
                "manualPost" to caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_POST_PROCESSING),
                "raw" to caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_RAW),
                "logical" to caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA),
                "physicalIds" to (if (Build.VERSION.SDK_INT >= 28) c.physicalCameraIds.toList() else emptyList()),
                "equivMm" to focals.map { f -> if (diag != null) Math.round(f * 43.27 / diag).toInt() else null },
                "zoomMin" to zoom?.lower?.toDouble(),
                "zoomMax" to zoom?.upper?.toDouble(),
                "iso" to c.get(CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE)?.let { "${it.lower}-${it.upper}" },
                "exposureNs" to c.get(CameraCharacteristics.SENSOR_INFO_EXPOSURE_TIME_RANGE)?.let { "${it.lower}-${it.upper}" },
                "wbMode" to whiteBalanceMode(c),
            )
        }
        val r = lastResult
        val live = if (r == null) null else mapOf(
            "iso" to r.get(CaptureResult.SENSOR_SENSITIVITY),
            "exposureNs" to r.get(CaptureResult.SENSOR_EXPOSURE_TIME),
            "aeMode" to r.get(CaptureResult.CONTROL_AE_MODE),
            "ev" to r.get(CaptureResult.CONTROL_AE_EXPOSURE_COMPENSATION),
            "awbMode" to r.get(CaptureResult.CONTROL_AWB_MODE),
            "afMode" to r.get(CaptureResult.CONTROL_AF_MODE),
            "focusDiopters" to r.get(CaptureResult.LENS_FOCUS_DISTANCE)?.toDouble(),
            "focalMm" to r.get(CaptureResult.LENS_FOCAL_LENGTH)?.toDouble(),
            "zoomRatio" to (if (Build.VERSION.SDK_INT >= 30) r.get(CaptureResult.CONTROL_ZOOM_RATIO)?.toDouble() else null),
            "activePhysicalId" to (if (Build.VERSION.SDK_INT >= 29) r.get(CaptureResult.LOGICAL_MULTI_CAMERA_ACTIVE_PHYSICAL_ID) else null),
        )
        return mapOf(
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "android" to "${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})",
            "openCameraId" to cameraId,
            "sessionRaw" to rawInSession,
            "requested" to mapOf(
                "autoExposure" to autoExposure, "iso" to iso, "exposureNs" to exposureNs,
                "ev" to evSteps, "awbAuto" to awbAuto, "kelvin" to kelvin,
                "autoFocus" to autoFocus, "focusDiopters" to focusDiopters.toDouble(),
                "zoom" to zoom.toDouble(), "flash" to flash,
            ),
            "live" to live,
            "cameras" to cameras,
        )
    }

    private fun whiteBalanceMode(c: CameraCharacteristics): String {
        if (Build.VERSION.SDK_INT >= 35) {
            val modes = c.get(CameraCharacteristics.COLOR_CORRECTION_AVAILABLE_MODES)
            if (modes != null && modes.contains(CameraMetadata.COLOR_CORRECTION_MODE_CCT)) {
                return "cct"
            }
        }
        val caps = c.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)?.toSet() ?: emptySet()
        return if (caps.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_POST_PROCESSING)) {
            "gains"
        } else "presets"
    }

    /** Light colour of a black body at [k] Kelvin (Tanner Helland), 0…1. */
    private fun kelvinToRgb(k: Int): FloatArray {
        val t = k / 100.0
        val r = if (t <= 66) 255.0 else 329.698727446 * Math.pow(t - 60, -0.1332047592)
        val g = if (t <= 66) 99.4708025861 * Math.log(t) - 161.1195681661
        else 288.1221695283 * Math.pow(t - 60, -0.0755148492)
        val b = when {
            t >= 66 -> 255.0
            t <= 19 -> 0.0
            else -> 138.5177312231 * Math.log(t - 10) - 305.0447927307
        }
        fun c(v: Double) = (v.coerceIn(1.0, 255.0) / 255.0).toFloat()
        return floatArrayOf(c(r), c(g), c(b))
    }

    /** Gains that neutralise light of [k] Kelvin, green normalised to 1. */
    private fun kelvinGains(k: Int): android.hardware.camera2.params.RggbChannelVector {
        val (r, g, b) = kelvinToRgb(k).let { Triple(it[0], it[1], it[2]) }
        val red = (g / r).coerceIn(0.25f, 8f)
        val blue = (g / b).coerceIn(0.25f, 8f)
        return android.hardware.camera2.params.RggbChannelVector(red, 1f, 1f, blue)
    }

    /** Nearest preset for phones without manual white balance. */
    private fun kelvinPreset(k: Int) = when {
        k < 3400 -> CameraMetadata.CONTROL_AWB_MODE_INCANDESCENT
        k < 4600 -> CameraMetadata.CONTROL_AWB_MODE_FLUORESCENT
        k < 6000 -> CameraMetadata.CONTROL_AWB_MODE_DAYLIGHT
        k < 7000 -> CameraMetadata.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT
        else -> CameraMetadata.CONTROL_AWB_MODE_SHADE
    }

    private fun awbName(mode: Int) = when (mode) {
        CameraMetadata.CONTROL_AWB_MODE_AUTO -> "auto"
        CameraMetadata.CONTROL_AWB_MODE_INCANDESCENT -> "incandescent"
        CameraMetadata.CONTROL_AWB_MODE_FLUORESCENT -> "fluorescent"
        CameraMetadata.CONTROL_AWB_MODE_DAYLIGHT -> "daylight"
        CameraMetadata.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT -> "cloudy"
        CameraMetadata.CONTROL_AWB_MODE_SHADE -> "shade"
        else -> null
    }

    private fun awbMode(name: String) = when (name) {
        "incandescent" -> CameraMetadata.CONTROL_AWB_MODE_INCANDESCENT
        "fluorescent" -> CameraMetadata.CONTROL_AWB_MODE_FLUORESCENT
        "daylight" -> CameraMetadata.CONTROL_AWB_MODE_DAYLIGHT
        "cloudy" -> CameraMetadata.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT
        "shade" -> CameraMetadata.CONTROL_AWB_MODE_SHADE
        else -> CameraMetadata.CONTROL_AWB_MODE_AUTO
    }

    // ---- Open / close -------------------------------------------------

    @SuppressLint("MissingPermission") // The Dart side asks for CAMERA first.
    private fun openCamera(result: MethodChannel.Result) {
        closeCamera()
        val id = pickBackCamera() ?: return result.error("no_camera", "No camera", null)
        val c = manager.getCameraCharacteristics(id)
        cameraId = id
        characteristics = c
        val map = c.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            ?: return result.error("no_camera", "No stream configuration", null)

        val t = HandlerThread("ShotbookProCamera").also { it.start() }
        thread = t
        handler = Handler(t.looper)

        // 4:3 is the native shape of phone sensors.
        val preview = choose(map.getOutputSizes(SurfaceTexture::class.java), 1920)
        val jpegSize = choose(map.getOutputSizes(ImageFormat.JPEG), 4032)
        val entry = textures.createSurfaceTexture()
        textureEntry = entry
        entry.surfaceTexture().setDefaultBufferSize(preview.width, preview.height)
        previewSurface = Surface(entry.surfaceTexture())
        jpegReader = ImageReader.newInstance(jpegSize.width, jpegSize.height, ImageFormat.JPEG, 2)
        val rawSizes = map.getOutputSizes(ImageFormat.RAW_SENSOR)
        rawReader = if (rawSizes != null && rawSizes.isNotEmpty()) {
            val largest = rawSizes.maxByOrNull { it.width.toLong() * it.height }!!
            ImageReader.newInstance(largest.width, largest.height, ImageFormat.RAW_SENSOR, 2)
        } else null

        var replied = false
        fun reply(block: () -> Unit) = main.post {
            if (!replied) {
                replied = true
                block()
            }
        }

        manager.openCamera(id, object : CameraDevice.StateCallback() {
            override fun onOpened(camera: CameraDevice) {
                device = camera
                createSession(withRaw = rawReader != null) { ok, raw ->
                    if (ok) {
                        reply {
                            result.success(
                                mapOf(
                                    "textureId" to entry.id(),
                                    "previewWidth" to preview.width,
                                    "previewHeight" to preview.height,
                                    "sensorOrientation" to (c.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 90),
                                    "raw" to raw,
                                )
                            )
                        }
                    } else {
                        reply { result.error("session", "Could not start the camera", null) }
                    }
                }
            }

            override fun onDisconnected(camera: CameraDevice) {
                camera.close()
                device = null
            }

            override fun onError(camera: CameraDevice, error: Int) {
                camera.close()
                device = null
                reply { result.error("camera_error", "Camera error $error", null) }
            }
        }, handler)
    }

    /** Largest 4:3 size not wider than [maxWidth]; any size as a fallback. */
    private fun choose(sizes: Array<Size>?, maxWidth: Int): Size {
        val all = sizes?.toList() ?: listOf(Size(1440, 1080))
        val fourThree = all.filter { abs(it.width * 3 - it.height * 4) < 8 && it.width <= maxWidth }
        return (fourThree.ifEmpty { all.filter { it.width <= maxWidth }.ifEmpty { all } })
            .maxByOrNull { it.width.toLong() * it.height }!!
    }

    @Suppress("DEPRECATION")
    private fun createSession(withRaw: Boolean, done: (Boolean, Boolean) -> Unit) {
        val camera = device ?: return done(false, false)
        val outputs = mutableListOf(previewSurface!!, jpegReader!!.surface)
        if (withRaw) outputs.add(rawReader!!.surface)
        try {
            camera.createCaptureSession(outputs, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(s: CameraCaptureSession) {
                    session = s
                    previewBuilder = null
                    rawInSession = withRaw
                    applyRepeating()
                    done(true, withRaw)
                }

                override fun onConfigureFailed(s: CameraCaptureSession) {
                    // Some phones cannot stream RAW together with preview and
                    // JPEG on the multi-lens camera: retry without RAW.
                    if (withRaw) createSession(false, done) else done(false, false)
                }
            }, handler)
        } catch (e: Exception) {
            if (withRaw) createSession(false, done) else done(false, false)
        }
    }

    private fun closeCamera() {
        try { session?.close() } catch (_: Exception) {}
        try { device?.close() } catch (_: Exception) {}
        session = null
        device = null
        previewBuilder = null
        lastTransform = null
        lastResult = null
        jpegReader?.close(); jpegReader = null
        rawReader?.close(); rawReader = null
        previewSurface?.release(); previewSurface = null
        textureEntry?.release(); textureEntry = null
        thread?.quitSafely(); thread = null; handler = null
    }

    // ---- Controls -----------------------------------------------------

    private fun readControls(call: MethodCall) {
        call.argument<Boolean>("autoExposure")?.let { autoExposure = it }
        call.argument<Int>("iso")?.let { iso = it }
        call.argument<Number>("exposureNs")?.let { exposureNs = it.toLong() }
        call.argument<Int>("ev")?.let { evSteps = it }
        call.argument<Boolean>("awbAuto")?.let { awbAuto = it }
        call.argument<Int>("kelvin")?.let { kelvin = it.coerceIn(2000, 10000) }
        call.argument<Boolean>("autoFocus")?.let { autoFocus = it }
        call.argument<Number>("focusDiopters")?.let { focusDiopters = it.toFloat() }
        call.argument<Number>("zoom")?.let { zoom = it.toFloat() }
        call.argument<String>("flash")?.let { flash = it }
    }

    private fun fill(builder: CaptureRequest.Builder) {
        val c = characteristics ?: return
        builder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
        val hasFlash = c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        if (autoExposure) {
            builder.set(
                CaptureRequest.CONTROL_AE_MODE,
                when {
                    !hasFlash || flash == "off" -> CameraMetadata.CONTROL_AE_MODE_ON
                    flash == "on" -> CameraMetadata.CONTROL_AE_MODE_ON_ALWAYS_FLASH
                    else -> CameraMetadata.CONTROL_AE_MODE_ON_AUTO_FLASH
                },
            )
            builder.set(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, evSteps)
        } else {
            builder.set(CaptureRequest.CONTROL_AE_MODE, CameraMetadata.CONTROL_AE_MODE_OFF)
            builder.set(CaptureRequest.SENSOR_SENSITIVITY, iso)
            builder.set(CaptureRequest.SENSOR_EXPOSURE_TIME, exposureNs)
            // Frame duration must be at least the exposure time.
            builder.set(CaptureRequest.SENSOR_FRAME_DURATION, max(exposureNs, 33_333_333L))
        }
        if (awbAuto) {
            builder.set(CaptureRequest.CONTROL_AWB_MODE, CameraMetadata.CONTROL_AWB_MODE_AUTO)
            builder.set(CaptureRequest.COLOR_CORRECTION_MODE, CameraMetadata.COLOR_CORRECTION_MODE_FAST)
        } else {
            when (whiteBalanceMode(c)) {
                "cct" -> if (Build.VERSION.SDK_INT >= 35) {
                    builder.set(CaptureRequest.CONTROL_AWB_MODE, CameraMetadata.CONTROL_AWB_MODE_OFF)
                    builder.set(CaptureRequest.COLOR_CORRECTION_MODE, CameraMetadata.COLOR_CORRECTION_MODE_CCT)
                    builder.set(CaptureRequest.COLOR_CORRECTION_COLOR_TEMPERATURE, kelvin)
                }
                "gains" -> {
                    builder.set(CaptureRequest.CONTROL_AWB_MODE, CameraMetadata.CONTROL_AWB_MODE_OFF)
                    builder.set(
                        CaptureRequest.COLOR_CORRECTION_MODE,
                        CameraMetadata.COLOR_CORRECTION_MODE_TRANSFORM_MATRIX,
                    )
                    builder.set(CaptureRequest.COLOR_CORRECTION_GAINS, kelvinGains(kelvin))
                    lastTransform?.let {
                        builder.set(CaptureRequest.COLOR_CORRECTION_TRANSFORM, it)
                    }
                }
                else -> builder.set(CaptureRequest.CONTROL_AWB_MODE, kelvinPreset(kelvin))
            }
        }
        if (autoFocus) {
            builder.set(CaptureRequest.CONTROL_AF_MODE, CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
        } else {
            builder.set(CaptureRequest.CONTROL_AF_MODE, CameraMetadata.CONTROL_AF_MODE_OFF)
            builder.set(CaptureRequest.LENS_FOCUS_DISTANCE, focusDiopters)
        }
        if (Build.VERSION.SDK_INT >= 30) {
            val range = c.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)
            val ratio = if (range != null) zoom.coerceIn(range.lower, range.upper) else 1f
            builder.set(CaptureRequest.CONTROL_ZOOM_RATIO, ratio)
        } else {
            val active = c.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE)
            if (active != null && zoom > 1f) {
                val w = (active.width() / zoom).toInt()
                val h = (active.height() / zoom).toInt()
                val x = (active.width() - w) / 2
                val y = (active.height() - h) / 2
                builder.set(CaptureRequest.SCALER_CROP_REGION, android.graphics.Rect(x, y, x + w, y + h))
            }
        }
    }

    /** Coalesces control changes: at most one request per ~33 ms. */
    private fun scheduleApply() {
        val h = handler ?: return
        h.post {
            if (applyScheduled) return@post
            applyScheduled = true
            val wait = (33 - (System.currentTimeMillis() - lastApplyAt)).coerceAtLeast(0)
            h.postDelayed({
                applyScheduled = false
                applyRepeating()
            }, wait)
        }
    }

    private val previewCallback = object : CameraCaptureSession.CaptureCallback() {
        override fun onCaptureCompleted(
            session: CameraCaptureSession,
            request: CaptureRequest,
            result: TotalCaptureResult,
        ) {
            if (awbAuto) {
                result.get(CaptureResult.COLOR_CORRECTION_TRANSFORM)?.let { lastTransform = it }
            }
            lastAeState = result.get(CaptureResult.CONTROL_AE_STATE)
            lastResult = result
        }
    }

    private fun applyRepeating() {
        val s = session ?: return
        val camera = device ?: return
        try {
            val b = previewBuilder ?: camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).also {
                it.addTarget(previewSurface!!)
                previewBuilder = it
            }
            fill(b)
            s.setRepeatingRequest(b.build(), previewCallback, handler)
            lastApplyAt = System.currentTimeMillis()
        } catch (_: Exception) {
            // The session may be closing; the next open applies the controls.
        }
    }

    // ---- Capture ------------------------------------------------------

    private fun capture(wantRaw: Boolean, result: MethodChannel.Result) {
        val hasFlash = characteristics?.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        val h = handler ?: return result.error("not_open", "Camera is not open", null)
        if (!(hasFlash && flash != "off" && autoExposure)) {
            h.post { captureStill(wantRaw, result) }
            return
        }
        // Flash in auto exposure: run the pre-flash metering sequence first,
        // then take the picture once exposure has settled (max 1.5 s).
        h.post {
            try {
                val builder = previewBuilder
                val s = session
                if (builder == null || s == null) {
                    captureStill(wantRaw, result); return@post
                }
                builder.set(
                    CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER,
                    CameraMetadata.CONTROL_AE_PRECAPTURE_TRIGGER_START,
                )
                s.capture(builder.build(), null, h)
                builder.set(
                    CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER,
                    CameraMetadata.CONTROL_AE_PRECAPTURE_TRIGGER_IDLE,
                )
                val started = System.currentTimeMillis()
                var sawPrecapture = false
                val poll = object : Runnable {
                    override fun run() {
                        val state = lastAeState
                        if (state == CameraMetadata.CONTROL_AE_STATE_PRECAPTURE) sawPrecapture = true
                        val settled = state == CameraMetadata.CONTROL_AE_STATE_CONVERGED ||
                            state == CameraMetadata.CONTROL_AE_STATE_FLASH_REQUIRED ||
                            state == CameraMetadata.CONTROL_AE_STATE_LOCKED
                        val elapsed = System.currentTimeMillis() - started
                        if ((sawPrecapture && settled) || (elapsed > 400 && settled) || elapsed > 1500) {
                            captureStill(wantRaw, result)
                        } else {
                            h.postDelayed(this, 40)
                        }
                    }
                }
                h.postDelayed(poll, 60)
            } catch (e: Exception) {
                captureStill(wantRaw, result)
            }
        }
    }

    private fun captureStill(wantRaw: Boolean, result: MethodChannel.Result) {
        // Runs on the camera thread: replies go back through the main thread.
        val s = session
        val camera = device
        val c = characteristics
        if (s == null || camera == null || c == null) {
            main.post { result.error("not_open", "Camera is not open", null) }
            return
        }
        val raw = wantRaw && rawInSession && rawReader != null
        val orientation = c.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 90

        var jpegImage: Image? = null
        var rawImage: Image? = null
        var captureResult: TotalCaptureResult? = null
        var finished = false

        fun finishIfReady() {
            if (finished) return
            if (jpegImage == null || (raw && (rawImage == null || captureResult == null))) return
            finished = true
            val saved = mutableMapOf<String, Any?>()
            try {
                saved["jpeg"] = saveJpeg(jpegImage!!)
                if (raw) saved["dng"] = saveDng(rawImage!!, captureResult!!, c, orientation)
                main.post { result.success(saved) }
            } catch (e: Exception) {
                main.post { result.error("save_failed", e.message, null) }
            } finally {
                jpegImage?.close()
                rawImage?.close()
                jpegReader?.setOnImageAvailableListener(null, null)
                rawReader?.setOnImageAvailableListener(null, null)
            }
        }

        jpegReader!!.setOnImageAvailableListener({ r ->
            jpegImage = r.acquireNextImage(); finishIfReady()
        }, handler)
        if (raw) {
            rawReader!!.setOnImageAvailableListener({ r ->
                rawImage = r.acquireNextImage(); finishIfReady()
            }, handler)
        }

        val b = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
        b.addTarget(jpegReader!!.surface)
        if (raw) b.addTarget(rawReader!!.surface)
        fill(b)
        if (!autoExposure && flash != "off" &&
            c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        ) {
            // Manual exposure cannot meter a pre-flash: fire it at full power.
            b.set(CaptureRequest.FLASH_MODE, CameraMetadata.FLASH_MODE_SINGLE)
        }
        b.set(CaptureRequest.JPEG_ORIENTATION, orientation)
        b.set(CaptureRequest.JPEG_QUALITY, 95.toByte())
        s.capture(b.build(), object : CameraCaptureSession.CaptureCallback() {
            override fun onCaptureCompleted(
                session: CameraCaptureSession,
                request: CaptureRequest,
                total: TotalCaptureResult,
            ) {
                captureResult = total
                finishIfReady()
            }

            override fun onCaptureFailed(
                session: CameraCaptureSession,
                request: CaptureRequest,
                failure: android.hardware.camera2.CaptureFailure,
            ) {
                if (!finished) {
                    finished = true
                    main.post { result.error("capture_failed", "Capture failed", null) }
                }
            }
        }, handler)
    }

    private fun stamp() = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())

    private fun insert(name: String, mime: String): Pair<android.net.Uri, OutputStream> {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= 29) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/SHOTBOOK")
            }
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Gallery unavailable")
        val stream = resolver.openOutputStream(uri) ?: throw IllegalStateException("Gallery unavailable")
        return uri to stream
    }

    private fun saveJpeg(image: Image): String {
        val buffer = image.planes[0].buffer
        var bytes = ByteArray(buffer.remaining()).also { buffer.get(it) }
        val matrix = lookMatrix
        if (matrix != null && matrix.size == 20) {
            bytes = try {
                applyLook(bytes, matrix, lookVignette, lookGrain)
            } catch (e: Throwable) {
                bytes // Out of memory or a bad frame: keep the plain photo.
            }
        }
        val (uri, stream) = insert("SHOTBOOK_${stamp()}.jpg", "image/jpeg")
        stream.use { it.write(bytes) }
        return uri.toString()
    }

    /**
     * Bakes the look into the JPEG: upright pixels (EXIF rotation applied),
     * colour matrix, optional vignette and film grain, re-encoded at 95.
     */
    private fun applyLook(jpeg: ByteArray, m: FloatArray, vignette: Float, grain: Float): ByteArray {
        val rotation = if (Build.VERSION.SDK_INT >= 24) {
            when (android.media.ExifInterface(java.io.ByteArrayInputStream(jpeg))
                .getAttributeInt(android.media.ExifInterface.TAG_ORIENTATION, 1)) {
                android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        } else 0f
        var source = android.graphics.BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size)
            ?: return jpeg
        if (rotation != 0f) {
            val r = android.graphics.Matrix().apply { postRotate(rotation) }
            val rotated = android.graphics.Bitmap.createBitmap(
                source, 0, 0, source.width, source.height, r, true,
            )
            if (rotated != source) source.recycle()
            source = rotated
        }
        val out = android.graphics.Bitmap.createBitmap(
            source.width, source.height, android.graphics.Bitmap.Config.ARGB_8888,
        )
        val canvas = android.graphics.Canvas(out)
        val paint = android.graphics.Paint(android.graphics.Paint.FILTER_BITMAP_FLAG).apply {
            colorFilter = android.graphics.ColorMatrixColorFilter(android.graphics.ColorMatrix(m))
        }
        canvas.drawBitmap(source, 0f, 0f, paint)
        source.recycle()
        val w = out.width.toFloat()
        val h = out.height.toFloat()
        if (vignette > 0f) {
            val radius = Math.hypot(w / 2.0, h / 2.0).toFloat()
            val shader = android.graphics.RadialGradient(
                w / 2, h / 2, radius,
                intArrayOf(0x00000000, 0x00000000, android.graphics.Color.argb((vignette * 200).toInt().coerceIn(0, 255), 0, 0, 0)),
                floatArrayOf(0f, 0.55f, 1f),
                android.graphics.Shader.TileMode.CLAMP,
            )
            canvas.drawRect(0f, 0f, w, h, android.graphics.Paint().apply { this.shader = shader })
        }
        if (grain > 0f) {
            // A small noise tile repeated over the frame: film-like and fast.
            val size = 256
            val pixels = IntArray(size * size)
            val random = java.util.Random(7)
            val alpha = (grain * 70).toInt().coerceIn(0, 255)
            for (i in pixels.indices) {
                val v = random.nextInt(256)
                pixels[i] = android.graphics.Color.argb(alpha, v, v, v)
            }
            val tile = android.graphics.Bitmap.createBitmap(pixels, size, size, android.graphics.Bitmap.Config.ARGB_8888)
            val scale = (w / 1400f).coerceAtLeast(1f)
            val shader = android.graphics.BitmapShader(
                tile, android.graphics.Shader.TileMode.REPEAT, android.graphics.Shader.TileMode.REPEAT,
            ).apply { setLocalMatrix(android.graphics.Matrix().apply { setScale(scale, scale) }) }
            canvas.drawRect(0f, 0f, w, h, android.graphics.Paint().apply {
                this.shader = shader
                xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.OVERLAY)
            })
            tile.recycle()
        }
        val result = java.io.ByteArrayOutputStream()
        out.compress(android.graphics.Bitmap.CompressFormat.JPEG, 95, result)
        out.recycle()
        return result.toByteArray()
    }

    private fun saveDng(
        image: Image,
        total: CaptureResult,
        c: CameraCharacteristics,
        sensorOrientation: Int,
    ): String {
        val (uri, stream) = insert("SHOTBOOK_${stamp()}.dng", "image/x-adobe-dng")
        DngCreator(c, total).use { dng ->
            dng.setOrientation(
                when (sensorOrientation) {
                    90 -> ExifInterface.ORIENTATION_ROTATE_90
                    180 -> ExifInterface.ORIENTATION_ROTATE_180
                    270 -> ExifInterface.ORIENTATION_ROTATE_270
                    else -> ExifInterface.ORIENTATION_NORMAL
                }
            )
            stream.use { dng.writeImage(it, image) }
        }
        return uri.toString()
    }
}
