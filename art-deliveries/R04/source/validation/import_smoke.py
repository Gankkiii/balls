#!/usr/bin/env python3
"""Import only handoff assets in a new Godot project; does not modify the game."""
import argparse,shutil,subprocess,tempfile,json
from PIL import Image
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--package',type=Path,required=True);p.add_argument('--logs',type=Path,required=True);p.add_argument('--godot',default='godot');a=p.parse_args()
a.logs.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='balls-r04-godot-') as folder:
 d=Path(folder);shutil.copytree(a.package/'assets',d/'assets');shutil.copyfile(Path(__file__).with_name('import_smoke.gd'),d/'import_smoke.gd')
 if (a.package/'ASSET_MANIFEST.json').exists():shutil.copyfile(a.package/'ASSET_MANIFEST.json',d/'ASSET_MANIFEST.json')
 else:
  entries=[]
  for asset in sorted((d/'assets').rglob('*')):
   if not asset.is_file():continue
   item={'path':asset.relative_to(d).as_posix()}
   if asset.suffix.lower()=='.png':
    with Image.open(asset) as im:item.update(width=im.width,height=im.height)
   entries.append(item)
  (d/'ASSET_MANIFEST.json').write_text(json.dumps({'files':entries}))
 (d/'project.godot').write_text('config_version=5\n[application]\nconfig/name="R04 import smoke only"\nconfig/features=PackedStringArray("4.6", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[importer_defaults]\nwav={\n"compress/mode": 0,\n"force/8_bit": false,\n"force/mono": false,\n"force/max_rate": false,\n"edit/trim": false,\n"edit/normalize": false,\n"edit/loop_mode": 0\n}\n')
 for name,cmd in [('isolated-import.log',['--headless','--editor','--import','--quit']),('isolated-load.log',['--headless','--script','import_smoke.gd'])]:
  r=subprocess.run([a.godot,'--path',str(d),*cmd],capture_output=True,text=True);output=r.stdout+r.stderr;(a.logs/name).write_text(output)
  assert r.returncode==0,(name,r.returncode)
  assert not any(x in output for x in ['SCRIPT ERROR:','ERROR:','Parse Error:']),(name,'error in log')
  if name=='isolated-load.log':
   assert 'failures=0' in output,output
   print(output.strip())
