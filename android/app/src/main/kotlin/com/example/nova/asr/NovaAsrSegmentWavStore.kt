package com.example.nova.asr

import android.content.Context
import com.example.nova.NovaAppSandboxGuard
import java.io.File
import java.io.RandomAccessFile

/**
 * Stores the exact Silero-completed PCM segment that Whisper decoded.
 * The returned reference remains inside the app sandbox and is consumed by
 * the TitaNet speaker-ID bridge. Old command samples are pruned aggressively.
 */
object NovaAsrSegmentWavStore {
    private const val SAMPLE_RATE = 16_000
    private const val MAX_FILES = 8

    fun write(
        context: Context,
        samples: ShortArray,
        segmentId: Int,
    ): String {
        if (samples.isEmpty()) return ""
        val dir = File(context.filesDir, "nova_asr_identity_segments").apply {
            if (!exists()) mkdirs()
        }
        prune(dir)
        val file = File(
            dir,
            "segment_${segmentId}_${System.currentTimeMillis()}.wav",
        )
        return try {
            RandomAccessFile(file, "rw").use { raf ->
                val dataBytes = samples.size * 2
                raf.setLength(0)
                raf.writeBytes("RIFF")
                raf.writeIntLE(36 + dataBytes)
                raf.writeBytes("WAVE")
                raf.writeBytes("fmt ")
                raf.writeIntLE(16)
                raf.writeShortLE(1)
                raf.writeShortLE(1)
                raf.writeIntLE(SAMPLE_RATE)
                raf.writeIntLE(SAMPLE_RATE * 2)
                raf.writeShortLE(2)
                raf.writeShortLE(16)
                raf.writeBytes("data")
                raf.writeIntLE(dataBytes)
                for (sample in samples) raf.writeShortLE(sample.toInt())
            }
            NovaAppSandboxGuard.toAppRelativeReference(context, file)
        } catch (_: Throwable) {
            runCatching { file.delete() }
            ""
        }
    }

    private fun prune(dir: File) {
        val files = dir.listFiles()
            ?.filter { it.isFile && it.extension.equals("wav", ignoreCase = true) }
            ?.sortedByDescending { it.lastModified() }
            .orEmpty()
        files.drop(MAX_FILES - 1).forEach { runCatching { it.delete() } }
    }
}

private fun RandomAccessFile.writeIntLE(value: Int) {
    write(
        byteArrayOf(
            (value and 0xff).toByte(),
            (value shr 8 and 0xff).toByte(),
            (value shr 16 and 0xff).toByte(),
            (value shr 24 and 0xff).toByte(),
        )
    )
}

private fun RandomAccessFile.writeShortLE(value: Int) {
    write(
        byteArrayOf(
            (value and 0xff).toByte(),
            (value shr 8 and 0xff).toByte(),
        )
    )
}
