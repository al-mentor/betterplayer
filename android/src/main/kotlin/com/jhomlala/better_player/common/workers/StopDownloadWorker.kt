package com.jhomlala.better_player.common.workers

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.Download
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.jhomlala.better_player.common.DownloadUtil.getDownloadManager

@OptIn(UnstableApi::class)
class StopDownloadWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        val downloadId = inputData.getString("downloadId") ?: return Result.failure()
        val downloadManager = getDownloadManager(applicationContext)
        downloadManager.setStopReason(downloadId, Download.STATE_STOPPED)
        return Result.success()
    }
}