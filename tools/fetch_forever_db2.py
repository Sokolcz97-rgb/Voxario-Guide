import argparse,csv,urllib.request
from pathlib import Path
from config import BUILD
TABLES=['Map','AreaTable','QuestV2','Creature','Item','ItemSparse']
p=argparse.ArgumentParser();p.add_argument('--refresh',action='store_true');a=p.parse_args()
cache=Path(__file__).parent/'cache'/'wago'/BUILD;cache.mkdir(parents=True,exist_ok=True)
for table in TABLES:
 out=cache/(table+'.csv')
 if not out.exists() or a.refresh:
  url=f'https://wago.tools/db2/{table}/csv?build={BUILD}'
  try:
   with urllib.request.urlopen(url,timeout=30) as r: data=r.read()
  except Exception as e: print(f'[FETCH] {table}: FAILED {e}'); continue
  if not data.strip(): raise SystemExit(f'[FETCH] {table}: empty response')
  out.write_bytes(data)
 with out.open(encoding='utf-8-sig',newline='') as f: rows=list(csv.DictReader(f)); headers=rows[0].keys() if rows else []
 print(f'[FETCH] {table}.csv: {len(rows)} rows | headers: {", ".join(headers)}')
 if table in ('Map','QuestV2','Creature') and not rows: raise SystemExit(f'[FETCH] required {table} has zero rows')
