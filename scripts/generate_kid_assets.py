#!/usr/bin/env python3
"""Generate original kid-friendly raster assets for Greats of Bharatha."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "GreatsOfBharatha" / "Resources" / "Assets.xcassets"
APP_ICON = ASSETS / "AppIcon.appiconset"
STORY_SET = ASSETS / "Chapter1ShivneriStory.imageset"


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(height - 1, 1)
        draw.line(
            [(0, y), (width, y)],
            fill=(lerp(top[0], bottom[0], t), lerp(top[1], bottom[1], t), lerp(top[2], bottom[2], t)),
        )
    return image


def draw_spark(draw: ImageDraw.ImageDraw, x: int, y: int, r: int, color: tuple[int, int, int, int]) -> None:
    draw.polygon([(x, y - r), (x + r // 3, y - r // 3), (x + r, y), (x + r // 3, y + r // 3),
                  (x, y + r), (x - r // 3, y + r // 3), (x - r, y), (x - r // 3, y - r // 3)], fill=color)


def draw_fort(draw: ImageDraw.ImageDraw, scale: float, offset_y: int = 0) -> None:
    def p(x: int, y: int) -> tuple[int, int]:
        return (round(x * scale), round((y + offset_y) * scale))

    wall = (74, 48, 32, 255)
    dark = (48, 33, 27, 255)
    draw.rectangle([p(168, 430), p(856, 602)], fill=wall)
    for x in range(178, 850, 92):
        draw.rectangle([p(x, 390), p(x + 54, 438)], fill=wall)
    draw.polygon([p(120, 602), p(904, 602), p(982, 720), p(42, 720)], fill=(104, 80, 52, 255))
    for x in (232, 410, 590, 768):
        draw.rectangle([p(x, 484), p(x + 58, 602)], fill=dark)
        draw.pieslice([p(x, 452), p(x + 58, 514)], 180, 360, fill=dark)
    draw.rectangle([p(468, 492), p(558, 602)], fill=(44, 31, 25, 255))
    draw.pieslice([p(468, 448), p(558, 536)], 180, 360, fill=(44, 31, 25, 255))


def draw_people(draw: ImageDraw.ImageDraw) -> None:
    # Jijabai-inspired guardian figure, simplified and original.
    draw.ellipse((212, 410, 280, 478), fill=(95, 49, 42, 255))
    draw.polygon([(188, 470), (304, 470), (340, 640), (158, 640)], fill=(181, 57, 62, 255))
    draw.polygon([(202, 480), (278, 480), (326, 638), (242, 600)], fill=(245, 166, 35, 255))
    draw.arc((202, 384, 282, 482), 205, 345, fill=(255, 222, 143, 255), width=8)

    # Young Shivaji-inspired child figure with saffron turban.
    draw.ellipse((382, 456, 438, 512), fill=(118, 67, 45, 255))
    draw.polygon([(364, 514), (456, 514), (486, 638), (338, 638)], fill=(38, 96, 64, 255))
    draw.polygon([(372, 450), (434, 430), (456, 466), (386, 478)], fill=(239, 105, 42, 255))
    draw.rectangle((398, 428, 448, 448), fill=(245, 166, 35, 255))
    draw.line((455, 540, 532, 494), fill=(86, 54, 36, 255), width=10)
    draw.ellipse((524, 486, 548, 510), fill=(245, 208, 96, 255))


def make_story(size: tuple[int, int]) -> Image.Image:
    width, height = size
    img = gradient(size, (255, 188, 82), (229, 90, 38)).convert("RGBA")
    draw = ImageDraw.Draw(img, "RGBA")

    draw.ellipse((-120, -120, 380, 300), fill=(255, 224, 130, 95))
    draw.ellipse((width - 260, 62, width - 70, 252), fill=(255, 236, 161, 140))
    for x, y, r in [(850, 110, 22), (744, 184, 13), (122, 170, 16), (628, 92, 11)]:
        draw_spark(draw, x, y, r, (255, 247, 190, 180))

    # Hills and fort
    draw.polygon([(0, 638), (230, 388), (462, 638)], fill=(49, 104, 70, 215))
    draw.polygon([(242, 638), (572, 330), (940, 638)], fill=(38, 83, 61, 235))
    draw.polygon([(594, 638), (846, 408), (1024, 638)], fill=(31, 72, 56, 230))
    draw_fort(draw, scale=1.0, offset_y=0)

    # Open story book foreground
    draw.rounded_rectangle((88, 626, 936, 756), radius=38, fill=(255, 250, 229, 245))
    draw.polygon([(512, 630), (532, 740), (500, 740)], fill=(226, 173, 84, 255))
    draw.arc((138, 632, 488, 742), 188, 350, fill=(202, 143, 66, 175), width=5)
    draw.arc((536, 632, 886, 742), 190, 352, fill=(202, 143, 66, 175), width=5)
    draw_people(draw)

    return img.filter(ImageFilter.UnsharpMask(radius=1.1, percent=115, threshold=3))


def make_icon(size: int) -> Image.Image:
    img = gradient((1024, 1024), (255, 183, 74), (218, 77, 20)).convert("RGBA")
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((82, 84, 942, 940), radius=216, outline=(255, 238, 176, 150), width=22)
    draw.ellipse((-100, -130, 460, 390), fill=(255, 226, 126, 90))
    draw.ellipse((680, 82, 868, 270), fill=(255, 246, 184, 180))
    draw_fort(draw, scale=0.78, offset_y=160)
    draw.rounded_rectangle((236, 688, 788, 840), radius=44, fill=(255, 249, 224, 245))
    draw.polygon([(512, 690), (532, 830), (492, 830)], fill=(216, 144, 54, 255))
    for x, y, r in [(700, 242, 42), (802, 332, 26), (236, 276, 30)]:
        draw_spark(draw, x, y, r, (255, 247, 190, 220))
    return img.resize((size, size), Image.Resampling.LANCZOS)


def write_story_assets() -> None:
    STORY_SET.mkdir(parents=True, exist_ok=True)
    base = make_story((1024, 768))
    for scale, filename in [(1, "Chapter1ShivneriStory.png"), (2, "Chapter1ShivneriStory@2x.png"), (3, "Chapter1ShivneriStory@3x.png")]:
        base.resize((1024 * scale, 768 * scale), Image.Resampling.LANCZOS).save(STORY_SET / filename)
    contents = {
        "images": [
            {"idiom": "universal", "scale": "1x", "filename": "Chapter1ShivneriStory.png"},
            {"idiom": "universal", "scale": "2x", "filename": "Chapter1ShivneriStory@2x.png"},
            {"idiom": "universal", "scale": "3x", "filename": "Chapter1ShivneriStory@3x.png"},
        ],
        "info": {"version": 1, "author": "xcode"},
    }
    (STORY_SET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def write_app_icons() -> None:
    APP_ICON.mkdir(parents=True, exist_ok=True)
    icon_sizes = {
        "AppIcon-20@2x.png": 40,
        "AppIcon-20@3x.png": 60,
        "AppIcon-29@2x.png": 58,
        "AppIcon-29@3x.png": 87,
        "AppIcon-40@2x.png": 80,
        "AppIcon-40@3x.png": 120,
        "AppIcon-60@2x.png": 120,
        "AppIcon-60@3x.png": 180,
        "AppIcon-20@1x~ipad.png": 20,
        "AppIcon-20@2x~ipad.png": 40,
        "AppIcon-29@1x~ipad.png": 29,
        "AppIcon-29@2x~ipad.png": 58,
        "AppIcon-40@1x~ipad.png": 40,
        "AppIcon-40@2x~ipad.png": 80,
        "AppIcon-76@1x.png": 76,
        "AppIcon-76@2x.png": 152,
        "AppIcon-83.5@2x.png": 167,
        "AppIcon-1024@1x.png": 1024,
    }
    for filename, size in icon_sizes.items():
        make_icon(size).save(APP_ICON / filename)


def main() -> None:
    write_story_assets()
    write_app_icons()


if __name__ == "__main__":
    main()
