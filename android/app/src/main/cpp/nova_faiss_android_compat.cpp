#include <cstddef>
#include <cstdint>
#include <chrono>

#ifndef FINTEGER
#define FINTEGER long
#endif

namespace faiss {

double getmillisecs() {
    using namespace std::chrono;
    return duration<double, std::milli>(steady_clock::now().time_since_epoch()).count();
}

} // namespace faiss

extern "C" {

// Minimal Android-side SGEMM fallback for FAISS flat-distance code paths.
// Column-major semantics matching BLAS sgemm_ are implemented for the
// transpose combinations used by FAISS distance helpers.
int sgemm_(
        const char* transa,
        const char* transb,
        FINTEGER* m,
        FINTEGER* n,
        FINTEGER* k,
        const float* alpha,
        const float* a,
        FINTEGER* lda,
        const float* b,
        FINTEGER* ldb,
        float* beta,
        float* c,
        FINTEGER* ldc) {
    if (!transa || !transb || !m || !n || !k || !alpha || !a || !lda || !b || !ldb || !beta || !c || !ldc) {
        return -1;
    }

    const bool ta = (*transa == 'T' || *transa == 't');
    const bool tb = (*transb == 'T' || *transb == 't');
    const FINTEGER M = *m;
    const FINTEGER N = *n;
    const FINTEGER K = *k;
    const FINTEGER LDA = *lda;
    const FINTEGER LDB = *ldb;
    const FINTEGER LDC = *ldc;
    const float A = *alpha;
    const float B = *beta;

    auto col_major = [](const float* base, FINTEGER row, FINTEGER col, FINTEGER ld) -> float {
        return base[col * ld + row];
    };
    auto col_major_out = [](float* base, FINTEGER row, FINTEGER col, FINTEGER ld) -> float& {
        return base[col * ld + row];
    };

    for (FINTEGER col = 0; col < N; ++col) {
        for (FINTEGER row = 0; row < M; ++row) {
            float sum = 0.0f;
            for (FINTEGER kk = 0; kk < K; ++kk) {
                const float av = ta ? col_major(a, kk, row, LDA) : col_major(a, row, kk, LDA);
                const float bv = tb ? col_major(b, col, kk, LDB) : col_major(b, kk, col, LDB);
                sum += av * bv;
            }
            float& out = col_major_out(c, row, col, LDC);
            out = A * sum + B * out;
        }
    }
    return 0;
}

} // extern "C"
