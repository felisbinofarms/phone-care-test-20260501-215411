"""
PhoneCare App Icon Generator
Produces a 1024x1024 PNG for AppIcon.appiconset.

Brand:
  Background:  Brand Blue  #0A3D62
  Symbol:      Health Green #1A8A6E + white
  Style:       Calm, trustworthy, clean — honest phone maintenance
  Icon motif:  Phone outline with a small heart pulse line inside
               (inspired by heart.text.square.fill)
  Rules:       No red / orange.  No text.
"""

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).parent.parent / "PhoneCare/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

# ── Brand palette ─────────────────────────────────────────────────────────────
BG_TOP    = (10,  61,  98)   # #0A3D62  Brand Blue
BG_BOTTOM = (6,   38,  60)   # slightly deeper blue at bottom
GREEN     = (26, 138, 110)   # #1A8A6E  Health Green
WHITE     = (255, 255, 255)
MINT      = (210, 245, 238)  # soft tint for subtle glow

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def make_gradient_background(size):
    img = Image.new("RGB", (size, size))
    for y in range(size):
        t = y / (size - 1)
        color = lerp_color(BG_TOP, BG_BOTTOM, t)
        for x in range(size):
            img.putpixel((x, y), color)
    return img

def apply_ios_corner_mask(img: Image.Image) -> Image.Image:
    """iOS icon corners: radius ≈ 22.5% of the larger side (continuous curve)."""
    size = img.size[0]
    radius = int(size * 0.225)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(img.convert("RGBA"), mask=mask)
    return result

def draw_phone(draw: ImageDraw.Draw, cx: int, cy: int, w: int, h: int,
               border: int, corner: int, color):
    """Draw a rounded phone outline (thick stroke)."""
    x0, y0 = cx - w // 2, cy - h // 2
    x1, y1 = x0 + w, y0 + h
    for i in range(border):
        draw.rounded_rectangle(
            [x0 + i, y0 + i, x1 - i, y1 - i],
            radius=max(corner - i, 2),
            outline=color,
            width=1
        )

def draw_screen(draw: ImageDraw.Draw, cx: int, cy: int, w: int, h: int,
                corner: int, color):
    """Fill the phone screen area."""
    x0 = cx - w // 2
    y0 = cy - h // 2
    draw.rounded_rectangle(
        [x0, y0, x0 + w, y0 + h],
        radius=corner,
        fill=color
    )

def draw_pulse_line(draw: ImageDraw.Draw, cx: int, cy: int, width: int,
                    height: int, color, line_width: int):
    """Draw an ECG-style pulse line inside the phone screen."""
    # Horizontal extent of the pulse line
    half_w = width // 2
    y_base = cy + height // 10   # slightly below vertical centre

    # Control points for pulse shape (normalised -1..1 x, -1..1 y)
    points_norm = [
        (-1.0,  0.0),
        (-0.6,  0.0),
        (-0.45, -0.60),
        (-0.30,  0.55),
        (-0.15, -0.95),   # peak
        ( 0.0,  0.90),
        ( 0.15,  0.0),
        ( 0.5,  0.0),
        ( 1.0,  0.0),
    ]
    pts = [
        (int(cx + p[0] * half_w), int(y_base - p[1] * height * 0.28))
        for p in points_norm
    ]
    # Draw with anti-alias by rendering multiple passes
    for offset in [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]:
        shifted = [(x + offset[0], y + offset[1]) for x, y in pts]
        draw.line(shifted, fill=color, width=line_width, joint="curve")

def draw_home_pill(draw: ImageDraw.Draw, cx: int, bottom_y: int, color):
    """Small home indicator pill at the bottom of the phone."""
    pill_w = 80
    pill_h = 10
    draw.rounded_rectangle(
        [cx - pill_w // 2, bottom_y - pill_h,
         cx + pill_w // 2, bottom_y],
        radius=pill_h // 2,
        fill=color
    )

def draw_notch(draw: ImageDraw.Draw, cx: int, top_y: int, color):
    """Dynamic Island–style notch/pill at the top."""
    pill_w = 90
    pill_h = 22
    draw.rounded_rectangle(
        [cx - pill_w // 2, top_y,
         cx + pill_w // 2, top_y + pill_h],
        radius=pill_h // 2,
        fill=color
    )

# ── Build the icon ─────────────────────────────────────────────────────────────

img = make_gradient_background(SIZE)
overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(overlay)

cx, cy = SIZE // 2, SIZE // 2

# ── Soft glow behind the phone ─────────────────────────────────────────────────
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for r in range(320, 0, -4):
    alpha = int(30 * (1 - r / 320) ** 2)
    gd.ellipse([cx - r, cy - r, cx + r, cy + r],
               fill=(*GREEN, alpha))
glow = glow.filter(ImageFilter.GaussianBlur(radius=18))
overlay = Image.alpha_composite(overlay, glow)
draw = ImageDraw.Draw(overlay)

# ── Phone body ────────────────────────────────────────────────────────────────
PHONE_W   = 320
PHONE_H   = 560
PHONE_BRD = 22          # stroke width of the phone outline
PHONE_COR = 64          # corner radius of the phone body
SCREEN_W  = PHONE_W - PHONE_BRD * 2 - 12
SCREEN_H  = PHONE_H - PHONE_BRD * 2 - 12
SCREEN_COR = 44

# Phone outline  (white)
draw_phone(draw, cx, cy,
           PHONE_W, PHONE_H,
           PHONE_BRD, PHONE_COR,
           WHITE + (230,))

# Screen background  (translucent green tint)
draw_screen(draw, cx, cy,
            SCREEN_W, SCREEN_H,
            SCREEN_COR,
            (*GREEN, 55))

# Dynamic Island notch
draw_notch(draw, cx, cy - SCREEN_H // 2 + 18, (*WHITE, 180))

# Home pill
draw_home_pill(draw, cx, cy + PHONE_H // 2 - PHONE_BRD - 14, (*WHITE, 160))

# ── Pulse / ECG line  (green → white gradient faked with draw calls) ──────────
PULSE_W = int(SCREEN_W * 0.80)
PULSE_H = int(SCREEN_H * 0.38)
# Draw a thicker shadow in green then sharp white on top
draw_pulse_line(draw, cx, cy - 20, PULSE_W, PULSE_H, (*GREEN, 200), 14)
draw_pulse_line(draw, cx, cy - 20, PULSE_W, PULSE_H, (*WHITE, 240), 7)

# ── Small heart icon in top-right of screen ────────────────────────────────────
HCX = cx + SCREEN_W // 2 - 48
HCY = cy - SCREEN_H // 2 + 58
HR  = 22
# Simple heart via two arcs + polygon
draw.ellipse([HCX - HR, HCY - HR, HCX, HCY], fill=(*GREEN, 230))
draw.ellipse([HCX, HCY - HR, HCX + HR, HCY], fill=(*GREEN, 230))
draw.polygon([
    (HCX - HR, HCY - 2),
    (HCX + HR, HCY - 2),
    (HCX, HCY + HR + 6),
], fill=(*GREEN, 230))

# ── Composite ─────────────────────────────────────────────────────────────────
img = img.convert("RGBA")
img = Image.alpha_composite(img, overlay)

# ── Apply iOS rounded-corner mask ─────────────────────────────────────────────
img = apply_ios_corner_mask(img)

# ── Save ──────────────────────────────────────────────────────────────────────
OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(str(OUT), "PNG")
print(f"Saved: {OUT}  ({OUT.stat().st_size // 1024} KB)")
