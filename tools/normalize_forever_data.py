"""Normalize only metadata actually present in pinned Forever DB2 CSV files."""
import csv
import json
from collections import defaultdict
from pathlib import Path

from config import BUILD

ROOT = Path(__file__).parent
CACHE = ROOT / "cache" / "wago" / BUILD
OUTPUT = ROOT / "generated"
REPORTS = OUTPUT / "reports"


def rows(table, required=True):
    path = CACHE / (table + ".csv")
    if not path.exists():
        if required:
            raise SystemExit(f"[NORMALIZE] missing {path}; run fetch first")
        return []
    with path.open(encoding="utf-8-sig", newline="") as source:
        return list(csv.DictReader(source))


def headers(table):
    path = CACHE / (table + ".csv")
    with path.open(encoding="utf-8-sig", newline="") as source:
        return csv.DictReader(source).fieldnames or []


def integer(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def nonempty(row, *names):
    return next((row[name] for name in names if row.get(name)), None)


def source(table, column):
    return f"wago_db2:{table}.{column}@{BUILD}"


def unavailable(**fields):
    return {name: "unavailable_from_db2" for name, present in fields.items() if not present}


areas = {integer(r["ID"]): r for r in rows("AreaTable") if integer(r.get("ID")) is not None}
zones = []
for r in rows("Map"):
    map_id, name = integer(r.get("ID")), nonempty(r, "MapName_lang")
    if map_id is None or not name:
        continue
    area = areas.get(integer(r.get("AreaTableID")))
    record = {
        "mapID": map_id, "name": name, "parentMapID": integer(r.get("ParentMapID")), "mapType": integer(r.get("MapType")),
        "source": "wago_db2", "sourceBuild": BUILD, "verification": "external_reference",
        "provenance": {"mapID": source("Map", "ID"), "name": source("Map", "MapName_lang"), "parentMapID": source("Map", "ParentMapID"), "mapType": source("Map", "MapType")},
    }
    if area and nonempty(area, "AreaName_lang"):
        record["areaName"] = nonempty(area, "AreaName_lang")
        record["provenance"]["areaName"] = source("AreaTable", "AreaName_lang")
    zones.append(record)


item_sparse = {integer(r["ID"]): r for r in rows("ItemSparse") if integer(r.get("ID")) is not None}
items = []
for r in rows("Item"):
    item_id = integer(r.get("ID"))
    if item_id is None:
        continue
    name = nonempty(item_sparse.get(item_id, {}), "Display_lang")
    record = {"itemID": item_id, "source": "wago_db2", "sourceBuild": BUILD, "verification": "external_reference", "provenance": {"itemID": source("Item", "ID")}}
    if name:
        record["name"] = name
        record["provenance"]["name"] = source("ItemSparse", "Display_lang")
    else:
        record["unavailableFromDB2"] = unavailable(name=False)
    items.append(record)


npcs = []
for r in rows("Creature"):
    npc_id, name = integer(r.get("ID")), nonempty(r, "Name_lang")
    if npc_id is None or not name:
        continue
    npcs.append({
        "npcID": npc_id, "name": name, "creatureType": integer(r.get("CreatureType")), "classification": integer(r.get("Classification")),
        "source": "wago_db2", "sourceBuild": BUILD, "verification": "external_reference",
        "provenance": {"npcID": source("Creature", "ID"), "name": source("Creature", "Name_lang"), "creatureType": source("Creature", "CreatureType"), "classification": source("Creature", "Classification")},
        "unavailableFromDB2": unavailable(questGiver=False, turnInNPC=False, locations=False),
    })


points = defaultdict(list)
for r in rows("QuestPOIPoint", required=False):
    blob_id = integer(r.get("QuestPOIBlobID"))
    if blob_id is not None:
        points[blob_id].append({"x": r.get("X"), "y": r.get("Y"), "z": r.get("Z")})
pois = defaultdict(list)
for r in rows("QuestPOIBlob", required=False):
    quest_id, blob_id = integer(r.get("QuestID")), integer(r.get("ID"))
    if quest_id is None or blob_id is None:
        continue
    poi = {"blobID": blob_id, "uiMapID": integer(r.get("UiMapID")), "objectiveIndex": integer(r.get("ObjectiveIndex")), "objectiveID": integer(r.get("ObjectiveID")), "pointCount": len(points[blob_id]), "provenance": {"blobID": source("QuestPOIBlob", "ID"), "uiMapID": source("QuestPOIBlob", "UiMapID"), "objectiveIndex": source("QuestPOIBlob", "ObjectiveIndex"), "objectiveID": source("QuestPOIBlob", "ObjectiveID"), "pointCount": source("QuestPOIPoint", "QuestPOIBlobID")}}
    # Raw DB2 POI values are not normalized navigation coordinates.
    if points[blob_id]:
        poi["rawPoints"] = points[blob_id]
        poi["provenance"]["rawPoints"] = source("QuestPOIPoint", "X/Y/Z")
    pois[quest_id].append(poi)


lines = {integer(r["ID"]): r for r in rows("QuestLine", required=False) if integer(r.get("ID")) is not None}
quest_lines = defaultdict(list)
for r in rows("QuestLineXQuest", required=False):
    quest_id, line_id = integer(r.get("QuestID")), integer(r.get("QuestLineID"))
    if quest_id is None or line_id is None:
        continue
    line = lines.get(line_id, {})
    quest_lines[quest_id].append({"questLineID": line_id, "name": nonempty(line, "Name_lang"), "orderIndex": integer(r.get("OrderIndex")), "provenance": {"questLineID": source("QuestLineXQuest", "QuestLineID"), "name": source("QuestLine", "Name_lang"), "orderIndex": source("QuestLineXQuest", "OrderIndex")}})


def readiness(record):
    if record.get("name") and record.get("objectives") and record.get("zoneMapID") is not None and record.get("starts") and record.get("ends") and record.get("routeCoordinates"):
        return "ROUTEABLE"
    if record.get("name") and record.get("objectives") and record.get("zoneMapID") is not None:
        return "PARTIALLY_ROUTEABLE"
    if record.get("zoneMapID") is not None:
        return "ZONE_IDENTIFIED"
    if record.get("objectives"):
        return "OBJECTIVES_AVAILABLE"
    if record.get("name"):
        return "NAMED"
    return "ID_ONLY"


quests = []
for r in rows("QuestV2"):
    quest_id = integer(r.get("ID"))
    if quest_id is None:
        continue
    quest_pois = pois[quest_id]
    map_ids = sorted({poi["uiMapID"] for poi in quest_pois if poi.get("uiMapID") is not None})
    record = {
        "questID": quest_id, "uiQuestDetailsThemeID": integer(r.get("UiQuestDetailsThemeID")), "poi": quest_pois,
        "questLines": sorted(quest_lines[quest_id], key=lambda item: (item.get("orderIndex") is None, item.get("orderIndex") or 0)),
        "source": "wago_db2", "sourceBuild": BUILD, "verification": "external_reference", "clientPresent": True,
        "provenance": {"questID": source("QuestV2", "ID"), "uiQuestDetailsThemeID": source("QuestV2", "UiQuestDetailsThemeID")},
        "unavailableFromDB2": unavailable(name=False, level=False, minLevel=False, faction=False, starts=False, ends=False, objectives=False, prerequisites=False, routeCoordinates=False),
    }
    if len(map_ids) == 1:
        record["zoneMapID"] = map_ids[0]
        record["provenance"]["zoneMapID"] = source("QuestPOIBlob", "UiMapID")
    record["routeReadiness"] = readiness(record)
    quests.append(record)


def count(records, predicate):
    return sum(1 for record in records if predicate(record))


levels = ("ID_ONLY", "NAMED", "OBJECTIVES_AVAILABLE", "ZONE_IDENTIFIED", "PARTIALLY_ROUTEABLE", "ROUTEABLE")
def region(name):
    map_ids = {record["mapID"] for record in zones if record["name"] == name or record.get("areaName") == name}
    area_ids = sorted(area_id for area_id, area in areas.items() if nonempty(area, "AreaName_lang") == name)
    linked = [record for record in quests if record.get("zoneMapID") in map_ids]
    return {"mapIDs": sorted(map_ids), "areaIDs": area_ids, "questCount": len(linked), "routeReadiness": {level: count(linked, lambda q, level=level: q["routeReadiness"] == level) for level in levels}}


coverage = {
    "sourceBuild": BUILD,
    "headers": {table: headers(table) for table in ("QuestV2", "QuestPOIBlob", "QuestPOIPoint", "QuestLine", "QuestLineXQuest", "Map", "AreaTable", "Creature", "Item", "ItemSparse")},
    "sources": {"QuestV2": "ID and UiQuestDetailsThemeID only", "QuestPOIBlob": "limited UiMapID and raw POI association", "QuestPOIPoint": "raw POI coordinates; not normalized navigation coordinates", "QuestLine": "quest-line display name", "QuestLineXQuest": "quest-line membership and order, not prerequisites", "Map": "map metadata", "AreaTable": "area names via Map.AreaTableID", "Creature": "creature names only; not quest-NPC classification", "Item": "item IDs", "ItemSparse": "item names via ID"},
    "quests": {"total": len(quests), "withNames": count(quests, lambda q: bool(q.get("name"))), "withLevel": count(quests, lambda q: q.get("level") is not None), "withMinLevel": count(quests, lambda q: q.get("minLevel") is not None), "withZone": count(quests, lambda q: q.get("zoneMapID") is not None), "withObjectives": count(quests, lambda q: bool(q.get("objectives"))), "withStartNPC": count(quests, lambda q: bool(q.get("starts"))), "withEndNPC": count(quests, lambda q: bool(q.get("ends"))), "withCoordinates": count(quests, lambda q: bool(q.get("routeCoordinates"))), "withRawPoiCoordinates": count(quests, lambda q: any(poi.get("rawPoints") for poi in q.get("poi", []))), "withQuestLine": count(quests, lambda q: bool(q.get("questLines"))), "routeReadiness": {level: count(quests, lambda q, level=level: q["routeReadiness"] == level) for level in levels}},
    "regions": {"Mulgore": region("Mulgore"), "Silverpine Forest": region("Silverpine Forest")},
    "unavailableFromDB2": ["quest name", "quest level", "quest minimum level", "quest faction", "objective type/target/count", "quest giver", "quest turn-in NPC", "quest prerequisites", "normalized route coordinates", "NPC spawn coordinates"],
}

OUTPUT.mkdir(parents=True, exist_ok=True)
REPORTS.mkdir(parents=True, exist_ok=True)
for filename, data in (("quests.json", quests), ("npcs.json", npcs), ("items.json", items), ("zones.json", zones)):
    (OUTPUT / filename).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[NORMALIZE] {filename}: {len(data)}")
(REPORTS / "quest_data_coverage.json").write_text(json.dumps(coverage, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("[NORMALIZE] reports/quest_data_coverage.json written")
if not quests or not npcs:
    raise SystemExit("[NORMALIZE] required normalized quest/NPC data is empty")
