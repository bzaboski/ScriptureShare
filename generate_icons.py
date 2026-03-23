#!/usr/bin/env python3
"""
Generate Scripture Share app icons.
Design: deep navy background, open Bible with gold spine and cross.
"""
import os
from PIL import Image, ImageDraw

MASTER_SIZE = 1024
OUTPUT_DIR = "/Users/dad/developer/scriptureshare"
ICON_DIRS = [
    f"{OUTPUT_DIR}/ScriptureShare/Assets.xcassets/AppIcon.appiconset",
    f"{OUTPUT_DIR}/ScriptureShareMessages/Assets.xcassets/AppIcon.appiconset",
]

# Colors
BG         = (18,  34,  80)    # Deep navy
GOLD       = (200, 160,  70)   # Gold spine
GOLD_DARK  = (150, 115,  45)   # Darker gold
PAGE_L     = (242, 232, 205)   # Left page parchment
PAGE_R     = (228, 218, 190)   # Right page (slightly darker)
LINE_COLOR = (170, 145,  85)   # Verse line color
LINE_DARK  = (140, 118,  60)   # Darker lines
CROSS      = (18,  34,  80)    # Cross same as background (embossed look)
SHADOW     = (8,   18,  50)    # Deep shadow


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), BG)
    draw = ImageDraw.Draw(img, "RGBA")
    s = size
    cx, cy = s // 2, s // 2

    # ── Subtle top-to-bottom gradient (dark navy → slightly lighter navy) ─
    for y in range(s):
        t = y / s
        r = int(BG[0] + (35 - BG[0]) * t * 0.4)
        g = int(BG[1] + (55 - BG[1]) * t * 0.4)
        b = int(BG[2] + (110 - BG[2]) * t * 0.4)
        draw.line([(0, y), (s, y)], fill=(r, g, b))

    # ── Book geometry ──────────────────────────────────────────────────────
    bw   = int(s * 0.62)   # total book width
    bh   = int(s * 0.52)   # book height
    bx   = cx - bw // 2    # left edge of book
    by   = cy - bh // 2 - int(s * 0.02)  # top edge (slightly above center)
    sw   = int(s * 0.065)  # spine width
    scx  = cx              # spine center x

    # Drop shadow
    sh_off = int(s * 0.025)
    draw.rectangle(
        [bx + sh_off, by + sh_off, bx + bw + sh_off, by + bh + sh_off],
        fill=(*SHADOW, 200),
    )

    # Left page
    draw.rectangle([bx, by, scx - sw // 2, by + bh], fill=PAGE_L)

    # Right page
    draw.rectangle([scx + sw // 2, by, bx + bw, by + bh], fill=PAGE_R)

    # Subtle page curl — thin darker strip at inner edges
    curl_w = int(s * 0.018)
    draw.rectangle(
        [scx - sw // 2 - curl_w, by, scx - sw // 2, by + bh],
        fill=(195, 180, 148),
    )
    draw.rectangle(
        [scx + sw // 2, by, scx + sw // 2 + curl_w, by + bh],
        fill=(188, 172, 140),
    )

    # ── Verse lines — left page ────────────────────────────────────────────
    lx1  = bx + int(s * 0.06)
    lx2  = scx - sw // 2 - int(s * 0.04)
    ly   = by + int(bh * 0.18)
    lgap = int(bh * 0.105)
    lh   = max(2, int(s * 0.014))
    short_lines = {2, 5}  # indices that are short (paragraph end feel)
    for i in range(6):
        w = int((lx2 - lx1) * (0.55 if i in short_lines else 0.92))
        draw.rectangle([lx1, ly, lx1 + w, ly + lh], fill=LINE_COLOR)
        ly += lgap

    # Verse lines — right page
    rx1  = scx + sw // 2 + int(s * 0.04)
    rx2  = bx + bw - int(s * 0.06)
    ry   = by + int(bh * 0.18)
    for i in range(6):
        w = int((rx2 - rx1) * (0.48 if i in {3} else 0.90))
        draw.rectangle([rx1, ry, rx1 + w, ry + lh], fill=LINE_DARK)
        ry += lgap

    # ── Gold spine ─────────────────────────────────────────────────────────
    spine_top    = by - int(s * 0.015)
    spine_bottom = by + bh + int(s * 0.015)
    draw.rectangle(
        [scx - sw // 2, spine_top, scx + sw // 2, spine_bottom],
        fill=GOLD,
    )
    # Spine highlight (left edge)
    draw.rectangle(
        [scx - sw // 2, spine_top,
         scx - sw // 2 + max(2, int(s * 0.008)), spine_bottom],
        fill=(220, 185, 100),
    )

    # ── Cross on spine ─────────────────────────────────────────────────────
    arm  = int(s * 0.048)
    tk   = max(3, int(s * 0.02))
    ccx  = scx
    ccy  = cy - int(s * 0.03)
    # Vertical bar
    draw.rectangle([ccx - tk // 2, ccy - arm, ccx + tk // 2, ccy + arm], fill=GOLD_DARK)
    # Horizontal bar
    draw.rectangle([ccx - arm, ccy - tk // 2, ccx + arm, ccy + tk // 2], fill=GOLD_DARK)

    # ── Book top cap (headband) ────────────────────────────────────────────
    cap_h = int(s * 0.022)
    draw.rectangle(
        [scx - sw // 2 - int(s*0.008), spine_top,
         scx + sw // 2 + int(s*0.008), spine_top + cap_h],
        fill=GOLD_DARK,
    )
    draw.rectangle(
        [scx - sw // 2 - int(s*0.008), spine_bottom - cap_h,
         scx + sw // 2 + int(s*0.008), spine_bottom],
        fill=GOLD_DARK,
    )

    # ── Thin gold border frame ─────────────────────────────────────────────
    inset = int(s * 0.022)
    border_w = max(2, int(s * 0.006))
    draw.rectangle(
        [inset, inset, s - inset, s - inset],
        outline=(*GOLD, 120),
        width=border_w,
    )

    return img


def contents_json(filename: str) -> str:
    return f"""{{
  "images" : [
    {{
      "filename" : "{filename}",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "1x",
      "size" : "1024x1024"
    }}
  ],
  "info" : {{
    "author" : "xcode",
    "version" : 1
  }}
}}
"""


def main():
    img = draw_icon(MASTER_SIZE)
    for icon_dir in ICON_DIRS:
        os.makedirs(icon_dir, exist_ok=True)
        fname = "AppIcon-1024.png"
        img.save(os.path.join(icon_dir, fname), "PNG")
        with open(os.path.join(icon_dir, "Contents.json"), "w") as f:
            f.write(contents_json(fname))
        print(f"Written: {icon_dir}")
    print(f"Done — {MASTER_SIZE}x{MASTER_SIZE}")


if __name__ == "__main__":
    main()
