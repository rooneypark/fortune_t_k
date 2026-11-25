#!/usr/bin/env python3
"""창 없는 화면 미리보기 (2026-11-25): tools/layout_dump.tscn 이 남긴 배치 기록(design/ux/규격/raw/*.json)을
그림 파일로 다시 그린다. 게임 창을 띄우지 않고 "지금 코드가 화면을 어떻게 그리는지"를 시안과 나란히 볼 수 있다.

  godot --headless --path . --audio-driver Dummy res://tools/layout_dump.tscn -- --no-save --save=<임시 json>
  python tools/layout_preview.py [이름 일부 ...]      (예: python tools/layout_preview.py 12_ 15_)

- 판 · 버튼: assets/ui 의 그림(9-slice 여백은 nine.json, 선 UI 이름은 px.gd 의 KIT 와 같은 표로 kit_* 그림에 잇는다)
- 그림: assets/ui · assets/ui/icons · assets/bg · assets/portraits 에서 이름으로 찾는다. 없으면 회색 칸 + 이름
- 글자: 기록된 크기 · 정렬로 쓴다 (글꼴은 맑은 고딕이라 폭이 게임과 조금 다르다)
결과: design/ux/규격/preview/<이름>.png  (1024 x 1792)
게임 화면과 똑같지는 않다 — 유닛 그림 · 직접 그리는 선 · 효과는 빠진다. 자리와 부품을 맞추는 용도다.
"""
import glob
import json
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "design", "ux", "규격", "raw")
OUT = os.path.join(ROOT, "design", "ux", "규격", "preview")
UI = os.path.join(ROOT, "assets", "ui")
DIRS = [UI, os.path.join(UI, "icons"), os.path.join(ROOT, "assets", "bg"), os.path.join(ROOT, "assets", "portraits")]
FONT = "C:/Windows/Fonts/malgunbd.ttf"
KIT = {"panel_ctrl": "kit_frame", "panel_wide": "kit_frame", "plate_title": "kit_title", "plate_lever": "kit_title",
       "tab_yellow": "kit_btn_yellow", "tab_red": "kit_btn_red", "tab_purple": "kit_btn_purple", "tab_blue": "kit_btn_blue",
       "tab_wood": "kit_tab_off", "tab_wood_on": "kit_tab_on", "tile": ""}
NINE = json.load(open(os.path.join(UI, "nine.json"), encoding="utf-8"))
_cache = {}


def find(name):
    if name in _cache:
        return _cache[name]
    im = None
    for d in DIRS:
        p = os.path.join(d, name + ".png")
        if os.path.exists(p):
            im = Image.open(p).convert("RGBA")
            break
    _cache[name] = im
    return im


def nine(im, w, h, m):
    l, t, r, b = (m, m, m, m) if not isinstance(m, list) else m
    l, r = min(l, w // 2), min(r, w // 2)
    t, b = min(t, h // 2), min(b, h // 2)
    a = np.array(im)
    sh, sw = a.shape[:2]
    out = Image.new("RGBA", (w, h))
    xs = [(0, l, 0, l), (l, sw - r, l, w - r), (sw - r, sw, w - r, w)]
    ys = [(0, t, 0, t), (t, sh - b, t, h - b), (sh - b, sh, h - b, h)]
    for sy0, sy1, dy0, dy1 in ys:
        for sx0, sx1, dx0, dx1 in xs:
            if dx1 > dx0 and dy1 > dy0 and sx1 > sx0 and sy1 > sy0:
                out.paste(Image.fromarray(a[sy0:sy1, sx0:sx1]).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST), (dx0, dy0))
    return out


def panel_art(name):
    base = name[:-8] if name.endswith("_pressed") else name
    if base in NINE and find(base) is not None:
        return base
    k = KIT.get(base, "kit_box")
    return k if k and k in NINE and find(k) is not None else ""


def render(path):
    d = json.load(open(path, encoding="utf-8"))
    off = int((d["canvas"][0] - 1024) / 2)
    img = Image.new("RGBA", (1024, 1792), (40, 44, 54, 255))
    dr = ImageDraw.Draw(img)
    small = ImageFont.truetype(FONT, 14)
    for it in d["items"]:
        x, y, w, h = int(it["x"]) - off, int(it["y"]), int(it["w"]), int(it["h"])
        if w < 2 or h < 2:
            continue
        kind, label = it["kind"], str(it["label"])
        if kind == "panel":
            art = panel_art(label)
            if art:
                img.alpha_composite(nine(find(art), w, h, NINE[art]), (x, y)) if -2000 < x < 3000 else None
            else:
                dr.rectangle([x, y, x + w - 1, y + h - 1], outline=(200, 210, 225, 255), width=2)
        elif kind in ("image", "button"):
            im = find(label)
            if im is not None:
                tile = im.resize((w, h), Image.NEAREST)
                img.alpha_composite(tile, (max(x, -w), y)) if 0 <= x < 1024 and 0 <= y < 1792 else img.paste(tile, (x, y), tile)
            elif kind == "image":
                dr.rectangle([x, y, x + w - 1, y + h - 1], fill=(90, 96, 110, 255), outline=(150, 160, 175, 255))
                dr.text((x + 3, y + 2), label[:14], font=small, fill=(230, 230, 230, 255))
        elif kind == "text":
            ex = it.get("extra", {})
            fs = max(8, int(ex.get("fs", 20)))
            f = ImageFont.truetype(FONT, int(fs * 0.86))
            label = " ".join(label.split())
            tw = dr.textlength(label, font=f)
            al = int(ex.get("align", 1))
            tx = x if al == 0 else (x + (w - tw) / 2 if al == 1 else x + w - tw)
            ty = y + (h - fs) / 2
            dr.text((tx, ty), label, font=f, fill=(255, 255, 255, 255), stroke_width=2, stroke_fill=(20, 18, 20, 255))
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, os.path.basename(path)[:-5] + ".png")
    img.convert("RGB").save(out)
    return out


if __name__ == "__main__":
    keys = sys.argv[1:]
    for p in sorted(glob.glob(os.path.join(RAW, "*.json"))):
        if not keys or any(k in os.path.basename(p) for k in keys):
            print(render(p))
