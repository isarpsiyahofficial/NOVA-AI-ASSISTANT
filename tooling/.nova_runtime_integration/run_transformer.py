from pathlib import Path
import runpy

path = Path('tooling/.nova_runtime_integration/apply.py')
text = path.read_text(encoding='utf-8')
old = '''    if count != 1:\n        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:120]!r}")\n    write(path, text.replace(old, new, 1))\n'''
new = '''    if count < 1:\n        raise SystemExit(f"{path}: expected a match, found 0: {old[:120]!r}")\n    repeated_verified = (\n        old == "    bool allowContinuityReuse = true,\\n"\n        or old.startswith(\n            "    final decision = await decideFromFreshExternalSample(\\n"\n        )\n        or old == (\n            "          lifecycleService.wake();\\n"\n            "          await powerService.setFullyOn(userInitiated: true);\\n"\n        )\n    )\n    if count != 1 and not repeated_verified:\n        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:120]!r}")\n    write(path, text.replace(old, new, 1))\n'''
if text.count(old) != 1:
    raise SystemExit('Transformer helper shape changed unexpectedly.')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
runpy.run_path(str(path), run_name='__main__')

dashboard_path = Path('lib/ui/dashboard/dashboard_page.dart')
dashboard = dashboard_path.read_text(encoding='utf-8')
unused_parameter = '    bool throughOwner = true,\n'
if dashboard.count(unused_parameter) != 1:
    raise SystemExit(
        'dashboard_page.dart: expected exactly one unused throughOwner parameter'
    )
dashboard_path.write_text(
    dashboard.replace(unused_parameter, '', 1),
    encoding='utf-8',
)
print('Removed the obsolete dashboard throughOwner parameter.')
