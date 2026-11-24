#!/usr/bin/env python3
"""로비 UI 그림(마젠타 배경) -> 로비 부품 (assets/ui/lobby_*.png) + 배경 (assets/bg/lobby_bg.png).

원본 그림: design/art/ui_src/
  로비_UI.webp           마젠타 배경 위에 UI 부품만 (초상 틀 · 금/군량 칩 · 설정 · 우편 · 임무 · 쟁패 · 출정 · 빈 탭 버튼 3개)
  로비_UI_탭판있음.webp  같은 그림에 하단 탭 판이 있는 것 (탭 판만 여기서 가져온다)
  로비_배경.webp         UI 없는 배경
  로비_UI_탭아이콘.webp  같은 그림에서 탭 버튼을 빼고 탭 아이콘 3개만 남긴 것 (아이콘과 그 자리를 여기서 가져온다)

원본을 깨뜨리지 않는 법:
- 도트로 줄였다 키우지 않는다. 원본 픽셀(572 x 1024)을 화면 크기(1024 x 1792)로 한 번만, 부드럽게(LANCZOS) 키운다.
  배경과 부품을 똑같은 비율로 키우므로 자리가 완성 화면과 그대로 맞는다.
- 가장자리: 마젠타가 섞인 만큼을 계산해서 투명도로 바꾸고 색에서 마젠타를 뺀다 (보랏빛 테두리가 남지 않는다).
- 부품마다 떨어진 덩어리 하나만 남긴다 (찌꺼기 조각 없음).

결과: 부품 그림 + assets/ui/lobby_layout.json (부품마다 화면 자리 x, y, w, h — lobby.gd 가 읽는다)
확인용: design/art/ui_src/로비_부품확인.png (체크무늬 · 어두운 바탕 위의 부품), 로비_합성확인.png (완성 화면 | 게임 합성)

Usage: python tools/import_lobby_ui.py
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


def load(name):
    return np.array(Image.open(os.path.join(SRC, name)).convert("RGB")).astype(float)


def matte(a):
    """마젠타 배경에서 부품을 떼어 낸다 -> (색 RGB, 투명도 0~1).
    마젠타 섞임 m = min(R - G, B - G) / 기준. 배경은 m ≈ 1, 부품 속은 0. 배경과 맞닿은 3px 띠에서만 섞임을 쓴다."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    raw = np.minimum(r - g, b - g)
    key = np.percentile(raw[raw > 120], 20) if (raw > 120).any() else 200.0   # 이 그림의 마젠타 세기
    m = np.clip(raw / key, 0.0, 1.0)
    bgmask = m > 0.75
    # 부품 속의 외딴 점(8px 미만)은 배경이 아니다. 부품 사이의 좁은 틈(3~4px)은 배경으로 남겨야 한다.
    lab0, n0 = ndimage.label(bgmask)
    if n0 > 1:
        sizes = ndimage.sum(bgmask, lab0, range(1, n0 + 1))
        bgmask = np.isin(lab0, [i + 1 for i, s in enumerate(sizes) if s >= 8])
    near = ndimage.binary_dilation(bgmask, iterations=3)
    # 마젠타가 비치는 그림자 띠(배경과 이어진, 섞임 20% 넘는 곳)도 섞임만큼 투명하게 한다
    lab1, _ = ndimage.label((m > 0.2) | bgmask)
    touch = np.unique(lab1[bgmask])
    near = near | (np.isin(lab1, touch[touch > 0]) & ~bgmask)
    alpha = np.where(bgmask, 0.0, np.where(near, 1.0 - m, 1.0))
    alpha = np.clip((alpha - 0.08) / 0.84, 0.0, 1.0)
    mg = np.median(a[bgmask], axis=0) if bgmask.any() else np.array([255.0, 0.0, 255.0])
    al3 = np.maximum(alpha, 0.05)[..., None]
    col = np.where((alpha[..., None] < 0.999) & near[..., None], (a - (1.0 - alpha[..., None]) * mg) / al3, a)
    # 테두리 띠(배경에서 5px 안)에 남은 보랏빛을 걷어 낸다: 빨강 · 파랑이 초록보다 같이 높은 만큼을 깎는다
    rim = ndimage.binary_dilation(bgmask, iterations=5) & ~bgmask
    spill = np.clip(np.minimum(col[..., 0] - col[..., 1], col[..., 2] - col[..., 1]), 0, None) * 0.85
    col[..., 0] = np.where(rim, col[..., 0] - spill, col[..., 0])
    col[..., 2] = np.where(rim, col[..., 2] - spill, col[..., 2])
    return np.clip(col, 0, 255), alpha


def components(alpha, min_area=400):
    solid = ndimage.binary_fill_holes(alpha > 0.5)
    lab, n = ndimage.label(solid)
    out = []
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        y, x = sl
        if (x.stop - x.start) * (y.stop - y.start) >= min_area:
            out.append((i, x.start, y.start, x.stop, y.stop))
    return lab, out


def cut(col, alpha, lab, comp, pad=2):
    """덩어리 하나를 RGBA로. 다른 덩어리와 찌꺼기는 버린다."""
    i, x0, y0, x1, y1 = comp
    h, w = alpha.shape
    x0, y0, x1, y1 = max(0, x0 - pad), max(0, y0 - pad), min(w, x1 + pad), min(h, y1 + pad)
    own = ndimage.binary_dilation(lab[y0:y1, x0:x1] == i, iterations=2)
    a = np.where(own, alpha[y0:y1, x0:x1], 0.0)
    rgba = np.dstack([col[y0:y1, x0:x1], a * 255.0]).astype(np.uint8)
    return Image.fromarray(rgba), (x0, y0, x1, y1)


def scale_rgba(im, w, h):
    """부드럽게 키운다. 색이 투명한 곳과 섞여 어두워지지 않게 미리 곱했다가 되돌린다."""
    a = np.array(im).astype(float)
    al = a[..., 3:4] / 255.0
    pm = Image.fromarray(np.dstack([a[..., :3] * al, a[..., 3]]).astype(np.uint8)).resize((w, h), Image.LANCZOS)
    b = np.array(pm).astype(float)
    al2 = b[..., 3:4] / 255.0
    rgb = np.where(al2 > 0.003, b[..., :3] / np.maximum(al2, 0.003), 0)
    return Image.fromarray(np.dstack([np.clip(rgb, 0, 255), b[..., 3]]).astype(np.uint8))


def main():
    a = load("로비_UI.webp")
    sh, sw = a.shape[:2]
    kx, ky = CW / sw, CH / sh
    col, alpha = matte(a)
    lab, comps = components(alpha)
    # 자리로 부품을 가려낸다 (원본 px)
    def pick(cx_lo, cx_hi, cy_lo, cy_hi):
        hit = [c for c in comps if cx_lo <= (c[1] + c[3]) / 2 / sw < cx_hi and cy_lo <= (c[2] + c[4]) / 2 / sh < cy_hi]
        assert len(hit) == 1, (cx_lo, cx_hi, cy_lo, cy_hi, hit)
        return hit[0]
    names = {
        "lobby_portrait": pick(0.0, 0.2, 0.0, 0.12), "lobby_chip_gold": pick(0.2, 0.52, 0.0, 0.1), "lobby_chip_rice": pick(0.52, 0.86, 0.0, 0.1),
        "lobby_btn_settings": pick(0.86, 1.0, 0.0, 0.1), "lobby_btn_mail": pick(0.0, 0.2, 0.12, 0.21), "lobby_btn_mission": pick(0.0, 0.2, 0.21, 0.3),
        "lobby_btn_arena": pick(0.8, 1.0, 0.12, 0.21), "lobby_btn_stage": pick(0.25, 0.75, 0.75, 0.89),
        "lobby_tab_1": pick(0.0, 0.34, 0.89, 1.0), "lobby_tab_2": pick(0.34, 0.66, 0.89, 1.0), "lobby_tab_3": pick(0.66, 1.0, 0.89, 1.0),
    }
    layout, made = {}, {}
    for name, comp in names.items():
        src_name = name
        if name == "lobby_tab_3":
            # 세 번째 탭 버튼에는 제미나이 워터마크가 있다: 같은 모양인 두 번째 버튼 그림을 쓴다 (자리는 세 번째 것)
            im, b2 = cut(col, alpha, lab, names["lobby_tab_2"])
            _, b1 = cut(col, alpha, lab, names["lobby_tab_1"])
            box = (b2[0] + (b2[0] - b1[0]), b2[1], b2[2] + (b2[0] - b1[0]), b2[3])
        else:
            im, box = cut(col, alpha, lab, comp)
        x, y = round(box[0] * kx), round(box[1] * ky)
        w, h = round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky)
        out = scale_rgba(im, w, h)
        out.save(os.path.join(UI, name + ".png"))
        layout[name] = [x, y, w, h]
        made[name] = out
    # 하단 탭 판: 탭판이 있는 그림에서 판만. 버튼이 박혀 있으므로 버튼 사이 칸의 색을 줄마다 가로로 이어 붙인다.
    b = load("로비_UI_탭판있음.webp")
    rb = np.minimum(b[..., 0] - b[..., 1], b[..., 2] - b[..., 1])
    rows = np.where((rb < 60).mean(axis=1) > 0.98)[0]          # 가로 전체가 마젠타가 아닌 줄 = 판
    top = int(rows.min())
    gap_x = int(round((names["lobby_tab_1"][3] + names["lobby_tab_2"][1]) / 2))   # 첫 버튼과 둘째 버튼 사이
    strip = b[top:, gap_x:gap_x + 1, :]
    bar = Image.fromarray(np.repeat(strip, sw, axis=1).astype(np.uint8)).convert("RGBA")
    by, bh = round(top * ky), CH - round(top * ky)
    bar = bar.resize((CW, bh), Image.LANCZOS)
    bar.save(os.path.join(UI, "lobby_tab_bar.png"))
    layout["lobby_tab_bar"] = [0, by, CW, bh]
    made["lobby_tab_bar"] = bar
    # 탭 아이콘 3개: 완성 화면의 아이콘만 마젠타 위에 남긴 그림에서, 자리까지 그대로 가져온다
    ic = load("로비_UI_탭아이콘.webp")
    # 제미나이 워터마크(반짝이)가 주머니 아이콘의 오른쪽 절반에 겹쳐 찍혀 있다 (원본 px: x 465~500, y 921~952).
    # 주머니는 좌우가 거의 같은 모양이므로, 깨끗한 왼쪽 절반을 뒤집어 오른쪽에 덮는다 (금화가 있는 윗부분은 그대로).
    WM_AXIS, WM_TOP, WM_BOTTOM, WM_HALF = 473, 921, 960, 34
    ic[WM_TOP:WM_BOTTOM, WM_AXIS + 1:WM_AXIS + 1 + WM_HALF] = ic[WM_TOP:WM_BOTTOM, WM_AXIS - WM_HALF:WM_AXIS][:, ::-1]
    icol, ialpha = matte(ic)
    ilab, icomps = components(ialpha, 300)
    ih, iw = ic.shape[:2]
    low = sorted([k for k in icomps if (k[2] + k[4]) / 2 / ih > 0.87], key=lambda k: k[1])
    assert len(low) == 3, low
    for name, comp in zip(("lobby_ic_hero", "lobby_ic_bag", "lobby_ic_shop"), low):
        im, box = cut(icol, ialpha, ilab, comp)
        x, y = round(box[0] * kx), round(box[1] * ky)
        w, h = round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky)
        out = scale_rgba(im, w, h)
        out.save(os.path.join(UI, name + ".png"))
        layout[name] = [x, y, w, h]
        made[name] = out
    # 배경
    bgsrc = np.array(Image.open(os.path.join(SRC, "로비_배경.webp")).convert("RGB"))
    # 제미나이 워터마크(오른쪽 아래 반짝이, 원본의 82~92% x 89~94% 자리)를 왼쪽 옆의 흙바닥으로 덮는다
    hh, ww = bgsrc.shape[:2]
    wx0, wx1, wy0, wy1 = int(ww * 0.79), int(ww * 0.90), int(hh * 0.885), int(hh * 0.945)
    bgsrc[wy0:wy1, wx0:wx1] = bgsrc[wy0:wy1, wx0 - (wx1 - wx0):wx0][:, ::-1]
    bgim = Image.fromarray(bgsrc).resize((CW, CH), Image.LANCZOS)
    bgim.save(os.path.join(BG, "lobby_bg.png"))
    json.dump(layout, open(os.path.join(UI, "lobby_layout.json"), "w", encoding="utf-8"), indent=1)
    for k, v in layout.items():
        print("%-20s %s" % (k, v))
    # ---- 확인용 1: 부품을 체크무늬(위) · 어두운 바탕(가운데) · 밝은 바탕(아래)에
    order = [n for n in made if n != "lobby_tab_bar"]
    Wd = sum(made[n].width + 16 for n in order) + 16
    Hd = max(made[n].height for n in order)
    sheet = Image.new("RGBA", (Wd, Hd * 3 + 64), (255, 255, 255, 255))
    for row, fillc in enumerate(("check", (24, 24, 34, 255), (250, 250, 250, 255))):
        x = 16
        for n in order:
            im = made[n]
            tile = Image.new("RGBA", im.size, fillc if fillc != "check" else (255, 0, 0, 255))
            if fillc == "check":
                t = np.zeros((im.height, im.width, 4), np.uint8)
                yy, xx = np.mgrid[0:im.height, 0:im.width]
                t[...] = np.where((((xx // 12) + (yy // 12)) % 2 == 0)[..., None], (60, 200, 90, 255), (40, 150, 230, 255))
                tile = Image.fromarray(t)
            tile.alpha_composite(im)
            sheet.paste(tile, (x, 16 + row * (Hd + 16)))
            x += im.width + 16
    sheet.save(os.path.join(SRC, "로비_부품확인.png"))
    # ---- 확인용 2: 완성 화면 | 게임 합성
    comp = bgim.convert("RGBA")
    comp.alpha_composite(made["lobby_tab_bar"], (0, layout["lobby_tab_bar"][1]))
    for n in order:
        if n in layout:
            comp.alpha_composite(made[n], (layout[n][0], layout[n][1]))
    orig = Image.open(os.path.join(SRC, "로비_완성화면.webp")).convert("RGBA").resize((CW, CH), Image.LANCZOS)
    both = Image.new("RGBA", (CW * 2 + 16, CH), (0, 0, 0, 255))
    both.paste(orig, (0, 0))
    both.paste(comp, (CW + 16, 0))
    both.resize((both.width // 2, both.height // 2), Image.LANCZOS).save(os.path.join(SRC, "로비_합성확인.png"))


if __name__ == "__main__":
    main()
