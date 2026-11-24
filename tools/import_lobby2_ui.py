#!/usr/bin/env python3
"""로비 그림 (2026-11-24 민수 님 확정) -> 로비 부품.
3차(지금): 단순한 도트 + 요즘 자동 디펜스 느낌, UI 색을 성에 맞춤(먹색 판 · 차분한 금테 · 주홍 출정 탭), 아래 탭 글자 자리.
(2차 원본 로비2_*.webp 는 남겨 둔다.)

원본: design/art/ui_src/  (모두 화면 크기 1024 x 1792 그대로라 키우지 않는다)
  로비3_배경.png      UI 없는 배경 (하늘 · 성루 · 성벽 · 빈 현판 · 성문 · 광장)
  로비3_UI.png        마젠타 바탕의 UI 부품 하나씩 (초상 틀 · 금 칸 · 군량 칸 · 톱니 · 편지 · 두루마리 · 빈 탭 · 빈 출정 탭 ·
                      탭 줄 바탕 · 탭 아이콘 5개). 배열이 그림마다 달라서 순서가 아니라 모양 · 자리로 부품을 가른다.
  로비3_완성화면.png  비교용 (부품 자리는 이 그림에서 잰 값)

- 버튼 · 틀은 완성 화면의 자리 크기로 맞춘다 (부품 그림은 완성 화면과 크기가 조금 다르게 그려져 있다).
- 탭 줄 바탕 · 탭 · 출정 탭은 9-slice (assets/ui/nine.json). 탭은 아래 여백에 글자 띠를 넣어 띠 높이는 그대로 둔다.
  아이콘은 게임이 탭 위쪽에, 글자(장수 · 가방 · 출정 · 쟁패 · 상점)는 아래 띠에 쓴다.
- 아래 탭은 완성 화면 자리 그대로 (탭 줄 y 1522). 다이얼로그(장수 · 가방 · 상점 창) 아래 끝은 1520 (app.gd DIALOG_RECT).
- 성문 열림: 배경의 나무 문짝(어두운 나무 + 쇠띠)을 색으로 골라 왼쪽 · 오른쪽 두 장과 문 안쪽 어둠을 만든다 (gate1_*).
- 성문 위 현판(빈 판)에는 게임이 스테이지 이름을 쓴다 (lobby_layout.json 의 lobby_plaque).

Usage: python tools/import_lobby2_ui.py    (확인용: design/art/ui_src/로비2_합성확인.png)
"""
import json
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

# 마젠타 그림의 부품 차례 (위 → 아래, 같은 줄은 왼쪽 → 오른쪽)
PARTS = ["lobby_portrait", "lobby_chip_gold", "lobby_chip_rice",
         "lobby_btn_settings", "lobby_btn_mail", "lobby_btn_mission",
         "lobby_tab", "lobby_tab_gold", "lobby_tab_bar",
         "lobby_ic_hero", "lobby_ic_bag", "lobby_ic_stage", "lobby_ic_arena", "lobby_ic_shop"]
# 화면 자리 (x, y, w, h) — 위쪽은 완성 화면에서 잰 값, 아래 탭은 다이얼로그 아래 끝(1576)에 맞춘 값
LAYOUT = {
    "lobby_portrait": [17, 14, 174, 180],
    "lobby_chip_gold": [197, 29, 334, 94],
    "lobby_chip_rice": [536, 29, 349, 94],
    "lobby_btn_settings": [898, 27, 108, 108],
    "lobby_btn_mail": [898, 148, 108, 108],
    "lobby_btn_mission": [898, 270, 108, 108],
    "lobby_plaque": [374, 450, 277, 62],          # 현판 속 (배경 그림의 빈 판) — 스테이지 이름 자리
    "lobby_tab_bar": [0, 1522, 1024, 270],          # 완성 화면 그대로 (2026-11-24: 창 아래 끝을 1520으로 올림)
    "lobby_tab_hero": [4, 1528, 194, 258],
    "lobby_tab_bag": [202, 1528, 190, 258],
    "lobby_tab_stage": [394, 1496, 230, 290],       # 가운데 출정 탭: 줄 위로 솟는다
    "lobby_tab_arena": [626, 1528, 190, 258],
    "lobby_tab_shop": [820, 1528, 198, 258],
}
# 9-slice 여백 [왼, 위, 오른, 아래]: 탭은 아래 여백에 글자 띠가 통째로 들어가 띠는 늘어나지 않고 위 아이콘 칸만 늘어난다
NINE = {"lobby_tab_bar": 16, "lobby_tab": [18, 18, 18, 84], "lobby_tab_gold": [22, 22, 22, 88]}
GATE = (381, 574, 263, 301)                          # 배경의 성문 나무 문짝 자리 (3차 그림)


def gate_pieces(bg):
    x, y, w, h = GATE
    door = bg[y:y + h, x:x + w].copy()
    lum = door[..., :3].astype(float).mean(axis=2)
    inside = ndimage.binary_fill_holes(lum < 125)
    lab, n = ndimage.label(inside)
    if n > 1:
        sizes = ndimage.sum(inside, lab, range(1, n + 1))
        inside = lab == (1 + int(np.argmax(sizes)))
    door[~inside, 3] = 0
    left, right = door.copy(), door.copy()
    left[:, w // 2:, 3] = 0
    right[:, : w // 2, 3] = 0
    Image.fromarray(left[:, : w // 2]).save(os.path.join(L.UI, "gate1_door_l.png"))
    Image.fromarray(right[:, w // 2:]).save(os.path.join(L.UI, "gate1_door_r.png"))
    hole = np.zeros((h, w, 4), np.uint8)
    hole[inside] = (14, 10, 8, 255)
    yy = np.mgrid[0:h, 0:w][0]
    hole[inside & (yy > h - 24)] = (40, 30, 22, 255)
    Image.fromarray(hole).save(os.path.join(L.UI, "gate1_hole.png"))


# 받은 UI 그림의 탭 · 탭 아이콘은 쓰지 않는다 (시안에서 탭을 직접 떼어 낸다, tabs_from_mockup)
SKIP = {"lobby_tab", "lobby_tab_gold", "lobby_tab_bar", "lobby_ic_hero", "lobby_ic_bag", "lobby_ic_stage", "lobby_ic_arena", "lobby_ic_shop"}


def classify(comps):
    """마젠타 그림의 덩어리 -> 부품 이름 (모양 · 자리로)."""
    box = {c: (c[1], c[2], c[3] - c[1], c[4] - c[2]) for c in comps}
    left = list(comps)
    out = {}

    def take(name, c):
        out[name] = c
        left.remove(c)

    icons = sorted([c for c in left if box[c][1] > 1050], key=lambda c: box[c][0])
    for name, c in zip(["lobby_ic_hero", "lobby_ic_bag", "lobby_ic_stage", "lobby_ic_arena", "lobby_ic_shop"], icons):
        take(name, c)
    take("lobby_tab_bar", max(left, key=lambda c: box[c][2]))
    rounds = sorted([c for c in left if box[c][0] > 760 and abs(box[c][2] - box[c][3]) < 20], key=lambda c: box[c][1])
    for name, c in zip(["lobby_btn_settings", "lobby_btn_mail", "lobby_btn_mission"], rounds):
        take(name, c)
    bars = sorted([c for c in left if box[c][2] > 2.5 * box[c][3]], key=lambda c: box[c][1])
    for name, c in zip(["lobby_chip_gold", "lobby_chip_rice"], bars):
        take(name, c)
    tabs = sorted([c for c in left if box[c][1] > 500], key=lambda c: box[c][2] * box[c][3])
    take("lobby_tab", tabs[0])
    take("lobby_tab_gold", tabs[1])
    take("lobby_portrait", left[0])
    return out


# 아래 탭 (2026-11-24 민수 님: 받은 탭 부품이 시안과 달라서, 시안(완성 화면)에서 직접 떼어 낸다 — 아이콘 · 빈 글자 띠 포함)
# 탭 자리 = 탭 테두리까지만 (보통 탭 아래 끝 y 1771, 출정 탭 1765). 그 아래 탭 줄은 탭 그림에 넣지 않는다 —
# 넣으면 누를 때 탭 줄까지 같이 눌려 보인다 (2026-11-24 민수 님).
MOCK_TABS = {"lobby_tab_hero": (0, 1525, 200, 248), "lobby_tab_bag": (200, 1525, 193, 248),
             "lobby_tab_stage": (389, 1495, 244, 272), "lobby_tab_arena": (625, 1525, 192, 248),  # 출정 탭은 윤곽선이 양옆으로 조금 나와 있다
             "lobby_tab_shop": (817, 1525, 207, 248)}


def tabs_from_mockup(layout):
    """시안에서 아래 탭 5칸을 그대로 잘라 낸다. 탭 줄보다 위로 솟은 출정 탭 윗부분은 배경과 다른 칸만 남긴다.
    글자 띠 자리(탭 안 px)는 layout 의 tab_band · tab_band_stage 에 적는다."""
    full = np.array(Image.open(os.path.join(L.SRC, "로비3_완성화면.png")).convert("RGBA")).astype(int)
    bg = np.array(Image.open(os.path.join(L.SRC, "로비3_배경.png")).convert("RGB")).astype(int)
    bar_top = 1525
    for name, (x, y, w, h) in MOCK_TABS.items():
        piece = full[y:y + h, x:x + w].copy()
        # 탭 모양대로: 배경(모래)과 다른 칸만 남기고, 가장자리를 2px 넉넉히 (윤곽선 끝 픽셀이 빠지지 않게).
        # 넉넉히 남긴 칸은 배경과 같은 색이라 보이지 않는다. 둥근 모서리 바깥은 투명이라 누를 때 탭만 내려간다.
        d = np.abs(full[y:y + h, x:x + w, :3] - bg[y:y + h, x:x + w]).sum(axis=2) > 30
        d = np.pad(d, 4, mode="edge")
        keep = ndimage.binary_fill_holes(ndimage.binary_closing(d, iterations=2))
        keep = ndimage.binary_dilation(keep, iterations=2)[4:-4, 4:-4]
        piece[..., 3] = np.where(keep, 255, 0)
        Image.fromarray(piece.astype(np.uint8)).save(os.path.join(L.UI, name + ".png"))
        layout[name] = [x, y, w, h]
        # 글자 띠 (탭 안 px, 시안에서 잰 값): 보통 탭 y 150~212, 출정 탭 y 178~242
        key = "tab_band_stage" if name == "lobby_tab_stage" else "tab_band"
        layout[key] = [12, 178, 0, 64] if key == "tab_band_stage" else [12, 150, 0, 62]
        print("%-18s %s band %s" % (name, (x, y, w, h), layout.get(key)))
    # 탭 줄 바탕: 시안의 띠에서 탭을 지운 것 (탭 자리는 탭 아래 바탕색으로 채운다). 탭을 눌러 내려가도 뒤에 탭이 겹쳐 보이지 않는다.
    strip = full[bar_top:, :, :].copy()
    body = full[1780, :, :].copy()
    strip[: 1772 - bar_top] = body[None, :, :]
    strip[: 1758 - bar_top, :, 3] = 0               # 탭 뒤 위쪽은 비운다 (누를 때 탭 위로 어두운 줄이 비치지 않게)
    Image.fromarray(strip.astype(np.uint8)).save(os.path.join(L.UI, "lobby_tab_bar.png"))
    layout["lobby_tab_bar"] = [0, bar_top, L.CW, L.CH - bar_top]


def main():
    bgim = Image.open(os.path.join(L.SRC, "로비3_배경.png")).convert("RGB").resize((L.CW, L.CH))
    bgim.save(os.path.join(L.BG, "lobby_bg.png"))
    gate_pieces(np.array(bgim.convert("RGBA")))

    col, alpha = L.matte(L.load("로비3_UI.png"))
    lab, comps = L.components(alpha, 800)
    named = classify(comps)
    assert set(named) == set(PARTS), sorted(set(PARTS) - set(named))
    layout = dict(LAYOUT)
    # 탭 그림의 자리 이름: 보통 탭 4칸 · 출정 탭 1칸은 같은 그림을 쓴다
    size_of = {"lobby_tab": LAYOUT["lobby_tab_hero"], "lobby_tab_gold": LAYOUT["lobby_tab_stage"]}
    for name in PARTS:
        if name in SKIP:
            continue
        im, box = L.cut(col, alpha, lab, named[name])
        target = LAYOUT.get(name) or size_of.get(name)
        if target is not None and name not in NINE:      # 9-slice 부품은 그림 그대로 (게임이 늘린다)
            im = L.scale_rgba(im, target[2], target[3])
        im.save(os.path.join(L.UI, name + ".png"))
        print("%-20s %s" % (name, im.size))
    tabs_from_mockup(layout)
    json.dump(layout, open(os.path.join(L.UI, "lobby_layout.json"), "w", encoding="utf-8"), indent=1)
    path = os.path.join(L.UI, "nine.json")
    nine = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    for k in ("lobby_tab", "lobby_tab_gold", "lobby_tab_bar"):
        nine.pop(k, None)
    json.dump(nine, open(path, "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
