package com.jhomlala.better_player.common

import android.app.Notification
import android.content.Context
import android.content.pm.ServiceInfo
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
import android.net.Uri
import android.os.Build
import androidx.annotation.OptIn
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.scheduler.PlatformScheduler
import com.google.android.exoplayer2.ui.DownloadNotificationHelper
import com.google.android.exoplayer2.util.NotificationUtil
import com.google.android.exoplayer2.util.Util
import com.google.common.util.concurrent.Service
import com.google.gson.Gson
import com.google.gson.JsonObject

import com.jhomlala.better_player.R
import com.jhomlala.better_player.common.DownloadUtil.DOWNLOAD_NOTIFICATION_CHANNEL_ID
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

private const val JOB_ID = 8888
private const val FOREGROUND_NOTIFICATION_ID = 8989


class MyDownloadService : DownloadService(
    FOREGROUND_NOTIFICATION_ID,
    DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
    DOWNLOAD_NOTIFICATION_CHANNEL_ID,
    R.string.exo_download_notification_channel_name, 0
) {

    override fun getDownloadManager(): DownloadManager {

        // This will only happen once, because getDownloadManager is guaranteed to be called only once
        // in the life cycle of the process.
        val downloadManager: DownloadManager = DownloadUtil.getDownloadManager(this)
        val downloadNotificationHelper: DownloadNotificationHelper =
            DownloadUtil.getDownloadNotificationHelper(this)
        downloadManager.addListener(
            TerminalStateNotificationHelper(
                this,
                downloadNotificationHelper,
                FOREGROUND_NOTIFICATION_ID + 1
            )
        )
        return downloadManager
    }

    override fun getScheduler(): PlatformScheduler? {
        return if (Build.VERSION.SDK_INT >= 21) PlatformScheduler(this, JOB_ID) else null
    }

    override fun getForegroundNotification(
        downloads: MutableList<Download>,
        notMetRequirements: Int
    ): Notification {
        val notificationHelper = DownloadUtil.getDownloadNotificationHelper(this)

        val notification = notificationHelper.buildProgressNotification(
            this,
            R.drawable.ic_download,
            null,
            null,
            downloads,
            notMetRequirements
        )
        DownloadUtil.eventChannel?.success(DownloadUtil.buildDownloadObject(downloads));

        // Start foreground service with media playback type
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Use startForeground with type on Android 12 (SDK 31) and higher
            startForeground(FOREGROUND_NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            // Use startForeground without type for older versions
            startForeground(FOREGROUND_NOTIFICATION_ID, notification)
        }

        return notification
    }


    /**
     * Creates and displays notifications for downloads when they complete or fail.
     *
     *
     * This helper will outlive the lifespan of a single instance of [MyDownloadService].
     * It is static to avoid leaking the first [MyDownloadService] instance.
     */
    private class TerminalStateNotificationHelper(
        context: Context,
        private val notificationHelper: DownloadNotificationHelper,
        firstNotificationId: Int
    ) : DownloadManager.Listener {
        private val context: Context = context.applicationContext
        private var nextNotificationId: Int = firstNotificationId


        override fun onDownloadChanged(
            downloadManager: DownloadManager,
            download: Download,
            finalException: Exception?
        ) {
            val notification: Notification = when (download.state) {
                Download.STATE_COMPLETED -> {
                    notificationHelper.buildDownloadCompletedNotification(
                        context,
                        R.drawable.ic_download_done,  /* contentIntent = */
                        null,
                        Util.fromUtf8Bytes(download.request.data)
                    )
                }

                Download.STATE_FAILED -> {
                    notificationHelper.buildDownloadFailedNotification(
                        context,
                        android.R.drawable.stat_notify_error,
                        null,
                        Util.fromUtf8Bytes(download.request.data)
                    )
                }

                else -> return
            }
            NotificationUtil.setNotification(context, nextNotificationId++, notification)
            DownloadUtil.eventChannel?.success(DownloadUtil.buildDownloadObject(List(1) { download }));

        }

    }

}