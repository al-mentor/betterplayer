package com.jhomlala.better_player.common

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import java.lang.ref.WeakReference

object ActivityUtils {
    private var topActivityRef: WeakReference<Activity>? = null
    private var application: Application? = null

    fun init(context: Context) {
        this.application = context.applicationContext as Application
        application?.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                topActivityRef = WeakReference(activity)
            }

            override fun onActivityStarted(activity: Activity) {
                topActivityRef = WeakReference(activity)
            }

            override fun onActivityResumed(activity: Activity) {
                topActivityRef = WeakReference(activity)
            }

            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {
                if (topActivityRef?.get() == activity) {
                    topActivityRef = null
                }
            }
        })
    }

    fun getTopActivity(): Activity? {
        return topActivityRef?.get()
    }

    fun getApplicationContext(): Context? {
        return application
    }
} 