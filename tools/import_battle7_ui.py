#!/usr/bin/env python3
"""전투 화면 7차 (2026-11-25 민수 님): 완성 화면 한 장(1024 x 1792, 게임 화면 크기 그대로)에서 부품을 직접 떼어 낸다.
로비 4차(tools/import_lobby4_ui.py)와 같은 방법 — 진한 외곽선이 둘러싼 모양 그대로, 투명도 0/1, 크기 그대로.

원본: design/art/ui_src/전투7_완성화면.png  (제미나이. 요청문 design/ux/화면별-요청문.md §E-3b)

만드는 것
- 위: 칩 4개(군량 · 병사 · 장수 · 웨이브), 배속 · 일시정지 버튼, 성 체력 막대(빈 홈 자리 castle_groove)
- 계속(▶) 버튼: 배속 버튼(▶▶)의 앞 삼각형 하나만 남겨 가운데에 놓는다
- 아래: 슬롯 판 · 조작 판 (속 부품을 지우고 판 색으로 메운 빈 판), 릴 3개, 화살표 6개, 값 판, 전투 시작 · 퇴각 버튼
- 릴: 틀(battle_reel_frame, 안쪽 투명) + 구르는 띠 한 마디(battle_reel_tile = 크림색 띠 + 칸). 받은 그림의 릴은 빈 크림색 창이라
  칸은 위쪽 칩의 숫자 칸과 같은 색(어두운 갈색 + 외곽선)으로 그려 넣는다.
- 레버: 손잡이 + 막대(battle_lever_knob)와 받침(battle_lever_base, 막대 자리를 받침 색으로 메움). 당기면 손잡이가 내려간다.
- 배경(assets/bg/battle_field.png): 부품 자리를 가장 가까운 바깥 색으로 메운 그림

확인용 (게임 실행 아님): design/art/ui_src/전투7_합성확인.png · 전투7_부품확인.png

Usage: python tools/import_battle7_ui.py
"""
import json
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_lobby4_ui import cut_part, seal_all, SRC, UI, BG, CW, CH, DARK  # noqa: E402

# 부품을 찾을 칸 (화면 좌표 x0, y0, x1, y1)
BOXES = {
    "battle_chip_rice": (30, 24, 236, 134),
    "battle_chip_army": (234, 24, 442, 134),
    "battle_chip_hero": (440, 24, 645, 134),
    "battle_chip_wave": (643, 24, 820, 134),
    "battle_btn_speed": (819, 22, 916, 136),
    "battle_btn_pause": (914, 22, 1012, 136),
    "battle_bar_castle": (30, 132, 1006, 234),
    "battle_panel_slot": (4, 1240, 543, 1772),
    "battle_panel_ctrl": (541, 1240, 1020, 1772),
    "battle_reel_1": (44, 1336, 192, 1682),
    "battle_reel_2": (204, 1336, 352, 1682),
    "battle_reel_3": (364, 1336, 512, 1682),
    "battle_arrow_up_1": (76, 1268, 162, 1330),
    "battle_arrow_up_2": (236, 1268, 322, 1330),
    "battle_arrow_up_3": (396, 1268, 482, 1330),
    "battle_arrow_down_1": (76, 1686, 162, 1746),
    "battle_arrow_down_2": (236, 1686, 322, 1746),
    "battle_arrow_down_3": (396, 1686, 482, 1746),
    "battle_lever": (590, 1278, 702, 1578),
    "battle_plate_cost": (552, 1592, 742, 1718),
    "battle_btn_start": (742, 1278, 990, 1490),
    "battle_btn_retreat": (742, 1496, 992, 1746),
}
RECT = {"battle_chip_rice", "battle_chip_army", "battle_chip_hero", "battle_chip_wave", "battle_bar_castle",
        "battle_reel_1", "battle_reel_2", "battle_reel_3", "battle_plate_cost", "battle_btn_start", "battle_btn_retreat"}
PANEL_KIDS = {"battle_panel_slot": ["battle_reel_", "battle_arrow_"], "battle_panel_ctrl": ["battle_lever", "battle_plate_cost", "battle_btn_start", "battle_btn_retreat"]}
CELL = 100                        # 릴 칸 한 변 (px)
GAP = 12                          # 칸 사이 크림색 띠
TRAVEL = 28                       # 레버 손잡이가 내려가는 거리


def tight(a, box):
    """네모 부품: 어두운 칸이 길게 이어진 줄(외곽선)의 맨 바깥 줄로 칸을 좁힌다 — 옆의 다른 그림(성벽 선 등)이 딸려 오지 않게."""
    x0, y0, x1, y1 = box
    dark = a[y0:y1, x0:x1].astype(float).mean(axis=2) < DARK
    rows = np.where(dark.sum(axis=1) > dark.shape[1] * 0.55)[0]
    cols = np.where(dark.sum(axis=0) > dark.shape[0] * 0.55)[0]
    return (x0 + int(cols.min()), y0 + int(rows.min()), x0 + int(cols.max()) + 1, y0 + int(rows.max()) + 1)


def save(name, img):
    Image.fromarray(img).save(os.path.join(UI, name + ".png"))


def reel_parts(reel, layout):
    """릴 그림 -> 틀(안쪽 투명) · 띠 한 마디 · 칸 자리 (릴 그림 왼쪽 위 기준 px)."""
    h, w = reel.shape[:2]
    lum = reel[..., :3].astype(float).mean(axis=2)
    cream = (lum > 180) & (reel[..., 3] > 0)
    ys, xs = np.where(cream)
    ix0, iy0, ix1, iy1 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    iw, ih = ix1 - ix0, iy1 - iy0
    frame = reel.copy()
    frame[iy0:iy1, ix0:ix1, 3] = 0
    save("battle_reel_frame", frame)
    step = CELL + GAP
    hx = ix0 + (iw - CELL) // 2
    hy = iy0 + (ih - CELL) // 2
    # 띠 한 마디: 위 GAP 줄은 크림색, 그 아래 칸
    paper = np.median(reel[iy0 + 20:iy1 - 20, ix0 + 6:ix1 - 6, :3].reshape(-1, 3), axis=0)
    tile = np.zeros((step, iw, 4), np.uint8)
    tile[..., :3] = paper
    tile[..., 3] = 255
    cx = hx - ix0
    tile[GAP:, cx:cx + CELL, :3] = layout["_ink"]
    tile[GAP + 4:step - 4, cx + 4:cx + CELL - 4, :3] = layout["_slot"]
    save("battle_reel_tile", tile)
    layout["reel_inner"] = [ix0, iy0, iw, ih]
    layout["reel_hole"] = [hx, hy, CELL, CELL]
    layout["reel_step"] = [0, 0, 0, step]
    layout["reel_hole_top"] = [hx, iy0, CELL, max(0, hy - GAP - iy0)]
    layout["reel_hole_bot"] = [hx, hy + step, CELL, max(0, iy1 - (hy + step))]
    print("reel inner", layout["reel_inner"], "hole", layout["reel_hole"], "top", layout["reel_hole_top"], "bot", layout["reel_hole_bot"])


def lever_parts(lev, rect, layout):
    """레버 -> 손잡이 + 막대 / 받침. 받침의 막대 자리는 받침 색 · 윗테두리로 메운다."""
    h, w = lev.shape[:2]
    al = lev[..., 3] > 0
    r, g, b = [lev[..., i].astype(int) for i in range(3)]
    red = al & (r > 150) & (g < 90) & (b < 90)
    kbot = int(np.where(red.any(axis=1))[0].max())
    width = al.sum(axis=1)
    # 받침: 손잡이 아래에서 너비가 다시 넓어지는 줄부터
    rod_w = int(np.median(width[kbot + 12:kbot + 60]))
    base_top = int(next(y for y in range(kbot + 12, h) if width[y] > rod_w * 2))
    # 막대: 받침 위쪽 줄의 가로 범위, 받침 속으로 들어간 끝
    cols = np.where(al[base_top - 10])[0]
    rx0, rx1 = int(cols.min()), int(cols.max()) + 1
    lum = lev[..., :3].astype(float).mean(axis=2)
    face = np.median(lev[base_top + 12:h - 10, 8:rx0 - 6, :3].reshape(-1, 3), axis=0)
    mid = (rx0 + rx1) // 2
    flum = float(face.mean())
    rod_end = int(max(y for y in range(base_top, h - 10) if abs(lum[y, mid] - flum) > 20)) + 1    # 막대 끝(아래 외곽선 포함)
    ys = np.arange(h)[:, None]
    xs = np.arange(w)[None, :]
    rod_in_base = (ys >= base_top) & (ys < rod_end) & (xs >= rx0) & (xs < rx1)
    knob = lev.copy()
    knob[(ys >= base_top) & ~rod_in_base] = 0
    my, mx = np.where(knob[..., 3] > 0)
    kb = (int(mx.min()), int(my.min()), int(mx.max()) + 1, int(my.max()) + 1)
    save("battle_lever_knob", knob[kb[1]:kb[3], kb[0]:kb[2]])
    base = lev.copy()
    base[:base_top] = 0
    # 막대 자리: 막대 왼쪽 옆 줄(받침 윗테두리 · 받침 색 · 아랫테두리)을 그대로 가로로 이어 붙인다
    base[:, rx0 - 3:rx1 + 3] = np.repeat(base[:, rx0 - 8:rx0 - 7], rx1 - rx0 + 6, axis=1)
    save("battle_lever_base", base)
    x, y, _, _ = rect
    layout["battle_lever_knob"] = [x + kb[0], y + kb[1], kb[2] - kb[0], kb[3] - kb[1]]
    layout["battle_lever_travel"] = [0, 0, 0, TRAVEL]
    print("lever base_top", base_top, "rod", (rx0, rx1, rod_end), "knob", layout["battle_lever_knob"], "face", face.astype(int))


def resume_button(speed):
    """배속 버튼(▶▶) -> 계속 버튼(▶): 앞(오른쪽) 삼각형만 남겨 가운데로. 두 삼각형이 맞닿아 끊긴 왼쪽 외곽선은 이어 준다."""
    h, w = speed.shape[:2]
    rgb = speed[..., :3].astype(int)
    lum = rgb.mean(axis=2)
    inner = ndimage.binary_erosion(speed[..., 3] > 0, iterations=10)
    dark, light = inner & (lum < 70), inner & (lum > 170)
    icon = dark | light
    ys, xs = np.where(icon)
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()) + 1, int(ys.min()), int(ys.max()) + 1
    face = np.median(rgb[inner & ~ndimage.binary_dilation(icon, iterations=3)], axis=0)
    ink = np.median(rgb[dark], axis=0)
    # 앞 삼각형의 왼쪽 외곽선: 가운데 근처에서 어두운 칸이 가장 많은 4줄
    cnt = dark.sum(axis=0)
    cand = range(x0 + 15, x1 - 15)
    cx = max(cand, key=lambda c: cnt[c:c + 4].sum())
    tri = speed[y0:y1, cx:x1].copy()
    tmask = icon[y0:y1, cx:x1].copy()
    rows = np.where(tmask[:, :4].any(axis=1))[0]
    tri[rows.min():rows.max() + 1, :4, :3] = ink             # 끊긴 외곽선을 잇는다
    tmask[rows.min():rows.max() + 1, :4] = True
    tmask = ndimage.binary_fill_holes(tmask)
    out = speed.copy()
    out[ndimage.binary_dilation(icon, iterations=3) & inner, :3] = face
    tw = x1 - cx
    px = (w - tw) // 2 + 3                                     # 삼각형은 무게 중심이 왼쪽이라 조금 오른쪽으로
    reg = out[y0:y1, px:px + tw]
    reg[tmask] = tri[tmask]
    return out


def main():
    a = np.array(Image.open(os.path.join(SRC, "전투7_완성화면.png")).convert("RGB"))
    assert a.shape[:2] == (CH, CW), a.shape
    layout, parts, masks = {}, {}, {}
    erase = np.zeros(a.shape[:2], bool)
    for name, box in BOXES.items():
        if name in RECT:
            box = tight(a, box)
        img, (x, y, w, h), mask, (ox, oy) = cut_part(a, box, straight=name in RECT or "panel" in name)
        parts[name] = img
        layout[name] = [int(x), int(y), int(w), int(h)]
        full = np.zeros(a.shape[:2], bool)
        full[oy:oy + mask.shape[0], ox:ox + mask.shape[1]] = mask
        masks[name] = full
        erase |= full
        print("%-22s %s" % (name, layout[name]))

    # 색: 외곽선 · 숫자 칸 (위쪽 칩의 어두운 칸)
    chip = parts["battle_chip_army"]
    ch, cw = chip.shape[:2]
    layout["_ink"] = [int(v) for v in np.median(chip[2:4, 20:cw - 20, :3].reshape(-1, 3), axis=0)]
    layout["_slot"] = [int(v) for v in np.median(chip[ch // 2 - 8:ch // 2 + 8, int(cw * 0.6):int(cw * 0.85), :3].reshape(-1, 3), axis=0)]

    # 빈 판: 속 부품 자리를 가장 가까운 판 색으로 메운다
    for pname, kids in PANEL_KIDS.items():
        x, y, w, h = layout[pname]
        kid = np.zeros(a.shape[:2], bool)
        for k in masks:
            if any(k.startswith(p) for p in kids):
                kid |= masks[k]
        kid = ndimage.binary_dilation(kid, iterations=3)[y:y + h, x:x + w]
        img = parts[pname]
        inside = ndimage.binary_erosion(img[..., 3] > 0, iterations=14)
        img[kid, :3] = np.median(img[inside & ~kid, :3], axis=0)      # 판 색은 고르다: 한 가지 색으로 메운다
        parts[pname] = img

    # 성 체력 홈: 막대 속의 어두운 긴 칸
    bar = parts["battle_bar_castle"]
    slot = np.abs(bar[..., :3].astype(int) - np.array(layout["_slot"])).sum(axis=2) < 36
    slot[:, : int(bar.shape[1] * 0.12)] = False
    lab, n = ndimage.label(ndimage.binary_opening(slot, iterations=2))
    sizes = ndimage.sum(lab > 0, lab, range(1, n + 1))
    ys, xs = np.where(lab == (1 + int(np.argmax(sizes))))
    layout["castle_groove"] = [int(xs.min()) + 3, int(ys.min()) + 3, int(xs.max() - xs.min()) - 5, int(ys.max() - ys.min()) - 5]
    print("castle_groove", layout["castle_groove"])

    # 계속 버튼은 일시정지 버튼 자리 · 모양에 (같은 크기라 일시정지 버튼의 바탕 위에 삼각형을 올린다)
    sp, pa = parts["battle_btn_speed"], parts["battle_btn_pause"]
    parts["battle_btn_resume"] = resume_button(sp)
    if parts["battle_btn_resume"].shape != pa.shape:
        parts["battle_btn_resume"] = np.array(Image.fromarray(parts["battle_btn_resume"]).resize((pa.shape[1], pa.shape[0]), Image.NEAREST))
    layout["battle_btn_resume"] = list(layout["battle_btn_pause"])

    for name, img in parts.items():
        save(name, img)
    reel_parts(parts["battle_reel_1"], layout)
    lever_parts(parts["battle_lever"], layout["battle_lever"], layout)

    seal_all(["battle_"])
    # 배경: 부품 자리(3px 넉넉히)를 가장 가까운 바깥 색으로
    er = ndimage.binary_dilation(erase, iterations=3)
    idx = ndimage.distance_transform_edt(er, return_distances=False, return_indices=True)
    bg = a[idx[0], idx[1]]
    Image.fromarray(bg).save(os.path.join(BG, "battle_field.png"))

    out = {k: v for k, v in layout.items() if not k.startswith("_")}
    json.dump(out, open(os.path.join(UI, "battle_layout.json"), "w", encoding="utf-8"), indent=1)
    path = os.path.join(UI, "nine.json")
    nine = json.load(open(path, encoding="utf-8"))
    for k in ("battle_panel_slot", "battle_panel_ctrl"):     # 판은 그림 크기 그대로 쓴다
        nine.pop(k, None)
    json.dump(nine, open(path, "w", encoding="utf-8"), indent=1)

    # 확인용: 배경 위에 부품을 자리대로 (레버는 받침 + 손잡이, 릴은 틀)
    comp = Image.fromarray(bg).convert("RGBA")
    order = ["battle_panel_slot", "battle_panel_ctrl"] + [k for k in parts if not k.startswith("battle_panel") and k not in ("battle_lever", "battle_btn_resume")]
    for name in order:
        comp.alpha_composite(Image.fromarray(parts[name]), tuple(layout[name][:2]))
    comp.alpha_composite(Image.open(os.path.join(UI, "battle_lever_base.png")), tuple(layout["battle_lever"][:2]))
    comp.alpha_composite(Image.open(os.path.join(UI, "battle_lever_knob.png")), tuple(layout["battle_lever_knob"][:2]))
    comp.convert("RGB").save(os.path.join(SRC, "전투7_합성확인.png"))
    sheet = Image.new("RGBA", (1700, 1500), (255, 0, 255, 255))
    x, y, rowh = 10, 10, 0
    names = [k for k in parts] + ["battle_reel_frame", "battle_reel_tile", "battle_lever_base", "battle_lever_knob"]
    for name in names:
        im = Image.open(os.path.join(UI, name + ".png")).convert("RGBA")
        if x + im.width > sheet.width - 10:
            x, y, rowh = 10, y + rowh + 12, 0
        sheet.alpha_composite(im, (x, y))
        x += im.width + 12
        rowh = max(rowh, im.height)
    sheet.crop((0, 0, sheet.width, y + rowh + 10)).convert("RGB").save(os.path.join(SRC, "전투7_부품확인.png"))


if __name__ == "__main__":
    main()
