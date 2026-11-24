#!/usr/bin/env python3
"""전투 UI 그림(마젠타 배경) -> 전투 위쪽 HUD 부품 (assets/ui/battle_*.png) + 자리 (assets/ui/battle_layout.json).

원본: design/art/ui_src/전투_UI.webp  (마젠타 배경 위에 전투 UI 부품만)
지금은 위쪽 HUD만 쓴다: 칩 4개(군량 · 병사 · 장수 · 웨이브) · 배속 · 일시정지 · 성 체력 판.
아래쪽 부품(릴 · 화살표 · 레버 · 값 칩 · 전투 시작 · 책사)은 전투_UI_하단.webp 에서 떼어 저장만 해 둔다
(battle_reel_* · battle_arrow_* · battle_lever · battle_plate_cost · battle_btn_start · battle_btn_advisor).
게임에는 전투 배경을 받은 뒤 같이 넣는다.

떼어 내는 법은 로비와 같다 (tools/import_lobby_ui.py 의 matte · cut · scale_rgba):
원본 픽셀을 화면 크기로 한 번만 부드럽게 키우고, 가장자리는 마젠타가 섞인 만큼 투명하게 한다.
성 체력 판의 초록 막대는 지워서 빈 홈으로 만든다 (막대는 게임이 그린다).

Usage: python tools/import_battle_ui.py     (확인용: design/art/ui_src/전투_부품확인.png)
"""
import json
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

TOP_NAMES = ["battle_chip_rice", "battle_chip_army", "battle_chip_hero", "battle_chip_wave", "battle_btn_speed", "battle_btn_pause"]


def empty_groove(a, box):
    """성 체력 판(box, 원본 px) 안의 초록 막대를 홈의 어두운 색으로 덮는다."""
    x0, y0, x1, y1 = box
    reg = a[y0:y1, x0:x1]
    r, g, b = reg[..., 0], reg[..., 1], reg[..., 2]
    green = (g > r + 25) & (g > b + 25)
    if not green.any():
        return
    ys, xs = np.where(green)
    # 홈의 빈 부분 = 초록 막대의 오른쪽 끝 바로 옆 (같은 높이)
    gx = min(reg.shape[1] - 1, xs.max() + 8)
    dark = np.median(reg[ys.min() + 2:ys.max() - 1, gx:gx + 12].reshape(-1, 3), axis=0)
    from scipy import ndimage
    green = ndimage.binary_dilation(green, iterations=2)
    reg[green] = dark


def cut_group(col, alpha, lab, group, pad=2):
    """덩어리 여러 개를 한 부품으로 (레버의 손잡이 · 받침처럼 떨어져 있어도 한 장)."""
    from scipy import ndimage
    h, w = alpha.shape
    x0, y0 = max(0, min(c[1] for c in group) - pad), max(0, min(c[2] for c in group) - pad)
    x1, y1 = min(w, max(c[3] for c in group) + pad), min(h, max(c[4] for c in group) + pad)
    own = ndimage.binary_dilation(np.isin(lab[y0:y1, x0:x1], [c[0] for c in group]), iterations=2)
    a = np.where(own, alpha[y0:y1, x0:x1], 0.0)
    return Image.fromarray(np.dstack([col[y0:y1, x0:x1], a * 255.0]).astype(np.uint8)), (x0, y0, x1, y1)


def bottom_parts(layout, made, kx, ky):
    """아래쪽 부품 (전투_UI_하단.webp): 릴 3개 · 위아래 화살표 · 레버 · 값 칩 · 전투 시작 · 책사.
    떼어 내서 저장만 한다 — 게임에는 전투 배경을 받은 뒤 같이 넣는다."""
    if not os.path.exists(os.path.join(L.SRC, "전투_UI_하단.webp")):
        return
    a = L.load("전투_UI_하단.webp")
    sh, sw = a.shape[:2]
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, 60)
    low = [c for c in comps if (c[2] + c[4]) / 2 / sh > 0.7]
    cx = lambda c: (c[1] + c[3]) / 2 / sw
    cy = lambda c: (c[2] + c[4]) / 2 / sh
    left = sorted([c for c in low if cx(c) < 0.5], key=lambda c: c[1])
    reels = sorted([c for c in left if c[4] - c[2] > 0.1 * sh], key=lambda c: c[1])
    arrows = [c for c in left if c not in reels]
    groups = {}
    for i, r in enumerate(reels):
        groups["battle_reel_%d" % (i + 1)] = [r]
    for i, c in enumerate(sorted([c for c in arrows if cy(c) < cy(reels[0])], key=lambda c: c[1])):
        groups["battle_arrow_up_%d" % (i + 1)] = [c]
    for i, c in enumerate(sorted([c for c in arrows if cy(c) > cy(reels[0])], key=lambda c: c[1])):
        groups["battle_arrow_down_%d" % (i + 1)] = [c]
    right = [c for c in low if cx(c) >= 0.5]
    groups["battle_lever"] = [c for c in right if cx(c) < 0.7 and cy(c) < 0.91]
    groups["battle_plate_cost"] = [c for c in right if cx(c) < 0.7 and cy(c) >= 0.91]
    groups["battle_btn_start"] = [c for c in right if cx(c) >= 0.7 and cy(c) < 0.86]
    groups["battle_btn_advisor"] = [c for c in right if cx(c) >= 0.7 and cy(c) >= 0.86]
    for name, group in groups.items():
        assert group, name
        im, box = cut_group(col, alpha, lab, group)
        x, y = round(box[0] * kx), round(box[1] * ky)
        w, h = round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky)
        out = L.scale_rgba(im, w, h)
        out.save(os.path.join(L.UI, name + ".png"))
        layout[name] = [x, y, w, h]
        print("%-22s %s" % (name, layout[name]))
    # 확인용: 밝은 바탕 · 어두운 바탕 위에 화면 자리 그대로
    y0 = min(layout[n][1] for n in groups) - 20
    hh = L.CH - y0
    sheet = Image.new("RGBA", (L.CW * 2 + 10, hh), (250, 250, 250, 255))
    sheet.paste(Image.new("RGBA", (L.CW, hh), (60, 42, 30, 255)), (L.CW + 10, 0))
    for n in groups:
        im = Image.open(os.path.join(L.UI, n + ".png")).convert("RGBA")
        sheet.alpha_composite(im, (layout[n][0], layout[n][1] - y0))
        sheet.alpha_composite(im, (layout[n][0] + L.CW + 10, layout[n][1] - y0))
    sheet.save(os.path.join(L.SRC, "전투_하단부품확인.png"))


def bottom_panels(layout, kx, ky):
    """아래쪽 판 두 장 (전투_UI_하단판.webp): 슬롯 판(릴이 들어갈 홈 3줄) · 조작 판(나무판)."""
    if not os.path.exists(os.path.join(L.SRC, "전투_UI_하단판.webp")):
        return
    a = L.load("전투_UI_하단판.webp")
    sh, sw = a.shape[:2]
    # 제미나이 워터마크(조작 판 오른쪽 아래의 반짝이, 원본 px x 455~512 · y 905~965)를 지운다:
    # 나무판은 가로로 같은 무늬가 이어지므로 같은 높이의 왼쪽 옆 부분을 그대로 가져와 덮는다.
    a[905:965, 455:512] = a[905:965, 385:442]
    col, alpha = L.matte(a)
    # 두 판은 맞붙어 있다: 가운데 근처에서 가장 어두운 세로줄(두 테두리 사이)을 경계로 나눈다
    top = int(np.where(alpha.mean(axis=1) > 0.9)[0].min())
    mid = slice(int(sw * 0.46), int(sw * 0.6))
    split = mid.start + int(np.argmin(a[top + 20:sh - 20, mid].sum(axis=2).mean(axis=0)))
    for name, x0, x1 in (("battle_panel_slot", 0, split), ("battle_panel_ctrl", split, sw)):
        rgba = np.dstack([col[top:, x0:x1], alpha[top:, x0:x1] * 255.0]).astype(np.uint8)
        x, y = round(x0 * kx), round(top * ky)
        w, h = round(x1 * kx) - x, L.CH - y   # 화면 맨 아래까지
        out = np.array(L.scale_rgba(Image.fromarray(rgba), w, h)).astype(int)
        # 두 판이 만나는 아래쪽 모서리 틈에 남은 분홍 칸을 지운다
        pink = (out[..., 0] - out[..., 1] > 50) & (out[..., 2] - out[..., 1] > 50)
        out[pink, 3] = 0
        Image.fromarray(out.astype(np.uint8)).save(os.path.join(L.UI, name + ".png"))
        layout[name] = [x, y, w, h]
        print("%-22s %s" % (name, layout[name]))


# 릴 그림 안의 칸 자리 (slot_view.gd 의 HOLE · ART_STEP 과 같게): 가운데 칸 y 105 · 높이 92, 칸에서 칸까지 132
REEL_HOLE_Y, REEL_HOLE_H, REEL_STEP = 105, 92, 132


def moving_parts(layout):
    """움직이는 부품을 그림에서 만든다 (새 그림을 받지 않고).
    - battle_reel_tile: 릴 그림의 한 마디(크림색 띠 40 + 어두운 칸 92 = 132px). 위아래로 이어 붙이면 끝없는 릴 띠가 된다.
    - battle_lever_base / battle_lever_knob: 레버에서 손잡이 + 막대를 떼어 낸 것과, 그 자리를 빈 홈으로 메운 받침."""
    from scipy import ndimage
    reel = Image.open(os.path.join(L.UI, "battle_reel_2.png")).convert("RGBA")
    top = REEL_HOLE_Y - (REEL_STEP - REEL_HOLE_H)
    reel.crop((0, top, reel.width, top + REEL_STEP)).save(os.path.join(L.UI, "battle_reel_tile.png"))
    lev = np.array(Image.open(os.path.join(L.UI, "battle_lever.png")).convert("RGBA")).astype(int)
    r, g, b, al = lev[..., 0], lev[..., 1], lev[..., 2], lev[..., 3]
    h, w = al.shape
    # 손잡이: 선명한 붉은 칸으로 자리를 찾고, 그 둘레(어두운 아랫부분 · 외곽선 포함)를 둥글게 잡는다
    red = (al > 128) & (r > 130) & (r - g > 70) & (r - b > 60)
    ys, xs = np.where(red)
    kcx = int(round((xs.min() + xs.max()) / 2))
    kcy = int(round((ys.min() + ys.max()) / 2))
    rad = max(xs.max() - xs.min(), ys.max() - ys.min()) / 2.0 + 13.0
    yy, xx = np.mgrid[0:h, 0:w]
    disk = ((xx - kcx) ** 2 + (yy - kcy) ** 2) <= rad ** 2
    # 둥근 범위 안에서 붉은 기가 있거나 아주 어두운(외곽선) 칸만 손잡이다
    red_any = disk & (al > 0) & (r - g > 18) & (r - b > 8) & (r > 45)
    red_any = ndimage.binary_fill_holes(ndimage.binary_closing(red_any, iterations=2))
    # 붉은 덩어리 + 그 둘레 4px의 진한 외곽선
    knob_m = ndimage.binary_dilation(red_any, iterations=4) & disk & (al > 0)
    kbot = int(np.where(knob_m.any(axis=1))[0].max())
    # 받침이 시작하는 줄: 그 위에 있는 것은 전부 손잡이다
    wide = (al > 128).sum(axis=1) > w * 0.7
    base_top = int(np.where(wide)[0].min())
    knob_m = knob_m | ((al > 0) & (np.arange(h)[:, None] < base_top))
    # 막대: 손잡이 아래의 쇠 색(붉은 기 없는 회색 · 푸른 회색) 덩어리. 손잡이 바로 아래에서 가장 큰 것.
    steel = (al > 128) & ((r + g + b) > 110) & (abs(r - g) < 14) & (b >= r - 2)
    steel[:kbot - 10] = False
    slab, sn = ndimage.label(steel)
    ssz = ndimage.sum(steel, slab, range(1, sn + 1))
    stick_m = slab == (int(np.argmax(ssz)) + 1)
    sys_, sxs = np.where(stick_m)
    sbot, scx = int(sys_.max()), int(round(sxs.mean()))
    box = np.zeros_like(stick_m)
    box[kbot - 6:sbot + 3, sxs.min() - 2:sxs.max() + 3] = True
    stick_m = box & (al > 0)
    move = knob_m | stick_m
    # 홈: 막대 아래로 이어지는 어두운 부분. 그 색으로 막대 자리를 메우고, 끝나는 줄까지가 손잡이가 내려갈 거리
    col = lev[:, scx, :3].sum(axis=1)
    gbot = sbot + 4
    while gbot < h - 1 and col[gbot + 1] < 70:
        gbot += 1
    dark = np.median(lev[sbot + 6:max(sbot + 10, gbot - 4), scx - 3:scx + 4, :3].reshape(-1, 3), axis=0)
    knob = lev.copy()
    knob[~move, 3] = 0
    my, mx = np.where(move)
    kbox = (mx.min(), my.min(), mx.max() + 1, my.max() + 1)
    Image.fromarray(knob.astype(np.uint8)).crop(kbox).save(os.path.join(L.UI, "battle_lever_knob.png"))
    base = lev.copy()
    above = move & (np.arange(h)[:, None] < base_top)
    base[above, 3] = 0
    # 손잡이가 받침 윗부분을 가리던 곳: 같은 줄의 왼쪽 옆(가려지지 않은 받침)을 가져와 메운다
    kx0 = int(np.where(knob_m.any(axis=0))[0].min())
    for y in range(base_top, min(h, int(np.where(knob_m.any(axis=1))[0].max()) + 1)):
        xsr = np.where(knob_m[y])[0]
        if len(xsr):
            base[y, xsr, :3] = lev[y, 14, :3]   # 받침 왼쪽의 나무 (테두리 안쪽)
    # 막대 자리는 홈의 어두운 색으로
    sm = stick_m & ~knob_m & (np.arange(h)[:, None] >= base_top)
    base[sm, 0], base[sm, 1], base[sm, 2] = dark[0], dark[1], dark[2]
    Image.fromarray(base.astype(np.uint8)).save(os.path.join(L.UI, "battle_lever_base.png"))
    lx, ly, lw, lh = layout["battle_lever"]
    layout["battle_lever_knob"] = [lx + int(kbox[0]), ly + int(kbox[1]), int(kbox[2] - kbox[0]), int(kbox[3] - kbox[1])]
    layout["battle_lever_travel"] = [0, 0, 0, int(max(30, gbot - sbot - 6))]
    print("%-22s %s  travel %d" % ("battle_lever_knob", layout["battle_lever_knob"], layout["battle_lever_travel"][3]))


def main():
    a = L.load("전투_UI.webp")
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha)
    top = [c for c in comps if (c[2] + c[4]) / 2 / sh < 0.16]
    row1 = sorted([c for c in top if (c[2] + c[4]) / 2 / sh < 0.075], key=lambda c: c[1])
    row2 = [c for c in top if (c[2] + c[4]) / 2 / sh >= 0.075]
    assert len(row1) == 6 and len(row2) == 1, (row1, row2)
    # 성 체력 판: 초록 막대를 지운 뒤 다시 떼어 낸다
    bar = row2[0]
    empty_groove(a, (bar[1], bar[2], bar[3], bar[4]))
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha)
    top = [c for c in comps if (c[2] + c[4]) / 2 / sh < 0.16]
    row1 = sorted([c for c in top if (c[2] + c[4]) / 2 / sh < 0.075], key=lambda c: c[1])
    row2 = [c for c in top if (c[2] + c[4]) / 2 / sh >= 0.075]
    parts = dict(zip(TOP_NAMES, row1))
    parts["battle_bar_castle"] = row2[0]
    layout, made = {}, {}
    for name, comp in parts.items():
        im, box = L.cut(col, alpha, lab, comp)
        x, y = round(box[0] * kx), round(box[1] * ky)
        w, h = round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky)
        out = L.scale_rgba(im, w, h)
        out.save(os.path.join(L.UI, name + ".png"))
        layout[name] = [x, y, w, h]
        made[name] = out
        print("%-20s %s" % (name, layout[name]))
    bottom_parts(layout, made, kx, ky)
    bottom_panels(layout, kx, ky)
    moving_parts(layout)
    # 전투 배경 (전투_배경.webp): 화면 크기로 한 번만 키운다. 그림의 성 · 길 자리가 곧 전장 좌표다
    # (battle_field.gd 의 BAND_TOP · BAND_BOTTOM · wall_x · GATE). 오른쪽 아래 워터마크는 아래쪽 판에 가려진다.
    if os.path.exists(os.path.join(L.SRC, "전투_배경.webp")):
        bgim = Image.open(os.path.join(L.SRC, "전투_배경.webp")).convert("RGB").resize((L.CW, L.CH), Image.LANCZOS)
        bgim.save(os.path.join(L.BG, "battle_field.png"))
    json.dump(layout, open(os.path.join(L.UI, "battle_layout.json"), "w", encoding="utf-8"), indent=1)
    # 확인용: 밝은 바탕 · 어두운 바탕 위의 부품 (화면 자리 그대로)
    sheet = Image.new("RGBA", (L.CW, 520), (250, 250, 250, 255))
    dark = Image.new("RGBA", (L.CW, 260), (24, 24, 34, 255))
    sheet.paste(dark, (0, 260))
    for name, im in made.items():
        x, y, _, _ = layout[name]
        sheet.alpha_composite(im, (x, y))
        sheet.alpha_composite(im, (x, y + 260))
    sheet.save(os.path.join(L.SRC, "전투_부품확인.png"))


if __name__ == "__main__":
    main()
