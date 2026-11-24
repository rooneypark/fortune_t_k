#!/usr/bin/env python3
"""운빨삼국 임시 아이콘 그림 (assets/ui/icons). 출시 전에 교체한다.

캐릭터 · 얼굴 그림은 24도트 규격 도구 tools/draw_units24.py 가 그린다 (2026-11-23).
이 파일은 아이콘만 그리고, main()에서 캐릭터 도구도 같이 부른다.

Usage: python tools/draw_art.py
"""
import json, math, os, shutil
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNITS = os.path.join(ROOT, "assets", "units")
PORTRAITS = os.path.join(ROOT, "assets", "portraits")
ICONS = os.path.join(ROOT, "assets", "ui", "icons")
UI = os.path.join(ROOT, "assets", "ui")

OUTLINE = (24, 20, 28, 255)
SKIN = (246, 200, 160, 255)
SKIN_D = (214, 160, 122, 255)


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def dark(c, k=0.72):
    return (int(c[0] * k), int(c[1] * k), int(c[2] * k), c[3])


def light(c, k=0.35):
    return (int(c[0] + (255 - c[0]) * k), int(c[1] + (255 - c[1]) * k), int(c[2] + (255 - c[2]) * k), c[3])


def outline(im):
    """1px dark outline around every opaque pixel (pixel-art look)."""
    a = im.split()[3]
    w, h = im.size
    src = a.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    o = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny] > 0:
                    o[x, y] = OUTLINE
                    break
    out.alpha_composite(im)
    return out


# ------------------------------------------------------------------ icons (16x16)
def icon(draw_fn, size=16):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    draw_fn(d)
    return outline(im)


GOLD, GOLD_D = rgb("#ffd447"), rgb("#c8901c")
ICON_DRAW = {
    "gold": lambda d: (d.ellipse([2, 6, 9, 13], fill=GOLD), d.ellipse([6, 3, 13, 10], fill=GOLD), d.point((9, 6), fill=GOLD_D), d.point((5, 9), fill=GOLD_D)),
    "rice": lambda d: (d.polygon([(4, 5), (11, 5), (13, 13), (2, 13)], fill=rgb("#d8b07a")), d.rectangle([5, 2, 10, 5], fill=rgb("#b88a50")), d.line([(5, 9), (10, 9)], fill=rgb("#f4e6c0"))),
    "medal": lambda d: (d.polygon([(4, 1), (7, 7), (9, 7), (12, 1)], fill=rgb("#d83030")), d.ellipse([3, 6, 12, 15], fill=GOLD), d.point((7, 10), fill=GOLD_D)),
    "scroll": lambda d: (d.rectangle([3, 3, 12, 12], fill=rgb("#f2e6c8")), d.rectangle([2, 2, 13, 3], fill=rgb("#b05030")), d.rectangle([2, 12, 13, 13], fill=rgb("#b05030")), d.line([(5, 6), (10, 6)], fill=rgb("#c83030")), d.line([(5, 9), (10, 9)], fill=rgb("#8a6a4a"))),
    "chest": lambda d: (d.rectangle([2, 6, 13, 13], fill=rgb("#a0602e")), d.pieslice([2, 2, 13, 11], 180, 360, fill=rgb("#c07a3a")), d.rectangle([2, 6, 13, 7], fill=GOLD), d.rectangle([7, 7, 8, 9], fill=GOLD)),
    "swords": lambda d: (d.line([(2, 2), (12, 12)], fill=rgb("#e6edf5"), width=2), d.line([(13, 2), (3, 12)], fill=rgb("#e6edf5"), width=2), d.line([(9, 13), (13, 9)], fill=GOLD, width=2), d.line([(2, 9), (6, 13)], fill=GOLD, width=2)),
    "sword": lambda d: (d.line([(3, 12), (12, 3)], fill=rgb("#e6edf5"), width=2), d.line([(2, 9), (6, 13)], fill=GOLD, width=2)),
    "bag": lambda d: (d.ellipse([2, 5, 13, 14], fill=rgb("#c89a5a")), d.rectangle([5, 2, 10, 6], fill=rgb("#a87a3a")), d.line([(4, 6), (11, 6)], fill=rgb("#d83030"))),
    "hero": lambda d: (d.ellipse([3, 2, 12, 11], fill=SKIN), d.pieslice([3, 1, 12, 10], 180, 360, fill=rgb("#d83030")), d.rectangle([4, 11, 11, 14], fill=GOLD), d.point((10, 6), fill=OUTLINE)),
    "lock": lambda d: (d.arc([4, 1, 11, 10], 180, 360, fill=rgb("#b8c2d0"), width=2), d.rectangle([3, 7, 12, 14], fill=GOLD), d.point((7, 10), fill=OUTLINE)),
    "star": lambda d: d.polygon([(7.5, 1), (9.5, 6), (14, 6), (10.5, 9), (12, 14), (7.5, 11), (3, 14), (4.5, 9), (1, 6), (5.5, 6)], fill=GOLD),
    "star_off": lambda d: d.polygon([(7.5, 1), (9.5, 6), (14, 6), (10.5, 9), (12, 14), (7.5, 11), (3, 14), (4.5, 9), (1, 6), (5.5, 6)], fill=rgb("#4a5260")),
    "heart": lambda d: (d.ellipse([1, 3, 8, 10], fill=rgb("#e83a4a")), d.ellipse([7, 3, 14, 10], fill=rgb("#e83a4a")), d.polygon([(1, 7), (14, 7), (7.5, 14)], fill=rgb("#e83a4a"))),
    "shield": lambda d: (d.polygon([(2, 2), (13, 2), (13, 8), (7.5, 14), (2, 8)], fill=rgb("#6f9ad8")), d.line([(7, 3), (7, 12)], fill=rgb("#bcd4f4"))),
    "orb": lambda d: (d.ellipse([2, 2, 13, 13], fill=rgb("#b07ae8")), d.ellipse([4, 4, 7, 7], fill=rgb("#e8d4ff"))),
    "boss": lambda d: (d.ellipse([2, 2, 13, 12], fill=rgb("#e8e0d0")), d.rectangle([4, 11, 11, 14], fill=rgb("#e8e0d0")), d.rectangle([4, 6, 6, 8], fill=OUTLINE), d.rectangle([9, 6, 11, 8], fill=OUTLINE)),
    "castle": lambda d: (d.rectangle([2, 6, 13, 14], fill=rgb("#c8b490")), d.polygon([(1, 6), (7.5, 1), (14, 6)], fill=rgb("#3a5a8a")), d.rectangle([6, 9, 9, 14], fill=rgb("#6a4a2a"))),
    "class_inf": lambda d: (d.line([(3, 13), (12, 2)], fill=rgb("#e6edf5"), width=2), d.polygon([(10, 1), (14, 1), (14, 5)], fill=rgb("#e6edf5"))),
    "class_arc": lambda d: (d.arc([2, 1, 12, 14], 270, 90, fill=rgb("#a07040"), width=2), d.line([(7, 1), (7, 14)], fill=rgb("#e8e0d0")), d.line([(2, 8), (13, 8)], fill=rgb("#e8e0d0"))),
    "class_cav": lambda d: (d.ellipse([2, 6, 11, 11], fill=rgb("#c89a5a")), d.polygon([(9, 7), (12, 2), (14, 4), (11, 8)], fill=rgb("#c89a5a")), d.line([(3, 10), (3, 14)], fill=rgb("#c89a5a"), width=2), d.line([(10, 10), (10, 14)], fill=rgb("#c89a5a"), width=2)),
    "class_str": lambda d: (d.pieslice([1, 1, 14, 14], 200, 340, fill=rgb("#f4f0e6")), d.line([(7, 8), (7, 14)], fill=rgb("#7a5230"), width=2)),
}
# file name -> drawing key. 쓰는 아이콘만 그린다 (2026-11-23 정리).
ICON_FILES = {}
for k in ["gold", "rice", "medal", "chest", "swords", "sword", "bag", "hero", "castle"]:
    ICON_FILES["icon_" + k] = k
for k in ["boss", "heart", "lock", "orb", "scroll", "shield", "star", "star_off", "sword"]:
    ICON_FILES["ic_" + k] = k
for k in ["class_inf", "class_arc", "class_cav", "class_str"]:
    ICON_FILES[k] = k


def make_icons():
    os.makedirs(ICONS, exist_ok=True)
    for name, key in ICON_FILES.items():
        icon(ICON_DRAW[key]).save(os.path.join(ICONS, name + ".png"))
    # battle wall strip (stone) and respawn ring
    wall = Image.new("RGBA", (256, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(wall)
    d.rectangle([0, 8, 255, 39], fill=rgb("#8a8478"))
    for x in range(0, 256, 16):
        d.rectangle([x + 2, 0, x + 10, 8], fill=rgb("#8a8478"))
    for y in range(10, 40, 8):
        off = 0 if (y // 8) % 2 else 8
        for x in range(-8 + off, 256, 16):
            d.rectangle([x + 1, y + 1, x + 14, y + 6], fill=rgb("#a49c8c"))
    outline(wall).save(os.path.join(UI, "wall.png"))
    ring = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    d.ellipse([2, 2, 29, 29], outline=rgb("#e6edf5"), width=3)
    ring.save(os.path.join(UI, "ring_respawn.png"))


def main():
    import draw_units24
    draw_units24.main()
    make_icons()
    print("icons", len(ICON_FILES))


if __name__ == "__main__":
    main()
