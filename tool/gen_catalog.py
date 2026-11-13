import json,sys,itertools,collections
C=sys.argv[1]
items=json.load(open(C+'/part-a.json'))+json.load(open(C+'/part-b.json'))
# Interleave categories so the catalog reads as a varied mix.
order=['Portrait','Street','Full Body','Night','Lifestyle','Car','Couple','Product']
by=collections.defaultdict(list)
for x in items: by[x['category']].append(x)
mixed=[]
for row in itertools.zip_longest(*[by[c] for c in order]):
    mixed+= [x for x in row if x]
assert len(mixed)==100
def d(s):
    if s is None: return 'null'
    return "'"+s.replace('\\','\\\\').replace("'","\\'").replace('$','\\$').replace('\n','\\n')+"'"
def m(obj,ind):
    pad=' '*ind
    if isinstance(obj,dict):
        if not obj: return 'const {}'
        return '{\n'+''.join(f"{pad}  {d(k)}: {m(v,ind+2)},\n" for k,v in obj.items())+pad+'}'
    return d(str(obj))
out=["// GENERATED from the curated catalog (scripts: scratchpad gen_catalog.py).",
"// 100 Creative Commons photos from Flickr via Openverse, with phone recipes.",
"// The same rows are seeded into Supabase; this list is the offline fallback.",
"import '../domain/photo_reference.dart';","",
"const photoCategories = [\n  'All',\n"+''.join(f"  '{c}',\n" for c in order)+"];","",
"const seedPhotoReferences = <PhotoReference>["]
sql_rows=[]
for i,x in enumerate(mixed):
    ar=round(x['width']/x['height'],3)
    en=dict(x['en'])
    out.append(f"""  PhotoReference(
    id: {d(x['legacy_id'])},
    title: {d(x['title'])},
    description: {d(x['description'])},
    imageUrl: {d(x['image_url'])},
    thumbUrl: {d(x['thumb_url'])},
    category: {d(x['category'])},
    sourcePage: {d(x['source_page'])},
    credit: {d(x['credit'])},
    creatorUrl: {d(x.get('creator_url'))},
    license: {d(x['license'])},
    licenseUrl: {d(x.get('license_url'))},
    deviceId: {d(x['device_id'])},
    device: {d(x['device'])},
    camera: {d(x['camera'])},
    focalLength: {d(x['focal_length'])},
    iso: {d(x['iso'])},
    shutterSpeed: {d(x['shutter_speed'])},
    aperture: {d(x['aperture'])},
    whiteBalance: {d(x['white_balance'])},
    exposureCompensation: {d(x['exposure_compensation'])},
    poseData: {m(x['pose_data'],4)},
    editingData: {m(x['editing_data'],4)},
    imageAspectRatio: {ar},
    translations: {{
      'en': {m(en,6)},
    }},
  ),""")
    sql_rows.append(dict(legacy_id=x['legacy_id'],title=x['title'],description=x['description'],image_url=x['image_url'],thumb_url=x['thumb_url'],
      source_page=x['source_page'],credit=x['credit'],creator_url=x.get('creator_url'),license=x['license'],license_url=x.get('license_url'),
      category=x['category'],source_type='curated',device_id=x['device_id'],device=x['device'],camera=x['camera'],focal_length=x['focal_length'],
      iso=x['iso'],shutter_speed=x['shutter_speed'],aperture=x['aperture'],white_balance=x['white_balance'],exposure_compensation=x['exposure_compensation'],
      pose_data=x['pose_data'],editing_data=x['editing_data'],aspect_ratio=ar,translations={'en':en},sort_order=i+1))
out.append("];")
open(sys.argv[2],'w').write('\n'.join(out)+'\n')
json.dump(sql_rows,open(C+'/catalog_rows.json','w'),ensure_ascii=False)
print(collections.Counter(x['category'] for x in mixed))
