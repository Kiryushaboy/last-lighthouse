#!/usr/bin/env python3
"""Рисует значки улучшений и бонусов в art/icons/*.svg: круглый «жетон» с объёмом и рисунок внутри.
Запуск: python3 tools/make_icons.py"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "art", "icons")

def badge(col, dark, light, glyph):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <defs>
    <radialGradient id="bg" cx="0.5" cy="0.35" r="0.75">
      <stop offset="0" stop-color="{light}"/><stop offset="0.55" stop-color="{col}"/><stop offset="1" stop-color="{dark}"/>
    </radialGradient>
    <linearGradient id="rim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.95"/><stop offset="1" stop-color="{col}"/>
    </linearGradient>
    <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.55"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff3b0"/><stop offset="1" stop-color="#f0a81c"/>
    </linearGradient>
    <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f4f8ff"/><stop offset="1" stop-color="#8fa3bd"/>
    </linearGradient>
  </defs>
  <circle cx="64" cy="68" r="56" fill="#000" opacity="0.35"/>
  <circle cx="64" cy="64" r="56" fill="{dark}"/>
  <circle cx="64" cy="64" r="56" fill="none" stroke="url(#rim)" stroke-width="5"/>
  <circle cx="64" cy="64" r="48" fill="url(#bg)"/>
  <g stroke-linecap="round" stroke-linejoin="round">
{glyph}
  </g>
  <path d="M22 54 A44 44 0 0 1 106 54 A60 36 0 0 0 22 54 Z" fill="url(#gloss)"/>
</svg>
'''

OUTLINE = '#101828'
def harpoon(x1, y1, x2, y2, w=7):
    import math
    a = math.atan2(y2 - y1, x2 - x1)
    def p(d, off): return (x2 + math.cos(a) * d - math.sin(a) * off, y2 + math.sin(a) * d + math.cos(a) * off)
    t, l, r = p(8, 0), p(-14, 12), p(-14, -12)
    return (f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{OUTLINE}" stroke-width="{w+5}"/>'
            f'<path d="M{t[0]:.1f} {t[1]:.1f} L{l[0]:.1f} {l[1]:.1f} L{r[0]:.1f} {r[1]:.1f} Z" fill="url(#steel)" stroke="{OUTLINE}" stroke-width="4"/>'
            f'<path d="M{x1} {y1} L{x2} {y2}" stroke="url(#gold)" stroke-width="{w}"/>')

HEART = 'M64 96 C28 70 30 40 48 40 C58 40 64 50 64 50 C64 50 70 40 80 40 C98 40 100 70 64 96 Z'
def heart(scale=1.0, dx=0, dy=0, fill='#ff4d6a'):
    return (f'<g transform="translate({dx} {dy}) translate(64 66) scale({scale}) translate(-64 -66)">'
            f'<path d="{HEART}" fill="{fill}" stroke="{OUTLINE}" stroke-width="5"/>'
            f'<path d="M46 52 Q48 46 56 47" stroke="#fff" stroke-width="5" fill="none" opacity="0.8"/></g>')

ICONS = {
 # улучшения в бою
 "damage": ("#e2493a", "#5a1410", "#ff8a6a", harpoon(36, 92, 88, 40, 9) +
            '<path d="M84 26 L90 40 L104 44 L92 52 L94 66 L84 56 L72 62 L76 48 L66 38 L80 38 Z" fill="url(#gold)" stroke="#101828" stroke-width="3"/>'),
 "fire_rate": ("#f2a53a", "#5e3306", "#ffd58a", harpoon(26, 86, 70, 42) + harpoon(48, 100, 96, 52) +
            '<path d="M24 50 L44 50 M20 64 L36 64 M28 36 L50 36" stroke="#fff" stroke-width="5" opacity="0.85"/>'),
 "multishot": ("#f2c53a", "#5e4506", "#ffe9a0", harpoon(64, 100, 64, 30) + harpoon(60, 100, 30, 44) + harpoon(68, 100, 98, 44)),
 "pierce": ("#4a8fe0", "#0f2c5a", "#9cc8ff",
            '<circle cx="46" cy="64" r="20" fill="#e2493a" stroke="#101828" stroke-width="5"/><circle cx="46" cy="64" r="8" fill="#5a1410"/>' + harpoon(20, 64, 104, 64, 8)),
 "shield": ("#2bb7d9", "#06384a", "#9aeaff",
            '<path d="M64 28 L96 40 Q98 78 64 102 Q30 78 32 40 Z" fill="#dff8ff" stroke="#101828" stroke-width="5"/>'
            '<path d="M64 38 L86 46 Q87 74 64 90 Z" fill="#2bb7d9" opacity="0.9"/><path d="M64 38 L42 46 Q41 74 64 90 Z" fill="#7fe3ff"/>'),
 "speed": ("#35c98a", "#0a4a30", "#9affd0",
            '<path d="M34 78 Q30 54 50 50 L62 38 L74 40 L70 54 Q92 56 98 76 L98 84 L34 84 Z" fill="#fff3d0" stroke="#101828" stroke-width="5"/>'
            '<path d="M34 84 L98 84 L98 90 Q66 96 34 90 Z" fill="#8a5a2a" stroke="#101828" stroke-width="4"/>'
            '<path d="M14 58 L30 58 M10 72 L26 72 M16 86 L28 86" stroke="#fff" stroke-width="5" opacity="0.9"/>'),
 "max_hp": ("#d63a5e", "#4f0a1c", "#ff9ab0", heart(1.05)),
 "magnet": ("#8a5fe0", "#2a1460", "#c9b0ff",
            '<path d="M38 40 L38 68 A26 26 0 0 0 90 68 L90 40 L74 40 L74 68 A10 10 0 0 1 54 68 L54 40 Z" fill="#e2493a" stroke="#101828" stroke-width="5"/>'
            '<path d="M38 40 L54 40 L54 54 L38 54 Z M74 40 L90 40 L90 54 L74 54 Z" fill="url(#steel)" stroke="#101828" stroke-width="5"/>'
            '<path d="M30 30 L24 22 M98 30 L104 22 M64 26 L64 16" stroke="#fff3b0" stroke-width="5"/>'),
 "beam": ("#e0b030", "#5a3d06", "#fff0a0",
            '<path d="M64 60 L18 26 L18 50 Z M64 60 L110 26 L110 50 Z" fill="#fff6c8" opacity="0.75"/>'
            '<path d="M50 104 L56 62 L72 62 L78 104 Z" fill="#f4f8ff" stroke="#101828" stroke-width="5"/>'
            '<path d="M53 84 L75 84 L76 94 L52 94 Z" fill="#e2493a"/>'
            '<rect x="52" y="46" width="24" height="18" rx="4" fill="url(#gold)" stroke="#101828" stroke-width="5"/>'
            '<path d="M48 46 L64 32 L80 46 Z" fill="#e2493a" stroke="#101828" stroke-width="5"/>'),
 # бонусы мастерской
 "hp": ("#d63a5e", "#4f0a1c", "#ff9ab0", heart(0.9, -6, 4) +
            '<circle cx="92" cy="40" r="15" fill="url(#gold)" stroke="#101828" stroke-width="4"/><path d="M92 32 L92 48 M84 40 L100 40" stroke="#101828" stroke-width="5"/>'),
 "power": ("#e2493a", "#5a1410", "#ff8a6a", harpoon(30, 98, 82, 46, 10) +
            '<path d="M70 22 L80 40 L100 44 L86 58 L90 78 L72 68 L56 78 L60 58 L46 44 L64 40 Z" fill="none" stroke="#fff3b0" stroke-width="4" opacity="0.9"/>'),
 "crit": ("#f27a2a", "#5a2406", "#ffc08a",
            '<path d="M64 20 L74 46 L102 38 L84 60 L104 82 L76 80 L64 106 L52 80 L24 82 L44 60 L26 38 L54 46 Z" fill="url(#gold)" stroke="#101828" stroke-width="5"/>'
            '<path d="M50 54 L62 70 M62 54 L50 70" stroke="#101828" stroke-width="6"/>'
            '<path d="M68 58 Q68 52 74 52 Q80 52 80 58 Q80 62 68 72 L82 72" stroke="#101828" stroke-width="6" fill="none"/>'),
 "start": ("#b06ae0", "#3a1460", "#e0b8ff",
            '<rect x="34" y="58" width="60" height="42" rx="5" fill="#ff6a8a" stroke="#101828" stroke-width="5"/>'
            '<rect x="28" y="44" width="72" height="18" rx="5" fill="#ff8aa6" stroke="#101828" stroke-width="5"/>'
            '<rect x="57" y="44" width="14" height="56" fill="url(#gold)" stroke="#101828" stroke-width="4"/>'
            '<path d="M64 44 Q44 20 40 34 Q38 44 64 44 Q84 20 88 34 Q90 44 64 44" fill="url(#gold)" stroke="#101828" stroke-width="4"/>'),
 "bubble": ("#2bb7d9", "#06384a", "#9aeaff",
            '<circle cx="64" cy="64" r="34" fill="#bff4ff" opacity="0.45" stroke="#e8fcff" stroke-width="5"/>'
            '<path d="M44 52 A24 24 0 0 1 60 38" stroke="#fff" stroke-width="6" fill="none"/>'
            '<path d="M64 46 L80 52 Q81 72 64 84 Q47 72 48 52 Z" fill="#dff8ff" stroke="#101828" stroke-width="4"/>'),
 "regen": ("#3ac96a", "#0a4a20", "#a0ffc0", heart(0.72, 0, 0) +
            '<path d="M24 64 A40 40 0 0 1 96 40" stroke="#eafff0" stroke-width="7" fill="none"/><path d="M100 26 L98 44 L82 38 Z" fill="#eafff0"/>'
            '<path d="M104 64 A40 40 0 0 1 32 88" stroke="#eafff0" stroke-width="7" fill="none"/><path d="M28 102 L30 84 L46 90 Z" fill="#eafff0"/>'),
 "pull": ("#8a5fe0", "#2a1460", "#c9b0ff",
            '<path d="M42 30 L42 54 A22 22 0 0 0 86 54 L86 30 L72 30 L72 54 A8 8 0 0 1 56 54 L56 30 Z" fill="#e2493a" stroke="#101828" stroke-width="5"/>'
            '<path d="M42 30 L56 30 L56 42 L42 42 Z M72 30 L86 30 L86 42 L72 42 Z" fill="url(#steel)" stroke="#101828" stroke-width="5"/>'
            '<path d="M64 84 L72 94 L64 104 L56 94 Z" fill="#7dffb0" stroke="#101828" stroke-width="4"/>'
            '<path d="M36 88 L42 96 L36 104 L30 96 Z M92 88 L98 96 L92 104 L86 96 Z" fill="#7dffb0" stroke="#101828" stroke-width="3"/>'),
 "luck": ("#e06a9a", "#5a1436", "#ffc0d8",
            '<path d="M64 98 Q26 88 28 54 Q30 32 64 30 Q98 32 100 54 Q102 88 64 98 Z" fill="#ffe2ec" stroke="#101828" stroke-width="5"/>'
            '<path d="M64 96 L40 44 M64 96 L52 36 M64 96 L64 32 M64 96 L76 36 M64 96 L88 44" stroke="#e06a9a" stroke-width="4" fill="none"/>'
            '<circle cx="94" cy="36" r="15" fill="url(#gold)" stroke="#101828" stroke-width="4"/><path d="M94 28 L94 44 M86 36 L102 36" stroke="#101828" stroke-width="5"/>'),
}

os.makedirs(OUT, exist_ok=True)
for name, (col, dark, light, glyph) in ICONS.items():
    with open(os.path.join(OUT, name + ".svg"), "w") as f:
        f.write(badge(col, dark, light, glyph))
print(len(ICONS), "icons")
