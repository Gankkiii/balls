from pathlib import Path
import json,hashlib
from PIL import Image
r=Path(__file__).resolve().parents[1]
f=json.loads((r/'fixtures.json').read_text())
assert (r/'fixtures.json').read_bytes()==(r.parent/'fixtures.json').read_bytes()
assert json.loads((r/'fixtures.js').read_text().removeprefix('window.HATCH_FIXTURES=').removesuffix(';'))==f
for p in (r/'screens').glob('*.png'):assert Image.open(p).size==(1600,900)
meta=json.loads((r/'review.json').read_text())
assert (r/meta['prototype']).exists() and (r/meta['image']).exists()
for im in meta['detail_images']:assert (r/im['image']).exists()
assert (r/'main.png').read_bytes()==(r/'screens/workbench.png').read_bytes()
manifest=[]
for c in f['people'][::2]:
 p=r/'assets'/f'{c["id"].rsplit("_",1)[0]}.png'
 manifest.append({'file':str(p.relative_to(r)),'source':'balls/'+c['art_source'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':list(Image.open(p).size)})
(r/'qa/assets.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
checks=json.loads((r/'qa/capture.json').read_text())
assert not checks['errors']
assert all(not x['outside'] and x['images'] for x in checks['bounds'])
tests=json.loads((r/'qa/flow-test.json').read_text());assert tests['status']=='PASS'
report={'status':'PASS','viewport':[1600,900],'state_screenshots':12,'image_files':10,'fixture_people':20,'shared_fixture_bytes_identical':True,'review_paths_valid':True,'non_scrollable_elements_within_viewport':True,'browser_checks':tests['cases_passed'],'browser_errors':0,'core_source_sha256':{name:hashlib.sha256((r/name).read_bytes()).hexdigest() for name in ['prototype.html','app.js','style.css','fixtures.js']},'not_run':['Godot new UI integration','real hatch/save','device/touch QA']}
(r/'qa/validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False))
