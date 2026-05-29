package com.example.nova

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object NovaCallRecordingController {

    @Volatile
    private var recorder: MediaRecorder? = null

    @Volatile
    private var currentFile: File? = null

    @Volatile
    private var recording: Boolean = false

    fun isRecording(): Boolean = recording

    fun currentPath(): String = currentFile?.absolutePath.orEmpty()

    fun toggle(context: Context): Map<String, Any> {
        return if (recording) stop() else start(context)
    }

    fun start(context: Context): Map<String, Any> {
        if (recording) {
            return result(true, "Kayıt zaten devam ediyor.", currentFile)
        }

        val appContext = context.applicationContext
        val dir = File(appContext.getExternalFilesDir(null), "call_recordings")
        if (!dir.exists()) dir.mkdirs()

        val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val outFile = File(dir, "nova_call_$stamp.m4a")

        return try {
            val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(appContext)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            mediaRecorder.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setOutputFile(outFile.absolutePath)
                prepare()
                start()
            }

            recorder = mediaRecorder
            currentFile = outFile
            recording = true
            result(true, "Kayıt başladı.", outFile)
        } catch (t: Throwable) {
            runCatching { recorder?.release() }
            recorder = null
            currentFile = null
            recording = false
            result(false, "Kayıt başlatılamadı: ${t.message ?: "unknown"}", null)
        }
    }

    fun stop(): Map<String, Any> {
        val file = currentFile
        return try {
            val active = recorder
            if (active != null) {
                runCatching { active.stop() }
                runCatching { active.reset() }
                runCatching { active.release() }
            }
            recorder = null
            recording = false
            val completed = file?.takeIf { it.exists() && it.length() > 0L }
            currentFile = completed
            result(true, if (completed != null) "Kayıt tamamlandı." else "Kayıt durduruldu.", completed)
        } catch (t: Throwable) {
            runCatching { recorder?.release() }
            recorder = null
            recording = false
            result(false, "Kayıt durdurulamadı: ${t.message ?: "unknown"}", file)
        }
    }

    private fun result(success: Boolean, message: String, file: File?): Map<String, Any> = mapOf(
        "success" to success,
        "message" to message,
        "isRecording" to recording,
        "path" to file?.absolutePath.orEmpty()
    )
}
