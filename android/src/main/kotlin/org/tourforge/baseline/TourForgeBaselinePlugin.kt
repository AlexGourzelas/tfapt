package org.tourforge.baseline

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TourForgeBaselinePlugin */
class TourForgeBaselinePlugin: FlutterPlugin {
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding.flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("org.tourforge.baseline.MapLibrePlatformView",
                MapLibrePlatformViewFactory(flutterPluginBinding.flutterEngine.dartExecutor.binaryMessenger))
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    }
}
