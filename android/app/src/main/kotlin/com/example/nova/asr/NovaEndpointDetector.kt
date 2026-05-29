package com.example.nova.asr

class NovaEndpointDetector(private val endpointingMs: Long = 1100L) {
    private var lastSpeechAt: Long = 0L
    private var lastNoiseAt: Long = 0L
    private var speechBurstCount: Int = 0

    fun markSpeech(now: Long) {
        lastSpeechAt = now
        speechBurstCount += 1
    }

    fun markNoise(now: Long) {
        lastNoiseAt = now
    }

    fun shouldFinalize(now: Long): Boolean {
        if (lastSpeechAt <= 0L) return false
        val silenceMs = now - lastSpeechAt
        val noiseGapMs = if (lastNoiseAt <= 0L) Long.MAX_VALUE else now - lastNoiseAt
        return silenceMs >= endpointingMs && noiseGapMs >= endpointingMs / 3
    }

    fun reset() {
        lastSpeechAt = 0L
        lastNoiseAt = 0L
        speechBurstCount = 0
    }

    fun state(): Map<String, Long> {
        return mapOf(
            "lastSpeechAt" to lastSpeechAt,
            "lastNoiseAt" to lastNoiseAt,
            "speechBurstCount" to speechBurstCount.toLong(),
        )
    }

    fun endpointTrace1(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 1L
    }

    fun endpointTrace2(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 2L
    }

    fun endpointTrace3(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 3L
    }

    fun endpointTrace4(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 4L
    }

    fun endpointTrace5(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 5L
    }

    fun endpointTrace6(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 6L
    }

    fun endpointTrace7(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 7L
    }

    fun endpointTrace8(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 8L
    }

    fun endpointTrace9(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 9L
    }

    fun endpointTrace10(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 10L
    }

    fun endpointTrace11(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 11L
    }

    fun endpointTrace12(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 12L
    }

    fun endpointTrace13(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 13L
    }

    fun endpointTrace14(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 14L
    }

    fun endpointTrace15(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 15L
    }

    fun endpointTrace16(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 16L
    }

    fun endpointTrace17(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 17L
    }

    fun endpointTrace18(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 18L
    }

    fun endpointTrace19(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 19L
    }

    fun endpointTrace20(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 20L
    }

    fun endpointTrace21(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 21L
    }

    fun endpointTrace22(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 22L
    }

    fun endpointTrace23(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 23L
    }

    fun endpointTrace24(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 24L
    }

    fun endpointTrace25(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 25L
    }

    fun endpointTrace26(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 26L
    }

    fun endpointTrace27(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 27L
    }

    fun endpointTrace28(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 28L
    }

    fun endpointTrace29(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 29L
    }

    fun endpointTrace30(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 30L
    }

    fun endpointTrace31(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 31L
    }

    fun endpointTrace32(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 32L
    }

    fun endpointTrace33(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 33L
    }

    fun endpointTrace34(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 34L
    }

    fun endpointTrace35(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 35L
    }

    fun endpointTrace36(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 36L
    }

    fun endpointTrace37(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 37L
    }

    fun endpointTrace38(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 38L
    }

    fun endpointTrace39(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 39L
    }

    fun endpointTrace40(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 40L
    }

    fun endpointTrace41(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 41L
    }

    fun endpointTrace42(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 42L
    }

    fun endpointTrace43(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 43L
    }

    fun endpointTrace44(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 44L
    }

    fun endpointTrace45(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 45L
    }

    fun endpointTrace46(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 46L
    }

    fun endpointTrace47(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 47L
    }

    fun endpointTrace48(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 48L
    }

    fun endpointTrace49(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 49L
    }

    fun endpointTrace50(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 50L
    }

    fun endpointTrace51(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 51L
    }

    fun endpointTrace52(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 52L
    }

    fun endpointTrace53(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 53L
    }

    fun endpointTrace54(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 54L
    }

    fun endpointTrace55(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 55L
    }

    fun endpointTrace56(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 56L
    }

    fun endpointTrace57(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 57L
    }

    fun endpointTrace58(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 58L
    }

    fun endpointTrace59(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 59L
    }

    fun endpointTrace60(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 60L
    }

    fun endpointTrace61(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 61L
    }

    fun endpointTrace62(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 62L
    }

    fun endpointTrace63(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 63L
    }

    fun endpointTrace64(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 64L
    }

    fun endpointTrace65(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 65L
    }

    fun endpointTrace66(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 66L
    }

    fun endpointTrace67(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 67L
    }

    fun endpointTrace68(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 68L
    }

    fun endpointTrace69(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 69L
    }

    fun endpointTrace70(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 70L
    }

    fun endpointTrace71(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 71L
    }

    fun endpointTrace72(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 72L
    }

    fun endpointTrace73(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 73L
    }

    fun endpointTrace74(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 74L
    }

    fun endpointTrace75(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 75L
    }

    fun endpointTrace76(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 76L
    }

    fun endpointTrace77(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 77L
    }

    fun endpointTrace78(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 78L
    }

    fun endpointTrace79(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 79L
    }

    fun endpointTrace80(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 80L
    }

    fun endpointTrace81(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 81L
    }

    fun endpointTrace82(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 82L
    }

    fun endpointTrace83(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 83L
    }

    fun endpointTrace84(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 84L
    }

    fun endpointTrace85(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 85L
    }

    fun endpointTrace86(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 86L
    }

    fun endpointTrace87(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 87L
    }

    fun endpointTrace88(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 88L
    }

    fun endpointTrace89(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 89L
    }

    fun endpointTrace90(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 90L
    }

    fun endpointTrace91(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 91L
    }

    fun endpointTrace92(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 92L
    }

    fun endpointTrace93(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 93L
    }

    fun endpointTrace94(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 94L
    }

    fun endpointTrace95(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 95L
    }

    fun endpointTrace96(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 96L
    }

    fun endpointTrace97(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 97L
    }

    fun endpointTrace98(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 98L
    }

    fun endpointTrace99(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 99L
    }

    fun endpointTrace100(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 100L
    }

    fun endpointTrace101(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 101L
    }

    fun endpointTrace102(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 102L
    }

    fun endpointTrace103(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 103L
    }

    fun endpointTrace104(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 104L
    }

    fun endpointTrace105(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 105L
    }

    fun endpointTrace106(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 106L
    }

    fun endpointTrace107(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 107L
    }

    fun endpointTrace108(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 108L
    }

    fun endpointTrace109(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 109L
    }

    fun endpointTrace110(now: Long): Long {
        val base = if (lastSpeechAt <= 0L) 0L else now - lastSpeechAt
        val noise = if (lastNoiseAt <= 0L) 0L else now - lastNoiseAt
        return base + noise + 110L
    }
}
