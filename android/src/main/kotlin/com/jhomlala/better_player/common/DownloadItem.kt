package com.jhomlala.better_player.common

import android.net.Uri
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.offline.Download
import java.util.UUID

data class DownloadItem(
    val uniqueId: String,
    val name: String?,
    val uri: Uri,
    val download: Download?,
    val duration: Long?,
    var mediaItem: MediaItem?
)


fun createDownloadItem(
    name: String? = "",
    uri: Uri,
    download: Download? = null,
    duration: Long? = null,
    mediaItem: MediaItem? = null
): DownloadItem {
    val uniqueId = extractUUIDFromUri(uri)
    return DownloadItem(uniqueId, name, uri, download, duration, mediaItem)
}


private fun extractUUIDFromUri(uri: Uri): String {
    val pathSegments = uri.pathSegments
    for (segment in pathSegments) {
        if (segment.contains("-")) {
            return segment
        }
    }
    // If no UUID found in path, generate a random one
    return UUID.randomUUID().toString()
}