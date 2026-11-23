#!/usr/bin/env python3
"""화면별 UI 영역 지도 (제미나이 · 그림 의뢰용).

tools/layout_dump.tscn 이 남긴 design/ux/규격/raw/*.json 을 읽어서, 화면마다
1024 x 1792 지도 PNG 를 그린다: 그림 · 버튼 · 판의 자리를 색 상자 + "이름 크기"로.
글자 자리는 옅은 줄로만. 결과: design/ux/규격/zones/<번호_이름>.png
추가 예정 화면은 FUTURE 에 손으로 적은 배치로 그린다.

Usage: python tools/zone_maps.py
"""
import glob, json, os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "design", "ux", "규격", "raw")
OUT = os.path.join(ROOT, "design", "ux", "규격", "zones")
FONT = os.path.join(ROOT, "assets", "fonts", "Galmuri11.ttf")
W, H = 1024, 1792

# kind -> (fill rgba, line rgb)
STYLE = {
    "bg": ((40, 60, 90, 255), (90, 120, 160)),
    "image": ((60, 160, 90, 70), (80, 220, 120)),
    "button": ((230, 170, 40, 70), (255, 200, 60)),
    "panel": ((120, 140, 170, 40), (170, 190, 220)),
    "text": ((255, 255, 255, 18), (140, 140, 140)),
}
SKIP_IMG = ("000",)          # 이름 없는 캐릭터 그림 조각


def font(n):
    return ImageFont.truetype(FONT, n)


def tag(d, x, y, s, col, f):
    w = int(d.textlength(s, font=f)) + 8
    d.rectangle([x, y, x + w, y + f.size + 6], fill=(0, 0, 0, 200))
    d.text((x + 4, y + 2), s, font=f, fill=col)


def draw(title, items, path):
    im = Image.new("RGBA", (W, H), (20, 24, 30, 255))
    d = ImageDraw.Draw(im)
    f, fs = font(22), font(18)
    for x in range(0, W, 64):
        d.line([(x, 0), (x, H)], fill=(255, 255, 255, 12))
    for y in range(0, H, 64):
        d.line([(0, y), (W, y)], fill=(255, 255, 255, 12))
    order = {"bg": 0, "panel": 1, "image": 2, "button": 3, "text": 4}
    for it in sorted(items, key=lambda i: order.get(i["kind"], 5)):
        k = it["kind"]
        x, y, w, h = it["x"], it["y"], it["w"], it["h"]
        fill, line = STYLE.get(k, STYLE["panel"])
        if k == "bg":
            d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill)
            tag(d, 8, H - 40, "배경 %s %dx%d" % (it["label"], it["src_w"], it["src_h"]), (200, 220, 255), f)
            continue
        if k == "text":
            d.rectangle([x, y, x + w - 1, y + h - 1], outline=line, width=1)
            continue
        if k in ("image", "button"):
            ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            ImageDraw.Draw(ov).rectangle([x, y, x + w - 1, y + h - 1], fill=fill)
            im.alpha_composite(ov)
            d = ImageDraw.Draw(im)
        d.rectangle([x, y, x + w - 1, y + h - 1], outline=line, width=3)
        if w >= 60 and h >= 30:
            tag(d, x + 4, y + 4, "%s %dx%d" % (it["label"], w, h), line + (255,), fs)
    tag(d, 8, 8, title, (255, 255, 255), font(30))
    im.save(path)


def from_raw(path):
    data = json.load(open(path, encoding="utf-8"))
    cw = int(data["canvas"][0])
    ox = (cw - W) // 2
    out, seen = [], set()
    for it in data["items"]:
        lab = str(it["label"])
        kind = it["kind"]
        if kind == "area" or (kind == "image" and (lab in SKIP_IMG or lab == "")):
            continue
        x = int(it["x"]) - ox
        e = dict(it, x=x)
        if kind == "image" and lab.endswith(("_bg", "_sky", "battle_field")) and int(it["w"]) >= 900:
            e = {"kind": "bg", "label": lab, "x": 0, "y": 0, "w": W, "h": H, "src_w": it["w"], "src_h": it["h"]}
        key = (e["kind"], e["x"], e["y"], e["w"], e["h"], lab)
        if key in seen or e["x"] + e["w"] < 0 or e["x"] > W:
            continue
        seen.add(key)
        out.append(e)
    return out


# 추가 예정 화면 (아직 코드 없음): 이름, [(종류, 이름, x, y, w, h)]
TOP = [("button", "frame_portrait", 36, 12, 148, 188), ("button", "panel_chip 금", 200, 36, 320, 96),
       ("button", "panel_chip 군량", 536, 36, 328, 96), ("button", "btn_settings", 880, 32, 104, 104)]
FUTURE = {
    "90_future_arena_battle": ("추가 예정: 군웅대전 대전 화면 (상대 진영 vs 내 진영)", TOP[:0] + [
        ("bg", "arena_bg", 0, 0, 1024, 1792),
        ("panel", "panel_wide 상대 이름·전투력", 28, 28, 968, 120), ("image", "상대 성 누끼 arena_castle_enemy", 612, 260, 400, 700),
        ("image", "내 성 누끼 arena_castle_mine", 12, 260, 400, 700), ("panel", "전장 띠", 0, 620, 1024, 600),
        ("button", "btn_pause", 912, 160, 88, 88), ("panel", "panel_ctrl 결과·보상", 112, 1300, 800, 420)]),
    "91_future_attendance": ("추가 예정: 출석부 (7일 · 28일)", TOP + [
        ("bg", "menu_bg", 0, 0, 1024, 1792), ("panel", "panel_ctrl 출석 판", 52, 260, 920, 1300),
        ("image", "plate_title 출석", 232, 220, 560, 100)] +
        [("button", "tile 하루 칸", 92 + (i % 4) * 214, 380 + (i // 4) * 260, 200, 240) for i in range(8)] +
        [("button", "tab_yellow 받기", 312, 1420, 400, 120)]),
    "92_future_ranking": ("추가 예정: 순위 (스테이지 · 군웅대전)", TOP + [
        ("bg", "menu_bg", 0, 0, 1024, 1792), ("button", "tab_wood 탭 2개", 60, 232, 904, 96)] +
        [("panel", "panel_slot 순위 줄", 60, 352 + i * 150, 904, 136) for i in range(8)] +
        [("panel", "panel_wide 내 순위", 60, 1580, 904, 136)]),
    "93_future_hero_story": ("추가 예정: 장수 열전 (큰 그림 + 이야기)", TOP + [
        ("bg", "menu_bg", 0, 0, 1024, 1792), ("image", "<id>_lihui 큰 그림", 60, 232, 416, 416),
        ("panel", "panel_ctrl 이야기", 60, 680, 904, 900), ("button", "tab_red 닫기 X", 900, 220, 88, 88)]),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for path in sorted(glob.glob(os.path.join(RAW, "*.json"))):
        name = os.path.splitext(os.path.basename(path))[0]
        draw(name, from_raw(path), os.path.join(OUT, name + ".png"))
        n += 1
    for name, (title, rows) in FUTURE.items():
        items = []
        for k, lab, x, y, w, h in rows:
            e = {"kind": k, "label": lab, "x": x, "y": y, "w": w, "h": h}
            if k == "bg":
                e.update(src_w=w, src_h=h)
            items.append(e)
        draw(title, items, os.path.join(OUT, name + ".png"))
        n += 1
    print("zone maps:", n)


if __name__ == "__main__":
    main()
