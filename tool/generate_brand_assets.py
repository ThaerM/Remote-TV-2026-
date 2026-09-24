#!/usr/bin/env python3
"""Generates every Remote TV 2026 icon and launch asset from one drawing.

The mark is a TV outline with Wi-Fi control arcs inside it, filled with the
brand gradient (control blue -> glow cyan -> signal green, the same tokens as
lib/core/design/app_colors.dart) on a dark graphite background. No text, no
manufacturer logos.

    pip install pillow
    python3 tool/generate_brand_assets.py

Outputs (overwritten):
  assets/branding/app_icon_master_1024.png     App Store master (no alpha)
  assets/branding/play_store_icon_512.png      Google Play listing icon
  assets/branding/play_feature_graphic_1024x500.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png
  android/app/src/main/res/mipmap-*/ic_launcher*.png
  android/app/src/main/res/drawable-*/splash_mark.png
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SS = 4  # supersampling factor for anti-aliased edges

BLUE = (0x5B, 0x8C, 0xFF)
CYAN = (0x4F, 0xD1, 0xFF)
GREEN = (0x3D, 0xDC, 0x97)
GRAPHITE_TOP = (0x1E, 0x22, 0x29)
GRAPHITE_BOTTOM = (0x0A, 0x0B, 0x0D)
LAUNCH_BACKGROUND = (0x0A, 0x0B, 0x0D)  # AppColors.darkBackground


def _lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def mark_mask(size: int, mark_width: float) -> Image.Image:
    """White-on-black mask of the mark, centred, [mark_width] px wide."""
    s = size * SS
    u = mark_width * SS / 560.0  # design units: the TV is 560 wide
    cx, cy = s / 2, s / 2 - 10 * u
    img = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(img)

    tv_w, tv_h, stroke = 560 * u, 380 * u, 46 * u
    left, top = cx - tv_w / 2, cy - tv_h / 2 - 20 * u
    d.rounded_rectangle(
        (left, top, left + tv_w, top + tv_h),
        radius=64 * u,
        outline=255,
        width=round(stroke),
    )
    # Stand.
    stand_w, stand_h = 210 * u, 40 * u
    stand_top = top + tv_h + 36 * u
    d.rounded_rectangle(
        (cx - stand_w / 2, stand_top, cx + stand_w / 2, stand_top + stand_h),
        radius=stand_h / 2,
        fill=255,
    )
    # Wi-Fi control arcs inside the screen, rising from a dot.
    dot_cy = top + tv_h - 104 * u
    dot_r = 32 * u
    d.ellipse((cx - dot_r, dot_cy - dot_r, cx + dot_r, dot_cy + dot_r), fill=255)
    arc_w = round(40 * u)
    for r in (96 * u, 176 * u):
        d.arc(
            (cx - r, dot_cy - r, cx + r, dot_cy + r),
            start=222,
            end=318,
            fill=255,
            width=arc_w,
        )
    return img


def gradient(size: int) -> Image.Image:
    """Diagonal blue -> cyan -> green fill."""
    s = size * SS
    small = 256
    g = Image.new("RGB", (small, small))
    px = g.load()
    for y in range(small):
        for x in range(small):
            # Stretched so the full blue -> green range spans the mark
            # itself, not the whole canvas.
            t = min(1.0, max(0.0, ((x + y) / (2 * (small - 1)) - 0.22) / 0.56))
            px[x, y] = _lerp(BLUE, CYAN, t / 0.5) if t < 0.5 else _lerp(
                CYAN, GREEN, (t - 0.5) / 0.5
            )
    return g.resize((s, s), Image.BICUBIC)


def graphite_background(size: int) -> Image.Image:
    s = size * SS
    small = 256
    bg = Image.new("RGB", (small, small))
    px = bg.load()
    for y in range(small):
        c = _lerp(GRAPHITE_TOP, GRAPHITE_BOTTOM, y / (small - 1))
        for x in range(small):
            px[x, y] = c
    bg = bg.resize((s, s), Image.BICUBIC)
    # Soft cyan glow behind the mark, like the Welcome screen.
    glow = Image.new("L", (s, s), 0)
    gd = ImageDraw.Draw(glow)
    r = s * 0.34
    gd.ellipse((s / 2 - r, s / 2 - r, s / 2 + r, s / 2 + r), fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(s * 0.12))
    bg = Image.composite(Image.new("RGB", (s, s), CYAN), bg, glow)
    return bg


def compose(size: int, mark_width: float, background: bool) -> Image.Image:
    mask = mark_mask(size, mark_width)
    fill = gradient(size)
    if background:
        base = graphite_background(size).convert("RGBA")
    else:
        base = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    layer = fill.convert("RGBA")
    layer.putalpha(mask)
    out = Image.alpha_composite(base, layer)
    return out.resize((size, size), Image.LANCZOS)


def rounded(img: Image.Image, radius_ratio: float) -> Image.Image:
    size = img.width
    mask = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * SS - 1, size * SS - 1),
        radius=size * SS * radius_ratio,
        fill=255,
    )
    mask = mask.resize((size, size), Image.LANCZOS)
    out = img.convert("RGBA")
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print(f"wrote {path.relative_to(ROOT)} {img.size[0]}x{img.size[1]}")


def main() -> None:
    # Full-bleed square icon; iOS applies its own mask. The mark fills ~62%.
    master = compose(1024, 1024 * 0.62, background=True).convert("RGB")
    save(master, ROOT / "assets/branding/app_icon_master_1024.png")
    save(
        master.resize((512, 512), Image.LANCZOS),
        ROOT / "assets/branding/play_store_icon_512.png",
    )
    # Play feature graphic: the mark centred on a wide graphite banner.
    banner = graphite_background(1024).resize((1024, 1024), Image.LANCZOS)
    banner = banner.crop((0, 262, 1024, 762))
    mark = compose(420, 420 * 0.9, background=False)
    banner.paste(mark, ((1024 - 420) // 2, (500 - 420) // 2), mark)
    save(banner, ROOT / "assets/branding/play_feature_graphic_1024x500.png")

    # iOS AppIcon set: every size listed in Contents.json, from the master.
    icon_set = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((icon_set / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        px = round(points * float(image["scale"].rstrip("x")))
        save(master.resize((px, px), Image.LANCZOS), icon_set / image["filename"])

    # Android. Adaptive icons are 108dp with a 66dp safe zone: the mark stays
    # inside the safe zone so every launcher mask (circle, squircle) keeps it.
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    res = ROOT / "android/app/src/main/res"
    for name, scale in densities.items():
        adaptive = round(108 * scale)
        save(
            compose(adaptive, adaptive * 0.46, background=False),
            res / f"mipmap-{name}/ic_launcher_foreground.png",
        )
        bg = graphite_background(adaptive).resize((adaptive, adaptive), Image.LANCZOS)
        save(bg, res / f"mipmap-{name}/ic_launcher_background.png")
        mono_mask = mark_mask(adaptive, adaptive * 0.46).resize(
            (adaptive, adaptive), Image.LANCZOS
        )
        mono = Image.new("RGBA", (adaptive, adaptive), (255, 255, 255, 0))
        mono.putalpha(mono_mask)
        save(mono, res / f"mipmap-{name}/ic_launcher_monochrome.png")
        legacy = round(48 * scale)
        save(
            rounded(compose(legacy, legacy * 0.62, background=True), 0.22),
            res / f"mipmap-{name}/ic_launcher.png",
        )
        # Pre-Android-12 launch screen: the mark alone on the dark window.
        splash = round(96 * scale)
        save(
            compose(splash, splash * 0.92, background=False),
            res / f"drawable-{name}/splash_mark.png",
        )

    # iOS launch screen image (storyboard centres it on a dark background).
    launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for suffix, scale in (("", 1), ("@2x", 2), ("@3x", 3)):
        px = round(96 * scale)
        save(compose(px, px * 0.92, background=False), launch / f"LaunchImage{suffix}.png")


if __name__ == "__main__":
    main()
