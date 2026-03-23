#!/usr/bin/env python3
"""
Generate the iMessage App Icon asset set for ScriptureShareMessages.
iMessage extension icons are landscape (wider than tall) for the app drawer.
"""
import os, json
from PIL import Image, ImageDraw

OUTPUT = "/Users/dad/developer/scriptureshare/ScriptureShareMessages/Assets.xcassets/iMessage App Icon.stickersiconset"

BG       = (18,  34,  80)
GOLD     = (200, 160,  70)
GOLD_D   = (150, 115,  45)
PAGE_L   = (242, 232, 205)
PAGE_R   = (228, 218, 190)
LINE_C   = (170, 145,  85)
SHADOW   = (8,   18,  50)

# (name, width_px, height_px)
SIZES = [
    # Landscape — Messages app drawer
    ("icon-27x20@2x.png",   54,  40),
    ("icon-27x20@3x.png",   81,  60),
    ("icon-32x24@2x.png",   64,  48),
    ("icon-32x24@3x.png",   96,  72),
    ("icon-67x50@2x.png",  134, 100),
    ("icon-74x55@2x.png",  148, 110),
    # Square — Settings
    ("icon-29x29@2x.png",   58,  58),
    ("icon-29x29@3x.png",   87,  87),
    # App Store landscape
    ("icon-1024x768@1x.png", 1024, 768),
]

CONTENTS = {
    "images": [
        {"filename": "icon-27x20@2x.png",   "idiom": "iphone", "scale": "2x", "size": "27x20"},
        {"filename": "icon-27x20@3x.png",   "idiom": "iphone", "scale": "3x", "size": "27x20"},
        {"filename": "icon-27x20@2x.png",   "idiom": "ipad",   "scale": "1x", "size": "27x20"},
        {"filename": "icon-67x50@2x.png",   "idiom": "ipad",   "scale": "2x", "size": "67x50"},
        {"filename": "icon-32x24@2x.png",   "idiom": "iphone", "scale": "2x", "size": "32x24"},
        {"filename": "icon-32x24@3x.png",   "idiom": "iphone", "scale": "3x", "size": "32x24"},
        {"filename": "icon-32x24@2x.png",   "idiom": "ipad",   "scale": "1x", "size": "32x24"},
        {"filename": "icon-74x55@2x.png",   "idiom": "ipad",   "scale": "2x", "size": "74x55"},
        {"filename": "icon-29x29@2x.png",   "idiom": "iphone", "scale": "2x", "size": "29x29"},
        {"filename": "icon-29x29@3x.png",   "idiom": "iphone", "scale": "3x", "size": "29x29"},
        {"filename": "icon-29x29@2x.png",   "idiom": "ipad",   "scale": "2x", "size": "29x29"},
        {"filename": "icon-1024x768@1x.png","idiom": "ios-marketing","scale": "1x","size": "1024x768"},
    ],
    "info": {"author": "xcode", "version": 1},
    "properties": {"pre-rendered": True},
}


def draw_landscape(w: int, h: int) -> Image.Image:
    img = Image.new("RGB", (w, h), BG)
    draw = ImageDraw.Draw(img)

    # Gradient bg
    for y in range(h):
        t = y / h
        r = int(BG[0] + 17 * t)
        g = int(BG[1] + 21 * t)
        b = int(BG[2] + 30 * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # Book — occupies ~70% width, ~72% height, centered
    bw  = int(w * 0.70)
    bh  = int(h * 0.72)
    bx  = (w - bw) // 2
    by  = (h - bh) // 2
    sw  = max(2, int(bw * 0.10))  # spine width
    scx = w // 2

    # Shadow
    so = max(1, int(h * 0.04))
    draw.rectangle([bx + so, by + so, bx + bw + so, by + bh + so], fill=(*SHADOW, 180))

    # Pages
    draw.rectangle([bx, by, scx - sw // 2, by + bh], fill=PAGE_L)
    draw.rectangle([scx + sw // 2, by, bx + bw, by + bh], fill=PAGE_R)

    # Spine
    draw.rectangle([scx - sw // 2, by - max(1, int(h*0.02)),
                    scx + sw // 2, by + bh + max(1, int(h*0.02))], fill=GOLD)

    # Cross on spine (only if large enough)
    if w >= 54:
        arm = max(1, int(sw * 0.55))
        tk  = max(1, int(sw * 0.22))
        ccy = by + bh // 2
        draw.rectangle([scx - tk//2, ccy - arm, scx + tk//2, ccy + arm], fill=GOLD_D)
        draw.rectangle([scx - arm, ccy - tk//2, scx + arm, ccy + tk//2], fill=GOLD_D)

    # Line marks on pages (only if large enough)
    if w >= 64:
        lx1 = bx + max(2, int(bw * 0.07))
        lx2 = scx - sw // 2 - max(1, int(bw * 0.03))
        ly  = by + int(bh * 0.22)
        lg  = max(2, int(bh * 0.12))
        lh  = max(1, int(bh * 0.07))
        for i in range(4):
            ww = int((lx2 - lx1) * (0.55 if i == 2 else 0.88))
            draw.rectangle([lx1, ly, lx1 + ww, ly + lh], fill=LINE_C)
            ly += lg

    return img


def draw_square(s: int) -> Image.Image:
    """Square icon for Settings."""
    img = Image.new("RGB", (s, s), BG)
    draw = ImageDraw.Draw(img)
    for y in range(s):
        t = y / s
        draw.line([(0, y), (s, y)],
                  fill=(int(BG[0]+17*t), int(BG[1]+21*t), int(BG[2]+30*t)))

    bw = int(s * 0.68)
    bh = int(s * 0.58)
    bx = (s - bw) // 2
    by = (s - bh) // 2
    sw = max(2, int(bw * 0.10))
    scx = s // 2

    draw.rectangle([bx+2, by+2, bx+bw+2, by+bh+2], fill=(*SHADOW, 160))
    draw.rectangle([bx, by, scx-sw//2, by+bh], fill=PAGE_L)
    draw.rectangle([scx+sw//2, by, bx+bw, by+bh], fill=PAGE_R)
    draw.rectangle([scx-sw//2, by, scx+sw//2, by+bh], fill=GOLD)

    arm = max(1, int(sw * 0.55))
    tk  = max(1, int(sw * 0.22))
    ccy = by + bh // 2
    draw.rectangle([scx-tk//2, ccy-arm, scx+tk//2, ccy+arm], fill=GOLD_D)
    draw.rectangle([scx-arm, ccy-tk//2, scx+arm, ccy+tk//2], fill=GOLD_D)
    return img


def main():
    os.makedirs(OUTPUT, exist_ok=True)

    for fname, w, h in SIZES:
        if w == h:
            img = draw_square(w)
        else:
            img = draw_landscape(w, h)
        img.save(os.path.join(OUTPUT, fname), "PNG")

    with open(os.path.join(OUTPUT, "Contents.json"), "w") as f:
        json.dump(CONTENTS, f, indent=2)

    print(f"Written {len(SIZES)} icons to:\n  {OUTPUT}")


if __name__ == "__main__":
    main()
