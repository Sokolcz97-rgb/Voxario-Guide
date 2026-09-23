import json
from pathlib import Path
root=Path(__file__).resolve().parent
build=json.loads((root/'config.json').read_text())['foreverBuild']
quests=json.loads((root/'generated'/'quests.json').read_text())
subset=sorted([q for q in quests if q.get('zoneName','').lower()=='durotar' and q.get('faction') in ('Horde',None)],key=lambda q:(q.get('minLevel',0),q['questID']))
out=root/'generated'/'reports'; (out/'routes').mkdir(parents=True,exist_ok=True)
data={'sourceBuild':build,'zone':'Durotar','faction':'Horde','quests':subset,'coverage':{'total':len(subset),'routeable':0,'needsManualVerification':len(subset)}}
for name,value in [('durotar_quests.json',data),('durotar_quest_graph.json',{'sourceBuild':build,'nodes':[q['questID'] for q in subset],'edges':[]}),('durotar_coverage.json',data['coverage']),('routes/durotar_01_10_draft.json',{'sourceBuild':build,'zone':'Durotar','steps':[]})]: (out/name).write_text(json.dumps(value,indent=2,sort_keys=True)+'\n')
