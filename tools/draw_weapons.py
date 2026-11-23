#!/usr/bin/env python3
"""슬롯 병사 칸의 무기 아이콘 (스테이지-흡수-합성-개편 §9.7) — 임시 그림.

병종 16종마다 assets/ui/icons/wp_<병종 id>.png (128x128, 투명 배경)을 그린다.
32x32 도트로 그리고 어두운 테두리를 두른 뒤 4배로 키운다. 직접 그린 그림이며
다른 게임의 그림을 쓰지 않는다. 출시 전에 교체한다.

    python tools/draw_weapons.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "ui", "icons")
N = 32
SCALE = 4

INK = (28, 20, 16, 255)
STEEL = (206, 212, 222, 255)
STEEL_D = (140, 150, 166, 255)
WOOD = (150, 100, 58, 255)
WOOD_D = (104, 68, 40, 255)
GOLD = (232, 190, 78, 255)
RED = (206, 70, 52, 255)
GREEN = (104, 160, 78, 255)
GREEN_D = (64, 110, 54, 255)
BROWN = (120, 84, 50, 255)
HORSE = (168, 120, 76, 255)
HORSE_D = (116, 80, 50, 255)
IRON = (120, 128, 144, 255)
FIRE1 = (255, 214, 84, 255)
FIRE2 = (246, 138, 46, 255)
FIRE3 = (214, 62, 40, 255)
BOLT = (255, 232, 96, 255)
BLUE = (110, 170, 240, 255)
WHITE = (240, 240, 232, 255)


def canvas():
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def outline(im):
    """Dark 1px rim around everything that was drawn."""
    src = im.load()
    out = im.copy()
    dst = out.load()
    for y in range(N):
        for x in range(N):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < N and 0 <= ny < N and src[nx, ny][3] != 0:
                    dst[x, y] = INK
                    break
    return out


def spear():
    im, d = canvas()
    d.line([(6, 27), (22, 9)], fill=WOOD, width=2)
    d.polygon([(21, 10), (28, 3), (25, 12)], fill=STEEL)
    d.line([(20, 12), (23, 9)], fill=RED, width=2)
    return im


def halberd():
    im, d = canvas()
    d.line([(7, 28), (23, 8)], fill=WOOD, width=2)
    d.polygon([(22, 9), (28, 2), (25, 11)], fill=STEEL)
    d.polygon([(17, 12), (12, 6), (20, 5), (22, 11)], fill=STEEL)
    d.line([(14, 8), (19, 7)], fill=STEEL_D, width=1)
    return im


def longspear():
    im, d = canvas()
    d.line([(16, 30), (16, 8)], fill=WOOD, width=2)
    d.polygon([(13, 9), (16, 1), (19, 9)], fill=STEEL)
    d.rectangle([13, 9, 19, 11], fill=GOLD)
    d.line([(14, 12), (12, 16)], fill=RED, width=1)
    d.line([(18, 12), (20, 16)], fill=RED, width=1)
    return im


def sword():
    im, d = canvas()
    d.polygon([(8, 21), (24, 4), (27, 5), (11, 24)], fill=STEEL)
    d.line([(10, 22), (25, 6)], fill=WHITE, width=1)
    d.line([(6, 18), (14, 26)], fill=GOLD, width=3)
    d.line([(8, 24), (4, 28)], fill=WOOD, width=3)
    return im


def shield():
    im, d = canvas()
    d.polygon([(6, 5), (26, 5), (26, 17), (16, 29), (6, 17)], fill=STEEL_D)
    d.polygon([(9, 8), (23, 8), (23, 16), (16, 25), (9, 16)], fill=BLUE)
    d.ellipse([13, 11, 19, 17], fill=GOLD)
    return im


def axe():
    im, d = canvas()
    d.line([(9, 28), (20, 7)], fill=WOOD, width=3)
    d.pieslice([10, 1, 30, 19], 300, 110, fill=STEEL)
    d.line([(21, 4), (26, 14)], fill=STEEL_D, width=1)
    return im


def vine():
    im, d = canvas()
    d.ellipse([4, 4, 28, 28], fill=BROWN)
    d.ellipse([7, 7, 25, 25], fill=GREEN_D)
    for k in range(9, 25, 4):
        d.line([(k, 7), (k, 25)], fill=GREEN, width=1)
        d.line([(7, k), (25, k)], fill=GREEN, width=1)
    d.ellipse([13, 13, 19, 19], fill=BROWN)
    return im


def archer():
    im, d = canvas()
    d.arc([2, 3, 22, 29], 290, 70, fill=WOOD, width=3)
    d.line([(16, 5), (16, 27)], fill=WHITE, width=1)
    d.line([(8, 16), (27, 16)], fill=WOOD_D, width=1)
    d.polygon([(26, 13), (30, 16), (26, 19)], fill=STEEL)
    d.line([(8, 14), (10, 16)], fill=RED, width=1)
    d.line([(8, 18), (10, 16)], fill=RED, width=1)
    return im


def crossbow():
    im, d = canvas()
    d.line([(16, 28), (16, 6)], fill=WOOD, width=3)
    d.arc([3, 2, 29, 18], 180, 360, fill=STEEL_D, width=3)
    d.line([(4, 10), (16, 16)], fill=WHITE, width=1)
    d.line([(28, 10), (16, 16)], fill=WHITE, width=1)
    d.polygon([(14, 6), (16, 1), (18, 6)], fill=STEEL)
    d.rectangle([14, 20, 18, 23], fill=GOLD)
    return im


def catapult():
    im, d = canvas()
    d.line([(4, 27), (28, 27)], fill=WOOD_D, width=3)
    d.line([(8, 27), (16, 14)], fill=WOOD, width=2)
    d.line([(24, 27), (16, 14)], fill=WOOD, width=2)
    d.line([(24, 22), (8, 7)], fill=WOOD, width=2)
    d.ellipse([3, 2, 11, 10], fill=STEEL_D)
    d.ellipse([5, 24, 11, 30], fill=IRON)
    d.ellipse([21, 24, 27, 30], fill=IRON)
    return im


def horse(body, shade, armor=False):
    im, d = canvas()
    d.polygon([(9, 29), (9, 17), (14, 8), (20, 4), (23, 8), (27, 18), (25, 22), (19, 19), (20, 29)], fill=body)
    d.polygon([(19, 4), (21, 0), (23, 6)], fill=body)
    d.line([(13, 9), (9, 18)], fill=shade, width=3)
    d.point((21, 10), fill=INK)
    d.point((22, 10), fill=INK)
    d.line([(24, 19), (26, 20)], fill=INK, width=1)
    if armor:
        d.polygon([(15, 8), (20, 4), (23, 8), (26, 16), (20, 14)], fill=IRON)
        d.line([(17, 9), (24, 15)], fill=STEEL, width=1)
        d.rectangle([9, 22, 20, 25], fill=IRON)
        d.point((21, 10), fill=INK)
    return im, d


def rider():
    im, d = horse(HORSE, HORSE_D)
    d.line([(17, 13), (25, 21)], fill=RED, width=1)
    return im


def heavy():
    im, _ = horse((132, 104, 84, 255), (92, 70, 56, 255), armor=True)
    return im


def harcher():
    im, d = horse(HORSE, HORSE_D)
    d.arc([0, 14, 12, 31], 280, 80, fill=WOOD, width=2)
    d.line([(7, 16), (7, 30)], fill=WHITE, width=1)
    return im


def fire():
    im, d = canvas()
    d.polygon([(16, 1), (24, 12), (27, 20), (23, 28), (16, 30), (9, 28), (5, 20), (9, 12), (12, 15)], fill=FIRE3)
    d.polygon([(16, 8), (22, 17), (22, 24), (16, 28), (10, 24), (11, 17), (14, 19)], fill=FIRE2)
    d.polygon([(16, 16), (19, 22), (16, 27), (13, 22)], fill=FIRE1)
    return im


def thunder():
    im, d = canvas()
    d.polygon([(19, 1), (7, 17), (14, 17), (10, 30), (25, 12), (17, 12), (22, 1)], fill=BOLT)
    d.line([(17, 4), (11, 15)], fill=WHITE, width=1)
    return im


def medic():
    im, d = canvas()
    d.ellipse([9, 13, 23, 29], fill=GREEN)
    d.ellipse([12, 6, 20, 15], fill=GREEN)
    d.rectangle([14, 2, 18, 6], fill=WOOD)
    d.line([(10, 14), (22, 14)], fill=RED, width=1)
    d.rectangle([15, 18, 17, 25], fill=WHITE)
    d.rectangle([12, 21, 20, 22], fill=WHITE)
    return im


ICONS = {
    "spear": spear, "halberd": halberd, "longspear": longspear,
    "sword": sword, "shield": shield, "axe": axe, "vine": vine,
    "archer": archer, "crossbow": crossbow, "catapult": catapult,
    "rider": rider, "heavy": heavy, "harcher": harcher,
    "fire": fire, "thunder": thunder, "medic": medic,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for tid, fn in ICONS.items():
        im = outline(fn()).resize((N * SCALE, N * SCALE), Image.NEAREST)
        im.save(os.path.join(OUT, "wp_%s.png" % tid))
    print("ok %d weapon icons -> assets/ui/icons" % len(ICONS))


if __name__ == "__main__":
    main()
