package com.jhomlala.better_player.common.workers

import android.app.Notification
import android.content.Context
import android.net.Uri
import android.os.Parcel
import androidx.annotation.OptIn
import androidx.media3.common.util.NotificationUtil
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadNotificationHelper
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.ForegroundInfo
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonDeserializer
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.jhomlala.better_player.R
import com.jhomlala.better_player.common.DownloadUtil
import java.lang.reflect.Type

@OptIn(UnstableApi::class)
class DownloadWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        val downloadRequestBytes = inputData.getByteArray("downloadRequest") ?: return Result.failure()
        val parcel = Parcel.obtain()
        parcel.unmarshall(downloadRequestBytes, 0, downloadRequestBytes.size)
        parcel.setDataPosition(0)
        val downloadRequest = DownloadRequest.CREATOR.createFromParcel(parcel)
        parcel.recycle()

        val downloadManager: DownloadManager = DownloadUtil.getDownloadManager(applicationContext)
        val downloadNotificationHelper: DownloadNotificationHelper =
            DownloadUtil.getDownloadNotificationHelper(applicationContext)

        downloadManager.addListener(
            TerminalStateNotificationHelper(
                applicationContext,
                downloadNotificationHelper,
                FOREGROUND_NOTIFICATION_ID + 1
            )
        )

        // Start the download process
        downloadManager.addDownload(downloadRequest)
        downloadManager.resumeDownloads()


        return Result.success()
    }


    override suspend fun getForegroundInfo(): ForegroundInfo {
        val notificationHelper = DownloadUtil.getDownloadNotificationHelper(applicationContext)
        val notification = notificationHelper.buildProgressNotification(
            applicationContext,
            R.drawable.ic_download,
            null,
            null,
            emptyList(),
            0
        )

        return ForegroundInfo(FOREGROUND_NOTIFICATION_ID, notification)
    }

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
            DownloadUtil.eventChannel?.success(DownloadUtil.buildDownloadObject(List(1) { download }))

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
        }
    }

    companion object {
        private const val FOREGROUND_NOTIFICATION_ID = 8989
    }
}

