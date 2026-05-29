#include <cstdint>

extern "C" {

static int g_omp_nested = 0;
static int g_omp_requested_threads = 1;

typedef struct {
    int state;
} omp_lock_t;

int omp_get_max_threads(void) {
    return g_omp_requested_threads > 0 ? g_omp_requested_threads : 1;
}

int omp_get_num_threads(void) {
    return 1;
}

int omp_get_thread_num(void) {
    return 0;
}

int omp_in_parallel(void) {
    return 0;
}

int omp_get_nested(void) {
    return g_omp_nested;
}

void omp_set_nested(int nested) {
    g_omp_nested = nested ? 1 : 0;
}

void omp_set_num_threads(int num_threads) {
    g_omp_requested_threads = num_threads > 0 ? num_threads : 1;
}

void omp_init_lock(omp_lock_t* lock) {
    if (lock) {
        lock->state = 0;
    }
}

void omp_destroy_lock(omp_lock_t* lock) {
    if (lock) {
        lock->state = 0;
    }
}

void omp_set_lock(omp_lock_t* lock) {
    if (lock) {
        lock->state = 1;
    }
}

void omp_unset_lock(omp_lock_t* lock) {
    if (lock) {
        lock->state = 0;
    }
}

}
