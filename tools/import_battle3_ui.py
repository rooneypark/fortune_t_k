#!/usr/bin/env python3
"""전투 화면 3차 그림 (2026-11-24 민수 님, 로비 3차와 같은 스타일) -> 전투 부품.

원본: design/art/ui_src/  (모두 화면 크기 1024 x 1792 그대로라 키우지 않는다)
  전투3_배경.png      UI 없는 배경 (하늘 · 왼쪽 비스듬한 성벽 · 아래쪽 성문 · 넓은 흙 전장)
  전투3_UI.png        마젠타 바탕의 UI 부품 하나씩 (군량 · 병사 · 장수 · 웨이브 칸, 배속 · 일시정지 · 계속 동그란 버튼,
                      성 체력 막대(빈 홈), 슬롯 판 · 조작 판(빈 판), 릴 하나, 위 · 아래 화살표, 레버, 값 칩, 빨간 빈 버튼)
  전투3_완성화면.png  비교용 (부품 자리는 이 그림에서 잰 값)

  전투4_완성화면.png  다시 받은 완성 화면 (성 체력 막대에 삼국지 성루, 전투 시작 = 쌍검, 퇴각 = 열린 성문). 2026-11-24 민수 님:
                      따로 그린 부품은 통일감이 없어서, 이 완성 화면에서 막대 · 두 버튼을 직접 떼어 낸다 (mockup_parts).
                      막대는 빨간 막대가 꽉 찬 채로 그려져 있어 홈 속 붉은 칸을 빈 홈 색으로 되돌린다.
  전투3_버튼.png      (예전) 따로 받은 버튼 · 성루 아이콘 — 전투4 가 있으면 쓰지 않는다: 전투 시작(빨강 + 쌍검) · 퇴각(먹색 + 성문 · 되돌아가는 화살표) · 삼국지 성루 아이콘.
                      성루 아이콘은 성 체력 막대 왼쪽의 서양 성 자리에 바꿔 끼운다 (막대 오른쪽 끝을 뒤집어 왼쪽 끝을 새로 만들고 얹음).

릴: 금테 틀은 가만히 있고 안쪽(크림색 띠 + 칸)만 구른다.
- battle_reel_1..3  릴 그림 (멈춘 모습, 그림이 없을 때 · 처음)
- battle_reel_frame 릴 틀 (안쪽이 투명)
- battle_reel_tile  안쪽 띠 한 마디 (칸 하나 + 사이 띠), 위아래로 이어 붙이면 끝없는 띠
- 칸 자리 · 한 마디 길이 · 안쪽 자리는 battle_layout.json 의 reel_hole · reel_hole_top · reel_hole_bot · reel_step · reel_inner
레버: 손잡이 + 막대(battle_lever_knob)와 빈 홈 받침(battle_lever_base)으로 나눈다 (lever_parts).
판 두 장(battle_panel_slot · battle_panel_ctrl)은 9-slice.

Usage: python tools/import_battle3_ui.py
"""
import json
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

LAYOUT = {
    "battle_chip_rice": [12, 26, 232, 91],
    "battle_chip_army": [250, 26, 201, 91],
    "battle_chip_hero": [456, 26, 186, 91],
    "battle_chip_wave": [647, 26, 186, 91],
    "battle_btn_speed": [835, 24, 92, 94],
    "battle_btn_pause": [927, 24, 92, 94],
    "battle_btn_resume": [927, 24, 92, 94],
    "battle_bar_castle": [13, 124, 998, 131],
    "battle_panel_slot": [0, 1270, 541, 522],
    "battle_panel_ctrl": [543, 1270, 481, 522],
    "battle_reel_1": [42, 1392, 147, 260],
    "battle_reel_2": [199, 1392, 147, 260],
    "battle_reel_3": [356, 1392, 147, 260],
    "battle_arrow_up_1": [75, 1336, 82, 45],
    "battle_arrow_up_2": [231, 1336, 82, 45],
    "battle_arrow_up_3": [388, 1336, 82, 45],
    "battle_arrow_down_1": [75, 1663, 82, 46],
    "battle_arrow_down_2": [231, 1663, 82, 46],
    "battle_arrow_down_3": [388, 1663, 82, 46],
    "battle_lever": [582, 1334, 119, 247],
    "battle_plate_cost": [575, 1605, 132, 59],
    "battle_btn_start": [724, 1332, 276, 162],
    "battle_btn_retreat": [724, 1519, 276, 179],
}
NINE = {"battle_panel_slot": 20, "battle_panel_ctrl": 20}


def classify(comps):
    box = {c: (c[1], c[2], c[3] - c[1], c[4] - c[2]) for c in comps}
    out = {}
    left = list(comps)

    def take(name, c):
        out[name] = c
        left.remove(c)

    take("bar", max(left, key=lambda c: box[c][2]))
    take("reel", max([c for c in left if box[c][3] > 1.6 * box[c][2] and box[c][2] > 160], key=lambda c: box[c][3]))
    take("lever", max([c for c in left if box[c][3] > 2.2 * box[c][2]], key=lambda c: box[c][3]))
    panels = sorted([c for c in left if box[c][2] > 300 and box[c][3] > 180 and box[c][1] < 920], key=lambda c: box[c][2])
    take("panel_small", panels[0])
    take("panel_big", panels[1])
    take("red", max([c for c in left if box[c][1] > 1100 and box[c][2] > 300], key=lambda c: box[c][2] * box[c][3]))
    take("plate", [c for c in left if box[c][1] > 900 and box[c][2] > 300][0])
    arrows = sorted([c for c in left if box[c][1] > 900 and box[c][2] < 160], key=lambda c: box[c][1])
    take("arrow_up", arrows[0])
    take("arrow_down", arrows[1])
    rounds = [c for c in left if abs(box[c][2] - box[c][3]) < 12 and box[c][2] < 170]
    top = sorted([c for c in rounds if box[c][1] < 200], key=lambda c: box[c][0])
    take("speed", top[0])
    take("pause", top[1])
    take("resume", [c for c in rounds if box[c][1] >= 200][0])
    chips = sorted(left, key=lambda c: (box[c][1] // 100, box[c][0]))
    for name, c in zip(["rice", "army", "hero", "wave"], chips):
        take(name, c)
    return out


def reel_parts(im, layout):
    """릴 그림 -> 틀(안쪽 투명) · 한 마디 띠 · 칸 자리."""
    a = np.array(im).astype(int)
    h, w = a.shape[:2]
    lum = a[..., :3].mean(axis=2)
    # 안쪽 = 크림색이 시작하는 자리 (가운데 줄에서 왼쪽 · 위에서 처음 밝은 칸)
    row = lum[h // 2]
    ix0 = int(np.where(row[: w // 3] > 190)[0].min())
    ix1 = w - ix0
    col = lum[:, w // 2]
    cream_x = ix0 + 3
    ccol = lum[:, cream_x]
    iy0 = int(np.where(ccol[: h // 4] > 190)[0].min())
    iy1 = h - iy0
    # 칸: 안쪽의 어두운 네모 (칸 금테 포함으로 조금 넓힌다)
    dark = lum < 90
    dark[:, : ix0 + 2] = False
    dark[:, ix1 - 2:] = False
    lab, n = ndimage.label(dark)
    boxes = []
    for o in ndimage.find_objects(lab):
        bh, bw = o[0].stop - o[0].start, o[1].stop - o[1].start
        # 칸 속(어두운 네모)만: 너비가 릴의 40~50% 남짓, 높이 20px 넘게 (칸 금테 · 테두리 조각은 뺀다)
        if w * 0.42 < bw < w * 0.47 and bh > 20:
            boxes.append((o[1].start, o[0].start, bw, bh))
    boxes.sort(key=lambda b: b[1])
    # 가운데 칸 = 릴 가운데에 가장 가까운 칸, 그 위 · 아래 칸
    mid = min(boxes, key=lambda b: abs(b[1] + b[3] / 2 - h / 2))
    top = [b for b in boxes if b[1] + b[3] <= mid[1]][0]
    bot = [b for b in boxes if b[1] >= mid[1] + mid[3]][-1]
    g = 6                                   # 칸 금테 두께 (px)
    hole = [mid[0] - g, mid[1] - g, mid[2] + 2 * g, mid[3] + 2 * g]
    step = bot[1] - mid[1]
    hole_top = [hole[0], iy0, hole[2], top[1] + top[3] + g - iy0]
    hole_bot = [hole[0], bot[1] - g, hole[2], iy1 - (bot[1] - g)]
    # 한 마디 띠: 가운데 칸 위 사이 띠부터 칸 끝까지 (step 길이), 안쪽 너비만
    t0 = hole[1] - (step - hole[3])
    tile = im.crop((ix0, t0, ix1, t0 + step))
    tile.save(os.path.join(L.UI, "battle_reel_tile.png"))
    frame = a.copy()
    frame[iy0:iy1, ix0:ix1, 3] = 0
    Image.fromarray(frame.astype(np.uint8)).save(os.path.join(L.UI, "battle_reel_frame.png"))
    layout["reel_inner"] = [ix0, iy0, ix1 - ix0, iy1 - iy0]
    layout["reel_hole"] = hole
    layout["reel_hole_top"] = hole_top
    layout["reel_hole_bot"] = hole_bot
    layout["reel_step"] = [0, 0, 0, step]
    print("reel inner", layout["reel_inner"], "hole", hole, "step", step)


def lever_parts(layout):
    """레버 그림 -> 손잡이(붉은 공) + 막대(battle_lever_knob)와, 그 자리를 홈 색으로 메운 받침(battle_lever_base).
    새 그림은 금테 홈이 레버 위까지 이어져서, 이 그림에 맞춰 새로 만든 것."""
    lev = np.array(Image.open(os.path.join(L.UI, "battle_lever.png")).convert("RGBA")).astype(int)
    r, g, b, al = lev[..., 0], lev[..., 1], lev[..., 2], lev[..., 3]
    h, w = al.shape
    yy, xx = np.mgrid[0:h, 0:w]
    red = (al > 128) & (r > 130) & (g < 80) & (b < 90)          # 붉은 공 (금테의 주황은 빼려고 초록 · 파랑이 낮은 칸만)
    ys, xs = np.where(red)
    kcx, kcy = (xs.min() + xs.max()) / 2.0, (ys.min() + ys.max()) / 2.0
    rad = max(xs.max() - xs.min(), ys.max() - ys.min()) / 2.0 + 4.0
    ball = (((xx - kcx) ** 2 + (yy - kcy) ** 2) <= rad ** 2) & (al > 0)
    kbot = int(np.where(ball.any(axis=1))[0].max())
    # 막대: 공 아래 가운데의 쇠 회색 (붉은 기 없는 밝은 회색)
    lum = (r + g + b) / 3.0
    steel = (al > 128) & (lum > 95) & (np.abs(r - g) < 22) & (np.abs(g - b) < 30) & (np.abs(xx - kcx) < w * 0.14)
    steel[: kbot - 4] = False
    slab, sn = ndimage.label(steel)
    ssz = ndimage.sum(steel, slab, range(1, sn + 1))
    stick = slab == (int(np.argmax(ssz)) + 1)
    sys_, sxs = np.where(stick)
    sbot = int(sys_.max())
    stick_box = np.zeros_like(stick)
    stick_box[kbot - 6:sbot + 3, sxs.min() - 2:sxs.max() + 3] = True
    move = ball | (stick_box & (al > 0))
    # 홈: 막대 아래 가운데의 어두운 칸. 손잡이가 내려갈 거리 = 홈 끝 - 막대 끝
    cx = int(round(kcx))
    colv = lum[:, cx]
    gbot = sbot + 2
    while gbot < h - 1 and colv[gbot + 1] < 70:
        gbot += 1
    dark = np.median(lev[sbot + 4:max(sbot + 8, gbot - 2), cx - 3:cx + 4, :3].reshape(-1, 3), axis=0)
    knob = lev.copy()
    knob[~move, 3] = 0
    my, mx = np.where(move)
    kbox = (mx.min(), my.min(), mx.max() + 1, my.max() + 1)
    Image.fromarray(knob.astype(np.uint8)).crop(kbox).save(os.path.join(L.UI, "battle_lever_knob.png"))
    # 받침: 손잡이 자리는 홈 색으로, 금테 틀 밖(공이 위로 튀어나온 곳)은 투명하게
    frame_top = int(np.where(al[:, 3] > 128)[0].min()) if (al[:, 3] > 128).any() else 0
    base = lev.copy()
    inside = move & (yy >= frame_top + 6) & (np.abs(xx - kcx) < w * 0.3)
    base[inside, 0], base[inside, 1], base[inside, 2] = dark[0], dark[1], dark[2]
    base[move & ~inside & (yy < frame_top + 6), 3] = 0
    Image.fromarray(base.astype(np.uint8)).save(os.path.join(L.UI, "battle_lever_base.png"))
    lx, ly, lw, lh = layout["battle_lever"]
    layout["battle_lever_knob"] = [lx + int(kbox[0]), ly + int(kbox[1]), int(kbox[2] - kbox[0]), int(kbox[3] - kbox[1])]
    layout["battle_lever_travel"] = [0, 0, 0, int(max(30, gbot - sbot - 6))]
    print("lever knob", layout["battle_lever_knob"], "travel", layout["battle_lever_travel"][3])


MOCK_BTNS = {"battle_btn_start": (722, 1325, 279, 171), "battle_btn_retreat": (722, 1515, 279, 185)}
MOCK_BAR = (13, 124, 998, 94)          # 금테 아래 끝(y 217)까지 — 그 아래는 하늘 · 구름


def mockup_parts(layout):
    """전투4_완성화면.png 에서 성 체력 막대 · 전투 시작 · 퇴각 버튼을 직접 떼어 낸다."""
    full = np.array(Image.open(os.path.join(L.SRC, "전투4_완성화면.png")).convert("RGBA")).astype(int)
    # 버튼: 둥근 모서리 바깥의 판 색(먹색) 칸은 투명으로 (가장자리에서 이어진 판 색만)
    for name, (x, y, w, h) in MOCK_BTNS.items():
        piece = full[y:y + h, x:x + w].copy()
        edge = np.concatenate([piece[0, :, :3], piece[-1, :, :3], piece[:, 0, :3], piece[:, -1, :3]])
        panel = np.median(edge, axis=0)
        near = np.abs(piece[..., :3] - panel).sum(axis=2) < 40
        lab, n = ndimage.label(near)
        border = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1])
        border.discard(0)
        outside = np.isin(lab, list(border))
        piece[outside, 3] = 0
        Image.fromarray(piece.astype(np.uint8)).save(os.path.join(L.UI, name + ".png"))
        layout[name] = [x, y, w, h]
        print("%-22s %s (전투4 완성 화면에서)" % (name, layout[name]))
    # 성 체력 막대: 배경과 다른 칸만 (막대 둘레의 하늘은 투명), 홈 속 붉은 막대는 빈 홈 색으로
    x, y, w, h = MOCK_BAR
    bgi = np.array(Image.open(os.path.join(L.SRC, "전투3_배경.png")).convert("RGB")).astype(int)
    bar = full[y:y + h, x:x + w].copy()
    d = np.abs(bar[..., :3] - bgi[y:y + h, x:x + w]).sum(axis=2) > 40
    d = np.pad(d, 4, mode="edge")
    keep = ndimage.binary_dilation(ndimage.binary_fill_holes(ndimage.binary_closing(d, iterations=2)), iterations=1)[4:-4, 4:-4]
    lab, n = ndimage.label(keep)
    sizes = ndimage.sum(keep, lab, range(1, n + 1))
    keep = lab == (1 + int(np.argmax(sizes)))
    bar[..., 3] = np.where(keep, 255, 0)

    r, g, b = bar[..., 0], bar[..., 1], bar[..., 2]
    red = (r > 140) & (g < 80) & (b < 80)
    red[:, : int(w * 0.13)] = False               # 왼쪽 성루의 붉은 기둥은 그대로
    lab, n = ndimage.label(red)
    sizes = ndimage.sum(red, lab, range(1, n + 1))
    red = lab == (1 + int(np.argmax(sizes)))
    ys, xs = np.where(red)
    gx0, gx1, gy0, gy1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    # 붉은 막대의 위 · 아래 밝은 줄 · 어두운 줄까지 (막대 테두리 안쪽 2px)
    gx0, gy0, gy1 = gx0 - 6, gy0 - 2, gy1 + 2     # 붉은 막대의 왼쪽 끝 · 위아래 밝고 어두운 줄까지
    bar[gy0:gy1, gx0:gx1, :3] = np.array([30, 36, 48])
    Image.fromarray(bar.astype(np.uint8)).save(os.path.join(L.UI, "battle_bar_castle.png"))
    layout["battle_bar_castle"] = [x, y, w, h]
    layout["castle_groove"] = [int(gx0), int(gy0), int(gx1 - gx0), int(gy1 - gy0)]
    print("battle_bar_castle groove", layout["castle_groove"])


def main():
    layout = dict(LAYOUT)
    bg = Image.open(os.path.join(L.SRC, "전투3_배경.png")).convert("RGB").resize((L.CW, L.CH))
    bg.save(os.path.join(L.BG, "battle_field.png"))
    col, alpha = L.matte(L.load("전투3_UI.png"))
    lab, comps = L.components(alpha, 800)
    named = classify(comps)
    cut = {k: L.cut(col, alpha, lab, c)[0] for k, c in named.items()}

    def save(name, im, fit=True):
        if fit and name in LAYOUT and name not in NINE:
            im = L.scale_rgba(im, LAYOUT[name][2], LAYOUT[name][3])
        im.save(os.path.join(L.UI, name + ".png"))
        print("%-22s %s" % (name, im.size))
        return im

    for k in ("rice", "army", "hero", "wave"):
        save("battle_chip_" + k, cut[k])
    save("battle_btn_speed", cut["speed"])
    save("battle_btn_pause", cut["pause"])
    save("battle_btn_resume", cut["resume"])
    bar = save("battle_bar_castle", cut["bar"])
    # 성 체력 홈: 가운데 줄에서 진한 외곽선 사이 (막대 그림 998 x 131 에서 잰 값: x 174~946, y 53~84)
    ba = np.array(bar).astype(int)
    lum = ba[..., :3].mean(axis=2)
    cy, cx = bar.height // 2, bar.width // 2
    ys = [y for y in range(cy, 0, -1) if lum[y, cx] < 32]
    ye = [y for y in range(cy, bar.height) if lum[y, cx] < 32]
    xs = [x for x in range(cx, 0, -1) if lum[cy, x] < 32]
    xe = [x for x in range(cx, bar.width) if lum[cy, x] < 32]
    gy0, gy1, gx0, gx1 = ys[0] + 2, ye[0] - 1, xs[0] + 2, xe[0] - 1
    layout["castle_groove"] = [gx0, gy0, gx1 - gx0, gy1 - gy0]
    save("battle_panel_slot", cut["panel_small"], fit=False)
    save("battle_panel_ctrl", cut["panel_big"], fit=False)
    reel = L.scale_rgba(cut["reel"], 147, 260)
    for i in (1, 2, 3):
        reel.save(os.path.join(L.UI, "battle_reel_%d.png" % i))
    reel_parts(reel, layout)
    for i in (1, 2, 3):
        save("battle_arrow_up_%d" % i, cut["arrow_up"])
        save("battle_arrow_down_%d" % i, cut["arrow_down"])
    save("battle_lever", cut["lever"])
    save("battle_plate_cost", cut["plate"])
    mockup_parts(layout)
    lever_parts(layout)
    json.dump(layout, open(os.path.join(L.UI, "battle_layout.json"), "w", encoding="utf-8"), indent=1)
    path = os.path.join(L.UI, "nine.json")
    nine = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    nine.update(NINE)
    json.dump(nine, open(path, "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
