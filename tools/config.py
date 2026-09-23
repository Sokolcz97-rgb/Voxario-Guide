import json
from pathlib import Path
BUILD=json.loads((Path(__file__).with_name('config.json')).read_text())['foreverBuild']
