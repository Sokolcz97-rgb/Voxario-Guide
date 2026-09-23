import json
from pathlib import Path
from config import BUILD
root=Path(__file__).resolve().parent/'generated'
required=('zones.json','quests.json','npcs.json','items.json')
for name in required:
 path=root/name
 if not path.exists(): raise SystemExit(f'[VALIDATE] missing {path}')
 data=json.loads(path.read_text())
 if name in ('quests.json','npcs.json') and not data: raise SystemExit(f'[VALIDATE] {name} is empty')
 ids=set()
 for record in data:
  key=next((k for k in ('mapID','questID','npcID','itemID') if k in record),None)
  if key is None or not isinstance(record[key],int) or record[key] in ids: raise SystemExit(f'[VALIDATE] invalid or duplicate ID in {name}')
  ids.add(record[key])
  if record.get('sourceBuild') not in (None,BUILD): raise SystemExit(f'[VALIDATE] build mismatch in {name}')
 print(f'[VALIDATE] {name}: {len(data)} records')
coverage=root/'reports'/'quest_data_coverage.json'
if not coverage.exists(): raise SystemExit(f'[VALIDATE] missing {coverage}')
report=json.loads(coverage.read_text())
if report.get('sourceBuild') != BUILD or report.get('quests',{}).get('total') != len(json.loads((root/'quests.json').read_text())):
 raise SystemExit('[VALIDATE] coverage report does not match normalized quest data')
print('[VALIDATE] reports/quest_data_coverage.json: consistent')
print('[VALIDATE] PASS')
