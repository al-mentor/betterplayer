package com.jhomlala.better_player.common

import android.app.Notification
import android.content.Context
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
        return if(Build.VERSION.SDK_INT >= 21) PlatformScheduler(this, JOB_ID) else null
    }

    override fun getForegroundNotification(
        downloads: MutableList<Download>,
        notMetRequirements: Int
    ): Notification {

        buildDownloadObject(downloads);

        return DownloadUtil.getDownloadNotificationHelper(this)
            .buildProgressNotification(
                this,
                R.drawable.ic_download,
                null,
                null,
                downloads,
                notMetRequirements
            )
    }

    private fun buildDownloadObject(
        downloads: MutableList<Download>
    ) {
        var downloadData = ArrayList<Map<String, String?>>()
        for (download in downloads) {
            var downloadMap = HashMap<String, String?>()
            downloadMap["uri"] = download.request.uri.toString();
            downloadMap["downloadState"] = download.state.toString();
            downloadMap["downloadId"] = download.request.id.toString();
            downloadMap["downloadPercentage"] = download.percentDownloaded.toString();
            downloadData.add(downloadMap)
        }
        val gson = Gson()
        val json = gson.toJson(downloadData)
        DownloadUtil.eventChannel?.success(json)
    }


    // Utility function to create JSON object with download progress information
    private fun createProgressJson(uri: String, status: Int?, percent: Float): String {
        val jsonObject = JsonObject()
        jsonObject.addProperty("uri", uri)
        jsonObject.addProperty("status", status)
        jsonObject.addProperty("percentage", percent)

        return Gson().toJson(jsonObject)
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
                        R.drawable.ic_download_done,  /* contentIntent = */
                        null,
                        Util.fromUtf8Bytes(download.request.data)
                    )
                }
                else -> return
            }
            NotificationUtil.setNotification(context, nextNotificationId++, notification)
        }

    }

}