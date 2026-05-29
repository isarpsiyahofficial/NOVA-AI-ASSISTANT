from __future__ import annotations
import json
from pathlib import Path
repo = Path(__file__).resolve().parents[2]
out_dir = repo / 'offline_corpus_json'
targets = json.loads((Path(__file__).resolve().with_name('nova_requested_targets_v26.json')).read_text(encoding='utf-8'))
rows = {}
for domain, target in targets.items():
    path = out_dir / f'{domain}.jsonl'
    actual = 0
    if path.exists():
        with path.open('r', encoding='utf-8') as f:
            actual = sum(1 for line in f if line.strip())
    rows[domain] = {'target': target, 'actual': actual, 'met_target': actual >= target}
print(json.dumps({'domains': rows}, ensure_ascii=False, indent=2))
