"""Package the established fort/book app emblem into native TV brand assets.

Run with Pillow. Layer artwork retains the existing brand; this script handles
catalog metadata, safe-area placement, scaling and the static Top Shelf layout.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'GreatsOfBharathaTV/Resources/TVAssets.xcassets'
BRAND = CATALOG / 'TVAppIcon.brandassets'
INFO = {'author': 'com.ganesh47.greatsofbharatha', 'version': 1}
EMBLEM = Image.open(ROOT / 'GreatsOfBharatha/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024@1x.png').convert('RGBA')
FONT = '/System/Library/Fonts/Supplemental/Georgia Bold.ttf'


def metadata(folder, value):
    folder.mkdir(parents=True, exist_ok=True)
    (folder / 'Contents.json').write_text(json.dumps(value, indent=2) + '\n')


def gradient(width, height):
    image = Image.new('RGBA', (width, height))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        factor = y / max(height - 1, 1)
        draw.line((0, y, width, y), fill=(int(21 + factor * 12), int(48 - factor * 18), int(45 - factor * 15), 255))
    return image


def foreground(width, height):
    image = Image.new('RGBA', (width, height))
    size = int(height * 0.73)
    emblem = EMBLEM.resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=size * 0.2, fill=255)
    image.paste(emblem, ((width - size) // 2, (height - size) // 2), mask)
    return image


assets = []
metadata(CATALOG, {'info': INFO})
for title, width, height, scales in [('Small', 400, 240, [1, 2]), ('Large', 1280, 768, [1])]:
    stack = BRAND / (title + '.imagestack')
    metadata(stack, {'info': INFO, 'layers': [{'filename': 'Foreground.imagestacklayer'}, {'filename': 'Background.imagestacklayer'}]})
    for name, renderer in [('Foreground', foreground), ('Background', gradient)]:
        layer = stack / (name + '.imagestacklayer')
        metadata(layer, {'info': INFO})
        image_set = layer / 'Content.imageset'
        images = []
        for scale in scales:
            filename = f'{name}@{scale}x.png'
            image_set.mkdir(parents=True, exist_ok=True)
            renderer(width * scale, height * scale).save(image_set / filename)
            images.append({'idiom': 'tv', 'filename': filename, 'scale': f'{scale}x'})
        metadata(image_set, {'info': INFO, 'images': images})
    assets.append({'idiom': 'tv', 'filename': stack.name, 'role': 'primary-app-icon', 'size': f'{width}x{height}'})

for title, width, role in [('TopShelf', 1920, 'top-shelf-image'), ('TopShelfWide', 2320, 'top-shelf-image-wide')]:
    image_set = BRAND / (title + '.imageset')
    images = []
    for scale in [1, 2]:
        height = 720
        image = gradient(width * scale, height * scale)
        emblem_size = 470 * scale
        emblem = EMBLEM.resize((emblem_size, emblem_size), Image.Resampling.LANCZOS)
        mask = Image.new('L', (emblem_size, emblem_size), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, emblem_size - 1, emblem_size - 1), radius=emblem_size * 0.2, fill=255)
        image.paste(emblem, (180 * scale, 125 * scale), mask)
        draw = ImageDraw.Draw(image)
        font = ImageFont.truetype(FONT, 72 * scale)
        small = ImageFont.truetype(FONT, 37 * scale)
        draw.text((760 * scale, 235 * scale), 'Greats of Bharatha', font=font, fill=(253, 243, 218))
        draw.text((762 * scale, 350 * scale), 'Stories. Forts. Discoveries.', font=small, fill=(250, 198, 90))
        filename = f'{title}@{scale}x.png'
        image_set.mkdir(parents=True, exist_ok=True)
        image.convert('RGB').save(image_set / filename)
        images.append({'idiom': 'tv', 'filename': filename, 'scale': f'{scale}x'})
    metadata(image_set, {'info': INFO, 'images': images})
    assets.append({'idiom': 'tv', 'filename': image_set.name, 'role': role, 'size': f'{width}x720'})
metadata(BRAND, {'info': INFO, 'assets': assets})
print('Prepared layered TV icons and standard/wide Top Shelf assets.')
