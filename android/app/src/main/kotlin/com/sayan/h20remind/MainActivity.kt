package com.sayan.h20remind

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (a ComponentActivity) is required for the Health
// Connect permission request, which uses the Activity Result API.
class MainActivity : FlutterFragmentActivity() {
    private lateinit var healthConnect: HealthConnectBridge

    override fun onCreate(savedInstanceState: Bundle?) {
        // Activity result launchers must be registered before the activity starts.
        healthConnect = HealthConnectBridge(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HealthConnectBridge.CHANNEL)
            .setMethodCallHandler(healthConnect)
    }
}
