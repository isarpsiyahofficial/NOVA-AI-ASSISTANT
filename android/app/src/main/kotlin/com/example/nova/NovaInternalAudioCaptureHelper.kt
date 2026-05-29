package com.example.nova

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

class NovaInternalAudioCaptureHelper(
    private val context: Context
) {

    interface Callback {
        fun onDone(success: Boolean, filePath: String, message: String)
    }

    fun recordInternalAudio(
        seconds: Int,
        outputName: String,
        callback: Callback
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            callback.onDone(false, "", "Telefon içi ses yakalama için Android 10+ gerekiyor.")
            return
        }

        val consent = NovaMediaProjectionState.peekGrantedConsent()
        if (consent == null) {
            callback.onDone(false, "", "Telefon içi ses izni hazır değil. Önce izin alınmalı.")
            return
        }

        try {
            NovaInternalAudioCaptureService.showRunning(context)

            val projectionManager =
                context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

            val projection: MediaProjection? =
                projectionManager.getMediaProjection(consent.resultCode, consent.dataIntent)

            if (projection == null) {
                NovaInternalAudioCaptureService.stop(context)
                callback.onDone(false, "", "Telefon içi ses yakalama başlatılamadı.")
                return
            }

            val captureConfig = AudioPlaybackCaptureConfiguration.Builder(projection)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .build()

            val sampleRate = 44100
            val channelMask = AudioFormat.CHANNEL_IN_MONO
            val encoding = AudioFormat.ENCODING_PCM_16BIT

            val format = AudioFormat.Builder()
                .setEncoding(encoding)
                .setSampleRate(sampleRate)
                .setChannelMask(channelMask)
                .build()

            val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelMask, encoding)
            val bufferSize = minBuffer.coerceAtLeast(sampleRate)

            val audioRecord = AudioRecord.Builder()
                .setAudioFormat(format)
                .setBufferSizeInBytes(bufferSize)
                .setAudioPlaybackCaptureConfig(captureConfig)
                .build()

            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                projection.stop()
                NovaInternalAudioCaptureService.stop(context)
                callback.onDone(false, "", "Telefon içi ses kaydı başlatılamadı.")
                return
            }

            val dir = File(context.filesDir, "nova_internal_audio_samples")
            if (!dir.exists()) dir.mkdirs()

            val safeOutputName = NovaAppSandboxGuard.sanitizeOutputName(outputName, "nova_internal_clone")
            val outFile = File(dir, "$safeOutputName.wav")
            if (outFile.exists()) outFile.delete()

            writeEmptyWavHeader(outFile)

            Thread {
                try {
                    val fos = FileOutputStream(outFile, true)
                    val buffer = ByteArray(bufferSize)
                    val totalTargetBytes =
                        seconds.coerceIn(2, 30) * sampleRate * 2
                    var written = 0

                    audioRecord.startRecording()

                    while (written < totalTargetBytes) {
                        val read = audioRecord.read(buffer, 0, buffer.size)
                        if (read > 0) {
                            fos.write(buffer, 0, read)
                            written += read
                        }
                    }

                    try {
                        audioRecord.stop()
                    } catch (_: Throwable) {
                    }

                    try {
                        audioRecord.release()
                    } catch (_: Throwable) {
                    }

                    try {
                        fos.flush()
                    } catch (_: Throwable) {
                    }

                    try {
                        fos.close()
                    } catch (_: Throwable) {
                    }

                    try {
                        projection.stop()
                    } catch (_: Throwable) {
                    }

                    NovaInternalAudioCaptureService.stop(context)

                    finalizeWavHeader(outFile, sampleRate, 1, 16)
                    callback.onDone(true, NovaAppSandboxGuard.toAppRelativeReference(context, outFile), "Telefon içi ses örneği alındı.")
                } catch (_: Throwable) {
                    try {
                        audioRecord.release()
                    } catch (_: Throwable) {
                    }
                    try {
                        projection.stop()
                    } catch (_: Throwable) {
                    }
                    NovaInternalAudioCaptureService.stop(context)
                    callback.onDone(false, "", "Telefon içi ses örneği alınamadı.")
                }
            }.start()
        } catch (_: Throwable) {
            NovaInternalAudioCaptureService.stop(context)
            callback.onDone(false, "", "Telefon içi ses yakalama kurulamadı.")
        }
    }

    private fun writeEmptyWavHeader(file: File) {
        RandomAccessFile(file, "rw").use { raf ->
            raf.setLength(0)
            raf.writeBytes("RIFF")
            raf.writeIntLE(0)
            raf.writeBytes("WAVE")
            raf.writeBytes("fmt ")
            raf.writeIntLE(16)
            raf.writeShortLE(1.toShort())
            raf.writeShortLE(1.toShort())
            raf.writeIntLE(44100)
            raf.writeIntLE(44100 * 2)
            raf.writeShortLE(2.toShort())
            raf.writeShortLE(16.toShort())
            raf.writeBytes("data")
            raf.writeIntLE(0)
        }
    }

    private fun finalizeWavHeader(
        file: File,
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int
    ) {
        val totalAudioLen = file.length() - 44
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * channels * bitsPerSample / 8

        RandomAccessFile(file, "rw").use { raf ->
            raf.seek(4)
            raf.writeIntLE(totalDataLen.toInt())
            raf.seek(22)
            raf.writeShortLE(channels.toShort())
            raf.seek(24)
            raf.writeIntLE(sampleRate)
            raf.seek(28)
            raf.writeIntLE(byteRate)
            raf.seek(34)
            raf.writeShortLE(bitsPerSample.toShort())
            raf.seek(40)
            raf.writeIntLE(totalAudioLen.toInt())
        }
    }
}

private fun RandomAccessFile.writeIntLE(value: Int) {
    write(
        byteArrayOf(
            (value and 0xff).toByte(),
            (value shr 8 and 0xff).toByte(),
            (value shr 16 and 0xff).toByte(),
            (value shr 24 and 0xff).toByte()
        )
    )
}

private fun RandomAccessFile.writeShortLE(value: Short) {
    write(
        byteArrayOf(
            (value.toInt() and 0xff).toByte(),
            (value.toInt() shr 8 and 0xff).toByte()
        )
    )
}