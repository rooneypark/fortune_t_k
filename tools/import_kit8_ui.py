#!/usr/bin/env python3
"""공용 UI 부품 (2026-11-25 민수 님): 8차 완성 화면들에서 떼어 낸 조각을 9-slice 공용 부품으로 만든다.
창마다 같은 틀 · 같은 금테 칸 · 같은 버튼을 쓰므로, 한 벌만 만들어 모든 창이 같이 쓴다.

먼저 돌릴 것: tools/import_popups8_ui.py (난이도 · 웨이브 승리 창의 틀 · 제목 띠 · 줄을 여기서 다시 쓴다)

만드는 것 (assets/ui/, 여백은 nine.json)
  kit_frame            작은 창 틀 (밝은 갈색 판)                     <- difficulty_frame
  kit_frame2           안쪽 판이 있는 큰 창 틀 (우편 · 임무 · 주공 정보 · 설정 · 확률)  <- 우편함8
  kit_title            제목 띠 (황갈색)                              <- difficulty_title
  kit_title_gold       제목 띠 (금색)                                <- 보상8
  kit_box              금테 어두운 칸 (칸 · 줄 · 어두운 버튼 공용)     <- wave_row_0
  kit_btn_red / _yellow / _purple / _blue   색 버튼                  <- 구매확인8 / 상점8 / 결과8 / 장수상세8
  kit_tab_on / kit_tab_off                 큰 창의 탭                <- 장수목록8
  dlg_frame            큰 창 틀 (장수 · 가방 · 상점)                  <- 장수목록8
  dlg_tab_on/off · dlg_chip_on/off · dlg_card · dlg_inner · dlg_bond
  btn_auto · btn_unequip · btn_prev · btn_next · btn_plus  통째 그림 버튼
  ctl_track · ctl_track_fill · ctl_knob · ctl_cell · ctl_cell_on       설정의 막대 · 손잡이 · 선택 칸

게임 쪽: Px.KIT (src/ui/kit/px.gd) 가 선 UI의 부품 이름(panel_ctrl · panel_slot · plate_title …)을 kit_* 그림에 잇는다.
9-slice 가운데는 늘어나므로 한 가지 색으로 고르게 메운다 (아이콘이 그려진 조각은 아이콘을 지운다).

확인용 (게임 실행 아님): design/art/ui_src/공용부품8_확인.png

Usage: python tools/import_kit8_ui.py
"""
import json
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby4_ui as L4  # noqa: E402
import import_popups8_ui as P8  # noqa: E402

SRC, UI = L4.SRC, L4.UI


def ui(name):
    return np.array(Image.open(os.path.join(UI, name + ".png")).convert("RGBA"))


def flatten(img, m, erase=None):
    """9-slice 가운데(여백 m 안쪽)를 한 가지 색으로. erase = 색을 뽑을 때 뺄 자리(아이콘)."""
    out = img.copy()
    l, t, r, b = (m, m, m, m) if isinstance(m, int) else m
    h, w = out.shape[:2]
    core = out[t:h - b, l:w - r, :3]
    flat = core.reshape(-1, 3)
    med = np.median(flat, axis=0)
    near = np.abs(flat.astype(int) - med).sum(axis=1) < 40
    core[...] = np.median(flat[near], axis=0) if near.sum() > 20 else med
    return out


def sym_v(img):
    """위쪽 절반을 아래쪽 절반의 거울 그림으로 (위에 다른 조각이 걸쳐 있던 틀 · 띠를 깨끗하게)."""
    h = img.shape[0]
    half = img[h - h // 2:]
    return np.concatenate([half[::-1], img[h // 2:h - h // 2], half], axis=0)


def sym_h(img):
    """왼쪽 절반을 오른쪽 절반의 거울 그림으로 (왼쪽에 아이콘이 그려진 버튼을 빈 버튼으로)."""
    w = img.shape[1]
    half = img[:, w - w // 2:]
    return np.concatenate([half[:, ::-1], img[:, w // 2:w - w // 2], half], axis=1)


def render9(img, w, h, m):
    """9-slice 로 (w, h) 크기 그림을 만든다 (가운데는 고른 색이라 늘려도 깨지지 않는다)."""
    l, t, r, b = (m, m, m, m) if isinstance(m, int) else m
    sh, sw = img.shape[:2]
    out = np.zeros((h, w, 4), np.uint8)
    xs = [(0, l, 0, l), (l, sw - r, l, w - r), (sw - r, sw, w - r, w)]
    ys = [(0, t, 0, t), (t, sh - b, t, h - b), (sh - b, sh, h - b, h)]
    for sy0, sy1, dy0, dy1 in ys:
        for sx0, sx1, dx0, dx1 in xs:
            if dx1 <= dx0 or dy1 <= dy0:
                continue
            piece = Image.fromarray(img[sy0:sy1, sx0:sx1]).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST)
            out[dy0:dy1, dx0:dx1] = np.array(piece)
    return out


def icon_of(img, m):
    """버튼 속 아이콘만 (버튼 색과 다른 칸) -> RGBA 조각."""
    h, w = img.shape[:2]
    core = img[m:h - m, m:w - m]
    rgb = core[..., :3].astype(int)
    base = np.median(rgb.reshape(-1, 3), axis=0)
    diff = np.abs(rgb - base).sum(axis=2) > 70
    lab, n = ndimage.label(ndimage.binary_dilation(diff, iterations=2))
    if n == 0:
        return None
    sizes = ndimage.sum(diff, lab, range(1, n + 1))
    keep = ndimage.binary_fill_holes(lab == (1 + int(np.argmax(sizes))))
    keep = ndimage.binary_erosion(keep, iterations=1)
    ys, xs = np.where(keep)
    out = core[ys.min():ys.max() + 1, xs.min():xs.max() + 1].copy()
    out[..., 3] = np.where(keep[ys.min():ys.max() + 1, xs.min():xs.max() + 1], 255, 0)
    return out


def with_icon(btn, icon, at=0.5):
    """버튼 그림 가운데(가로 at)에 아이콘을 얹는다."""
    out = Image.fromarray(btn).convert("RGBA")
    ic = Image.fromarray(icon)
    k = min(1.0, (btn.shape[0] * 0.56) / ic.height)
    if k < 1.0:
        ic = ic.resize((max(1, int(ic.width * k)), max(1, int(ic.height * k))), Image.NEAREST)
    out.alpha_composite(ic, (int(btn.shape[1] * at - ic.width / 2), (btn.shape[0] - ic.height) // 2))
    return np.array(out)


def save(name, img):
    Image.fromarray(img).save(os.path.join(UI, name + ".png"))


def main():
    nine = json.load(open(os.path.join(UI, "nine.json"), encoding="utf-8"))
    out = {}

    def put(name, img, margin=None):
        out[name] = img
        save(name, img)
        if margin is not None:
            nine[name] = margin
        else:
            nine.pop(name, None)

    # ---- 작은 창: 틀 · 제목 띠 · 금테 칸
    put("kit_frame", flatten(sym_v(ui("difficulty_frame")), 22), 22)
    put("kit_title", flatten(ui("difficulty_title"), [40, 22, 40, 22]), [40, 22, 40, 22])
    box = flatten(ui("wave_row_0"), 18)
    put("kit_box", box, 18)

    # ---- 안쪽 판이 있는 큰 창 틀 (우편 · 임무 · 주공 정보 · 설정): 바깥 틀 + 안쪽 판. 가운데는 안쪽 판 색.
    a = P8.load("우편함8_완성화면.png")
    # 바깥 틀이 어두운 갈색이라 밝기로는 못 잡는다: 잰 자리(x 84~939, y 364~1406)를 그대로 오린다
    crop = a[364:1406, 84:939]
    f2 = sym_v(np.dstack([crop, np.full(crop.shape[:2], 255, np.uint8)]))
    f2[60:-60, 60:-60, :3] = np.median(a[1205:1217, 300:700].reshape(-1, 3), axis=0)
    put("kit_frame2", f2, 60)

    # ---- 색 버튼
    a = P8.load("구매확인8_완성화면.png")
    red = flatten(P8.cut_dark(a, (522, 1054, 308, 108))[0], 16)
    put("kit_btn_red", red, 16)
    dark_btn = flatten(P8.cut_dark(a, (194, 1054, 308, 108))[0], 18)
    a = P8.load("상점8_완성화면.png")
    yellow = flatten(P8.cut_light(a, (712, 759, 169, 62), P8.ink_of(a))[0], 14)
    put("kit_btn_yellow", yellow, 14)
    a = P8.load("결과8_시안1.png")
    put("kit_btn_purple", flatten(P8.cut_dark(a, (278, 1123, 467, 110))[0], 16), 16)
    a = P8.load("보상8_완성화면.png")
    put("kit_title_gold", flatten(sym_v(P8.cut_light(a, (254, 614, 516, 88), P8.ink_of(a))[0]), [40, 22, 40, 22]), [40, 22, 40, 22])

    # ---- 장수 상세: 파랑 · 빨강 버튼(아이콘), 화살표 버튼, 인연 띠
    a = P8.load("장수상세8_완성화면.png")
    blue_raw = P8.cut_dark(a, (126, 1087, 379, 75))[0]
    red_raw = P8.cut_dark(a, (519, 1087, 378, 75))[0]
    blue = flatten(sym_h(blue_raw), 14)
    put("kit_btn_blue", blue, 14)
    star, arrow = icon_of(blue_raw[:, :110], 12), icon_of(red_raw[:, :110], 12)
    # 자동 장착 · 해제: 시안의 버튼을 아이콘째 그대로 (화면도 같은 크기로 놓는다 — detail8.gd)
    put("btn_auto", blue_raw)
    put("btn_unequip", red_raw)
    nxt = P8.cut_dark(a, (855, 592, 58, 77))[0]
    put("btn_next", np.array(Image.fromarray(nxt).resize((91, 103), Image.NEAREST)))
    put("btn_prev", np.array(Image.fromarray(nxt[:, ::-1]).resize((91, 103), Image.NEAREST)))
    put("dlg_bond", flatten(P8.cut_dark(a, (126, 796, 771, 83))[0], [84, 18, 18, 18]), [84, 18, 18, 18])

    # ---- 큰 창 (장수 목록): 틀 · 탭 · 진영 칩 · 카드
    a = P8.load("장수목록8_완성화면.png")
    fr = a[325:1495, 83:941]
    frame = np.dstack([fr, np.full(fr.shape[:2], 255, np.uint8)])
    k = 6                                                      # 모서리 계단: 틀 바깥 귀퉁이는 투명
    lum = fr.astype(float).mean(axis=2)
    for cy, cx in ((slice(0, k), slice(0, k)), (slice(0, k), slice(-k, None)), (slice(-k, None), slice(0, k)), (slice(-k, None), slice(-k, None))):
        frame[cy, cx, 3] = np.where(lum[cy, cx] > 150, 0, 255)  # 귀퉁이에 비친 밝은 하늘 · 모래
    base = np.median(a[1484:1489, 200:800].reshape(-1, 3), axis=0)   # 틀 색 (아래 테두리 띠)
    frame[18:-18, 18:-18, :3] = base
    put("dlg_frame", sym_v(frame), 20)
    for name, (x0, x1) in (("on", (121, 384)), ("off", (384, 638))):
        t = a[346:447, x0:x1]
        # 탭: 왼쪽 끝 24px 띠를 거울로 이어 붙인 것 (가운데의 아이콘 · 얼룩이 남지 않는다). 가운데는 게임이 늘린다.
        strip = np.dstack([t[:, :24], np.full((t.shape[0], 24), 255, np.uint8)])
        tab = np.concatenate([strip, np.repeat(strip[:, 23:24], 16, axis=1), strip[:, ::-1]], axis=1)
        put("dlg_tab_" + name, tab, [24, 16, 24, 6])
        put("kit_tab_" + name, tab, [24, 16, 24, 6])
    put("dlg_chip_on", flatten(P8.cut_dark(a, (127, 472, 145, 61))[0], 16), 16)
    put("dlg_chip_off", flatten(P8.cut_dark(a, (286, 472, 141, 61))[0], 16), 16)
    # 카드: 얼굴 칸 + 이름 띠 (아래 62px 은 띠라서 늘리지 않는다)
    put("dlg_card", flatten(P8.cut_dark(a, (127, 554, 183, 206))[0], [18, 18, 18, 62]), [18, 18, 18, 62])
    # 큰 창의 안쪽 판 (탭 아래의 밝은 판): 탭이 걸친 위쪽은 아래쪽을 뒤집어 쓴다
    inn = a[447:1482, 97:928]
    inner = sym_v(np.dstack([inn, np.full(inn.shape[:2], 255, np.uint8)]))
    inner[18:-18, 18:-18, :3] = np.median(a[1448:1470, 300:700].reshape(-1, 3), axis=0)     # 판 색 (카드 아래 빈 띠에서)
    put("dlg_inner", inner, 18)

    # ---- 통째 그림 버튼 (옛 그림과 같은 크기)
    a = P8.load("로비8_완성화면.png")
    old = L4.DARK
    plus = L4.cut_part(a, (432, 46, 494, 108), straight=True)[0]
    L4.DARK = old
    put("btn_plus", np.array(Image.fromarray(plus).resize((64, 64), Image.NEAREST)))

    # ---- 설정: 막대 · 손잡이 · 선택 칸 (어두운 칸 위에 그려져 있어 외곽선 기준을 낮춘다)
    a = P8.load("설정8_시안1.png")
    ink = P8.ink_of(a)
    knob = P8.cut_light(a, (554, 532, 40, 40), ink)[0]
    put("ctl_knob", np.array(Image.fromarray(knob).resize((60, 60), Image.NEAREST)))
    L4.DARK = 44
    try:
        groove = L4.cut_part(a, (298, 600, 846, 664), straight=True)[0]      # 아래 막대(손잡이 왼쪽 · 오른쪽이 같다)
    finally:
        L4.DARK = old
    gh = groove.shape[0]
    left = groove[:, :200]                                                    # 손잡이가 없는 왼쪽 끝으로 9-slice
    track = render9(np.concatenate([left, left[:, ::-1]], axis=1), 525, gh, [12, 6, 12, 6])
    put("ctl_track", track)
    fill = track.copy()
    inner = np.zeros(fill.shape[:2], bool)
    inner[6:-6, 6:-6] = True
    fill[inner, :3] = np.median(knob[10:-10, 10:-10, :3].reshape(-1, 3), axis=0)
    put("ctl_track_fill", fill)
    cell_on = flatten(P8.cut_light(a, (406, 772, 120, 70), ink)[0], 14)
    put("ctl_cell_on", render9(cell_on, 174, 124, 14))
    put("ctl_cell", render9(box, 175, 124, 18))

    json.dump(nine, open(os.path.join(UI, "nine.json"), "w", encoding="utf-8"), indent=1)
    L4.seal_all(["kit_", "dlg_", "btn_", "ctl_"])
    for k in out:
        out[k] = ui(k)

    # 확인용
    sheet = Image.new("RGBA", (1800, 2300), (255, 0, 255, 255))
    x, y, rowh = 10, 10, 0
    for name, img in out.items():
        im = Image.fromarray(img)
        if im.width > 700:
            im = im.resize((im.width // 2, im.height // 2), Image.NEAREST)
        if x + im.width > sheet.width - 10:
            x, y, rowh = 10, y + rowh + 12, 0
        sheet.alpha_composite(im, (x, y))
        x += im.width + 12
        rowh = max(rowh, im.height)
    sheet.crop((0, 0, sheet.width, y + rowh + 10)).convert("RGB").save(os.path.join(SRC, "공용부품8_확인.png"))
    print("kit:", ", ".join("%s %dx%d" % (k, v.shape[1], v.shape[0]) for k, v in out.items()))


if __name__ == "__main__":
    main()
