#!/usr/bin/env python3
"""로비 4차 (2026-11-25 민수 님): 완성 화면 한 장(1024 x 1792, 게임 화면 크기 그대로)에서 부품을 직접 떼어 낸다.

원본: design/art/ui_src/로비8_완성화면.png  (제미나이, 2D 도트 · 캐릭터 비율에 맞춘 그림을 세로로 다시 받은 것.
      처음 받은 정사각 그림 로비7_완성화면.png 는 비교용으로 남겨 둔다.)

하는 일
- 부품: UI 조각마다 진한 남색 외곽선(5px)이 닫힌 테두리를 이루므로, 외곽선 덩어리를 찾아 속을 채운 모양 그대로 떼어 낸다.
  투명도는 0 아니면 1 (도트 그림이라 반투명 띠를 두지 않는다). 외곽선 바깥의 배경과 섞인 칸은 버리고,
  맨 바깥 한 줄은 외곽선 색으로 덮어 배경색(하늘 · 모래)이 묻어나지 않게 한다. 크기 · 자리는 원본 그대로 (늘리지 않는다).
- 배경: 부품이 있던 자리는 가장 가까운 바깥 색으로 메운다 (버튼이 눌려 내려갈 때 밑에 같은 그림이 비치지 않게).
- 성문 열림: 나무 문짝을 색으로 골라 왼쪽 · 오른쪽 두 장과 문 안쪽 어둠을 만든다 (gate1_*).

결과: assets/bg/lobby_bg.png, assets/ui/lobby_*.png · gate1_*.png, assets/ui/lobby_layout.json
확인용 (게임 실행 아님): design/art/ui_src/로비8_합성확인.png · 로비8_부품확인.png

Usage: python tools/import_lobby4_ui.py
"""
import json
import os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "design", "art", "ui_src")
UI = os.path.join(ROOT, "assets", "ui")
BG = os.path.join(ROOT, "assets", "bg")
CW, CH = 1024, 1792
DARK = 90                        # 외곽선: 밝기(평균)가 이보다 어두운 칸
# 부품을 찾을 칸 (화면 좌표 x0, y0, x1, y1) — 외곽선 덩어리는 이 안에서만 찾는다. 붙어 있는 탭은 칸으로 가른다.
BOXES = {
    "lobby_portrait": (15, 12, 178, 178),
    "lobby_chip_gold": (177, 28, 508, 125),
    "lobby_chip_rice": (507, 28, 880, 125),
    "lobby_btn_settings": (886, 17, 1006, 139),
    "lobby_btn_mail": (886, 139, 1006, 256),
    "lobby_btn_mission": (886, 256, 1006, 377),
    "lobby_tab_hero": (14, 1583, 204, 1768),
    "lobby_tab_bag": (204, 1583, 405, 1768),
    "lobby_tab_stage": (405, 1560, 618, 1769),
    "lobby_tab_arena": (618, 1583, 819, 1768),
    "lobby_tab_shop": (819, 1583, 1011, 1768),
}
PLAQUE = [396, 702, 234, 50]     # 현판 속 어두운 판 (배경에 그려져 있다) — 스테이지 이름 자리
GATE = (383, 788, 258, 268)      # 성문 나무 문짝을 찾을 칸
LABEL_Y = (1700, 1746)           # 탭 아래 글자 띠 (화면 y)


SQ = np.ones((3, 3), bool)
SEAL_SKIP = ("gate1_",)          # 외곽선이 없는 조각 (성문 문짝): 가장자리를 건드리지 않는다


def seal(img, rings=2):
    """조각의 가장자리를 마감한다 (2026-11-25 민수 님: 가장자리에 한 픽셀씩 남는다 / 깎여 나간 것도 있다).
    - 투명도는 0 아니면 255.
    - 바깥 두 줄(모서리의 대각선 칸 포함)에서 **어두운 칸만** 외곽선 색 한 가지로 맞춘다: 외곽선에 배경(하늘 · 모래 · 판)이
      섞여 푸르스름하거나 누르스름해진 칸이 사라진다. 밝은 칸(금테 · 버튼 색 · 아이콘 색)은 그림이므로 건드리지 않는다
      — 외곽선이 얇은 조각에서 그림이 한 줄 깎이지 않게.
    - 투명한 칸의 색은 외곽선 색으로: 그림을 늘리거나 걸러 그릴 때 가장자리에 밝은 색이 번지지 않는다.
    빈틈이 없는 그림(배경 · 띠)은 그대로 둔다."""
    out = img.copy()
    m = out[..., 3] > 127
    if m.all() or not m.any():
        return out
    rgb = out[..., :3].astype(int)
    lum = rgb.mean(axis=2)
    dark = m & (lum < 40)
    ink = np.median(rgb[dark], axis=0) if dark.sum() > 20 else np.array([20, 18, 20])
    ring1 = m & ~ndimage.binary_erosion(m, structure=SQ, iterations=1, border_value=0)
    ring2 = m & ~ndimage.binary_erosion(m, structure=SQ, iterations=max(1, rings), border_value=0)
    snap = (ring1 & (lum < 96)) | (ring2 & (lum < 72))
    out[snap, :3] = ink
    out[~m, :3] = ink
    out[..., 3] = np.where(m, 255, 0)
    return out


def seal_all(prefixes):
    """이 도구가 만든 그림(assets/ui/<머리말>*.png)의 가장자리를 마감한다."""
    for f in sorted(os.listdir(UI)):
        if f.endswith(".png") and f.startswith(tuple(prefixes)) and not f.startswith(SEAL_SKIP):
            path = os.path.join(UI, f)
            src = np.array(Image.open(path).convert("RGBA"))
            os.environ["SEAL_NAME"] = f
            dst = seal(src)
            if not np.array_equal(src, dst):
                Image.fromarray(dst).save(path)


def straighten(mask):
    """네모 조각의 가장자리를 반듯하게: 맨 바깥 세 줄 가운데 반 넘게 찬 줄은 끊긴 곳을 이어 채우고, 덜 찬 줄은 지운다.
    (원본 외곽선이 살짝 번져 맨 바깥 줄이 점선처럼 남는 것을 없앤다. 모서리의 계단 모양은 그대로 남는다.)"""
    m = mask.copy()
    for axis in (0, 1):
        v = m if axis == 0 else m.T
        cnt = v.sum(axis=1)
        idx = np.where(cnt > 0)[0]
        if len(idx) < 8:
            continue
        full = cnt.max()
        for line in list(idx[:3][::-1]) + list(idx[-3:]):
            if cnt[line] >= full * 0.5:
                xs = np.where(v[line])[0]
                v[line, xs.min():xs.max() + 1] = True
            else:
                v[line] = False
    return m


def cut_part(a, box, straight=False):
    """외곽선이 둘러싼 모양 그대로 -> (RGBA, (x, y, w, h))."""
    x0, y0, x1, y1 = box
    reg = a[y0:y1, x0:x1].astype(float)
    dark = reg.mean(axis=2) < DARK
    # 어두운 칸을 모두 모아 속을 채운 뒤 가장 큰 덩어리 = 부품 (바깥 외곽선이 닫혀 있어 속이 통째로 찬다)
    filled = ndimage.binary_fill_holes(dark)
    lab, n = ndimage.label(filled)
    sizes = ndimage.sum(filled, lab, range(1, n + 1))
    mask = lab == (1 + int(np.argmax(sizes)))
    # 한두 칸 삐져나오거나 파인 곳을 고른다 (원본 외곽선이 살짝 번져 있다)
    mask = ndimage.median_filter(mask.astype(np.uint8), size=5).astype(bool)
    if straight:
        mask = straighten(mask)
    outline = mask & dark & ~ndimage.binary_erosion(mask, iterations=3, border_value=0)
    ys, xs = np.where(mask)
    bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    m = mask[by0:by1, bx0:bx1]
    rgb = reg[by0:by1, bx0:bx1].copy()
    ink = np.median(reg[outline], axis=0)
    # 맨 바깥 한 줄: 배경과 섞였을 수 있으니 외곽선 색으로
    rim = m & ~ndimage.binary_erosion(m, iterations=1, border_value=0)
    rgb[rim] = ink
    out = np.dstack([rgb, np.where(m, 255, 0)]).astype(np.uint8)
    return out, (x0 + bx0, y0 + by0, bx1 - bx0, by1 - by0), mask, (x0, y0)


def gate_pieces(bg, off):
    x, y, w, h = GATE
    y += off
    door = bg[y:y + h, x:x + w].copy()
    r, b = door[..., 0].astype(int), door[..., 2].astype(int)
    wood = (r - b > 28) | (door[..., :3].mean(axis=2) < 60)      # 나무 + 가운데 어두운 틈
    wood = ndimage.binary_fill_holes(ndimage.binary_closing(wood, iterations=3))
    lab, n = ndimage.label(wood)
    sizes = ndimage.sum(wood, lab, range(1, n + 1))
    inside = lab == (1 + int(np.argmax(sizes)))
    ys, xs = np.where(inside)
    gx0, gy0, gx1, gy1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    door, inside = door[gy0:gy1, gx0:gx1], inside[gy0:gy1, gx0:gx1]
    hh, ww = inside.shape
    door[~inside, 3] = 0
    Image.fromarray(door[:, : ww // 2]).save(os.path.join(UI, "gate1_door_l.png"))
    Image.fromarray(door[:, ww // 2:]).save(os.path.join(UI, "gate1_door_r.png"))
    hole = np.zeros((hh, ww, 4), np.uint8)
    hole[inside] = (14, 10, 8, 255)
    yy = np.mgrid[0:hh, 0:ww][0]
    hole[inside & (yy > hh - 16)] = (40, 30, 22, 255)
    Image.fromarray(hole).save(os.path.join(UI, "gate1_hole.png"))
    return [int(x + gx0), int(y + gy0 - off), int(ww), int(hh)]


def main():
    a = np.array(Image.open(os.path.join(SRC, "로비8_완성화면.png")).convert("RGB"))
    assert a.shape[:2] == (CH, CW), a.shape
    erase = np.zeros(a.shape[:2], bool)
    layout, parts = {}, {}
    for name, box in BOXES.items():
        img, (x, y, w, h), mask, (ox, oy) = cut_part(a, box, straight="_btn_" not in name)      # 둥근 버튼만 빼고 반듯하게
        parts[name] = img
        layout[name] = [int(x), int(y), int(w), int(h)]
        erase[oy:oy + mask.shape[0], ox:ox + mask.shape[1]] |= mask
        print("%-20s %s" % (name, layout[name]))

    # 배경에서 부품을 지운다: 부품 자리(3px 넉넉히)의 칸마다 가장 가까운 바깥 칸의 색으로 메운다
    erase = ndimage.binary_dilation(erase, iterations=3)
    idx = ndimage.distance_transform_edt(erase, return_distances=False, return_indices=True)
    clean = a[idx[0], idx[1]]

    full = clean
    Image.fromarray(full).save(os.path.join(BG, "lobby_bg.png"))
    for name, img in parts.items():
        Image.fromarray(img).save(os.path.join(UI, name + ".png"))

    # 탭 줄 바탕: 배경 맨 아래의 어두운 띠 (탭을 지운 것). 누름을 막는 판으로도 쓴다.
    bar_top = min(layout[k][1] for k in layout if k.startswith("lobby_tab_")) + 20
    Image.fromarray(np.dstack([full[bar_top:], np.full((CH - bar_top, CW), 255, np.uint8)])).save(os.path.join(UI, "lobby_tab_bar.png"))
    layout["lobby_tab_bar"] = [0, int(bar_top), CW, int(CH - bar_top)]
    layout["lobby_plaque"] = PLAQUE
    # 글자 띠 (탭 안 px): [옆 여백, 위, 0, 높이]
    for key, tab in (("tab_band", "lobby_tab_hero"), ("tab_band_stage", "lobby_tab_stage")):
        layout[key] = [18, int(LABEL_Y[0] - layout[tab][1]), 0, int(LABEL_Y[1] - LABEL_Y[0])]
    layout["gate"] = gate_pieces(np.dstack([full, np.full((CH, CW), 255, np.uint8)]), 0)
    json.dump(layout, open(os.path.join(UI, "lobby_layout.json"), "w", encoding="utf-8"), indent=1)

    # 확인용 그림
    comp = Image.fromarray(full).convert("RGBA")
    for name, img in parts.items():
        comp.alpha_composite(Image.fromarray(img), tuple(layout[name][:2]))
    comp.convert("RGB").save(os.path.join(SRC, "로비8_합성확인.png"))
    k = 3
    sheet = Image.new("RGBA", (1280, 860), (255, 0, 255, 255))
    for i in range(0, sheet.width, 20):
        for j in range(430, sheet.height, 20):
            sheet.paste((40, 40, 46, 255) if (i // 20 + j // 20) % 2 else (70, 70, 78, 255), (i, j, i + 20, j + 20))
    x = 10
    for row, y in ((list(parts)[:6], 10), (list(parts)[6:], 200), (list(parts)[:6], 440), (list(parts)[6:], 630)):
        x = 10
        for name in row:
            im = Image.fromarray(parts[name])
            sheet.alpha_composite(im, (x, y))
            x += im.width + 12
    sheet = sheet.convert("RGB")
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(SRC, "로비8_부품확인.png"))
    seal_all(["lobby_"])
    print("gate", layout["gate"], "bar", layout["lobby_tab_bar"])


if __name__ == "__main__":
    main()
