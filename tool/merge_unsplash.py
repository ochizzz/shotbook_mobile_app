"""Turns recipe rows written for Unsplash candidates into catalog rows.

Usage: merge_unsplash.py <details.jsonl> <out_dir_with_out_N.json> <result.json>
Images stay on Unsplash (hotlinked) as the API guidelines require.
"""
import glob, json, sys

details = {}
for line in open(sys.argv[1]):
    r = json.loads(line)
    details[r['id']] = r
rows = []
for path in sorted(glob.glob(sys.argv[2] + '/out_*.json')):
    rows += json.load(open(path))
seen = set()
result = []
for x in rows:
    uid = x['unsplash_id']
    if uid in seen or uid not in details:
        continue
    seen.add(uid)
    d = details[uid]
    raw = d['urls']['raw']
    x.update(
        legacy_id='us-' + uid,
        image_url=raw + '&w=1600&q=80&fm=jpg&fit=max',
        thumb_url=raw + '&w=600&q=75&fm=jpg&fit=max',
        source_page=d['links']['html'],
        credit=d['user']['name'],
        creator_url=d['user']['links']['html'],
        license='Unsplash License',
        license_url='https://unsplash.com/license',
        source_type='curated',
        aspect_ratio=round(d['width'] / d['height'], 3),
    )
    result.append(x)
json.dump(result, open(sys.argv[3], 'w'), ensure_ascii=False, indent=1)
print(len(result))
