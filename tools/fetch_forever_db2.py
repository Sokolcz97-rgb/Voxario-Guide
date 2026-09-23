import argparse, csv, time
from pathlib import Path
try:
    import requests
except ImportError:
    raise SystemExit('requests is required. Run: python -m pip install -r .\\tools\\requirements.txt')
from config import BUILD

REQUIRED = ('Map', 'QuestV2', 'Creature')
OPTIONAL = ('AreaTable', 'Item', 'ItemSparse')
BASE = 'https://wago.tools/db2/{table}/csv?build={build}&locale=enUS'

def fetch(session, table, target, refresh):
    url = BASE.format(table=table, build=BUILD)
    print(f'[TEST] {table} URL: {url}')
    if target.exists() and not refresh:
        print(f'[FETCH] {table}: cached {target}')
        return True
    response = None
    for attempt in range(3):
        try:
            response = session.get(url, timeout=45)
            if response.status_code not in (429, 500, 502, 503, 504): break
            time.sleep(2 ** attempt)
        except requests.RequestException as error:
            if attempt == 2: print(f'[FETCH] {table} FAILED\n        URL: {url}\n        Error: {error}'); return False
            time.sleep(2 ** attempt)
    print(f'[TEST] HTTP status: {response.status_code}\n[TEST] Content-Type: {response.headers.get("Content-Type", "unknown")}\n[TEST] Bytes: {len(response.content)}')
    preview = response.text[:200].replace('\n', ' ')
    if response.status_code != 200 or not response.content or '<html' in preview.lower():
        print(f'[FETCH] {table} FAILED\n        HTTP {response.status_code}\n        URL: {url}\n        Response: {preview}')
        return False
    try:
        text = response.content.decode('utf-8-sig'); rows = list(csv.DictReader(text.splitlines()))
    except Exception as error:
        print(f'[FETCH] {table} FAILED\n        CSV validation: {error}'); return False
    if not rows:
        print(f'[FETCH] {table} FAILED\n        CSV has zero rows'); return False
    temporary = target.with_suffix('.csv.tmp'); temporary.write_bytes(response.content); temporary.replace(target)
    print(f'[FETCH] {table}: HTTP 200 | {len(response.content)} bytes | {len(rows)} rows | headers: {", ".join(rows[0].keys())}')
    return True

parser = argparse.ArgumentParser(); parser.add_argument('--refresh', action='store_true'); parser.add_argument('--table', choices=REQUIRED + OPTIONAL); args = parser.parse_args()
cache = Path(__file__).parent / 'cache' / 'wago' / BUILD; cache.mkdir(parents=True, exist_ok=True)
session = requests.Session(); session.headers.update({'User-Agent': 'VoxarioGuide-DB2-Downloader/0.1 (development tooling)', 'Accept': 'text/csv,text/plain,*/*'})
tables = (args.table,) if args.table else REQUIRED + OPTIONAL
for table in tables:
    success = fetch(session, table, cache / f'{table}.csv', args.refresh)
    if not success and table in REQUIRED:
        raise SystemExit('Required DB2 download failed; normalization was not started.')
