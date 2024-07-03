package com.jhomlala.better_player.common

import android.app.AlertDialog
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import android.os.StatFs
import android.util.Log
import android.view.View
import android.widget.PopupMenu
import android.widget.Toast
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.TrackGroup
import androidx.media3.common.util.Assertions
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.HttpDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory

import androidx.media3.exoplayer.drm.DrmSessionEventListener
import androidx.media3.exoplayer.drm.OfflineLicenseHelper
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadHelper
import androidx.media3.exoplayer.offline.DownloadIndex
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.media3.exoplayer.offline.DownloadService
import androidx.media3.exoplayer.source.TrackGroupArray
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector

import com.google.gson.Gson
import com.google.gson.JsonObject
import com.jhomlala.better_player.R
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.withContext
import java.io.IOException
import java.util.concurrent.CopyOnWriteArraySet


private const val TAG = "DownloadTracker"
private const val DEFAULT_BITRATE = 500_000

/** Tracks media that has been downloaded.  */

class DownloadTracker
    (
    context: Context,
    private val httpDataSourceFactory: HttpDataSource.Factory,
    private val downloadManager: DownloadManager
) {

    /**
     * Listens for changes in the tracked downloads.
     */
    interface Listener {
        /**
         * Called when the tracked downloads changed.
         */
        fun onDownloadsChanged(download: Download)

    }

    private val applicationContext: Context = context.applicationContext
    private val listeners: CopyOnWriteArraySet<Listener> = CopyOnWriteArraySet()
    private val downloadIndex: DownloadIndex = downloadManager.downloadIndex
    private var startDownloadDialogHelper: StartDownloadDialogHelper? = null
    private var availableBytesLeft: Long =
        StatFs(DownloadUtil.getDownloadDirectory(context).path).availableBytes

    val downloads: HashMap<Uri, Download> = HashMap()

    init {
        downloadManager.addListener(DownloadManagerListener())
        loadDownloads()
    }

    fun addListener(listener: Listener) {
        Assertions.checkNotNull(listener)
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }


    fun isDownloaded(mediaItem: MediaItem): Boolean {
        val uuid = mediaItem.localConfiguration?.uri?.let { DownloadUtil.extractUUIDFromUri(it) }
        if (uuid != null) {
            for ((key, value) in downloads) {
                if (key.toString().contains(uuid) && value.state == Download.STATE_COMPLETED) {
                    return true
                }
            }
        }
        return false
    }


    fun hasDownload(uri: Uri?): Boolean = (getDownload(uri) != null)

    fun getDownloadRequest(uri: Uri?): DownloadRequest? {
        uri ?: return null
        val download = getDownload(uri)
        return if (download != null && download.state != Download.STATE_FAILED) download.request else null
    }


    fun getDownload(uri: Uri?): Download? {
        uri ?: return null
        val uuid = DownloadUtil.extractUUIDFromUri(uri)
        for ((key, value) in downloads) {
            if (key.toString().contains(uuid!!) && value.state != Download.STATE_FAILED) {
                return value
            }
        }
        return null
    }


    fun toggleDownloadDialogHelper(
        context: Context, mediaItem: MediaItem,
        mediaItems: List<MediaItem>? = null,
        positiveCallback: (() -> Unit)? = null, dismissCallback: (() -> Unit)? = null,
        result: MethodChannel.Result? = null,
    ) {
        startDownloadDialogHelper?.release()


        if (mediaItems != null) {
            globalQualitySelected = 3;
            mediaItems.forEach {
                if (!isDownloaded(it)) {
                    startDownloadDialogHelper = StartDownloadDialogHelper(
                        context,
                        getDownloadHelper(it),
                        it,
                        positiveCallback,
                        dismissCallback,
                        result
                    )
                }
            }

            return;
        }

        startDownloadDialogHelper = StartDownloadDialogHelper(
            context,
            getDownloadHelper(mediaItem),
            mediaItem,
            positiveCallback,
            dismissCallback,
            result
        )
    }

    fun toggleDownloadPopupMenu(context: Context, anchor: View, uri: Uri?) {
        val popupMenu = PopupMenu(context, anchor).apply { inflate(R.menu.popup_menu) }
        val download = downloads[uri]
        download ?: return

        popupMenu.menu.apply {
            findItem(R.id.cancel_download).isVisible = listOf(
                Download.STATE_DOWNLOADING,
                Download.STATE_STOPPED,
                Download.STATE_QUEUED,
                Download.STATE_FAILED
            ).contains(download.state)
            findItem(R.id.delete_download).isVisible = download.state == Download.STATE_COMPLETED
            findItem(R.id.resume_download).isVisible =
                listOf(Download.STATE_STOPPED, Download.STATE_FAILED).contains(download.state)
            findItem(R.id.pause_download).isVisible = download.state == Download.STATE_DOWNLOADING
        }

        popupMenu.setOnMenuItemClickListener {
            when (it.itemId) {
                R.id.cancel_download, R.id.delete_download -> removeDownload(download.request.uri)
                R.id.resume_download -> {
                    DownloadService.sendSetStopReason(
                        context,
                        MyDownloadService::class.java,
                        download.request.id,
                        Download.STOP_REASON_NONE,
                        true
                    )
                }

                R.id.pause_download -> {
                    DownloadService.sendSetStopReason(
                        context,
                        MyDownloadService::class.java,
                        download.request.id,
                        Download.STATE_STOPPED,
                        false
                    )
                }
            }
            return@setOnMenuItemClickListener true
        }
        popupMenu.show()
    }

    fun removeDownload(uri: Uri?) {

        val downlaod = getDownload(uri);

        downlaod?.let {
            DownloadService.sendRemoveDownload(
                applicationContext, MyDownloadService::class.java, downlaod.request.id, false
            )
        }
    }

    fun deleteAllDownloadedAssets() {
        val downloadUris = downloads.keys.toList()
        for (uri in downloadUris) {
            val download = downloads[uri]
            download?.let {
                DownloadService.sendRemoveDownload(
                    applicationContext, MyDownloadService::class.java, download.request.id, false
                )
                downloads.remove(uri)
            }
        }
    }


    private fun loadDownloads() {
        try {
            downloadIndex.getDownloads().use { loadedDownloads ->
                while (loadedDownloads.moveToNext()) {
                    val download = loadedDownloads.download
                    downloads[download.request.uri] = download
                }
            }
        } catch (e: IOException) {
            Log.w(TAG, "Failed to query downloads", e)
        }
    }

    @ExperimentalCoroutinesApi
    suspend fun getAllDownloadProgressFlow(): Flow<List<Download>> = callbackFlow {
        while (coroutineContext.isActive) {
            trySend(downloads.values.toList()).isSuccess
            delay(1000)
        }
    }


    @ExperimentalCoroutinesApi
    suspend fun getCurrentProgressDownload(uri: Uri?): Flow<Float?> {
        var percent: Float? =
            downloadManager.currentDownloads.find { it.request.uri == uri }?.percentDownloaded
        return callbackFlow {
            while (percent != null) {

                percent =
                    downloadManager.currentDownloads.find { it.request.uri == uri }?.percentDownloaded
                trySend(percent).isSuccess
                withContext(Dispatchers.IO) {
                    delay(1000)
                }
            }
        }
    }


    private fun getDownloadHelper(mediaItem: MediaItem): DownloadHelper {
        return when (mediaItem.localConfiguration?.mimeType) {
            MimeTypes.APPLICATION_MPD, MimeTypes.APPLICATION_M3U8, MimeTypes.APPLICATION_SS -> {
                DownloadHelper.forMediaItem(
                    applicationContext,
                    mediaItem,
                    DefaultRenderersFactory(applicationContext),
                    httpDataSourceFactory
                )
            }

            else -> DownloadHelper.forMediaItem(applicationContext, mediaItem)
        }
    }

    private inner class DownloadManagerListener : DownloadManager.Listener {
        override fun onDownloadChanged(
            downloadManager: DownloadManager, download: Download, finalException: Exception?
        ) {
            downloads[download.request.uri] = download
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }
            if (download.state == Download.STATE_COMPLETED) {
                // Add delta between estimation and reality to have a better availableBytesLeft
                availableBytesLeft += Util.fromUtf8Bytes(download.request.data)
                    .toLong() - download.bytesDownloaded
            }
        }

        override fun onDownloadRemoved(downloadManager: DownloadManager, download: Download) {
            downloads.remove(download.request.uri)
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }

            // Add the estimated or downloaded bytes to the availableBytes
            availableBytesLeft += if (download.percentDownloaded == 100f) {
                download.bytesDownloaded
            } else {
                val dataString = Util.fromUtf8Bytes(download.request.data)
                if (dataString.isEmpty()) {
                    0L // or any other default value you deem appropriate
                } else {
                    try {
                        dataString.toLong()
                    } catch (e: NumberFormatException) {
                        // Log the error if necessary
                        0L // or handle the error as needed
                    }
                }
            }
        }

    }

    // Can't use applicationContext because it'll result in a crash, instead
    // Use context of the activity calling for the AlertDialog
    private inner class StartDownloadDialogHelper(
        private val context: Context,
        private val downloadHelper: DownloadHelper,
        private val mediaItem: MediaItem,
        private val positiveCallback: (() -> Unit)? = null,
        private val dismissCallback: (() -> Unit)? = null,
        private val result: MethodChannel.Result? = null,
    ) : DownloadHelper.Callback {

        private var trackSelectionDialog: AlertDialog? = null

        init {
            downloadHelper.prepare(this)
        }

        fun release() {
            downloadHelper.release()
            trackSelectionDialog?.dismiss()
        }

        // DownloadHelper.Callback implementation.
        override fun onPrepared(helper: DownloadHelper) {
            if (helper.periodCount == 0) {
                Log.d(TAG, "No periods found. Downloading entire stream.")
                val mediaItemTag: MediaItemTag = mediaItem.localConfiguration?.tag as MediaItemTag
                val estimatedContentLength: Long =
                    (DEFAULT_BITRATE * mediaItemTag.duration).div(C.MILLIS_PER_SECOND)
                        .div(C.BITS_PER_BYTE)
                val downloadRequest: DownloadRequest = downloadHelper.getDownloadRequest(
                    mediaItemTag.title, Util.getUtf8Bytes(estimatedContentLength.toString())
                )
                startDownload(downloadRequest)
                release()
                return
            }

            val dialogBuilder: AlertDialog.Builder = AlertDialog.Builder(context)
            val formatDownloadable: MutableList<Format> = mutableListOf()
            var formatSelected: Format
            var qualitySelected: DefaultTrackSelector.Parameters
            val mappedTrackInfo = downloadHelper.getMappedTrackInfo(0)

            for (i in 0 until mappedTrackInfo.rendererCount) {
                if (C.TRACK_TYPE_VIDEO == mappedTrackInfo.getRendererType(i)) {
                    val trackGroups: TrackGroupArray = mappedTrackInfo.getTrackGroups(i)
                    for (j in 0 until trackGroups.length) {
                        val trackGroup: TrackGroup = trackGroups[j]
                        for (k in 0 until trackGroup.length) {
                            formatDownloadable.add(trackGroup.getFormat(k))
                        }
                    }
                }
            }

            if (formatDownloadable.isEmpty()) {
                dialogBuilder.setTitle("An error occurred").setPositiveButton("OK", null).show()
                return
            }

            // We sort here because later we use formatDownloadable to select track
            formatDownloadable.sortBy { it.height }
            val mediaItemTag: MediaItemTag = mediaItem.localConfiguration?.tag as MediaItemTag
            val optionsDownload: List<String> = formatDownloadable.map {
                context.getString(
                    R.string.dialog_option,
                    it.height,
                    (it.bitrate * mediaItemTag.duration).div(8000).formatFileSize()
                )
            }

            //Default quality download
            formatSelected = formatDownloadable[0]
            qualitySelected = DefaultTrackSelector(context).buildUponParameters()
                .setMinVideoSize(formatDownloadable[0].width, formatDownloadable[0].height)
                .setMinVideoBitrate(formatDownloadable[0].bitrate)
                .setMaxVideoSize(formatDownloadable[0].width, formatDownloadable[0].height)
                .setMaxVideoBitrate(formatDownloadable[0].bitrate).build()
            if (globalQualitySelected != null) {
                if (globalQualitySelected!! > optionsDownload.toTypedArray().size - 1) {
                    globalQualitySelected = optionsDownload.toTypedArray().size - 1
                }
                formatSelected = formatDownloadable[globalQualitySelected!!]
                qualitySelected = DefaultTrackSelector(context).buildUponParameters()
                    .setMinVideoSize(formatSelected.width, formatSelected.height)
                    .setMinVideoBitrate(formatSelected.bitrate)
                    .setMaxVideoSize(formatSelected.width, formatSelected.height)
                    .setMaxVideoBitrate(formatSelected.bitrate).build()
                fireDownloadWithSelectQuality(helper, qualitySelected, formatSelected, mediaItemTag)
                trackSelectionDialog = null
                result?.success(true)
                return;
            }

            dialogBuilder.setTitle("Select Download Format")
                .setSingleChoiceItems(optionsDownload.toTypedArray(), 0) { _, which ->
                    formatSelected = formatDownloadable[which]
                    qualitySelected = DefaultTrackSelector(context).buildUponParameters()
                        .setMinVideoSize(formatSelected.width, formatSelected.height)
                        .setMinVideoBitrate(formatSelected.bitrate)
                        .setMaxVideoSize(formatSelected.width, formatSelected.height)
                        .setMaxVideoBitrate(formatSelected.bitrate).build()
                    Log.e(
                        TAG,
                        "format Selected= width: ${formatSelected.width}, height: ${formatSelected.height}"
                    )
                }.setPositiveButton("Download") { _, _ ->
                    fireDownloadWithSelectQuality(
                        helper, qualitySelected, formatSelected, mediaItemTag
                    )
                    result?.success(true)

                }.setOnDismissListener {
                    trackSelectionDialog = null
                    downloadHelper.release()
                    dismissCallback?.invoke()
                }
            trackSelectionDialog = dialogBuilder.create().apply { show() }
        }

        private fun fireDownloadWithSelectQuality(
            helper: DownloadHelper,
            qualitySelected: DefaultTrackSelector.Parameters,
            formatSelected: Format,
            mediaItemTag: MediaItemTag
        ) {
            helper.clearTrackSelections(0)
            helper.addTrackSelection(0, qualitySelected)

            val drmConfiguration = mediaItem.localConfiguration?.drmConfiguration
            val estimatedContentLength: Long = (qualitySelected.maxVideoBitrate * mediaItemTag.duration)
                .div(C.MILLIS_PER_SECOND).div(C.BITS_PER_BYTE)
            var keySetId: ByteArray? = null

            if (drmConfiguration != null) {
                val conditionVariable = ConditionVariable()
                val offlineHelper = OfflineLicenseHelper.newWidevineInstance(
                    drmConfiguration.licenseUri.toString(),
                    drmConfiguration.forceDefaultLicenseUri ?: false,
                    DownloadUtil.getHttpDataSourceFactory(context),
                    drmConfiguration.licenseRequestHeaders,
                    DrmSessionEventListener.EventDispatcher()
                )

                val handlerThread = HandlerThread("DrmLicenseHelper")
                handlerThread.start()
                val handler = Handler(handlerThread.looper)

                handler.post {
                    try {
                        keySetId = offlineHelper.downloadLicense(formatSelected)
                        Log.e("DownloadTracker", "keySetId: $keySetId")
                        conditionVariable.open()
                    } catch (e: Exception) {
                        Log.e("DownloadTracker", "Failed to download license", e)
                        conditionVariable.open()
                    }
                }

                val TIMEOUT_MS: Long = 10000 // 10 seconds timeout
                val success = conditionVariable.block(TIMEOUT_MS)
                if (!success) {
                    Log.e("DownloadTracker", "Timeout while waiting for DRM license acquisition")
                }

                handlerThread.quitSafely()
            }

            if (availableBytesLeft > estimatedContentLength) {
                var downloadRequest: DownloadRequest = helper.getDownloadRequest(
                    (mediaItem.localConfiguration?.tag as MediaItemTag).title,
                    Util.getUtf8Bytes(estimatedContentLength.toString())
                )
                if (keySetId != null) {
                    downloadRequest = downloadRequest.copyWithKeySetId(keySetId)
                }
                startDownload(downloadRequest)
                availableBytesLeft -= estimatedContentLength
                Log.e(TAG, "availableBytesLeft after calculation: $availableBytesLeft")
            } else {
                result?.success(false)
                Toast.makeText(context, "Not enough space to download this file", Toast.LENGTH_LONG).show()
            }
            positiveCallback?.invoke()
        }

        override fun onPrepareError(helper: DownloadHelper, e: IOException) {

            DownloadUtil
                .eventChannel?.success(DownloadUtil
                    .buildFailedDownloadObject(mediaItem.localConfiguration?.uri!!));



            result?.success(false)

            Toast.makeText(applicationContext, R.string.download_start_error, Toast.LENGTH_LONG)
                .show()
            Log.e(
                TAG,
                if (e is DownloadHelper.LiveContentUnsupportedException) "Downloading live content unsupported" else "Failed to start download",
                e
            )
        }

        // Internal methods.
        private fun startDownload(downloadRequest: DownloadRequest = buildDownloadRequest()) {
            DownloadService.sendAddDownload(
                applicationContext, MyDownloadService::class.java, downloadRequest, true
            )
        }

        private fun buildDownloadRequest(): DownloadRequest {
            return downloadHelper.getDownloadRequest(
                (mediaItem.localConfiguration?.tag as MediaItemTag).title,
                Util.getUtf8Bytes(mediaItem.localConfiguration?.uri.toString())
            )
        }
    }

    companion object {
        var globalQualitySelected: Int? = null
    }
}
