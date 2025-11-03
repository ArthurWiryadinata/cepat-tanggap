package com.example.cepattanggap

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    private val CHANNEL_ID = "emergency_channel_v2"

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        val type = data["type"] ?: "normal"
        val title = data["title"] ?: "🚨 Emergency!"
        val message = data["message"] ?: "Segera lakukan tindakan!"

        // 🔍 Log debugging
        android.util.Log.d("FCM_DEBUG", "📩 Data diterima: $data")
        android.util.Log.d("FCM_DEBUG", "➡️ Type: $type")

        if (type == "emergency") {

            // 🚫 Cek apakah app sedang foreground
            if (isAppInForeground(this)) {
                android.util.Log.d("FCM_DEBUG", "📱 App sedang foreground — tidak tampilkan notifikasi.")
                return
            }

            android.util.Log.d("FCM_DEBUG", "📴 App background — tampilkan notifikasi.")
            createNotificationChannel()
            showEmergencyNotification(title, message)

            // ✅ Getar terus
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
            val pattern = longArrayOf(0, 1000, 500, 1000)
            val repeatIndex = 0
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = android.os.VibrationEffect.createWaveform(pattern, repeatIndex)
                vibrator.vibrate(effect)
            } else {
                vibrator.vibrate(pattern, repeatIndex)
            }
        }
    }

    // 🔍 Fungsi untuk cek apakah app sedang aktif (foreground)
    private fun isAppInForeground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false

        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == context.packageName
            ) {
                return true
            }
        }
        return false
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Emergency Alerts"
            val descriptionText = "Channel untuk notifikasi darurat"
            val importance = NotificationManager.IMPORTANCE_HIGH

            val soundUri = Uri.parse("android.resource://${packageName}/raw/alert_sound")

            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
                enableLights(true)
                lightColor = Color.RED
                setSound(soundUri, audioAttributes)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }

            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun showEmergencyNotification(title: String, message: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val soundUri = Uri.parse("android.resource://${packageName}/raw/alarm_sound")

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setColor(Color.RED)
            .setOngoing(true)
            .setAutoCancel(true)
            .setSound(soundUri)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setVibrate(longArrayOf(0, 1000, 500, 1000))
            .setContentIntent(pendingIntent)

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(9999, builder.build())
    }
}
