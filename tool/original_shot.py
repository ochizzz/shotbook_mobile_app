"""Original shot data for a photo from its Unsplash EXIF.

`original_shot(exif)` returns {camera, focal_mm, equiv_mm, aperture,
shutter, iso}: the source numbers the app adapts to the user's phone.
The 35 mm equivalent uses the crop factor of the camera body.
"""
import re

FULL_FRAME = re.compile(
    r'EOS (5D|6D|R5|R6|R3|R8|RP|R\b|1D)|^ ?EOS R$|ILCE-7|ILCE-9|ILCE-1\b|'
    r'NIKON (D6\b|D7[05]0\b|D8\d\d\b|D600\b|D610\b|D780\b|Z ?[5-9]\b|Z ?f\b)|LEICA (M|Q|SL)', re.I)
APSC_CANON = re.compile(r'EOS (\d{2,4}D|REBEL|Rebel|M\d*|R7|R10|R50|R100|Kiss)', re.I)
MFT = re.compile(r'OLYMPUS|PANASONIC|DC-G|DMC-G|E-M\d|PEN', re.I)
# Phones: crop factor of the main camera (equivalent / physical focal length).
PHONES = [
    (re.compile(r'iPhone', re.I), 7.0),
    (re.compile(r'Pixel', re.I), 6.0),
    (re.compile(r'ONEPLUS|VOG-|HUAWEI|SM-|Galaxy', re.I), 6.0),
]


def crop_factor(make, model):
    name = f'{make or ""} {model or ""}'
    if FULL_FRAME.search(name):
        return 1.0
    if 'canon' in name.lower() and APSC_CANON.search(name):
        return 1.6
    if MFT.search(name):
        return 2.0
    for pattern, crop in PHONES:
        if pattern.search(name):
            return crop
    return 1.5  # Other APS-C: Nikon D3xxx/D5xxx/D7xxx, Sony A6xxx, Fujifilm X, Samsung NX


def camera_name(make, model):
    make = (make or '').replace('CORPORATION', '').replace('IMAGING CORP.', '').strip()
    model = (model or '').strip()
    if model.lower().startswith(make.split(' ')[0].lower()):
        return model
    return f'{make.title() if make.isupper() else make} {model}'.strip()


def original_shot(exif):
    focal = float(exif['focal_length'])
    crop = crop_factor(exif.get('make'), exif.get('model'))
    return {
        'camera': camera_name(exif.get('make'), exif.get('model')),
        'focal_mm': round(focal, 1),
        'equiv_mm': round(focal * crop),
        'aperture': float(exif['aperture']),
        'shutter': str(exif['exposure_time']),
        'iso': int(exif['iso']),
    }
