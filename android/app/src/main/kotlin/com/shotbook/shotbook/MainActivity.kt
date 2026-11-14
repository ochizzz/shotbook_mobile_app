package com.shotbook.shotbook

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // SHOTBOOK's own manual photo camera (see ProCameraPlugin).
        flutterEngine.plugins.add(ProCameraPlugin())
    }
}
