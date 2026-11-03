#!/usr/bin/env python3
"""Assemble a frozen R04 handoff snapshot. Never edits game code or publishes."""
import argparse,hashlib,json,shutil,zipfile
from pathlib import Path
from PIL import Image
import wave

def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 a=argparse.ArgumentParser();a.add_argument('--source',type=Path,required=True);a.add_argument('--destination',type=Path,required=True);a.add_argument('--zip',type=Path,required=True);args=a.parse_args()
 src=args.source.resolve();dst=args.destination.resolve();z=args.zip.resolve()
 assert src!=dst and src not in dst.parents and dst not in src.parents,'use separate, non-nested source and destination'
 assert not dst.exists(),'destination must be new; preserve previous artifacts'
 assert not z.exists(),'ZIP must be new; preserve previous artifacts'
 for p in src.rglob('*'):
  assert not p.is_symlink(),p
 shutil.copytree(src,dst,ignore=shutil.ignore_patterns('__pycache__','*.pyc','ASSET_MANIFEST.json','SHA256SUMS.txt'))
 entries=[]
 for p in sorted(dst.rglob('*')):
  if not p.is_file():continue
  path=p.relative_to(dst).as_posix();prefix=path.split('/')[0]
  category={'assets':'importable_unbound','reference':'reference_only','source':'editable_source_not_game','metadata':'technical_interface','docs':'documentation','qa':'validation_evidence'}.get(prefix,'documentation')
  e={'path':path,'category':category,'bytes':p.stat().st_size,'sha256':digest(p)}
  if p.suffix.lower() in ['.png','.gif']:
   with Image.open(p) as im:
    e.update(width=im.width,height=im.height,mode=im.mode,frames=getattr(im,'n_frames',1))
    if im.mode=='RGBA':e['alpha_bbox']=list(im.getchannel('A').getbbox() or []);e['alpha_extrema']=list(im.getchannel('A').getextrema())
  elif p.suffix.lower()=='.wav':
   with wave.open(str(p),'rb') as w:e.update(sample_rate=w.getframerate(),channels=w.getnchannels(),sample_width_bytes=w.getsampwidth(),samples=w.getnframes(),duration_s=w.getnframes()/w.getframerate())
  entries.append(e)
 manifest={'version':'R04-handoff-1','game_baseline':'d202089','review_commit':'33d13fc55256fb6ef4b7f7cf31ea75bd328b28e2','approval':'User accepted R04 revision and requested this coding handoff; no in-game/device/listening QA implied','files':entries,'self_exclusions':['ASSET_MANIFEST.json','SHA256SUMS.txt'],'coordinate_and_event_metadata':['metadata/characters.json','metadata/ui.json','metadata/audio.json']}
 (dst/'ASSET_MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 checks=[p for p in sorted(dst.rglob('*')) if p.is_file() and p.name!='SHA256SUMS.txt']
 (dst/'SHA256SUMS.txt').write_text(''.join(digest(p)+'  '+p.relative_to(dst).as_posix()+'\n' for p in checks))
 z.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(z,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as f:
  for p in sorted(dst.rglob('*')):
   if p.is_file():f.write(p,Path(dst.name)/p.relative_to(dst))
 z.with_suffix(z.suffix+'.sha256').write_text(digest(z)+'  '+z.name+'\n')
 print(json.dumps({'manifest_files':len(entries),'zip_bytes':z.stat().st_size,'zip_sha256':digest(z)}))
if __name__=='__main__':main()
