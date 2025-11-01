package com.example.cepattanggap

import android.app.KeyguardManager
import android.content.Context
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.Vibrator
import android.os.VibrationEffect
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class FullScreenAlertActivity : AppCompatActivity() {

    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 🔹 Aktifkan layar meskipun terkunci
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

        setContentView(R.layout.activity_full_screen_alert)

        // 🔹 Ambil data dari intent
        val alertTitle = intent.getStringExtra("title") ?: "🚨 Emergency!"
        val alertMessage = intent.getStringExtra("message") ?: "Segera lakukan tindakan!"
        Log.d("ALERT_SCREEN", "🚨 Opened FullScreenAlertActivity with title=$alertTitle, message=$alertMessage")

        // 🔹 Kalau HP dikunci, buka layar kuncinya sementara
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            keyguardManager.requestDismissKeyguard(this, null)
        }

        // 🔹 Tampilkan ke UI
        findViewById<TextView>(R.id.alertTitle).text = alertTitle
        findViewById<TextView>(R.id.alertMessage).text = alertMessage

        // 🔹 Getar HP
        vibratePhone()

        // 🔹 Putar suara alarm
        mediaPlayer = MediaPlayer.create(this, R.raw.alert_sound)
        mediaPlayer?.isLooping = true
        mediaPlayer?.start()

        // 🔹 Tombol untuk menutup layar darurat
        findViewById<Button>(R.id.btnClose).setOnClickListener {
            mediaPlayer?.stop()
            finish()
        }
    }

    private fun vibratePhone() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        val pattern = longArrayOf(0, 500, 1000) // delay, vibrate, sleep
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0)) // loop
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, 0)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaPlayer?.release()
        mediaPlayer = null
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        vibrator.cancel()
    }
}
