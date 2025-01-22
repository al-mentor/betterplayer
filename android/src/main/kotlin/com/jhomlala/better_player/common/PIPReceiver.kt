package com.jhomlala.better_player.common

import android.R
import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class PIPReceiver(val binaryMessenger: BinaryMessenger, val activity: Activity): BroadcastReceiver() {
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onReceive(context: Context?, intent: Intent?) {
        val methodChannel =
            MethodChannel(binaryMessenger, "com.example.betterplayer/pip")

        when (intent?.action) {
            ACTION_PLAY -> {
                methodChannel.invokeMethod("play", null)
                val params = pipParams(true)
                activity.setPictureInPictureParams(params);
            }

            ACTION_PAUSE -> {
                methodChannel.invokeMethod("pause", null)
                val params = pipParams(false)
                activity.setPictureInPictureParams(params);

            }

            ACTION_NEXT -> {
                methodChannel.invokeMethod("next", null)
                val params = pipParams(true)
                activity.setPictureInPictureParams(params);
            }

            ACTION_PREVIOUS -> {
                methodChannel.invokeMethod("previous", null)
                val params = pipParams(true)
                activity.setPictureInPictureParams(params);
            }
        }
    }



    @RequiresApi(Build.VERSION_CODES.O)
    private fun pipParams(isPlaying: Boolean): PictureInPictureParams {
        val actions = ArrayList<RemoteAction>()
        if (!isPlaying) {
            val playAction = RemoteAction(
                Icon.createWithResource(activity, R.drawable.ic_media_play),
                "Play",
                "Play",
                PendingIntent.getBroadcast(
                    activity,
                    0,
                    Intent(ACTION_PLAY),
                    PendingIntent.FLAG_IMMUTABLE
                )
            )
            actions.add(playAction)
        }
        if (isPlaying) {
            val pauseAction = RemoteAction(
                Icon.createWithResource(
                    activity,
                    android.R.drawable.ic_media_pause
                ),
                "Pause",
                "Pause",
                PendingIntent.getBroadcast(
                    activity,
                    1,
                    Intent(ACTION_PAUSE),
                    PendingIntent.FLAG_IMMUTABLE
                )
            )
            actions.add(pauseAction)
        }
        val nextAction = RemoteAction(
            Icon.createWithResource(activity, R.drawable.ic_media_previous),
            "Next",
            "Next",
            PendingIntent.getBroadcast(
                activity,
                2,
                Intent(ACTION_NEXT),
                PendingIntent.FLAG_IMMUTABLE
            )
        )
        actions.add(nextAction)

        val previousAction = RemoteAction(
            Icon.createWithResource(
                activity,
                R.drawable. ic_media_next
            ),
            "Previous",
            "Previous",
            PendingIntent.getBroadcast(
                activity,
                3,
                Intent(ACTION_PREVIOUS),
                PendingIntent.FLAG_IMMUTABLE
            )
        )
        actions.add(previousAction)

        // Set the actions in PiP mode
        val params = PictureInPictureParams.Builder()
            .setActions(actions)
            .setAspectRatio(Rational(16, 9))
            .build()
        return params;
    }

    companion object{
        const val ACTION_PLAY = "com.jhomlala.better_player.PLAY"
        const val ACTION_PAUSE = "com.jhomlala.better_player.PAUSE"
        const val ACTION_NEXT = "com.jhomlala.better_player.NEXT"
        const val ACTION_PREVIOUS = "com.jhomlala.better_player.PREVIOUS"
    }


}