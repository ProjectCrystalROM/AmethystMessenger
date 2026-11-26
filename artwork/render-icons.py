#!/usr/bin/env python3
"""Render GTK2 PNGs and uncompressed Windows ICOs from the amethyst master."""
import base64
import io
from pathlib import Path
import struct

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PIXMAPS = ROOT / "pidgin/pixmaps"
MASTER = Image.open(ROOT / "artwork/amethyst.png").convert("RGBA")
MASTER = MASTER.crop(MASTER.getbbox())


def gemstone(size):
    image = Image.new("RGBA", (size, size))
    gem = MASTER.copy()
    gem.thumbnail((round(size * .94), round(size * .94)), Image.Resampling.LANCZOS)
    image.alpha_composite(gem, ((size - gem.width) // 2, (size - gem.height) // 2))
    return image


def ico(path, frames):
    directory = bytearray(struct.pack("<HHH", 0, 1, len(frames)))
    payload = bytearray()
    for image, depth in frames:
        size = image.width
        pixel_data = image if depth == 32 else image.convert("RGB").quantize(
            colors=2**depth, dither=Image.Dither.NONE)
        buffer = io.BytesIO()
        pixel_data.save(buffer, format="BMP")
        dib = bytearray(buffer.getvalue()[14:])
        struct.pack_into("<i", dib, 8, size * 2)
        if depth == 4:
            palette = dib[40:104]
            pixels = dib[struct.unpack_from("<I", buffer.getvalue(), 10)[0] - 14:]
            stride = (size + 3) // 4 * 4
            indexed = bytearray()
            for row in range(size):
                line = pixels[row * stride:row * stride + size]
                indexed.extend(bytes([(line[i] << 4) | line[i + 1]
                                      for i in range(0, size, 2)]))
            dib = dib[:40] + palette + indexed
            struct.pack_into("<H", dib, 14, 4)
            struct.pack_into("<II", dib, 32, 16, 16)
            struct.pack_into("<I", dib, 20, len(indexed))

        mask_stride = ((size + 31) // 32) * 4
        mask = bytearray(mask_stride * size)
        alpha = image.getchannel("A")
        for row in range(size):
            for col in range(size):
                if alpha.getpixel((col, size - 1 - row)) < (16 if depth == 32 else 128):
                    mask[row * mask_stride + col // 8] |= 128 >> (col % 8)

        offset = 6 + 16 * len(frames) + len(payload)
        directory.extend(struct.pack("<BBBBHHII", size % 256, size % 256,
                                     16 if depth == 4 else 0, 0, 1, depth,
                                     len(dib) + len(mask), offset))
        payload.extend(dib + mask)
    path.write_bytes(directory + payload)


def status_icon(size, state):
    image = gemstone(size)
    colors = {
        "available": "#5ccc5e", "away": "#ffd051", "busy": "#ed5f58",
        "connect": "#5ac7ed", "email": "#ffdc85", "invisible": "#b9a4d8",
        "offline": "#a4a1ab", "pending": "#6cd8fc", "xa": "#ee9c4d",
    }
    width = max(5, round(size * .34))
    start = size - width
    draw = ImageDraw.Draw(image)
    draw.ellipse((start, start, size - 1, size - 1), fill=colors[state],
                 outline="#37224d", width=max(1, size // 24))
    return image


for path in (PIXMAPS / "icons").rglob("amethyst.png"):
    gemstone(Image.open(path).width).save(path)

svg_image = io.BytesIO()
gemstone(128).save(svg_image, format="PNG")
data = base64.b64encode(svg_image.getvalue()).decode("ascii")
for path in (PIXMAPS / "icons").rglob("amethyst.svg"):
    path.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'viewBox="0 0 128 128"><image width="128" height="128" '
        f'xlink:href="data:image/png;base64,{data}"/></svg>\n'
    )

for name in ("logo.png", "logo-nonvv.png"):
    gemstone(108).save(PIXMAPS / name)
(PIXMAPS / "logo.svg").write_bytes(
    (PIXMAPS / "icons/hicolor/scalable/apps/amethyst.svg").read_bytes()
)

for path in (PIXMAPS / "tray").rglob("pidgin-tray-*.png"):
    status_icon(Image.open(path).width, path.stem.removeprefix("pidgin-tray-")).save(path)

old_status_names = {"connecting": "connect", "extended-away": "xa", "message": "pending"}
for path in (PIXMAPS / "tray/16").glob("*_4bit.ico"):
    name = path.name.removesuffix("_4bit.ico")
    ico(path, [(status_icon(16, old_status_names.get(name, name)), 4)])

app_frames = [(gemstone(size), depth) for size in (16, 24, 32, 48, 64, 128)
              for depth in ((32, 8) if size <= 48 else (32,))]
ico(PIXMAPS / "pidgin.ico", app_frames)
nsis_pixmaps = ROOT / "pidgin/win32/nsis/pixmaps"
for path in nsis_pixmaps.glob("pidgin-*.ico"):
    ico(path, app_frames)

for name in ("pidgin-header.bmp", "pidgin-intro.bmp"):
    path = nsis_pixmaps / name
    width, height = Image.open(path).size
    canvas = Image.new("RGB", (width, height), "#f5effb")
    gem = gemstone(round(min(width, height) * .70))
    canvas.paste(gem, (width - gem.width - 8, (height - gem.height) // 2), gem)
    canvas.save(path)
