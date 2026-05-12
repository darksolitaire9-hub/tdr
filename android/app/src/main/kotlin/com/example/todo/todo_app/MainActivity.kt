package com.example.todo.todo_app

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.todo/volume_buttons"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            channel?.invokeMethod("volumeUp", null)
            return true
        } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            channel?.invokeMethod("volumeDown", null)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
