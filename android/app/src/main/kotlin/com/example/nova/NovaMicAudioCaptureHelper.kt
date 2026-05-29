package com.example.nova

import android.Manifest
import android.content.pm.PackageManager
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

class NovaMicAudioCaptureHelper(
    private val context: Context
) {

    interface Callback {
        fun onDone(success: Boolean, filePath: String, message: String)
    }

    fun recordSample(
        seconds: Int,
        outputName: String,
        callback: Callback
    ) {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            callback.onDone(false, "", "Mikrofon izni verilmedi.")
            return
        }

        NovaAudioInputPolicy.beginPassiveListening(context)

        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val safeSeconds = seconds.coerceIn(2, 25)

        try {
            val minBuffer = AudioRecord.getMinBufferSize(
                sampleRate,
                channelConfig,
                encoding
            )

            if (minBuffer <= 0) {
                NovaAudioInputPolicy.endPassiveListening(context)
                callback.onDone(false, "", "Mikrofon buffer boyutu alınamadı.")
                return
            }

            val bufferSize = maxOf(minBuffer * 4, sampleRate * 2) // GEMMA6644: ALSA timeout/drop azaltmak için daha güvenli capture buffer

            val audioRecord = try {
                AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    sampleRate,
                    channelConfig,
                    encoding,
                    bufferSize
                )
            } catch (_: Throwable) {
                AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    channelConfig,
                    encoding,
                    bufferSize
                )
            }

            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                try {
                    audioRecord.release()
                } catch (_: Throwable) {
                }
                NovaAudioInputPolicy.endPassiveListening(context)
                callback.onDone(false, "", "Mikrofon kaydı başlatılamadı.")
                return
            }

            val dir = File(context.filesDir, "nova_audio_samples")
            if (!dir.exists()) {
                dir.mkdirs()
            }

            val safeOutputName = NovaAppSandboxGuard.sanitizeOutputName(outputName, "nova_external_clone")
            val file = File(dir, "$safeOutputName.wav")
            if (file.exists()) {
                file.delete()
            }

            writeEmptyWavHeader(file)

            Thread {
                var fos: FileOutputStream? = null
                var aec: AcousticEchoCanceler? = null
                var ns: NoiseSuppressor? = null
                var agc: AutomaticGainControl? = null
                try {
                    fos = FileOutputStream(file, true)
                    val buffer = ByteArray(bufferSize)
                    val totalTargetBytes = safeSeconds * sampleRate * 2
                    var written = 0

                    val audioSessionId = audioRecord.audioSessionId
                    aec = if (AcousticEchoCanceler.isAvailable()) runCatching { AcousticEchoCanceler.create(audioSessionId) }.getOrNull() else null
                    ns = if (NoiseSuppressor.isAvailable()) runCatching { NoiseSuppressor.create(audioSessionId) }.getOrNull() else null
                    agc = if (AutomaticGainControl.isAvailable()) runCatching { AutomaticGainControl.create(audioSessionId) }.getOrNull() else null
                    runCatching { aec?.enabled = true }
                    runCatching { ns?.enabled = true }
                    runCatching { agc?.enabled = true }

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

                    try { aec?.release() } catch (_: Throwable) {}
                    try { ns?.release() } catch (_: Throwable) {}
                    try { agc?.release() } catch (_: Throwable) {}

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

                    finalizeWavHeader(
                        file = file,
                        sampleRate = sampleRate,
                        channels = 1,
                        bitsPerSample = 16
                    )

                    NovaAudioInputPolicy.endPassiveListening(context)
                    callback.onDone(true, NovaAppSandboxGuard.toAppRelativeReference(context, file), "Mikrofon kaydı tamamlandı.")
                } catch (_: Throwable) {
                    try { aec?.release() } catch (_: Throwable) {}
                    try { ns?.release() } catch (_: Throwable) {}
                    try { agc?.release() } catch (_: Throwable) {}

                    try {
                        audioRecord.release()
                    } catch (_: Throwable) {
                    }

                    try {
                        fos?.close()
                    } catch (_: Throwable) {
                    }

                    NovaAudioInputPolicy.endPassiveListening(context)
                    callback.onDone(false, "", "Mikrofon kaydı başarısız.")
                }
            }.start()
        } catch (_: Throwable) {
            NovaAudioInputPolicy.endPassiveListening(context)
            callback.onDone(false, "", "Mikrofon kaydı başlatılamadı.")
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
            raf.writeIntLE(16000)
            raf.writeIntLE(16000 * 2)
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