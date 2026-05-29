package com.example.nova

import android.content.Context

class NovaAsrModelLocator(private val context: Context) {
    private val delegate = com.example.nova.asr.NovaAsrModelLocator(context)

    fun resolve(): com.example.nova.asr.NovaAsrModelLocator.ModelResolution {
        return delegate.resolve()
    }
}
