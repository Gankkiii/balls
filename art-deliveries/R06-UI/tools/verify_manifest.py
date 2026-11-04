#!/usr/bin/env python3
"""Verify an extracted R06-UI delivery without running the game."""
import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'manifest.json').read_text())
expected={r['path'] for r in data['files']}
actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and p.relative_to(root).as_posix()!='manifest.json'}
assert expected==actual,{'missing':sorted(expected-actual),'unexpected':sorted(actual-expected)}
for row in data['files']:
 rel=Path(row['path']);assert not rel.is_absolute() and '..' not in rel.parts
 p=root/rel;assert not p.is_symlink()
 b=p.read_bytes();assert len(b)==row['bytes'] and hashlib.sha256(b).hexdigest()==row['sha256'],row['path']
print('PASS files=',len(expected))
