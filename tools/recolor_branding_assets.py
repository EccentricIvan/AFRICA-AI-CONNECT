#!/usr/bin/env python3
"""Recolor warm branding PNGs to crystal-blue (light) and emit dark variants.

Light pass: hue-shift cream/peach toward sky blue (~205°), lift whites.
Dark pass: desaturate, darken, cool navy base in transparent areas.

Usage:
  python tools/recolor_branding_assets.py [--dry-run]
"""

from __future__ import annotations

import argparse
import colorsys
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Install Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"

# (source filename, light output, dark output or None to skip dark pair)
ASSETS: list[tuple[str, str, str | None]] = [
    ("card_background_light.png", "card_background_light.png", "card_background_dark.png"),
    ("learn_background.png", "learn_background.png", "learn_background_dark.png"),
    ("market_background.png", "market_background.png", "market_background_dark.png"),
    ("chat_background.png", "chat_background.png", "chat_background_dark.png"),
    ("community_background.png", "community_background.png", "community_background_dark.png"),
    ("learn_progress_mascot.png", "learn_progress_mascot.png", None),
    # welcome_hero.png — keep original warm colors on onboarding; do not recolor
]

TARGET_HUE = 205 / 360.0  # crystal sky blue
NAVY = (16, 24, 32)  # #101820


def _rgb_to_hls(r: int, g: int, b: int) -> tuple[float, float, float]:
    return colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)


def _hls_to_rgb(h: float, l: float, s: float) -> tuple[int, int, int]:
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return int(round(r * 255)), int(round(g * 255)), int(round(b * 255))


def recolor_light_pixel(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
    if a == 0:
        return r, g, b, a

    h, l, s = _rgb_to_hls(r, g, b)

    # Preserve near-white pixels for seamless card blends.
    if l > 0.94 and s < 0.08:
        lift = min(1.0, l + 0.02)
        nr, ng, nb = _hls_to_rgb(h, lift, s * 0.5)
        return nr, ng, nb, a

    # Warm / peach tones: shift hue toward sky blue, reduce orange saturation.
    if 0.02 <= h <= 0.18 or s > 0.12:
        new_h = TARGET_HUE + (h - TARGET_HUE) * 0.15
        new_s = s * 0.55
        new_l = min(1.0, l * 1.06 + 0.04)
        nr, ng, nb = _hls_to_rgb(new_h, new_l, new_s)
        return nr, ng, nb, a

    # Cool shadows: nudge slightly bluer, lighter.
    new_h = TARGET_HUE + (h - TARGET_HUE) * 0.35
    new_s = s * 0.75
    new_l = min(1.0, l * 1.04)
    nr, ng, nb = _hls_to_rgb(new_h, new_l, new_s)
    return nr, ng, nb, a


def recolor_dark_pixel(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
    if a == 0:
        return NAVY[0], NAVY[1], NAVY[2], 255

    h, l, s = _rgb_to_hls(r, g, b)
    new_s = s * 0.80
    new_l = max(0.08, l * 0.42)
    new_h = TARGET_HUE + (h - TARGET_HUE) * 0.25
    nr, ng, nb = _hls_to_rgb(new_h, new_l, new_s)

    # Blend toward navy for very dark regions.
    blend = max(0.0, 0.55 - new_l)
    nr = int(nr * (1 - blend) + NAVY[0] * blend)
    ng = int(ng * (1 - blend) + NAVY[1] * blend)
    nb = int(nb * (1 - blend) + NAVY[2] * blend)
    return nr, ng, nb, a


def process_image(src: Path, light_out: Path, dark_out: Path | None, dry_run: bool) -> None:
    if not src.is_file():
        print(f"SKIP missing: {src}")
        return

    img = Image.open(src).convert("RGBA")
    light_px = img.load()
    light_img = Image.new("RGBA", img.size)
    light_load = light_img.load()

    for y in range(img.height):
        for x in range(img.width):
            light_load[x, y] = recolor_light_pixel(*light_px[x, y])

    if not dry_run:
        light_out.parent.mkdir(parents=True, exist_ok=True)
        light_img.save(light_out, optimize=True)
    print(f"light: {src.name} -> {light_out.name}")

    if dark_out is None:
        return

    dark_img = Image.new("RGBA", img.size)
    dark_load = dark_img.load()
    for y in range(light_img.height):
        for x in range(light_img.width):
            dark_load[x, y] = recolor_dark_pixel(*light_load[x, y])

    if not dry_run:
        dark_img.save(dark_out, optimize=True)
    print(f"dark:  {src.name} -> {dark_out.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    for src_name, light_name, dark_name in ASSETS:
        src = BRANDING / src_name
        light_out = BRANDING / light_name
        dark_out = BRANDING / dark_name if dark_name else None
        process_image(src, light_out, dark_out, args.dry_run)

    print("Done.")


if __name__ == "__main__":
    main()
