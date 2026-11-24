#!/usr/bin/env python3
"""운빨삼국 UI 임시 그림 (자리 표시용). 제미나이 · 정식 그림이 오면 같은 파일 이름으로 덮어쓴다.

- 모든 그림은 도트 크기로 그려서 4배(최근접)로 저장한다 (도트 1칸 = 4px).
- 누끼(투명 배경) 부품은 바깥이 투명이다. 배경은 화면을 꽉 채운다.
- 배경 · 성 · 성문 임시 그림에는 오른쪽 아래에 "파일 이름 · 크기"를 적어 둔다 (정식 그림에는 글자 없음).
- (2026-11-24) 로비 · 전투는 제미나이 그림으로 바뀌었다: tools/import_lobby_ui.py · import_battle_ui.py.

Usage: python tools/draw_ui_placeholders.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

from draw_art import rgb, dark, light, outline, OUTLINE, SKIN

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, "assets", "ui")
ICONS = os.path.join(UI, "icons")
BG = os.path.join(ROOT, "assets", "bg")
FONT = os.path.join(ROOT, "assets", "fonts", "Galmuri11.ttf")

GOLD, GOLD_D = rgb("#ffd447"), rgb("#c8901c")
WHITE = rgb("#f4f0e6")
STEEL = rgb("#c8d2de")
RED = rgb("#d83a34")
GREEN = rgb("#5fbf3a")
BLUE = rgb("#4f8fe0")
WOOD = rgb("#8a5a30")
STONE = rgb("#8f887a")
STONE_D = rgb("#6c6558")
PLATE = rgb("#1b222c")
EDGE = rgb("#cfd6df")


def up(im, k=4):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def label(im, text):
    """Name tag in the bottom-right corner (placeholders only)."""
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 24)
    w = int(d.textlength(text, font=f)) + 16
    x, y = im.width - w - 8, im.height - 40
    d.rectangle([x, y, x + w, y + 32], fill=(0, 0, 0, 170))
    d.text((x + 8, y + 3), text, font=f, fill=(255, 255, 255, 255))
    return im


GEMINI = os.path.join(ROOT, "design", "art", "gemini")


def save(im, folder, name):
    """Saves a placeholder, unless real art came in (design/art/gemini/<name>_원본.*)."""
    import glob
    # 로비 배경 · 성문 조각은 받은 그림(design/art/ui_src, tools/import_lobby_ui.py)을 쓴다: 덮어쓰지 않는다
    if name == "battle_field" and os.path.exists(os.path.join(ROOT, "design", "art", "ui_src", "전투_배경.webp")):
        print("  keep real art:", name)
        return
    if name in ("lobby_bg", "gate1_door_l", "gate1_door_r", "gate1_hole") and os.path.exists(os.path.join(ROOT, "design", "art", "ui_src", "로비_배경.webp")):
        print("  keep real art:", name)
        return
    if glob.glob(os.path.join(GEMINI, name + "_원본.*")):
        print("  keep real art:", name)
        return
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name + ".png"))


# ------------------------------------------------------------------ icons (16 x 16 dots -> 64 px)
def icon(fn, size=16):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fn(ImageDraw.Draw(im))
    return up(outline(im))


def tri(d, pts, c):
    d.polygon(pts, fill=c)


def gear(d, c=STEEL):
    for a in [(7, 0, 8, 15), (0, 7, 15, 8), (2, 2, 4, 4), (11, 2, 13, 4), (2, 11, 4, 13), (11, 11, 13, 13)]:
        d.rectangle(a, fill=c)
    d.ellipse([2, 2, 13, 13], fill=c)
    d.ellipse([5, 5, 10, 10], fill=PLATE)


def gift(d, x=0, y=0, c=RED):
    d.rectangle([x + 2, y + 6, x + 13, y + 14], fill=c)
    d.rectangle([x + 1, y + 4, x + 14, y + 7], fill=light(c, 0.2))
    d.rectangle([x + 7, y + 4, x + 8, y + 14], fill=GOLD)
    d.line([(x + 7, y + 4), (x + 4, y + 1)], fill=GOLD, width=2)
    d.line([(x + 8, y + 4), (x + 11, y + 1)], fill=GOLD, width=2)


def skull(d, x, y):
    d.ellipse([x, y, x + 6, y + 5], fill=WHITE)
    d.rectangle([x + 1, y + 4, x + 5, y + 6], fill=WHITE)
    d.point((x + 2, y + 3), fill=OUTLINE)
    d.point((x + 4, y + 3), fill=OUTLINE)


def arrow_r(d, c, y=8, x0=2, x1=13):
    d.line([(x0, y), (x1 - 3, y)], fill=c, width=3)
    tri(d, [(x1 - 4, y - 4), (x1, y), (x1 - 4, y + 4)], c)


def star(d, c=GOLD, s=1.0, ox=0, oy=0):
    pts = [(7.5, 1), (9.5, 6), (14, 6), (10.5, 9), (12, 14), (7.5, 11), (3, 14), (4.5, 9), (1, 6), (5.5, 6)]
    d.polygon([(ox + x * s, oy + y * s) for x, y in pts], fill=c)


ICON = {
    # 행동 버튼 (design/ux/UI-그림-규격.md §5.3)
    "act_ok": lambda d: d.line([(2, 8), (6, 12), (14, 3)], fill=GREEN, width=3),
    "act_cancel": lambda d: (d.line([(3, 3), (12, 12)], fill=RED, width=3), d.line([(12, 3), (3, 12)], fill=RED, width=3)),
    "act_play": lambda d: tri(d, [(4, 2), (13, 8), (4, 14)], GOLD),
    "act_next": lambda d: (tri(d, [(1, 3), (8, 8), (1, 13)], GOLD), tri(d, [(8, 3), (15, 8), (8, 13)], GOLD)),
    "act_retry": lambda d: (d.arc([2, 2, 13, 13], 40, 330, fill=GOLD, width=3), tri(d, [(10, 0), (15, 4), (10, 7)], GOLD)),
    "act_home": lambda d: (d.rectangle([2, 7, 13, 14], fill=rgb("#c8b490")), tri(d, [(1, 7), (7.5, 1), (14, 7)], rgb("#3a5a8a")), d.rectangle([6, 10, 9, 14], fill=WOOD)),
    "act_go": lambda d: arrow_r(d, GOLD),
    "act_absorb": lambda d: (d.line([(1, 3), (7, 8)], fill=BLUE, width=2), d.line([(1, 13), (7, 8)], fill=BLUE, width=2), arrow_r(d, GOLD, 8, 6, 15)),
    "act_synth": lambda d: (d.rectangle([0, 1, 3, 4], fill=STEEL), d.rectangle([0, 6, 3, 9], fill=STEEL), d.rectangle([0, 11, 3, 14], fill=STEEL), arrow_r(d, GOLD, 8, 4, 11), d.rectangle([11, 5, 15, 10], fill=rgb("#b07ae8"))),
    "act_enhance": lambda d: (d.rectangle([2, 2, 10, 6], fill=STEEL), d.line([(6, 6), (12, 14)], fill=WOOD, width=2)),
    "act_break": lambda d: (d.polygon([(2, 2), (7, 2), (6, 7), (2, 9)], fill=rgb("#b07ae8")), d.polygon([(9, 2), (14, 3), (13, 9), (8, 7)], fill=rgb("#b07ae8")), d.polygon([(3, 11), (8, 9), (12, 11), (8, 14)], fill=rgb("#b07ae8"))),
    "act_buy": lambda d: (d.ellipse([1, 4, 10, 13], fill=GOLD), d.point((5, 8), fill=GOLD_D), arrow_r(d, GREEN, 8, 9, 16)),
    "act_claim": lambda d: gift(d),
    "act_claim_all": lambda d: (gift(d, -2, -1, rgb("#8a4ad8")), gift(d, 2, 2)),
    "act_trash": lambda d: (d.rectangle([3, 4, 12, 14], fill=STEEL), d.rectangle([1, 2, 14, 3], fill=STEEL), d.rectangle([6, 0, 9, 1], fill=STEEL), d.line([(6, 6), (6, 12)], fill=STONE_D), d.line([(9, 6), (9, 12)], fill=STONE_D)),
    "act_done": lambda d: (d.ellipse([1, 1, 14, 14], fill=rgb("#4a5260")), d.line([(4, 8), (7, 11), (12, 4)], fill=WHITE, width=2)),
    "act_equip": lambda d: (d.rectangle([2, 9, 13, 14], fill=WOOD), d.line([(7, 1), (7, 9)], fill=GREEN, width=3), tri(d, [(3, 5), (7, 10), (12, 5)], GREEN)),
    "act_unequip": lambda d: (d.rectangle([2, 9, 13, 14], fill=WOOD), d.line([(7, 3), (7, 10)], fill=RED, width=3), tri(d, [(3, 5), (7, 0), (12, 5)], RED)),
    "act_auto": lambda d: (d.rectangle([2, 9, 13, 14], fill=WOOD), star(d, GOLD, 0.6, 3, 0)),
    "act_revive": lambda d: (d.ellipse([1, 3, 8, 10], fill=RED), d.ellipse([7, 3, 14, 10], fill=RED), tri(d, [(1, 7), (14, 7), (7.5, 14)], RED), d.line([(7, 5), (7, 11)], fill=WHITE, width=2), d.line([(4, 8), (10, 8)], fill=WHITE, width=2)),
    "act_ticket": lambda d: (d.rectangle([1, 4, 14, 12], fill=GOLD), d.line([(5, 4), (5, 12)], fill=GOLD_D), d.line([(10, 6), (10, 10)], fill=OUTLINE), d.line([(8, 8), (12, 8)], fill=OUTLINE)),
    "act_shop": lambda d: (tri(d, [(1, 6), (7.5, 1), (14, 6)], RED), d.rectangle([2, 6, 13, 14], fill=rgb("#e8d8b0")), d.rectangle([6, 9, 9, 14], fill=WOOD)),
    "act_odds": lambda d: (d.rectangle([2, 2, 13, 13], fill=WHITE), d.point((5, 5), fill=OUTLINE), d.point((10, 10), fill=OUTLINE), d.point((7, 7), fill=OUTLINE), d.point((10, 5), fill=OUTLINE), d.point((5, 10), fill=OUTLINE)),
    "act_settings": lambda d: gear(d),
    "act_retreat": lambda d: (d.line([(3, 1), (3, 15)], fill=WOOD, width=2), d.polygon([(4, 2), (14, 4), (12, 7), (14, 10), (4, 9)], fill=WHITE)),
    "act_exit": lambda d: (d.rectangle([2, 1, 10, 14], fill=WOOD), d.point((8, 8), fill=GOLD), arrow_r(d, RED, 8, 8, 16)),
    # 필터 (§5.2)
    "flt_all": lambda d: [d.rectangle([x, y, x + 5, y + 5], fill=STEEL) for x in (2, 9) for y in (2, 9)],
    "flt_mine": lambda d: (d.rectangle([2, 2, 13, 13], outline=STEEL, width=2), d.line([(4, 8), (7, 11), (12, 4)], fill=GREEN, width=2)),
    # 탭 (§5.1)
    "tab_hero": lambda d: (d.ellipse([3, 3, 12, 12], fill=SKIN), d.pieslice([3, 1, 12, 10], 180, 360, fill=RED), d.rectangle([4, 12, 11, 15], fill=GOLD), d.point((10, 7), fill=OUTLINE)),
    "tab_soldier": lambda d: (d.ellipse([2, 3, 10, 11], fill=SKIN), d.pieslice([2, 1, 10, 9], 180, 360, fill=STEEL), d.rectangle([3, 11, 9, 15], fill=BLUE), d.line([(13, 0), (13, 15)], fill=WOOD, width=2), tri(d, [(11, 2), (13, 0), (15, 2)], STEEL)),
    "tab_growth": lambda d: star(d),
    "tab_trait": lambda d: (d.ellipse([2, 2, 13, 13], fill=rgb("#4ac8e8")), d.ellipse([4, 4, 7, 7], fill=WHITE), d.point((12, 1), fill=GOLD), d.point((1, 12), fill=GOLD)),
    "tab_gear": lambda d: (d.polygon([(6, 5), (14, 5), (14, 10), (10, 15), (6, 10)], fill=BLUE), d.line([(1, 14), (9, 2)], fill=STEEL, width=2), d.line([(1, 11), (4, 14)], fill=GOLD, width=2)),
    "tab_daily": lambda d: (d.ellipse([4, 4, 11, 11], fill=GOLD), [d.point(p, fill=GOLD) for p in [(7, 1), (8, 1), (7, 14), (8, 14), (1, 7), (1, 8), (14, 7), (14, 8), (3, 3), (12, 3), (3, 12), (12, 12)]]),
    "tab_weekly": lambda d: (d.rectangle([1, 3, 14, 14], fill=WHITE), d.rectangle([1, 3, 14, 5], fill=RED), [d.rectangle([x, y, x + 1, y + 1], fill=OUTLINE) for x in (3, 7, 11) for y in (8, 11)]),
    "tab_trophy": lambda d: (d.rectangle([4, 1, 11, 8], fill=GOLD), d.arc([0, 1, 6, 7], 90, 270, fill=GOLD, width=2), d.arc([9, 1, 15, 7], 270, 90, fill=GOLD, width=2), d.rectangle([7, 8, 8, 11], fill=GOLD), d.rectangle([4, 12, 11, 14], fill=GOLD_D)),
    "tab_pick": lambda d: (star(d, rgb("#ff8ad8")), d.point((14, 1), fill=WHITE), d.point((1, 14), fill=WHITE)),
    "tab_pack": lambda d: (d.rectangle([1, 6, 9, 14], fill=WOOD), d.rectangle([6, 2, 14, 10], fill=light(WOOD, 0.2)), d.rectangle([9, 2, 10, 10], fill=GOLD), d.rectangle([4, 6, 5, 14], fill=GOLD)),
    # 난이도 (§5.4): 해골 1 · 2 · 3개
    "diff_1": lambda d: skull(d, 4, 4),
    "diff_2": lambda d: (skull(d, 0, 4), skull(d, 8, 4)),
    "diff_3": lambda d: (skull(d, 4, 0), skull(d, 0, 8), skull(d, 8, 8)),
}


# ------------------------------------------------------------------ whole-picture buttons (§4.3)
def plate(w, h, edge=EDGE, fill=PLATE):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], fill=OUTLINE)
    d.rectangle([1, 1, w - 2, h - 2], fill=fill)
    d.rectangle([1, 1, w - 2, h - 2], outline=edge)
    d.line([(2, 2), (w - 3, 2)], fill=light(fill, 0.15))
    return im, d


def picture_button(w, h, glyph, edge=EDGE, fill=PLATE):
    """Plate (w x h dots) with a 16-dot glyph in the middle (wide plates: on the left)."""
    im, d = plate(w, h, edge, fill)
    g = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    ICON[glyph](ImageDraw.Draw(g)) if glyph in ICON else BIG[glyph](ImageDraw.Draw(g))
    g = outline(g)
    k = max(1, min((w - 4) // 16, (h - 4) // 16))
    g = g.resize((16 * k, 16 * k), Image.NEAREST)
    x = (w - g.width) // 2 if w < h * 2.5 else 8
    im.alpha_composite(g, (x, (h - g.height) // 2))
    return up(im)


BIG = {
    "mail": lambda d: (d.rectangle([1, 3, 14, 12], fill=WHITE), d.line([(1, 3), (7.5, 9), (14, 3)], fill=STONE_D, width=1), d.rectangle([11, 4, 13, 6], fill=RED)),
    "mission": lambda d: (d.rectangle([3, 2, 12, 13], fill=rgb("#f2e6c8")), d.rectangle([2, 1, 13, 2], fill=rgb("#b05030")), d.rectangle([2, 13, 13, 14], fill=rgb("#b05030")), d.line([(5, 6), (10, 6)], fill=RED), d.line([(5, 9), (10, 9)], fill=WOOD)),
    "bag": lambda d: (d.ellipse([2, 5, 13, 14], fill=rgb("#c89a5a")), d.rectangle([5, 2, 10, 6], fill=rgb("#a87a3a")), d.line([(11, 1), (14, 6)], fill=STEEL, width=2)),
    "flag": lambda d: (d.line([(4, 1), (4, 15)], fill=WOOD, width=2), d.polygon([(5, 2), (14, 4), (5, 9)], fill=GOLD)),
    "pause": lambda d: (d.rectangle([4, 3, 6, 12], fill=WHITE), d.rectangle([9, 3, 11, 12], fill=WHITE)),
    "plus": lambda d: (d.rectangle([7, 2, 8, 13], fill=WHITE), d.rectangle([2, 7, 13, 8], fill=WHITE)),
    "swords": lambda d: (d.line([(2, 2), (12, 12)], fill=STEEL, width=2), d.line([(13, 2), (3, 12)], fill=STEEL, width=2), d.line([(9, 13), (13, 9)], fill=GOLD, width=2), d.line([(2, 9), (6, 13)], fill=GOLD, width=2)),
    "fan": lambda d: (d.pieslice([0, 1, 15, 16], 200, 340, fill=WHITE), d.line([(7, 8), (7, 15)], fill=WOOD, width=2), d.line([(3, 4), (7, 8)], fill=STONE), d.line([(11, 4), (7, 8)], fill=STONE)),
}

# file -> (dots w, dots h, glyph, edge colour, fill)
BUTTONS = {
    "btn_settings": (26, 26, "act_settings", EDGE, PLATE),
    "btn_mail": (30, 32, "mail", EDGE, PLATE),
    "btn_mission": (30, 32, "mission", EDGE, PLATE),
    "btn_pause": (22, 22, "pause", EDGE, PLATE),
    "btn_plus": (16, 16, "plus", GOLD, rgb("#2a3e1e")),
    "btn_battle": (64, 38, "swords", rgb("#ff6b5b"), rgb("#4a1717")),
    "btn_advisor": (64, 32, "fan", rgb("#c79bff"), rgb("#2c1d45")),
}


# ------------------------------------------------------------------ lobby buttons (2026-11-23: 출정 북 + 쟁패 깃발)
# ------------------------------------------------------------------ lobby (한 장, 성문 하나)
# ------------------------------------------------------------------ other backgrounds
def plain_bg(name, w, h, top, bottom, note):
    im = Image.new("RGBA", (w, h), rgb(top))
    d = ImageDraw.Draw(im)
    for y in range(h):
        k = y / max(1, h - 1)
        a, b = rgb(top), rgb(bottom)
        d.line([(0, y), (w, y)], fill=tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3)) + (255,))
    for y in range(0, h, 16):
        for x in range((y // 16 % 2) * 8, w, 16):
            d.point((x, y), fill=(255, 255, 255, 40))
    return label(up(im), "%s %dx%d (%s)" % (name, w * 4, h * 4, note))


def main():
    os.makedirs(ICONS, exist_ok=True)
    for name, fn in ICON.items():
        icon(fn).save(os.path.join(ICONS, name + ".png"))
    # 로비 · 전투의 버튼은 제미나이 그림(tools/import_lobby_ui.py · import_battle_ui.py)을 쓴다. 여기서는 "+"만 만든다.
    for name, (w, h, g, e, f) in BUTTONS.items():
        if name == "btn_plus":
            save(picture_button(w, h, g, e, f), UI, name)
    save(plain_bg("intro_bg", 256, 448, "#20304a", "#0d1117", "배경"), BG, "intro_bg")
    save(plain_bg("menu_bg", 256, 448, "#2a3a2a", "#141a14", "메뉴 배경"), BG, "menu_bg")
    print("placeholders: icons %d, buttons 1, bg 2" % len(ICON))


if __name__ == "__main__":
    main()
