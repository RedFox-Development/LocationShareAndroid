package com.example.location_share_android

import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		// Enable edge-to-edge drawing and use WindowInsetsController for compatibility
		WindowCompat.setDecorFitsSystemWindows(window, false)
		val insetsController = WindowInsetsControllerCompat(window, window.decorView)
		// Let the app decide system bar appearance; do not force colors here.
		insetsController.isAppearanceLightStatusBars = false
		insetsController.isAppearanceLightNavigationBars = false
	}
}
