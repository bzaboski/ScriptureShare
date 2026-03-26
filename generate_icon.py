"""
Scripture Share — App Icon Generator
Draws the 1024×1024 master icon and exports all iOS asset catalog sizes.

Usage:  python3 generate_icon.py
Output: ScriptureShare/Assets.xcassets/AppIcon.appiconset/
"""

import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ── Canvas ────────────────────────────────────────────────────────────────────
SIZE   = 1024
CANVAS = SIZE

# ── Colour palette ────────────────────────────────────────────────────────────
BG_TOP        = (10,  25,  80)     # deep navy
BG_BOT        = (4,   10,  35)     # near-black blue
GOLD_LIGHT    = (255, 235, 100)
GOLD_MID      = (212, 168,  20)
GOLD_DARK     = (160, 110,   5)
GOLD_EDGE     = (100,  65,   0)
BIBLE_COVER   = (90,  45,  10)     # dark leather brown
BIBLE_SPINE   = (60,  28,   5)
BIBLE_PAGE    = (245, 238, 215)    # aged cream
BIBLE_SHADOW  = (30,  15,   5)
GLOW_COLOR    = (255, 220,  60)
RAY_COLOR     = (255, 240, 130)

FONT_BOLD  = "/System/Library/Fonts/Supplemental/Georgia.ttf"
FONT_REG   = "/System/Library/Fonts/Supplemental/Georgia.ttf"


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def make_gradient(size, top, bottom):
    img = Image.new("RGBA", (size, size))
    px  = img.load()
    for y in range(size):
        t = y / (size - 1)
        c = lerp_color(top, bottom, t)
        for x in range(size):
            px[x, y] = c + (255,)
    return img

def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask

def draw_glow_ellipse(layer, cx, cy, rx, ry, color, alpha_max=180, steps=18):
    d = ImageDraw.Draw(layer)
    for i in range(steps, 0, -1):
        t     = i / steps
        a     = int(alpha_max * (1 - t) * (1 - t))
        ex    = int(rx * t * 2.2)
        ey    = int(ry * t * 2.2)
        d.ellipse([cx - ex, cy - ey, cx + ex, cy + ey],
                  fill=color + (a,))


# ─────────────────────────────────────────────────────────────────────────────
# Layer 1 — Background gradient
# ─────────────────────────────────────────────────────────────────────────────

def draw_background(canvas):
    bg = make_gradient(SIZE, BG_TOP, BG_BOT)
    canvas.paste(bg, (0, 0))

    # Subtle radial vignette brightening at centre top
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    g    = ImageDraw.Draw(glow)
    for r in range(350, 0, -10):
        t = 1 - r / 350
        a = int(30 * t * t)
        g.ellipse([SIZE//2 - r, 80 - r//2, SIZE//2 + r, 80 + r], fill=(80, 120, 220, a))
    canvas.alpha_composite(glow)


# ─────────────────────────────────────────────────────────────────────────────
# Layer 2 — Light rays behind cross
# ─────────────────────────────────────────────────────────────────────────────

def draw_rays(canvas, cx, cy):
    ray_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(ray_layer)
    num_rays = 16
    for i in range(num_rays):
        angle    = math.radians(i * (360 / num_rays))
        spread   = math.radians(6)
        length   = SIZE * 0.72
        ax       = cx + math.cos(angle - spread) * 18
        ay       = cy + math.sin(angle - spread) * 18
        bx       = cx + math.cos(angle + spread) * 18
        by       = cy + math.sin(angle + spread) * 18
        tip_x    = cx + math.cos(angle) * length
        tip_y    = cy + math.sin(angle) * length
        poly     = [(int(ax), int(ay)), (int(bx), int(by)), (int(tip_x), int(tip_y))]
        d.polygon(poly, fill=RAY_COLOR + (18,))
    ray_layer = ray_layer.filter(ImageFilter.GaussianBlur(radius=14))
    canvas.alpha_composite(ray_layer)


# ─────────────────────────────────────────────────────────────────────────────
# Layer 3 — Bible book
# ─────────────────────────────────────────────────────────────────────────────

def draw_bible(canvas):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d     = ImageDraw.Draw(layer)

    # Book sits centre-bottom, slightly large so cross overlaps it well
    bx, by  = 200, 440    # top-left of book body
    bw, bh  = 624, 460    # width, height
    spine_w = 28
    page_in = 12          # page inset from cover edge

    # Drop shadow
    for sh in range(18, 0, -3):
        a = int(160 * (1 - sh / 18))
        d.rounded_rectangle(
            [bx + sh, by + sh, bx + bw + sh, by + bh + sh],
            radius=18, fill=BIBLE_SHADOW + (a,)
        )

    # Back cover
    d.rounded_rectangle([bx, by, bx + bw, by + bh], radius=16,
                         fill=BIBLE_COVER + (255,))

    # Spine
    d.rounded_rectangle([bx + bw // 2 - spine_w // 2, by,
                          bx + bw // 2 + spine_w // 2, by + bh],
                         radius=6, fill=BIBLE_SPINE + (255,))

    # Left page (slightly tilted feel via trapezoid)
    lp = [
        (bx + page_in,           by + page_in),
        (bx + bw // 2 - 2,       by + page_in),
        (bx + bw // 2 - 2,       by + bh - page_in),
        (bx + page_in,           by + bh - page_in),
    ]
    d.polygon(lp, fill=BIBLE_PAGE + (245,))

    # Right page
    rp = [
        (bx + bw // 2 + 2,       by + page_in),
        (bx + bw - page_in,      by + page_in),
        (bx + bw - page_in,      by + bh - page_in),
        (bx + bw // 2 + 2,       by + bh - page_in),
    ]
    d.polygon(rp, fill=BIBLE_PAGE + (245,))

    # Text lines on pages
    line_color = (160, 145, 110, 130)
    line_x0_l  = bx + page_in + 20
    line_x1_l  = bx + bw // 2 - 16
    line_x0_r  = bx + bw // 2 + 16
    line_x1_r  = bx + bw - page_in - 20
    for row in range(10):
        ly = by + page_in + 34 + row * 34
        if ly > by + bh - page_in - 20:
            break
        d.line([(line_x0_l, ly), (line_x1_l, ly)], fill=line_color, width=4)
        d.line([(line_x0_r, ly), (line_x1_r, ly)], fill=line_color, width=4)

    # Front cover bevels (highlight top edge, shadow bottom)
    d.line([(bx + 18, by + 4), (bx + bw - 18, by + 4)],
           fill=(140, 90, 30, 120), width=3)
    d.line([(bx + 18, by + bh - 4), (bx + bw - 18, by + bh - 4)],
           fill=(40, 18, 2, 180), width=3)

    # Cover title area (small gold title block)
    try:
        fnt_title = ImageFont.truetype(FONT_BOLD, 38)
    except Exception:
        fnt_title = ImageFont.load_default()
    title_y = by + 38
    d.text((bx + bw // 2, title_y), "HOLY BIBLE",
           font=fnt_title, fill=GOLD_MID + (200,), anchor="mm")

    # Decorative lines around title
    for oy in [-26, 26]:
        d.line([(bx + bw // 2 - 110, title_y + oy),
                (bx + bw // 2 + 110, title_y + oy)],
               fill=GOLD_DARK + (140,), width=2)

    canvas.alpha_composite(layer)


# ─────────────────────────────────────────────────────────────────────────────
# Layer 4 — Glow halo behind cross
# ─────────────────────────────────────────────────────────────────────────────

def draw_cross_glow(canvas, cx, cy):
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_glow_ellipse(glow, cx, cy, 130, 130, GLOW_COLOR, alpha_max=160, steps=22)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=28))
    canvas.alpha_composite(glow)


# ─────────────────────────────────────────────────────────────────────────────
# Layer 5 — Golden cross
# ─────────────────────────────────────────────────────────────────────────────

def draw_cross(canvas, cx, cy):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d     = ImageDraw.Draw(layer)

    # Cross dimensions
    arm_w  = 88     # arm thickness
    v_h    = 480    # total vertical bar height
    h_w    = 340    # total horizontal bar width
    h_off  = -60    # horizontal bar offset from centre (upward)

    # Vertical bar
    vx0 = cx - arm_w // 2
    vx1 = cx + arm_w // 2
    vy0 = cy - v_h // 2
    vy1 = cy + v_h // 2

    # Horizontal bar
    hx0 = cx - h_w // 2
    hx1 = cx + h_w // 2
    hy0 = cy + h_off - arm_w // 2
    hy1 = cy + h_off + arm_w // 2

    def gold_rect(x0, y0, x1, y1, radius=14):
        # Base gold
        d.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=GOLD_MID + (255,))
        # Left/top edge highlight
        d.rounded_rectangle([x0, y0, x0 + 10, y1], radius=radius, fill=GOLD_LIGHT + (200,))
        d.rounded_rectangle([x0, y0, x1, y0 + 10], radius=radius, fill=GOLD_LIGHT + (200,))
        # Right/bottom shadow
        d.rounded_rectangle([x1 - 10, y0, x1, y1], radius=radius, fill=GOLD_DARK + (200,))
        d.rounded_rectangle([x0, y1 - 10, x1, y1], radius=radius, fill=GOLD_DARK + (200,))

    gold_rect(vx0, vy0, vx1, vy1)
    gold_rect(hx0, hy0, hx1, hy1)

    # Centre rosette where bars intersect
    d.ellipse([cx - 30, cy + h_off - 30, cx + 30, cy + h_off + 30],
              fill=GOLD_LIGHT + (255,))
    d.ellipse([cx - 18, cy + h_off - 18, cx + 18, cy + h_off + 18],
              fill=GOLD_MID + (255,))

    # Thin outline for crispness
    d.rounded_rectangle([vx0, vy0, vx1, vy1], radius=14,
                         outline=GOLD_EDGE + (180,), width=3)
    d.rounded_rectangle([hx0, hy0, hx1, hy1], radius=14,
                         outline=GOLD_EDGE + (180,), width=3)

    canvas.alpha_composite(layer)


# ─────────────────────────────────────────────────────────────────────────────
# Layer 6 — App name text
# ─────────────────────────────────────────────────────────────────────────────

def draw_text(canvas):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d     = ImageDraw.Draw(layer)
    cx    = SIZE // 2

    try:
        fnt_name = ImageFont.truetype(FONT_BOLD, 58)
    except Exception:
        fnt_name = ImageFont.load_default()

    # "SCRIPTURE SHARE" — white with subtle gold shadow
    ty = SIZE - 110
    d.text((cx + 2, ty + 2), "SCRIPTURE SHARE",
           font=fnt_name, fill=GOLD_DARK + (120,), anchor="mm")
    d.text((cx, ty), "SCRIPTURE SHARE",
           font=fnt_name, fill=(255, 255, 255, 230), anchor="mm")

    canvas.alpha_composite(layer)


# ─────────────────────────────────────────────────────────────────────────────
# Layer 7 — Z-Team watermark (matches MajesticMath style)
# ─────────────────────────────────────────────────────────────────────────────

def draw_zteam(canvas):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d     = ImageDraw.Draw(layer)

    try:
        fnt_z = ImageFont.truetype(FONT_BOLD, 26)
    except Exception:
        fnt_z = ImageFont.load_default()

    # Badge background — semi-transparent white pill (same as MajesticMath SVG)
    bx, by = SIZE - 152, SIZE - 58
    bw, bh = 112, 36
    d.rounded_rectangle([bx, by, bx + bw, by + bh],
                         radius=8, fill=(255, 255, 255, 55))
    d.rounded_rectangle([bx, by, bx + bw, by + bh],
                         radius=8, outline=(255, 255, 255, 80), width=1)
    d.text((bx + bw // 2, by + bh // 2), "Z-TEAM",
           font=fnt_z, fill=(255, 255, 255, 180), anchor="mm")

    canvas.alpha_composite(layer)


# ─────────────────────────────────────────────────────────────────────────────
# Compose & export
# ─────────────────────────────────────────────────────────────────────────────

def build_icon():
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))

    cx = SIZE // 2
    cy = 460    # cross centre — sits over the Bible

    draw_background(canvas)
    draw_rays(canvas, cx, cy)
    draw_bible(canvas)
    draw_cross_glow(canvas, cx, cy)
    draw_cross(canvas, cx, cy)
    draw_text(canvas)
    draw_zteam(canvas)

    # Convert to RGB (App Store requires no alpha on the 1024 master)
    final = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    final.paste(canvas.convert("RGB"), (0, 0))
    return final


# iOS asset catalog sizes
ICON_SIZES = [
    (20,  1), (20,  2), (20,  3),
    (29,  1), (29,  2), (29,  3),
    (38,  2), (38,  3),
    (40,  1), (40,  2), (40,  3),
    (60,  2), (60,  3),
    (64,  2), (64,  3),
    (68,  2),
    (76,  1), (76,  2),
    (83,  2),
    (1024, 1),
]

def export_all(master, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    generated = []
    seen = set()
    for pt, scale in ICON_SIZES:
        px = pt * scale
        if px in seen:
            continue
        seen.add(px)
        fname = f"AppIcon-{px}.png" if px != 1024 else "AppIcon-1024.png"
        path  = os.path.join(out_dir, fname)
        resized = master.resize((px, px), Image.LANCZOS)
        resized.save(path, "PNG", optimize=True)
        generated.append((pt, scale, px, fname))
        print(f"  ✓  {fname}  ({px}×{px})")
    return generated


def write_contents_json(generated, out_dir):
    images = []
    for pt, scale, px, fname in generated:
        if pt == 1024:
            images.append({
                "filename": fname,
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            })
        else:
            # Map to idioms
            if pt in (76, 83):
                idiom = "ipad"
            elif pt in (38, 64, 68):
                idiom = "watch" if pt in (38, 64) else "car"
            else:
                idiom = "iphone"
            images.append({
                "filename": fname,
                "idiom": idiom,
                "scale": f"{scale}x",
                "size": f"{pt}x{pt}"
            })

    import json
    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1}
    }
    path = os.path.join(out_dir, "Contents.json")
    with open(path, "w") as f:
        json.dump(contents, f, indent=2)
    print(f"  ✓  Contents.json")


if __name__ == "__main__":
    out = "ScriptureShare/Assets.xcassets/AppIcon.appiconset"
    print("Building master icon…")
    master = build_icon()
    print("Exporting all sizes…")
    generated = export_all(master, out)
    write_contents_json(generated, out)
    print(f"\nDone — {len(generated)} icons written to {out}/")
