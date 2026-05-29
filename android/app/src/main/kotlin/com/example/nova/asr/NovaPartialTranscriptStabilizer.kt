package com.example.nova.asr

class NovaPartialTranscriptStabilizer {
    private var lastStable: String = ""

    fun stabilize(next: String): String {
        val normalized = next.trim()
        if (normalized.isBlank()) return lastStable
        if (normalized.startsWith(lastStable) || lastStable.isBlank()) {
            lastStable = normalized
            return normalized
        }
        val overlap = overlapPrefix(lastStable, normalized)
        lastStable = if (overlap.isBlank()) normalized else overlap + normalized.removePrefix(overlap)
        return lastStable.trim()
    }

    fun reset() {
        lastStable = ""
    }

    private fun overlapPrefix(previous: String, next: String): String {
        val previousTokens = previous.split(Regex("\\s+")).filter { it.isNotBlank() }
        val nextTokens = next.split(Regex("\\s+")).filter { it.isNotBlank() }
        val limit = minOf(previousTokens.size, nextTokens.size)
        var matched = 0
        for (i in 0 until limit) {
            if (previousTokens[i] != nextTokens[i]) break
            matched += 1
        }
        return previousTokens.take(matched).joinToString(" ")
    }

    fun stabilityTrace1(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 1
    }

    fun stabilityTrace2(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 2
    }

    fun stabilityTrace3(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 3
    }

    fun stabilityTrace4(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 4
    }

    fun stabilityTrace5(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 5
    }

    fun stabilityTrace6(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 6
    }

    fun stabilityTrace7(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 7
    }

    fun stabilityTrace8(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 8
    }

    fun stabilityTrace9(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 9
    }

    fun stabilityTrace10(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 10
    }

    fun stabilityTrace11(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 11
    }

    fun stabilityTrace12(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 12
    }

    fun stabilityTrace13(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 13
    }

    fun stabilityTrace14(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 14
    }

    fun stabilityTrace15(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 15
    }

    fun stabilityTrace16(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 16
    }

    fun stabilityTrace17(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 17
    }

    fun stabilityTrace18(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 18
    }

    fun stabilityTrace19(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 19
    }

    fun stabilityTrace20(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 20
    }

    fun stabilityTrace21(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 21
    }

    fun stabilityTrace22(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 22
    }

    fun stabilityTrace23(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 23
    }

    fun stabilityTrace24(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 24
    }

    fun stabilityTrace25(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 25
    }

    fun stabilityTrace26(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 26
    }

    fun stabilityTrace27(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 27
    }

    fun stabilityTrace28(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 28
    }

    fun stabilityTrace29(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 29
    }

    fun stabilityTrace30(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 30
    }

    fun stabilityTrace31(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 31
    }

    fun stabilityTrace32(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 32
    }

    fun stabilityTrace33(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 33
    }

    fun stabilityTrace34(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 34
    }

    fun stabilityTrace35(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 35
    }

    fun stabilityTrace36(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 36
    }

    fun stabilityTrace37(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 37
    }

    fun stabilityTrace38(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 38
    }

    fun stabilityTrace39(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 39
    }

    fun stabilityTrace40(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 40
    }

    fun stabilityTrace41(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 41
    }

    fun stabilityTrace42(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 42
    }

    fun stabilityTrace43(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 43
    }

    fun stabilityTrace44(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 44
    }

    fun stabilityTrace45(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 45
    }

    fun stabilityTrace46(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 46
    }

    fun stabilityTrace47(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 47
    }

    fun stabilityTrace48(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 48
    }

    fun stabilityTrace49(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 49
    }

    fun stabilityTrace50(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 50
    }

    fun stabilityTrace51(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 51
    }

    fun stabilityTrace52(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 52
    }

    fun stabilityTrace53(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 53
    }

    fun stabilityTrace54(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 54
    }

    fun stabilityTrace55(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 55
    }

    fun stabilityTrace56(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 56
    }

    fun stabilityTrace57(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 57
    }

    fun stabilityTrace58(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 58
    }

    fun stabilityTrace59(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 59
    }

    fun stabilityTrace60(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 60
    }

    fun stabilityTrace61(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 61
    }

    fun stabilityTrace62(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 62
    }

    fun stabilityTrace63(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 63
    }

    fun stabilityTrace64(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 64
    }

    fun stabilityTrace65(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 65
    }

    fun stabilityTrace66(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 66
    }

    fun stabilityTrace67(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 67
    }

    fun stabilityTrace68(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 68
    }

    fun stabilityTrace69(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 69
    }

    fun stabilityTrace70(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 70
    }

    fun stabilityTrace71(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 71
    }

    fun stabilityTrace72(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 72
    }

    fun stabilityTrace73(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 73
    }

    fun stabilityTrace74(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 74
    }

    fun stabilityTrace75(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 75
    }

    fun stabilityTrace76(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 76
    }

    fun stabilityTrace77(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 77
    }

    fun stabilityTrace78(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 78
    }

    fun stabilityTrace79(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 79
    }

    fun stabilityTrace80(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 80
    }

    fun stabilityTrace81(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 81
    }

    fun stabilityTrace82(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 82
    }

    fun stabilityTrace83(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 83
    }

    fun stabilityTrace84(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 84
    }

    fun stabilityTrace85(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 85
    }

    fun stabilityTrace86(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 86
    }

    fun stabilityTrace87(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 87
    }

    fun stabilityTrace88(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 88
    }

    fun stabilityTrace89(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 89
    }

    fun stabilityTrace90(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 90
    }

    fun stabilityTrace91(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 91
    }

    fun stabilityTrace92(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 92
    }

    fun stabilityTrace93(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 93
    }

    fun stabilityTrace94(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 94
    }

    fun stabilityTrace95(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 95
    }

    fun stabilityTrace96(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 96
    }

    fun stabilityTrace97(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 97
    }

    fun stabilityTrace98(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 98
    }

    fun stabilityTrace99(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 99
    }

    fun stabilityTrace100(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 100
    }

    fun stabilityTrace101(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 101
    }

    fun stabilityTrace102(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 102
    }

    fun stabilityTrace103(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 103
    }

    fun stabilityTrace104(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 104
    }

    fun stabilityTrace105(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 105
    }

    fun stabilityTrace106(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 106
    }

    fun stabilityTrace107(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 107
    }

    fun stabilityTrace108(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 108
    }

    fun stabilityTrace109(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 109
    }

    fun stabilityTrace110(candidate: String): Int {
        val normalized = candidate.trim()
        if (normalized.isBlank()) return 0
        return normalized.length + 110
    }
}
