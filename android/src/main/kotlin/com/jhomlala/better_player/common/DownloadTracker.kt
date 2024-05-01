package com.jhomlala.better_player.common

import android.app.AlertDialog
import android.content.Context
import android.net.Uri
import android.os.StatFs
import android.util.Log
import android.view.View
import android.widget.PopupMenu
import android.widget.Toast
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.DefaultRenderersFactory
import com.google.android.exoplayer2.Format
import com.google.android.exoplayer2.drm.DrmSessionEventListener
import com.google.android.exoplayer2.drm.OfflineLicenseHelper
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadHelper
import com.google.android.exoplayer2.offline.DownloadIndex
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.offline.DownloadRequest
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.source.TrackGroup
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.upstream.HttpDataSource
import com.google.android.exoplayer2.util.Assertions
import com.google.android.exoplayer2.util.MimeTypes
import com.google.android.exoplayer2.util.Util
import com.jhomlala.better_player.R
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
class DownloadTracker(
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

    val downloads: MutableList<DownloadItem> = mutableListOf()

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

    fun isDownloaded(downloadItem: DownloadItem): Boolean {
         return downloads.any { it.uniqueId == downloadItem.uniqueId && it.download?.state == Download.STATE_COMPLETED }
    }


    fun hasDownload(downloadItem: DownloadItem): Boolean = downloads.any { it.uniqueId == downloadItem.uniqueId }

    fun getDownloadRequest(downloadItem: DownloadItem): DownloadRequest? {
        return downloads.find { it.uniqueId == downloadItem.uniqueId }?.let { it.download?.request ?: it.download?.request }
    }


    fun getDownload(downloadItem: DownloadItem): DownloadItem? {
        return downloads.find { it.uniqueId == downloadItem.uniqueId }
    }

    fun toggleDownloadDialogHelper(
        context: Context, downloadItem: DownloadItem,
        downloadItems: List<DownloadItem>? = null,
        positiveCallback: (() -> Unit)? = null, dismissCallback: (() -> Unit)? = null,
        result: MethodChannel.Result? = null,
    ) {
        startDownloadDialogHelper?.release()


        if (downloadItems != null) {
            globalQualitySelected = 3;
            downloadItems.forEach {
                if (!isDownloaded(it)) {
                    startDownloadDialogHelper =
                        StartDownloadDialogHelper(
                            context,
                            getDownloadHelper(it),
                            it,
                            positiveCallback, dismissCallback, result
                        )
                }
            }

            return;
        }

        startDownloadDialogHelper =
            StartDownloadDialogHelper(
                context,
                getDownloadHelper(downloadItem),
                downloadItem,
                positiveCallback,
                dismissCallback, result
            )
    }

    fun toggleDownloadPopupMenu(context: Context, anchor: View, downloadItem: DownloadItem) {
        val popupMenu = PopupMenu(context, anchor).apply { inflate(R.menu.popup_menu) }
        val download = getDownload(downloadItem)?.download
        download ?: return

        popupMenu.menu.apply {
            findItem(R.id.cancel_download).isVisible =
                listOf(
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
                R.id.cancel_download, R.id.delete_download -> removeDownload(downloadItem)
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

    fun removeDownload(downloadItem: DownloadItem) {
        val download = getDownload(downloadItem)
        download?.let {
            download.download?.request?.id?.let { id ->
                DownloadService.sendRemoveDownload(
                    applicationContext,
                    MyDownloadService::class.java,
                    id,
                    false
                )
            }
        }
    }
    fun deleteAllDownloadedAssets() {
        val downloadsToRemove = downloads.toList()
        for (downloadItem in downloadsToRemove) {
            downloadItem.download?.request?.let {
                DownloadService.sendRemoveDownload(
                    applicationContext,
                    MyDownloadService::class.java,
                    it.id,
                    false
                )
            }
            downloads.remove(downloadItem)
        }
    }



    private fun loadDownloads() {
        try {
            downloadIndex.getDownloads().use { loadedDownloads ->
                while (loadedDownloads.moveToNext()) {
                    val download = loadedDownloads.download
                    val uri = download.request.uri
                    val downloadItem = createDownloadItem("Name", uri, download)
                    downloads.add(downloadItem)
                }
            }
        } catch (e: IOException) {
            Log.w(TAG, "Failed to query downloads", e)
        }
    }




    @ExperimentalCoroutinesApi
    suspend fun getAllDownloadProgressFlow(): Flow<List<DownloadItem>> = callbackFlow {
        while (coroutineContext.isActive) {
            trySend(downloads.toList()).isSuccess
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


    private fun getDownloadHelper(downloadItem: DownloadItem): DownloadHelper {
        return when (downloadItem.mediaItem?.localConfiguration?.mimeType) {
            MimeTypes.APPLICATION_MPD, MimeTypes.APPLICATION_M3U8, MimeTypes.APPLICATION_SS -> {
                DownloadHelper.forMediaItem(
                    applicationContext,
                    downloadItem.mediaItem!!,
                    DefaultRenderersFactory(applicationContext),
                    httpDataSourceFactory
                )
            }

            else -> DownloadHelper.forMediaItem(applicationContext,  downloadItem.mediaItem!!)
        }
    }

    private inner class DownloadManagerListener : DownloadManager.Listener {
        override fun onDownloadChanged(
            downloadManager: DownloadManager,
            download: Download,
            finalException: Exception?
        ) {
            val uri = download.request.uri
            val downloadItem = createDownloadItem( "Name", uri, download)
            downloads.removeAll { it.uri == uri } // Remove existing download item with the same URI
            downloads.add(downloadItem)
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }
            if (download.state == Download.STATE_COMPLETED) {
                // Add delta between estimation and reality to have a better availableBytesLeft
                availableBytesLeft +=
                    Util.fromUtf8Bytes(download.request.data).toLong() - download.bytesDownloaded
            }
        }

        override fun onDownloadRemoved(downloadManager: DownloadManager, download: Download) {
            val uri = download.request.uri
            downloads.removeAll { it.uri == uri }
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }

            // Add the estimated or downloaded bytes to the availableBytes
            availableBytesLeft += if (download.percentDownloaded == 100f) {
                download.bytesDownloaded
            } else {
                Util.fromUtf8Bytes(download.request.data).toLong()
            }
        }
    }

    // Can't use applicationContext because it'll result in a crash, instead
    // Use context of the activity calling for the AlertDialog
    private inner class StartDownloadDialogHelper(
        private val context: Context,
        private val downloadHelper: DownloadHelper,
        private val downloadItem: DownloadItem,
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
                 val estimatedContentLength: Long = (DEFAULT_BITRATE * (downloadItem.duration!! ))
                    .div(C.MILLIS_PER_SECOND).div(C.BITS_PER_BYTE)
                val downloadRequest: DownloadRequest = downloadHelper.getDownloadRequest(
                    downloadItem.uri.toString(),
                    Util.getUtf8Bytes(estimatedContentLength.toString())
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
                dialogBuilder.setTitle("An error occurred")
                    .setPositiveButton("OK", null)
                    .show()
                return
            }

            // We sort here because later we use formatDownloadable to select track
            formatDownloadable.sortBy { it.height }
             val optionsDownload: List<String> = formatDownloadable.map {
                context.getString(
                    R.string.dialog_option, it.height,
                    (it.bitrate * downloadItem.duration!!).div(8000).formatFileSize()
                )
            }

            //Default quality download
            formatSelected = formatDownloadable[0]
            qualitySelected = DefaultTrackSelector(context).buildUponParameters()
                .setMinVideoSize(formatDownloadable[0].width, formatDownloadable[0].height)
                .setMinVideoBitrate(formatDownloadable[0].bitrate)
                .setMaxVideoSize(formatDownloadable[0].width, formatDownloadable[0].height)
                .setMaxVideoBitrate(formatDownloadable[0].bitrate)
                .build()
            if (globalQualitySelected != null) {
                if (globalQualitySelected!! > optionsDownload.toTypedArray().size - 1) {
                    globalQualitySelected = optionsDownload.toTypedArray().size - 1
                }
                formatSelected = formatDownloadable[globalQualitySelected!!]
                qualitySelected = DefaultTrackSelector(context).buildUponParameters()
                    .setMinVideoSize(formatSelected.width, formatSelected.height)
                    .setMinVideoBitrate(formatSelected.bitrate)
                    .setMaxVideoSize(formatSelected.width, formatSelected.height)
                    .setMaxVideoBitrate(formatSelected.bitrate)
                    .build()
                fireDownloadWithSelectQuality(helper, qualitySelected, formatSelected, downloadItem)
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
                        .setMaxVideoBitrate(formatSelected.bitrate)
                        .build()
                    Log.e(
                        TAG,
                        "format Selected= width: ${formatSelected.width}, height: ${formatSelected.height}"
                    )
                }.setPositiveButton("Download") { _, _ ->
                    fireDownloadWithSelectQuality(
                        helper,
                        qualitySelected,
                        formatSelected,
                        downloadItem
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
            downloadItem: DownloadItem
        ) {
            helper.clearTrackSelections(0)
            helper.addTrackSelection(0, qualitySelected)
            val drmConfiguration = downloadItem.mediaItem?.localConfiguration?.drmConfiguration
            val offlineHelper = OfflineLicenseHelper.newWidevineInstance(
                drmConfiguration?.licenseUri.toString(),
                drmConfiguration?.forceDefaultLicenseUri ?: false,
                DownloadUtil.getHttpDataSourceFactory(context),
                drmConfiguration?.licenseRequestHeaders,
                DrmSessionEventListener.EventDispatcher()
            )
            val keySetId = offlineHelper.downloadLicense(formatSelected)
            Log.e("DownloadTracker", "keySetId: $keySetId")
            val estimatedContentLength: Long =
                (qualitySelected.maxVideoBitrate * downloadItem.duration!!)
                    .div(C.MILLIS_PER_SECOND).div(C.BITS_PER_BYTE)
            if (availableBytesLeft > estimatedContentLength) {
                val downloadRequest: DownloadRequest = downloadHelper.getDownloadRequest(
                    downloadItem.uri.toString(),
                    Util.getUtf8Bytes(estimatedContentLength.toString())
                ).copyWithKeySetId(keySetId)

                startDownload(downloadRequest)
                availableBytesLeft -= estimatedContentLength
                Log.e(TAG, "availableBytesLeft after calculation: $availableBytesLeft")
            } else {
                Toast.makeText(
                    context,
                    "Not enough space to download this file",
                    Toast.LENGTH_LONG
                ).show()
            }
            positiveCallback?.invoke()
        }

        override fun onPrepareError(helper: DownloadHelper, e: IOException) {
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
                applicationContext,
                MyDownloadService::class.java,
                downloadRequest,
                true
            )
        }

        private fun buildDownloadRequest(): DownloadRequest {
            return downloadHelper.getDownloadRequest(
                downloadItem.uri.toString() ,
                Util.getUtf8Bytes(downloadItem.uri.toString())
            )
        }
    }

    companion object {
        var globalQualitySelected: Int? = null
    }
}
