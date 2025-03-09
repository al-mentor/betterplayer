package com.jhomlala.better_player.common.workers

import android.content.Context
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
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import com.jhomlala.better_player.R
import com.jhomlala.better_player.common.DownloadUtil

@OptIn(UnstableApi::class)
class DownloadWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {
    private var terminalStateHelper: TerminalStateNotificationHelper? = null

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

        if (terminalStateHelper == null) {
            terminalStateHelper = TerminalStateNotificationHelper(
                applicationContext,
                downloadNotificationHelper,
                FOREGROUND_NOTIFICATION_ID + 1
            )
            downloadManager.addListener(terminalStateHelper!!)
        }





        // Start the download process
        downloadManager.addDownload(downloadRequest)
        downloadManager.resumeDownloads()


        return Result.success()
    }



    override suspend fun getForegroundInfo(): ForegroundInfo {
        // Ensure the notification channel exists before building a notification
        DownloadUtil.createNotificationChannel(applicationContext)

        val notificationHelper = DownloadUtil.getDownloadNotificationHelper(applicationContext)
        val notification = notificationHelper.buildProgressNotification(
            applicationContext,
            R.drawable.ic_download,
            null,
            "Downloading...", // Add a title
            emptyList(),
            0
        )

        return ForegroundInfo(FOREGROUND_NOTIFICATION_ID, notification)
    }
    // Add this to DownloadWorker.kt, replacing the existing TerminalStateNotificationHelper class

    private class TerminalStateNotificationHelper(
        context: Context,
        private val notificationHelper: DownloadNotificationHelper,
        firstNotificationId: Int
    ) : DownloadManager.Listener {
        private val context: Context = context.applicationContext
        private var nextNotificationId: Int = firstNotificationId
        private val progressHandler = android.os.Handler(android.os.Looper.getMainLooper())
        private val progressRunnables = mutableMapOf<String, Runnable>()

        override fun onDownloadChanged(
            downloadManager: DownloadManager,
            download: Download,
            finalException: Exception?
        ) {

            when (download.state) {
                Download.STATE_DOWNLOADING -> {
                    // Setup a recurring progress reporter for active downloads
                    if (!progressRunnables.containsKey(download.request.id)) {
                        val runnable = object : Runnable {
                            override fun run() {
                                // Get the latest download state
                                val updatedDownload = downloadManager.downloadIndex.getDownload(download.request.id)
                                if (updatedDownload != null && updatedDownload.state == Download.STATE_DOWNLOADING) {
                                    // Send progress update
                                    DownloadUtil.eventChannel?.success(
                                        DownloadUtil.buildDownloadObject(List(1) { updatedDownload })
                                    )

                                    // Update notification with current progress
                                    val notification = notificationHelper.buildProgressNotification(
                                        context,
                                        R.drawable.ic_download,
                                        null,
                                        "Downloading: ${updatedDownload.percentDownloaded.toInt()}%",
                                        emptyList(),
                                        updatedDownload.percentDownloaded.toInt()
                                    )
                                    NotificationUtil.setNotification(context, FOREGROUND_NOTIFICATION_ID, notification)

                                    // Schedule next update in 500ms
                                    progressHandler.postDelayed(this, 500)
                                } else {
                                    // Download is no longer active, remove the runnable
                                    progressRunnables.remove(download.request.id)
                                }
                            }
                        }

                        // Store the runnable and start it
                        progressRunnables[download.request.id] = runnable
                        progressHandler.post(runnable)
                    }
                }

                Download.STATE_COMPLETED -> {
                    // Cancel progress updates
                    cancelProgressUpdates(download.request.id)
                    downloadManager.removeListener(this)
                    // Cancel the ongoing foreground notification
                    val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    notificationManager.cancel(FOREGROUND_NOTIFICATION_ID)

                    val completionNotification = notificationHelper.buildDownloadCompletedNotification(
                        context,
                        R.drawable.ic_download_done,
                        null,
                        Util.fromUtf8Bytes(download.request.data)
                    )
                    NotificationUtil.setNotification(context, nextNotificationId++, completionNotification)
                    DownloadUtil.eventChannel?.success(
                        DownloadUtil.buildDownloadObject(List(1) { download })
                    )
                }

                Download.STATE_FAILED -> {
                    // Cancel progress updates
                    cancelProgressUpdates(download.request.id)
                    // Cancel the ongoing foreground notification
                    val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    notificationManager.cancel(FOREGROUND_NOTIFICATION_ID)

                    // Show failure notification
                    val notification = notificationHelper.buildDownloadFailedNotification(
                        context,
                        android.R.drawable.stat_notify_error,
                        null,
                        Util.fromUtf8Bytes(download.request.data)
                    )
                    NotificationUtil.setNotification(context, nextNotificationId++, notification)
                    DownloadUtil.eventChannel?.success(
                        DownloadUtil.buildDownloadObject(List(1) { download })
                    )
                }

                Download.STATE_STOPPED, Download.STATE_QUEUED, Download.STATE_REMOVING, Download.STATE_RESTARTING -> {
                    // Cancel progress updates for non-downloading states
                    cancelProgressUpdates(download.request.id)
                }
            }
        }

        private fun cancelProgressUpdates(downloadId: String) {
            progressRunnables[downloadId]?.let { runnable ->
                progressHandler.removeCallbacks(runnable)
                progressRunnables.remove(downloadId)
            }
        }

        // Call this when the worker is destroyed
        fun release() {
            // Cancel all progress updates
            for ((downloadId, runnable) in progressRunnables) {
                progressHandler.removeCallbacks(runnable)
            }
            progressRunnables.clear()
        }
    }

    companion object {
        private const val FOREGROUND_NOTIFICATION_ID = 8989
    }
}

