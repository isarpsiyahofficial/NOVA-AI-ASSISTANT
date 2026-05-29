package com.example.nova

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class NovaPhoneLauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startActivity(Intent(this, NovaDialerActivity::class.java).apply {
            putExtra(NovaDialerActivity.EXTRA_INITIAL_TAB, NovaDialerActivity.TAB_RECENTS)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        })
        finish()
    }
}
