#!/usr/bin/env python3
"""Рисует картинки заставки в art/splash/: фон (ночное море и маяк), луч и название.
Всё рисуется вдвое крупнее и уменьшается, поэтому края гладкие. Запуск: python3 tools/make_splash.py"""
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1440, 3200          # итоговый фон, 9:20 — обрезается под экран по краям
SS = 2                     # сглаживание: рисуем в SS раз крупнее
HORIZON = 0.60
OUT = "art/splash/"
FONT = "ui/fonts/RussoOne-Regular.ttf"
FONT_BODY = "ui/fonts/Rubik-VariableFont_wght.ttf"


def vgrad(w, h, stops):
    """Вертикальный градиент: stops = [(доля, (r,g,b)), ...]."""
    ys = np.linspace(0, 1, h)
    out = np.zeros((h, 3))
    for c in range(3):
        out[:, c] = np.interp(ys, [s[0] for s in stops], [s[1][c] for s in stops])
    # Лёгкий шум против полос на градиенте.
    arr = np.repeat(out[:, None, :], w, axis=1) + np.random.default_rng(1).uniform(-1.2, 1.2, (h, w, 1))
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


def glow(img, center, radius, color, strength=1.0):
    """Мягкое свечение, прибавляется к картинке."""
    w, h = img.size
    x0, y0 = int(max(0, center[0] - radius)), int(max(0, center[1] - radius))
    x1, y1 = int(min(w, center[0] + radius)), int(min(h, center[1] + radius))
    if x1 <= x0 or y1 <= y0:
        return
    ys, xs = np.mgrid[y0:y1, x0:x1]
    d = np.sqrt((xs - center[0]) ** 2 + (ys - center[1]) ** 2) / radius
    a = np.clip(1 - d, 0, 1) ** 2.2 * strength
    region = np.asarray(img.crop((x0, y0, x1, y1))).astype(float)
    region[..., :3] += a[..., None] * np.array(color)
    img.paste(Image.fromarray(np.clip(region, 0, 255).astype(np.uint8), img.mode), (x0, y0))


def make_bg():
    w, h = W * SS, H * SS
    u = w / 720.0
    hz = int(h * HORIZON)
    rnd = random.Random(7)
    sky = vgrad(w, hz, [(0, (3, 5, 20)), (0.5, (12, 20, 62)), (0.86, (58, 34, 104)), (1, (120, 56, 120))])
    sea = vgrad(w, h - hz, [(0, (20, 52, 92)), (0.25, (8, 26, 56)), (1, (0, 4, 14))])
    img = Image.new("RGB", (w, h))
    img.paste(sky, (0, 0))
    img.paste(sea, (0, hz))
    d = ImageDraw.Draw(img, "RGBA")
    # Звёзды.
    for _ in range(420):
        x, y = rnd.random() * w, rnd.random() ** 1.3 * hz * 0.94
        r = rnd.choice([1.0, 1.2, 1.5, 2.2, 3.0]) * u * 0.55
        a = rnd.randint(110, 255)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 250, 235, a))
        if r > 1.4 * u:
            glow(img, (x, y), 14 * u, (90, 90, 120), 0.9)
    d = ImageDraw.Draw(img, "RGBA")
    # Луна.
    moon = (w * 0.77, h * 0.2)
    glow(img, moon, 260 * u, (70, 85, 130), 1.0)
    d = ImageDraw.Draw(img, "RGBA")
    mr = 46 * u
    d.ellipse((moon[0] - mr, moon[1] - mr, moon[0] + mr, moon[1] + mr), fill=(244, 247, 255, 255))
    for cx, cy, cr in [(-14, -8, 9), (12, 14, 6), (16, -18, 4)]:
        d.ellipse((moon[0] + (cx - cr) * u, moon[1] + (cy - cr) * u, moon[0] + (cx + cr) * u, moon[1] + (cy + cr) * u), fill=(206, 216, 240, 255))
    base = (w * 0.5, hz + 6 * u)
    top = -340
    lamp = (base[0], base[1] + (top - 34) * u)
    # Зарево у горизонта и ореол фонаря.
    glow(img, (w * 0.5, hz), 520 * u, (120, 50, 70), 0.9)
    glow(img, lamp, 420 * u, (150, 110, 40), 1.0)
    d = ImageDraw.Draw(img, "RGBA")
    # Волны: тонкие светлые линии, ближе к зрителю — крупнее.
    for i in range(12):
        k = i / 11.0
        y = hz + (h - hz) * (0.03 + 0.92 * k * k)
        amp = (2.5 + 12 * k) * u
        pts = []
        for j in range(0, w + 1, 16):
            pts.append((j, y + math.sin(j * 0.012 / u * (1.7 - k) + i * 1.7) * amp))
        d.line(pts, fill=(120, 215, 255, int(34 + 60 * k)), width=int((1.6 + 3.6 * k) * u), joint="curve")
        gw = (22 + 120 * k) * u
        for s in range(3):
            off = (rnd.random() - 0.5) * gw * 0.8
            ln = gw * (0.35 + 0.5 * rnd.random())
            yy = y + (s - 1) * 9 * u * (0.4 + k)
            d.line((base[0] + off - ln, yy, base[0] + off + ln, yy), fill=(255, 224, 130, int(150 - 90 * k)), width=int((2.5 + 3.5 * k) * u))
    # Скала.
    rock = [(-200, 16), (-160, -14), (-104, -28), (-64, -52), (64, -52), (108, -28), (166, -14), (210, 16)]
    rp = [(base[0] + x * u, base[1] + y * u) for x, y in rock]
    d.polygon(rp, fill=(9, 12, 26, 255))
    d.line(rp, fill=(100, 220, 255, 150), width=int(3 * u), joint="curve")
    # Башня.
    bottom, bands = -50, 5
    for i in range(bands):
        y0 = bottom + (top - bottom) * i / bands
        y1 = bottom + (top - bottom) * (i + 1) / bands
        w0 = 58 + (36 - 58) * i / bands
        w1 = 58 + (36 - 58) * (i + 1) / bands
        col = (242, 245, 255, 255) if i % 2 == 0 else (242, 76, 92, 255)
        d.polygon([(base[0] - w0 * u, base[1] + y0 * u), (base[0] + w0 * u, base[1] + y0 * u),
                   (base[0] + w1 * u, base[1] + y1 * u), (base[0] - w1 * u, base[1] + y1 * u)], fill=col)
        d.polygon([(base[0] + w0 * 0.3 * u, base[1] + y0 * u), (base[0] + w0 * u, base[1] + y0 * u),
                   (base[0] + w1 * u, base[1] + y1 * u), (base[0] + w1 * 0.3 * u, base[1] + y1 * u)], fill=(14, 14, 64, 70))
        d.polygon([(base[0] - w0 * u, base[1] + y0 * u), (base[0] - w0 * 0.72 * u, base[1] + y0 * u),
                   (base[0] - w1 * 0.72 * u, base[1] + y1 * u), (base[0] - w1 * u, base[1] + y1 * u)], fill=(255, 255, 255, 60))
    d.line([(base[0] - 58 * u, base[1] + bottom * u), (base[0] - 36 * u, base[1] + top * u),
            (base[0] + 36 * u, base[1] + top * u), (base[0] + 58 * u, base[1] + bottom * u)], fill=(115, 230, 255, 255), width=int(3.5 * u), joint="curve")
    d.rounded_rectangle((base[0] - 13 * u, base[1] + (bottom - 46) * u, base[0] + 13 * u, base[1] + bottom * u), radius=12 * u, fill=(30, 36, 66, 255))
    d.ellipse((base[0] - 10 * u, base[1] - 210 * u, base[0] + 10 * u, base[1] - 190 * u), fill=(255, 217, 115, 255), outline=(30, 36, 66, 255), width=int(3 * u))
    # Балкон, фонарь, крыша.
    d.rounded_rectangle((base[0] - 52 * u, base[1] + (top - 12) * u, base[0] + 52 * u, base[1] + top * u), radius=4 * u, fill=(26, 31, 61, 255))
    d.rectangle((base[0] - 28 * u, base[1] + (top - 62) * u, base[0] + 28 * u, base[1] + (top - 10) * u), fill=(26, 31, 61, 255))
    d.rectangle((base[0] - 20 * u, base[1] + (top - 56) * u, base[0] + 20 * u, base[1] + (top - 14) * u), fill=(255, 246, 190, 255))
    d.rectangle((base[0] - 28 * u, base[1] + (top - 62) * u, base[0] + 28 * u, base[1] + (top - 10) * u), outline=(255, 219, 115, 255), width=int(3 * u))
    d.polygon([(base[0] - 40 * u, base[1] + (top - 62) * u), (base[0] + 40 * u, base[1] + (top - 62) * u), (base[0], base[1] + (top - 106) * u)], fill=(242, 76, 92, 255))
    d.ellipse((base[0] - 5 * u, base[1] + (top - 114) * u, base[0] + 5 * u, base[1] + (top - 104) * u), fill=(255, 219, 115, 255))
    glow(img, lamp, 120 * u, (255, 240, 170), 0.95)
    glow(img, lamp, 40 * u, (255, 255, 255), 0.9)
    img = img.resize((W, H), Image.LANCZOS)
    img.save(OUT + "bg.png", optimize=True)
    return lamp[0] / w, lamp[1] / h


def make_beam():
    """Луч: мягкий конус света вправо от левого края, прозрачный к концу и по бокам."""
    w, h = 1024, 512
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    x = xs / w
    half = 0.02 + 0.47 * x                      # полуширина конуса в долях высоты
    side = np.abs(ys / h - 0.5) / half
    a = np.clip(1 - side, 0, 1) ** 1.6 * (1 - x) ** 1.3 * np.clip(x * 30, 0, 1)
    arr = np.zeros((h, w, 4))
    arr[..., 0], arr[..., 1], arr[..., 2] = 255, 236, 160
    arr[..., 3] = a * 255
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(OUT + "beam.png", optimize=True)


def make_title():
    w, h = 1400 * SS, 760 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lines = [("ПОСЛЕДНИЙ", 196), ("МАЯК", 286)]
    y = 40 * SS
    layers = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_l = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for text, size in lines:
        f = ImageFont.truetype(FONT, size * SS)
        box = f.getbbox(text)
        x = (w - (box[2] - box[0])) / 2 - box[0]
        ImageDraw.Draw(glow_l).text((x, y), text, font=f, fill=(255, 150, 40, 255), stroke_width=10 * SS, stroke_fill=(255, 150, 40, 255))
        dl = ImageDraw.Draw(layers)
        dl.text((x, y + 14 * SS), text, font=f, fill=(120, 60, 10, 255), stroke_width=12 * SS, stroke_fill=(6, 8, 26, 255))
        dl.text((x, y), text, font=f, fill=(255, 255, 255, 255), stroke_width=12 * SS, stroke_fill=(6, 8, 26, 255))
        # Золотой градиент по буквам: сверху светлее.
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).text((x, y), text, font=f, fill=255)
        top, bot = y + box[1], y + box[3]
        grad = vgrad(w, h, [(0, (255, 244, 190)), (max(0.001, top / h), (255, 244, 190)), ((top + bot) / 2 / h, (255, 214, 100)), (bot / h, (240, 150, 40)), (1, (240, 150, 40))]).convert("RGBA")
        layers.paste(grad, (0, 0), mask)
        y += int(size * 1.02) * SS
    fb = ImageFont.truetype(FONT_BODY, 62 * SS)
    try:
        fb.set_variation_by_axes([500])
    except Exception:
        pass
    sub = "Продержитесь до рассвета"
    box = fb.getbbox(sub)
    ImageDraw.Draw(layers).text(((w - (box[2] - box[0])) / 2 - box[0], y + 60 * SS), sub, font=fb, fill=(214, 236, 255, 255), stroke_width=6 * SS, stroke_fill=(6, 8, 26, 255))
    glow_l = glow_l.filter(ImageFilter.GaussianBlur(26 * SS))
    a = np.asarray(glow_l).astype(float)
    a[..., 3] *= 0.55
    img = Image.alpha_composite(Image.fromarray(a.astype(np.uint8), "RGBA"), layers)
    img.resize((w // SS, h // SS), Image.LANCZOS).save(OUT + "title.png", optimize=True)


if __name__ == "__main__":
    lx, ly = make_bg()
    make_beam()
    make_title()
    print("lamp at", round(lx, 4), round(ly, 4))
