#!/usr/bin/env python3
"""
Nova V34 static runtime integrity gate.
Runs without Flutter/Dart. It catches the exact class of issues that kept
runtime behavior unchanged: duplicate AI roots, raw AiResponse producers,
TTS without SingleBrain proof, invalid AiRequest constructor args, and missing
native proof metadata.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]

AI_REQUEST_ALLOWED = {
    'prompt', 'mode', 'internetAllowed', 'isResearchRequest',
    'isSelfLearningRequest', 'isFastResponsePriority',
    'isUserApprovedApiUsage', 'isBehaviorTeachingRequest', 'isScreenLocked',
    'requestedByVoice', 'learningModeHint', 'requestOrigin', 'userInitiated',
    'userConfirmedThisAction', 'metadata',
}

CRITICAL_RUNTIME_GRAPH_SOURCES = {
    'dashboard_voice', 'setup_voice', 'hotpath_owner', 'runtime_orchestrator',
    'local_model', 'tts_gate', 'asr_final_transcript', 'native_main_activity',
    'native_model_bridge', 'call_companion', 'reminder_runtime', 'speech_runtime',
}

NATIVE_PROOF_KEYS = {
    'nativeSuccess', 'acceptedNativeText', 'rawNativeLocalModel',
    'authoritativeLocalBrain', 'localModelAuthorityProof', 'modelUsed',
    'fromLocalModel', 'modelRequestId', 'brainDecisionId', 'finalTextSource',
    'singleBrainAuthority', 'singleBrainRequired', 'aiChainRequired',
    'localModelAuthorityProofRequired', 'tts_source',
}


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8', errors='ignore')


def iter_files(*roots: str) -> Iterable[Path]:
    for root in roots:
        p = ROOT / root
        if p.is_file():
            yield p
        elif p.exists():
            for f in p.rglob('*'):
                if f.is_file():
                    yield f


def extract_call_blocks(source: str, token: str):
    i = 0
    while True:
        idx = source.find(token, i)
        if idx < 0:
            break
        start = idx + len(token)
        depth = 1
        k = start
        in_str = None
        esc = False
        while k < len(source) and depth:
            c = source[k]
            if in_str:
                if esc:
                    esc = False
                elif c == '\\':
                    esc = True
                elif c == in_str:
                    in_str = None
            else:
                if c in ('"', "'"):
                    in_str = c
                elif c in '({[':
                    depth += 1
                elif c in ')}]':
                    depth -= 1
            k += 1
        yield idx, source[start:k - 1]
        i = max(k, idx + 1)


def top_level_named_args(block: str):
    depth = 0
    cur = ''
    parts = []
    in_str = None
    esc = False
    for c in block:
        if in_str:
            cur += c
            if esc:
                esc = False
            elif c == '\\':
                esc = True
            elif c == in_str:
                in_str = None
        else:
            if c in ('"', "'"):
                in_str = c
                cur += c
            elif c in '({[':
                depth += 1
                cur += c
            elif c in ')}]':
                depth -= 1
                cur += c
            elif c == ',' and depth == 0:
                parts.append(cur)
                cur = ''
            else:
                cur += c
    if cur.strip():
        parts.append(cur)
    out = []
    for part in parts:
        m = re.match(r'\s*([A-Za-z_]\w*)\s*:', part)
        if m:
            out.append(m.group(1))
    return out


def check_ai_request_args(errors: list[str]):
    for f in iter_files('lib'):
        if f.suffix != '.dart':
            continue
        s = f.read_text(encoding='utf-8', errors='ignore')
        for idx, block in extract_call_blocks(s, 'AiRequest('):
            bad = [name for name in top_level_named_args(block) if name not in AI_REQUEST_ALLOWED]
            if bad:
                line = s.count('\n', 0, idx) + 1
                errors.append(f'INVALID_AIREQUEST_ARGS {f.relative_to(ROOT)}:{line} {bad}')


def check_patterns(errors: list[str]):
    all_text = '\n'.join(
        f'{p.relative_to(ROOT)}\n{p.read_text(encoding="utf-8", errors="ignore")}'
        for p in iter_files('lib', 'android/app/src/main/kotlin')
        if p.suffix in {'.dart', '.kt', '.java'}
    )

    constructor_hits = []
    for f in iter_files('lib'):
        if f.suffix != '.dart':
            continue
        s = f.read_text(encoding='utf-8', errors='ignore')
        for m in re.finditer(r'\bNovaAiService\s*\(', s):
            rel = str(f.relative_to(ROOT))
            if rel not in {
                'lib/core/ai/nova_ai_service.dart',
                'lib/services/runtime/nova_runtime_graph_service.dart',
            }:
                constructor_hits.append(f'{rel}:{s.count(chr(10), 0, m.start()) + 1}')
    if constructor_hits:
        errors.append('INDEPENDENT_NOVA_AI_SERVICE_CONSTRUCTORS ' + ', '.join(constructor_hits))

    external_success = []
    for f in iter_files('lib'):
        if f.suffix != '.dart':
            continue
        rel = str(f.relative_to(ROOT))
        if rel == 'lib/core/ai/ai_response.dart':
            continue
        s = f.read_text(encoding='utf-8', errors='ignore')
        if 'AiResponse.success' in s:
            external_success.append(rel)
    if external_success:
        errors.append('EXTERNAL_AIRESPONSE_SUCCESS ' + ', '.join(external_success))

    for forbidden in ['allowOperationalSpeech: true', 'allowSecuritySpeech: true']:
        if forbidden in all_text:
            errors.append(f'FORBIDDEN_DIRECT_SPEECH_FLAG {forbidden}')

    ai_response = read('lib/core/ai/ai_response.dart')
    if 'authorityTextHash' not in ai_response or 'authorityTextMatches' not in ai_response:
        errors.append('MISSING_TEXT_BOUND_AUTHORITY_PROOF')

    sba = read('lib/services/runtime/nova_single_brain_authority_service.dart')
    for required in [
        'response.hasNativeLocalProof',
        'AiResponse.authorityTextMatches',
        "meta['singleBrainAllowed'] == true",
        "meta['singleBrainAuthority'] == true",
        "meta['tts_source'] == brainTtsSource",
        "meta['modelUsed'] == true",
    ]:
        if required not in sba:
            errors.append(f'MISSING_STRICT_SBA_SPEECH_GATE {required}')

    graph = read('lib/services/runtime/nova_runtime_graph_service.dart')
    missing_sources = sorted(src for src in CRITICAL_RUNTIME_GRAPH_SOURCES if src not in graph)
    if missing_sources:
        errors.append('MISSING_RUNTIME_GRAPH_SOURCES ' + ', '.join(missing_sources))

    main_activity = read('android/app/src/main/kotlin/com/example/nova/MainActivity.kt')
    missing_native = sorted(k for k in NATIVE_PROOF_KEYS if k not in main_activity)
    if missing_native:
        errors.append('MISSING_NATIVE_PROOF_KEYS ' + ', '.join(missing_native))
    if not any(marker in main_activity for marker in ['FINALMOBILE_SINGLE_BRAIN_RUNTIME_GRAPH_CUTOVER_V34','FINALMOBILE_SINGLE_BRAIN_RUNTIME_GRAPH_CUTOVER_V35','FINALMOBILE_SINGLE_BRAIN_RUNTIME_GRAPH_CUTOVER_V36','FINALMOBILE_SINGLE_BRAIN_RUNTIME_GRAPH_CUTOVER_V37','FINALMOBILE_SECURITY_PASSIVE_ORIENTATION_CUTOVER_V38','FINALMOBILE_SECURITY_PASSIVE_SCOPE_FIX_CUTOVER_V39']):
        errors.append('MISSING_V34_OR_NEWER_BUILD_MARKER')

    local_model = read('lib/services/local_model/local_model_service.dart')
    if 'is Map' not in local_model or 'raw string' not in local_model.lower() and 'rawString' not in local_model:
        errors.append('LOCAL_MODEL_RAW_STRING_GATE_NOT_VISIBLE')


def check_direct_tts(errors: list[str]):
    for f in iter_files('lib'):
        if f.suffix != '.dart':
            continue
        rel = str(f.relative_to(ROOT))
        if rel == 'lib/services/tts/nova_tts_service.dart':
            continue
        s = f.read_text(encoding='utf-8', errors='ignore')
        for m in re.finditer(r'\b\w*ttsService!?\.speak\s*\(', s):
            # Low-level speech runtime is allowed only because it has a local authority gate before TtsService.speak.
            if rel == 'lib/services/speech_runtime/nova_speech_runtime_service.dart':
                prefix = s[max(0, m.start() - 3500):m.start()]
                if 'authorizeSpeech' in prefix and 'SPEECH_PROVENANCE_TTS_GATE' in prefix:
                    continue
            _, block = next(extract_call_blocks(s[m.start():], s[m.start():m.end()]), (0, ''))
            if 'authorityResponse:' not in block:
                line = s.count('\n', 0, m.start()) + 1
                errors.append(f'DIRECT_TTS_WITHOUT_AUTHORITY_RESPONSE {rel}:{line}')


def main() -> int:
    errors: list[str] = []
    check_ai_request_args(errors)
    check_patterns(errors)
    check_direct_tts(errors)
    if errors:
        print('NOVA_V34_STATIC_RUNTIME_GATE FAIL')
        for err in errors:
            print('FAIL', err)
        return 1
    print('NOVA_V34_STATIC_RUNTIME_GATE PASS')
    print('checked=AiRequestArgs,SingleBrainConstructors,AiResponseFactories,TtsProofGate,RuntimeGraph,NativeProofPayload,TextBoundProof')
    return 0

if __name__ == '__main__':
    sys.exit(main())
