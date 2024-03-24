package com.jhomlala.better_player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import com.google.android.exoplayer2.database.StandaloneDatabaseProvider
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.offline.DownloadRequest
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.scheduler.PlatformScheduler
import com.google.android.exoplayer2.scheduler.Requirements
import com.google.android.exoplayer2.scheduler.Scheduler
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.cache.NoOpCacheEvictor
import com.google.android.exoplayer2.upstream.cache.SimpleCache
import com.google.android.exoplayer2.util.Util
import java.io.File
import java.lang.Exception
import java.util.concurrent.Executors

class MyDownloadService : DownloadService(NOTIFICATION_ID) , DownloadManager.Listener {



    private val databaseProvider by lazy { StandaloneDatabaseProvider(applicationContext) }
    private val downloadCache by lazy { SimpleCache(File(applicationContext.filesDir, "downloads"), NoOpCacheEvictor(), databaseProvider) }
    private val dataSourceFactory by lazy { DefaultHttpDataSource.Factory() }
    private val downloadExecutor by lazy { Executors.newFixedThreadPool(3) }

    override fun onCreate() {
        super.onCreate()
        // Create the notification channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
            startForeground(NOTIFICATION_ID, getForegroundNotification(downloadManager.currentDownloads, Requirements.NETWORK))

        }
        // Start the service as a foreground service
        // Register the listener
        downloadManager.addListener(this)
    }



    override fun onDestroy() {
        super.onDestroy()
        // Unregister the listener
        downloadManager.removeListener(this)
    }

    override fun getDownloadManager(): DownloadManager {
        val downloadManager =  DownloadManager(applicationContext, databaseProvider, downloadCache, dataSourceFactory, downloadExecutor)

        return downloadManager;
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Create a notification channel if necessary
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
            // Build the foreground notification
            val notification = Notification.Builder(applicationContext, CHANNEL_ID)
                .setContentTitle("Download")
                .setContentText("Downloading...")
                .setSmallIcon(R.drawable.exo_media_action_repeat_one)
                .build()

            // Start the service in the foreground
            startForeground(NOTIFICATION_ID, notification)
        }



        // Your existing logic to handle the intent...

        return START_STICKY
    }


    override fun onDownloadChanged(
        downloadManager: DownloadManager,
        download: Download,
        finalException: Exception?
    ) {
        // Print the download state and its associated values
        when (download.state) { // Access the state property of the download
            Download.STATE_QUEUED -> {
                println("Download state: QUEUED")
                println("Percent downloaded: ${download.percentDownloaded}")
            }
            Download.STATE_STOPPED -> {
                println("Download state: STOPPED")
                println("Percent downloaded: ${download.percentDownloaded}")
            }
            Download.STATE_DOWNLOADING -> {
                println("Download state: DOWNLOADING")
                println("Percent downloaded: ${download.percentDownloaded}")
            }
            Download.STATE_COMPLETED -> {
                println("Download state: COMPLETED")
                println("Percent downloaded: ${download.percentDownloaded}")
            }
            Download.STATE_FAILED -> {
                println("Download state: FAILED")
                println("Failure reason: ${download.failureReason}")
            }
            Download.STATE_REMOVING -> {
                println("Download state: REMOVING")
            }
            Download.STATE_RESTARTING -> {
                println("Download state: RESTARTING")
            }
            else -> {
                println("Unknown download state")
            }
        }
    }

    override fun getScheduler(): Scheduler? {
        return if (Util.SDK_INT >= 21) {
            PlatformScheduler(applicationContext, JOB_ID)
        } else {
            null
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun getForegroundNotification(downloads: MutableList<Download>, notificationId: Int): Notification {
        // Create a notification channel (if necessary)
        createNotificationChannel()

        // Build the foreground notification
        return Notification.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle("Download")
            .setContentText("Downloading...")
            .setSmallIcon(R.drawable.exo_media_action_repeat_one)
            .build()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Download Channel",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Notification channel for downloads"
        }
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    companion object {
        private const val JOB_ID = 1
        private const val CHANNEL_ID = "download_channel"
        private const val NOTIFICATION_ID = 100
        fun startDownloadService(context: Context, downloadRequest: DownloadRequest) {
            val intent = Intent(context, MyDownloadService::class.java)
            intent.putExtra("download_request", downloadRequest)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

    }
}
