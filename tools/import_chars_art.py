#!/usr/bin/env python3
"""캐릭터 원화 (2026-11-25 민수 님): 제미나이 원화 시트(마젠타 바탕, 한 장에 여러 명)에서 한 명씩 떼어 낸다.

순서: 원화(이 도구) -> 모션 모델링 -> 픽셀랩 스프라이트. 초상화는 원화의 머리를 잘라 만든다.
요청문: design/ux/캐릭터-요청문.md

떼어 내는 법
- 바탕(마젠타)과 이어진 마젠타빛 칸을 모두 바탕으로 본다 (캐릭터 속의 보라 · 분홍은 바탕과 이어져 있지 않아 남는다).
- 가장자리 3px 안에서 마젠타가 비친 칸은 외곽선 색으로 덮는다 (보랏빛 테두리가 남지 않게). 투명도는 0/255.
- 서로 닿은 캐릭터는 SPLIT 에 적은 세로줄에서 끊는다.

SHEETS: 원화 파일 -> 왼쪽 위부터 읽는 차례대로의 이름. 이름이 "-" 로 시작하면 버린다 (다시 받을 것).
결과: design/art/ui_src/캐릭터/원화/<id>.png, 그림체 기준 design/art/ui_src/캐릭터/기준_원화_그림체.png

Usage: python tools/import_chars_art.py
"""
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby4_ui as L4  # noqa: E402

DIR = os.path.join(L4.SRC, "캐릭터")
OUT = os.path.join(DIR, "원화")
SQ = np.ones((3, 3), bool)
# 원화 시트: (파일, [이름 ...], [(x0, x1, y0, y1) 끊을 곳 ...])
SHEETS = [
    ("A-1_원화_시안3.png", ["liubei", "-관우(말이 옆에 섬)", "zhangfei", "zhugeliang", "-조조(도보)", "-빨간 옷", "-조운(도보)", "lvbu"],
     [(500, 580, 400, 840)]),
]
# 그림체 기준으로 쓸 것 (통과한 원화)
STYLE = ["liubei", "zhangfei", "zhugeliang", "lvbu"]


def cut_sheet(path, names, splits):
    a = np.array(Image.open(path).convert("RGB")).astype(int)
    bg = np.median(a[:40, :40].reshape(-1, 3), axis=0)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    magish = (np.minimum(r - g, b - g) > 70) & (np.abs(a - bg).sum(axis=2) < 260)
    lab, _ = ndimage.label(magish)
    border = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1])
    border.discard(0)
    back = np.isin(lab, list(border))                      # 바탕과 이어진 마젠타빛
    fig = ~back
    for x0, x1, y0, y1 in splits:                           # 붙은 캐릭터 끊기: 가장 좁은 세로줄
        col = fig[y0:y1, x0:x1].sum(axis=0)
        cx = x0 + int(np.argmin(col))
        fig[y0:y1, cx - 1:cx + 2] = False
        # 끊은 자리에 남은 옆 캐릭터의 가는 조각(외곽선 토막)을 지운다: 끊은 줄에 닿은, 7px 보다 가는 부분
        win = fig[y0:y1, cx - 16:cx + 17]
        thin = win & ~ndimage.binary_opening(win, structure=np.ones((7, 7), bool))
        tl, _ = ndimage.label(thin)
        hit = set(tl[:, 13:20].ravel()) - {0}
        win[np.isin(tl, list(hit))] = False
    fig = ndimage.binary_opening(fig, iterations=1)
    lab, n = ndimage.label(ndimage.binary_fill_holes(fig))
    objs = []
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        y, x = sl
        if (x.stop - x.start) > 80 and (y.stop - y.start) > 150:
            objs.append((y.start, x.start, i, sl))
    # 줄(위아래)로 묶고 줄 안에서는 왼쪽부터
    objs.sort()
    rows, cur = [], []
    for o in objs:
        if cur and o[0] - cur[0][0] > 200:
            rows.append(sorted(cur, key=lambda t: t[1]))
            cur = []
        cur.append(o)
    rows.append(sorted(cur, key=lambda t: t[1]))
    flat = [o for row in rows for o in row]
    assert len(flat) == len(names), (len(flat), len(names))
    out = {}
    for (_, _, i, sl), name in zip(flat, names):
        mask = lab[sl] == i
        rgb = a[sl].copy()
        # 가장자리 3px: 마젠타가 비친 칸 -> 외곽선 색
        dark = mask & (rgb.mean(axis=2) < 40)
        ink = np.median(rgb[dark], axis=0) if dark.sum() > 20 else np.array([20, 18, 20])
        rim = mask & ~ndimage.binary_erosion(mask, structure=SQ, iterations=3, border_value=0)
        spill = np.minimum(rgb[..., 0] - rgb[..., 1], rgb[..., 2] - rgb[..., 1]) > 28
        rgb[rim & spill] = ink
        img = L4.seal(np.dstack([rgb, np.where(mask, 255, 0)]).astype(np.uint8))
        out[name] = img
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    got = {}
    for fname, names, splits in SHEETS:
        for name, img in cut_sheet(os.path.join(DIR, fname), names, splits).items():
            if name.startswith("-"):
                continue
            Image.fromarray(img).save(os.path.join(OUT, name + ".png"))
            got[name] = img
            print("%-12s %dx%d  (%s)" % (name, img.shape[1], img.shape[0], fname))
    # 그림체 기준: 통과한 원화를 마젠타 바탕에 나란히
    pick = [got[k] for k in STYLE if k in got]
    if pick:
        gap = 44
        h = max(p.shape[0] for p in pick) + gap * 2
        w = sum(p.shape[1] for p in pick) + gap * (len(pick) + 1)
        ref = Image.new("RGBA", (w, h), (255, 0, 255, 255))
        x = gap
        for p in pick:
            im = Image.fromarray(p)
            ref.alpha_composite(im, (x, h - gap - im.height))
            x += im.width + gap
        ref.convert("RGB").save(os.path.join(DIR, "기준_원화_그림체.png"))
    print("원화 %d명" % len(got))


if __name__ == "__main__":
    main()
