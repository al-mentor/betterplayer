package com.jhomlala.better_player.common


import android.content.Context
import android.net.Uri
import androidx.media3.database.DatabaseProvider
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.cache.Cache
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadNotificationHelper
import com.google.gson.Gson
import com.jhomlala.better_player.R
import io.flutter.plugin.common.EventChannel.EventSink
import java.io.File
import java.util.concurrent.Executors
import java.util.regex.Pattern


object DownloadUtil {
    const val DOWNLOAD_NOTIFICATION_CHANNEL_ID = "download_channel"
    private const val TAG = "DownloadUtil"
    private const val DOWNLOAD_CONTENT_DIRECTORY = "downloads"

    private lateinit var databaseProvider: DatabaseProvider
    private lateinit var downloadCache: Cache
    private lateinit var dataSourceFactory: DataSource.Factory
    private lateinit var httpDataSourceFactory: HttpDataSource.Factory
    private lateinit var downloadNotificationHelper: DownloadNotificationHelper
    private lateinit var downloadDirectory: File
    private lateinit var downloadManager: DownloadManager
    private lateinit var downloadTracker: DownloadTracker

     var eventChannel:  EventSink? = null


    fun extractUUIDFromUri(uri: Uri): String? {
        val regex = Pattern.compile("[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+")
        val matcher = regex.matcher(uri.toString())

        return if (matcher.find()) {
            matcher.group(0)
        } else {
            null
        }
    }


    fun buildDownloadObject(
        downloads: List<Download>
    ): String? {
        val downloadData = ArrayList<Map<String, String?>>()
        for (download in downloads) {
            val downloadMap = HashMap<String, String?>()
            downloadMap["uri"] =  extractUUIDFromUri(download.request.uri);
            downloadMap["downloadState"] = download.state.toString();
            downloadMap["downloadId"] = download.request.id;
            downloadMap["downloadPercentage"] = download.percentDownloaded.toString();
            downloadData.add(downloadMap)
        }
        val gson = Gson()
        val json = gson.toJson(downloadData)
        return json;
    }

    fun buildFailedDownloadObject(
        uri: Uri,
    ): String? {
        val downloadData = ArrayList<Map<String, String?>>()

            val downloadMap = HashMap<String, String?>()
            downloadMap["uri"] =  extractUUIDFromUri(uri);
            downloadMap["downloadState"] = "5";
            downloadMap["downloadId"] = uri.toString();
            downloadMap["downloadPercentage"] = "0";
            downloadData.add(downloadMap)

        val gson = Gson()
        val json = gson.toJson(downloadData)
        return json;
    }



    @Synchronized
    fun getHttpDataSourceFactory(context: Context): HttpDataSource.Factory {
        if(!DownloadUtil::httpDataSourceFactory.isInitialized) {
            httpDataSourceFactory = DefaultHttpDataSource.Factory()
                .setConnectTimeoutMs(800000)
                .setReadTimeoutMs(800000)
                .setAllowCrossProtocolRedirects(true)
        }
        return httpDataSourceFactory
     }

    @Synchronized
    fun getReadOnlyDataSourceFactory(context: Context): DataSource.Factory {
        if(!DownloadUtil::dataSourceFactory.isInitialized) {
            val contextApplication = context.applicationContext
            val upstreamFactory = DefaultDataSource.Factory(
                contextApplication,
                getHttpDataSourceFactory(contextApplication)
            )
            dataSourceFactory = CacheDataSource.Factory()
                .setCache(getDownloadCache(contextApplication))
                .setUpstreamDataSourceFactory(upstreamFactory)
                .setCacheWriteDataSinkFactory(null)
                .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
        }
        return dataSourceFactory
    }

    @Synchronized
    fun getDownloadNotificationHelper(context: Context?): DownloadNotificationHelper {
        if(!DownloadUtil::downloadNotificationHelper.isInitialized) {
            downloadNotificationHelper =
                DownloadNotificationHelper(context!!, DOWNLOAD_NOTIFICATION_CHANNEL_ID)
        }
        return downloadNotificationHelper
    }

    @Synchronized
    fun getDownloadManager(context: Context): DownloadManager {
        ensureDownloadManagerInitialized(context)
        return downloadManager
    }

    @Synchronized
    fun getDownloadTracker(context: Context): DownloadTracker {
        ensureDownloadManagerInitialized(context)
        return downloadTracker
    }

    fun getDownloadString(context: Context, @Download.State downloadState: Int): String {
        return when (downloadState) {
            Download.STATE_COMPLETED -> context.resources.getString(R.string.exo_download_completed)
            Download.STATE_DOWNLOADING -> context.resources.getString(R.string.exo_download_downloading)
            Download.STATE_FAILED -> context.resources.getString(R.string.exo_download_failed)
            Download.STATE_QUEUED -> context.resources.getString(R.string.exo_download_queued)
            Download.STATE_REMOVING -> context.resources.getString(R.string.exo_download_removing)
            Download.STATE_RESTARTING -> context.resources.getString(R.string.exo_download_restarting)
            Download.STATE_STOPPED -> context.resources.getString(R.string.exo_download_stopped)
            else -> throw IllegalArgumentException()
        }
    }

    @Synchronized
    private fun getDownloadCache(context: Context): Cache {
        if(!DownloadUtil::downloadCache.isInitialized) {
            val downloadContentDirectory =
                File(getDownloadDirectory(context), DOWNLOAD_CONTENT_DIRECTORY)
            downloadCache = SimpleCache(
                downloadContentDirectory,
                NoOpCacheEvictor(),
                getDatabaseProvider(context)
            )
        }
        return downloadCache
    }

    @Synchronized
    private fun ensureDownloadManagerInitialized(context: Context) {
        if(!DownloadUtil::downloadManager.isInitialized) {
            downloadManager = DownloadManager(
                context,
                getDatabaseProvider(context),
                getDownloadCache(context),
                getHttpDataSourceFactory(context),
                Executors.newFixedThreadPool(6)
            ).apply {
                maxParallelDownloads = 2
            }
            downloadTracker =
                DownloadTracker(context, getHttpDataSourceFactory(context), downloadManager)
        }
    }

    @Synchronized
    private fun getDatabaseProvider(context: Context): DatabaseProvider {
        if(!DownloadUtil::databaseProvider.isInitialized) databaseProvider =
            StandaloneDatabaseProvider(context)
        return databaseProvider
    }

    @Synchronized
    fun getDownloadDirectory(context: Context): File {
        if(!DownloadUtil::downloadDirectory.isInitialized) {
            downloadDirectory = context.getExternalFilesDir(null) ?: context.filesDir
        }
        return downloadDirectory
    }

}
