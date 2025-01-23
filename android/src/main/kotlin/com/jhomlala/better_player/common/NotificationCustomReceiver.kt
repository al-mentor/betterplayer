package com.jhomlala.better_player.common

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.PlayerNotificationManager
import com.jhomlala.better_player.BetterPlayer


@UnstableApi
class NotificationCustomReceiver() : PlayerNotificationManager.CustomActionReceiver {
    override fun createCustomActions(
        context: Context,
        instanceId: Int
    ): MutableMap<String, NotificationCompat.Action> {
        // Create a map to hold the custom actions
        val customActions = mutableMapOf<String, NotificationCompat.Action>()

        // Next Action
        val nextAction = NotificationCompat.Action(
            android.R.drawable.ic_media_previous, // Icon for Next
            "Next", // Label for Next
            PendingIntent.getBroadcast(
                context,
                0, // Request code for Next
                Intent(ACTION_NEXT).setPackage(context.packageName),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        )
        val previousAction = NotificationCompat.Action(
            android.R.drawable.ic_media_next , // Icon for Previous
            "Previous", // Label for Previous
            PendingIntent.getBroadcast(
                context,
                1, // Request code for Previous
                Intent(ACTION_PREVIOUS).setPackage(context.packageName),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        )
        customActions[ACTION_PREVIOUS] = previousAction

        customActions[ACTION_NEXT] = nextAction



        return customActions
    }

    override fun getCustomActions(player: Player): MutableList<String> {
        // Return the list of custom actions to display
        return mutableListOf(ACTION_NEXT, ACTION_PREVIOUS)
    }

    override fun onCustomAction(player: Player, action: String, intent: Intent) {
        when (action) {
            ACTION_NEXT -> {
                val event: MutableMap<String, Any> = HashMap()
                event["event"] = "next_action"
                BetterPlayer.eventSink.success(event)
            }
            ACTION_PREVIOUS -> {
                val event: MutableMap<String, Any> = HashMap()
                event["event"] = "previous_action"
                BetterPlayer.eventSink.success(event)

            }
        }
    }

    companion object{
        const val ACTION_NEXT = "com.jhomlala.better_player.NEXT"
        const val ACTION_PREVIOUS = "com.jhomlala.better_player.PREVIOUS"
    }

}