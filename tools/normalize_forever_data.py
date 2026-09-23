import csv,json
from pathlib import Path
from config import BUILD
root=Path(__file__).parent; cache=root/'cache'/'wago'/BUILD; out=root/'generated'
def rows(table):
 p=cache/(table+'.csv')
 if not p.exists(): raise SystemExit(f'[NORMALIZE] missing {p}; run fetch first')
 return list(csv.DictReader(p.open(encoding='utf-8-sig',newline='')))
def field(row,*names): return next((row[n] for n in names if n in row and row[n]),None)
quest=[]
for r in rows('QuestV2'):
 q=field(r,'ID','QuestID');
 if q and q.isdigit(): quest.append({'questID':int(q),'source':'wago_db2','sourceBuild':BUILD,'verification':'external_reference','clientPresent':True})
npcs=[]
for r in rows('Creature'):
 i=field(r,'ID'); name=field(r,'Name_lang','Name')
 if i and i.isdigit() and name: npcs.append({'npcID':int(i),'name':name,'source':'wago_db2','sourceBuild':BUILD,'verification':'external_reference'})
items=[]
for r in rows('Item'):
 i=field(r,'ID');
 if i and i.isdigit(): items.append({'itemID':int(i),'source':'wago_db2','sourceBuild':BUILD,'verification':'external_reference'})
for name,data in [('quests.json',quest),('npcs.json',npcs),('items.json',items)]: (out/name).write_text(json.dumps(data,indent=2)+'\n'); print(f'[NORMALIZE] {name}: {len(data)}')
if not quest or not npcs: raise SystemExit('[NORMALIZE] required normalized quest/NPC data is empty')
