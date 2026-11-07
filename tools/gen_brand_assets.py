#!/usr/bin/env python3
"""Generate every raster brand asset from the frozen Wadaag lens geometry.

Source of truth: PLAN.md section 7. Two rings r=100 at x=210 and x=302 on a
512 canvas, stroke 24, lens filled foam, teal ring over amber at the top.
Never recolour, add shadows or gradients, or use the Bluetooth logo.

Run: python3 tools/gen_brand_assets.py   (needs Pillow)
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "app/android/app/src/main/res"
WIN = ROOT / "app/windows/runner/resources"
BRANDING = ROOT / "app/assets/branding"

TIDE_INK = (6, 34, 43, 255)
REEF = (13, 52, 65, 255)
LAGOON = (34, 209, 198, 255)
SUN = (255, 180, 58, 255)
FOAM = (234, 247, 246, 255)
WHITE = (255, 255, 255, 255)

# Canvas geometry (PLAN section 7).
CANVAS = 512
LEFT_R = 100
LEFT_C = (210, 256)
RIGHT_C = (302, 256)
STROKE = 24
TOP_ARC = (-74.5, -50.5)  # degrees: the teal arc that passes over amber


def _circles(draw: ImageDraw.ImageDraw, scale: float, ox: float, oy: float,
             ring_left, ring_right, stroke_color_left, stroke_color_right) -> None:
    """Draw the two rings, the interlock arc, in canvas coordinates."""
    w = max(1, round(STROKE * scale))

    def box(cx: float, cy: float) -> list[float]:
        r = LEFT_R * scale
        x = ox + cx * scale
        y = oy + cy * scale
        return [x - r, y - r, x + r, y + r]

    draw.ellipse(box(*LEFT_C), outline=stroke_color_left, width=w)
    draw.ellipse(box(*RIGHT_C), outline=stroke_color_right, width=w)
    # Teal passes over amber at the top crossing.
    r = LEFT_R * scale
    draw.arc(
        box(*LEFT_C),
        start=TOP_ARC[0],
        end=TOP_ARC[1],
        fill=stroke_color_left,
        width=w,
    )


def _lens(scale: float, ox: float, oy: float, color) -> Image.Image:
    """The overlap of the two rings, as a separate RGBA layer."""
    size = CANVAS
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    a = Image.new("L", (size, size), 0)
    b = Image.new("L", (size, size), 0)
    d_a = ImageDraw.Draw(a)
    d_b = ImageDraw.Draw(b)

    def box(cx: float, cy: float) -> list[float]:
        r = LEFT_R * scale
        x = ox + cx * scale
        y = oy + cy * scale
        return [x - r, y - r, x + r, y + r]

    d_a.ellipse(box(*LEFT_C), fill=255)
    d_b.ellipse(box(*RIGHT_C), fill=255)
    mask = Image.new("L", (size, size), 0)
    mask.paste(Image.eval(Image.merge("L", (a,)).convert("L"), lambda v: v))
    # Multiply the two masks: only where both rings cover a pixel.
    from PIL import ImageChops

    mask = ImageChops.multiply(a, b)
    layer.paste(Image.new("RGBA", (size, size), color), (0, 0), mask)
    return layer


def mark(size: int, *, background: bool = True, mono: bool = False,
         padding: float = 0.0) -> Image.Image:
    """The mark at [size] px. padding shrinks the mark inside the canvas."""
    ss = 4  # supersample for clean curves
    px = size * ss
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = (px / CANVAS) * (1.0 - padding)
    ox = (px - CANVAS * scale) / 2
    oy = (px - CANVAS * scale) / 2

    if background:
        radius = 116 * (px / CANVAS)
        draw.rounded_rectangle([0, 0, px - 1, px - 1], radius=radius,
                               fill=TIDE_INK)

    lens_color = WHITE if mono else FOAM
    ring = WHITE if mono else LAGOON
    other = WHITE if mono else SUN

    img.alpha_composite(_lens(scale, ox, oy, lens_color))
    draw = ImageDraw.Draw(img)
    _circles(draw, scale, ox, oy, None, None, ring, other)
    return img.resize((size, size), Image.LANCZOS)


def notification_icon(size: int) -> Image.Image:
    """White monochrome silhouette for the status bar (24 dp)."""
    ss = 4
    px = size * ss
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    scale = (px / CANVAS)
    ox = (px - CANVAS * scale) / 2
    oy = (px - CANVAS * scale) / 2
    img.alpha_composite(_lens(scale, ox, oy, WHITE))
    draw = ImageDraw.Draw(img)
    _circles(draw, scale, ox, oy, None, None, WHITE, WHITE)
    return img.resize((size, size), Image.LANCZOS)


def foreground(size: int) -> Image.Image:
    """Adaptive-icon foreground: rings and lens only, at 90 % of the layer."""
    ss = 4
    px = size * ss
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    scale = (px / CANVAS) * 0.62
    ox = (px - CANVAS * scale) / 2
    oy = (px - CANVAS * scale) / 2
    img.alpha_composite(_lens(scale, ox, oy, FOAM))
    draw = ImageDraw.Draw(img)
    _circles(draw, scale, ox, oy, None, None, LAGOON, SUN)
    return img.resize((size, size), Image.LANCZOS)


DENSITIES = {
    "mdpi": 1,
    "hdpi": 1.5,
    "xhdpi": 2,
    "xxhdpi": 3,
    "xxxhdpi": 4,
}


def main() -> None:
    BRANDING.mkdir(parents=True, exist_ok=True)
    WIN.mkdir(parents=True, exist_ok=True)

    for density, factor in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy = round(48 * factor)
        mark(legacy).save(folder / "ic_launcher.png")
        mark(legacy, background=False).save(folder / "ic_launcher_round.png")
        layer = round(108 * factor)
        foreground(layer).save(folder / "ic_launcher_foreground.png")
        # Themed icons need one colour: lens filled, rings stroked.
        notification_icon(layer).save(folder / "ic_launcher_monochrome.png")
        notif = round(24 * factor)
        drawable = RES / f"drawable-{density}"
        drawable.mkdir(parents=True, exist_ok=True)
        notification_icon(notif).save(drawable / "ic_stat_notify.png")

    # Android 12 splash icon (sits inside the system splash circle).
    (RES / "drawable-nodpi").mkdir(parents=True, exist_ok=True)
    mark(288, background=False).save(RES / "drawable-nodpi/splash_mark.png")

    mark(512).save(BRANDING / "mark_512.png")
    mark(1024).save(BRANDING / "mark_1024.png")

    # Windows .ico with every size the plan asks for.
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    base = mark(256)
    base.save(WIN / "app_icon.ico", format="ICO", sizes=ico_sizes)
    print("brand assets written")


if __name__ == "__main__":
    main()
