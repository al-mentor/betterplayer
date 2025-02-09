package com.jhomlala.better_player.common

import android.R
import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Rational
import androidx.annotation.OptIn
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.media3.common.util.UnstableApi
import com.jhomlala.better_player.BetterPlayer
import com.jhomlala.better_player.common.PIPReceiver.Companion.isRegistered

class PIPReceiver( val activity: Activity): BroadcastReceiver() {
    @OptIn(UnstableApi::class) @RequiresApi(Build.VERSION_CODES.O)
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            ACTION_PLAY -> {
                val event: MutableMap<String, Any> = HashMap()
                event["event"] = "play_action"
                BetterPlayer.eventSink.success(event)
                val params = pipParams(true)
                activity.setPictureInPictureParams(params);
            }

            ACTION_PAUSE -> {
                val event: MutableMap<String, Any> = HashMap()
                event["event"] = "pause_action"
                BetterPlayer.eventSink.success(event)
                val params = pipParams(false)
                activity.setPictureInPictureParams(params);

            }

            ACTION_NEXT -> {
                val event: MutableMap<String, Any> = HashMap()
                event["event"] = "next_action"
                BetterPlayer.eventSink.success(event)
                val params = pipParams(true)
                activity.setPictureInPictureParams(params);
            }

            ACTION_PREVIOUS -> {
                val event: MutableMap<String, Any> = HashMap()
                event["event"] = "previous_action"
                BetterPlayer.eventSink.success(event)
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
            Icon.createWithResource(activity, R.drawable.ic_media_next),
            "Next",
            "Next",
            PendingIntent.getBroadcast(
                activity,
                2,
                Intent(ACTION_NEXT),
                PendingIntent.FLAG_IMMUTABLE
            )
        )

        val previousAction = RemoteAction(
            Icon.createWithResource(
                activity,
                R.drawable. ic_media_previous
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
        actions.add(nextAction)

        actions.add(previousAction)

        // Set the actions in PiP mode
        val params = PictureInPictureParams.Builder()
            .setActions(actions)
            .setAspectRatio(Rational(16, 9))
            .build()
        return params;
    }
    fun registerReceiver(context: Context) {
        if (!isRegistered) {
            val filter = IntentFilter().apply {
                addAction(ACTION_PLAY)
                addAction(ACTION_PAUSE)
                addAction(ACTION_NEXT)
                addAction(ACTION_PREVIOUS)
            }
            ContextCompat.registerReceiver(
                context,
                this,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
            isRegistered = true
        }
    }

    fun unregisterReceiver(context: Context) {
        if (isRegistered) {
            context.unregisterReceiver(this)
            isRegistered = false
        }
    }

    companion object{
        const val ACTION_PLAY = "com.jhomlala.better_player.PLAY"
        const val ACTION_PAUSE = "com.jhomlala.better_player.PAUSE"
        const val ACTION_NEXT = "com.jhomlala.better_player.NEXT"
        const val ACTION_PREVIOUS = "com.jhomlala.better_player.PREVIOUS"
        var isRegistered = false

    }


}