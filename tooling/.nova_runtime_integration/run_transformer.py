from pathlib import Path
import runpy

path = Path('tooling/.nova_runtime_integration/apply.py')
text = path.read_text(encoding='utf-8')
old = '''    if count != 1:\n        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:120]!r}")\n    write(path, text.replace(old, new, 1))\n'''
new = '''    if count < 1:\n        raise SystemExit(f"{path}: expected a match, found 0: {old[:120]!r}")\n    repeated_default = old == "    bool allowContinuityReuse = true,\\n"\n    if count != 1 and not repeated_default:\n        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:120]!r}")\n    write(path, text.replace(old, new, 1))\n'''
if text.count(old) != 1:
    raise SystemExit('Transformer helper shape changed unexpectedly.')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
runpy.run_path(str(path), run_name='__main__')
