
#include <jni.h>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>
#include <cmath>
#include <algorithm>

#if NOVA_HAS_REAL_FAISS
#include "faiss/IndexFlat.h"
#endif

namespace {
std::mutex g_mutex;
long long g_next_handle = 1;

struct IndexHolder {
#if NOVA_HAS_REAL_FAISS
    std::unique_ptr<faiss::Index> index;
#endif
    std::vector<long long> ids;
    int dimension = 0;
    bool useCosine = true;
};

std::unordered_map<long long, IndexHolder> g_indices;

static void normalize(std::vector<float>& values) {
    float sum = 0.0f;
    for (float v : values) sum += v * v;
    if (sum <= 0.0f) return;
    const float inv = 1.0f / std::sqrt(sum);
    for (float& v : values) v *= inv;
}

static std::vector<float> toVector(JNIEnv* env, jfloatArray array) {
    const jsize size = env->GetArrayLength(array);
    std::vector<float> out(static_cast<size_t>(size));
    env->GetFloatArrayRegion(array, 0, size, out.data());
    return out;
}
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_nova_faiss_NovaFaissNativeBridge_nativeIsAvailable(
        JNIEnv*, jobject) {
#if NOVA_HAS_REAL_FAISS
    return JNI_TRUE;
#else
    return JNI_FALSE;
#endif
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_example_nova_faiss_NovaFaissNativeBridge_nativeCreateIndex(
        JNIEnv*, jobject, jint dimension, jboolean useCosine) {
#if !NOVA_HAS_REAL_FAISS
    return 0;
#else
    if (dimension <= 0) return 0;
    std::lock_guard<std::mutex> lock(g_mutex);
    const long long handle = g_next_handle++;
    IndexHolder holder;
    holder.dimension = dimension;
    holder.useCosine = useCosine == JNI_TRUE;
    if (holder.useCosine) {
        holder.index = std::make_unique<faiss::IndexFlatIP>(dimension);
    } else {
        holder.index = std::make_unique<faiss::IndexFlatL2>(dimension);
    }
    g_indices.emplace(handle, std::move(holder));
    return static_cast<jlong>(handle);
#endif
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_nova_faiss_NovaFaissNativeBridge_nativeReset(
        JNIEnv*, jobject, jlong handle) {
#if NOVA_HAS_REAL_FAISS
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_indices.find(static_cast<long long>(handle));
    if (it == g_indices.end()) return;
    it->second.ids.clear();
    it->second.index->reset();
#endif
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_nova_faiss_NovaFaissNativeBridge_nativeAdd(
        JNIEnv* env, jobject, jlong handle, jlong id, jfloatArray vectorArray) {
#if !NOVA_HAS_REAL_FAISS
    return JNI_FALSE;
#else
    std::vector<float> values = toVector(env, vectorArray);
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_indices.find(static_cast<long long>(handle));
    if (it == g_indices.end()) return JNI_FALSE;
    auto& holder = it->second;
    if (static_cast<int>(values.size()) != holder.dimension) return JNI_FALSE;
    if (holder.useCosine) normalize(values);
    holder.index->add(1, values.data());
    holder.ids.push_back(static_cast<long long>(id));
    return JNI_TRUE;
#endif
}

extern "C" JNIEXPORT jlongArray JNICALL
Java_com_example_nova_faiss_NovaFaissNativeBridge_nativeSearchIds(
        JNIEnv* env, jobject, jlong handle, jfloatArray queryArray, jint k) {
    jlongArray out = env->NewLongArray(std::max(0, k));
#if !NOVA_HAS_REAL_FAISS
    std::vector<jlong> empty(static_cast<size_t>(std::max(0, k)), -1);
    env->SetLongArrayRegion(out, 0, static_cast<jsize>(empty.size()), empty.data());
    return out;
#else
    std::vector<float> query = toVector(env, queryArray);
    std::vector<jlong> ids(static_cast<size_t>(std::max(0, k)), -1);
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_indices.find(static_cast<long long>(handle));
    if (it == g_indices.end()) {
        env->SetLongArrayRegion(out, 0, static_cast<jsize>(ids.size()), ids.data());
        return out;
    }
    auto& holder = it->second;
    if (static_cast<int>(query.size()) != holder.dimension || k <= 0 || holder.ids.empty()) {
        env->SetLongArrayRegion(out, 0, static_cast<jsize>(ids.size()), ids.data());
        return out;
    }
    if (holder.useCosine) normalize(query);
    std::vector<faiss::idx_t> labels(static_cast<size_t>(k), -1);
    std::vector<float> distances(static_cast<size_t>(k), -1.0f);
    holder.index->search(1, query.data(), k, distances.data(), labels.data());
    for (int i = 0; i < k; ++i) {
        const auto label = labels[static_cast<size_t>(i)];
        if (label < 0 || static_cast<size_t>(label) >= holder.ids.size()) continue;
        ids[static_cast<size_t>(i)] = static_cast<jlong>(holder.ids[static_cast<size_t>(label)]);
    }
    env->SetLongArrayRegion(out, 0, static_cast<jsize>(ids.size()), ids.data());
    return out;
#endif
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_example_nova_faiss_NovaFaissNativeBridge_nativeSearchScores(
        JNIEnv* env, jobject, jlong handle, jfloatArray queryArray, jint k) {
    jfloatArray out = env->NewFloatArray(std::max(0, k));
#if !NOVA_HAS_REAL_FAISS
    std::vector<float> empty(static_cast<size_t>(std::max(0, k)), 0.0f);
    env->SetFloatArrayRegion(out, 0, static_cast<jsize>(empty.size()), empty.data());
    return out;
#else
    std::vector<float> query = toVector(env, queryArray);
    std::vector<float> distances(static_cast<size_t>(std::max(0, k)), 0.0f);
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_indices.find(static_cast<long long>(handle));
    if (it == g_indices.end()) {
        env->SetFloatArrayRegion(out, 0, static_cast<jsize>(distances.size()), distances.data());
        return out;
    }
    auto& holder = it->second;
    if (static_cast<int>(query.size()) != holder.dimension || k <= 0 || holder.ids.empty()) {
        env->SetFloatArrayRegion(out, 0, static_cast<jsize>(distances.size()), distances.data());
        return out;
    }
    if (holder.useCosine) normalize(query);
    std::vector<faiss::idx_t> labels(static_cast<size_t>(k), -1);
    holder.index->search(1, query.data(), k, distances.data(), labels.data());
    env->SetFloatArrayRegion(out, 0, static_cast<jsize>(distances.size()), distances.data());
    return out;
#endif
}
