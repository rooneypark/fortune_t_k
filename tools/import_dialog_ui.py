#!/usr/bin/env python3
"""공용 다이얼로그 부품 (2026-11-24): 장수 목록 화면 그림 -> assets/ui/dlg_*.png + 9-slice 여백 (assets/ui/nine.json).

원본: design/art/ui_src/
  장수목록_UI_창틀.webp   큰 창 틀만 (마젠타 바탕)
  장수목록_UI_버튼.webp   고른 탭 · 안 고른 탭 · 고른 칩 · 안 고른 칩 · 카드 칸 (하나씩, 마젠타 바탕) — 지금은 카드만 쓴다
  장수목록_UI_버튼2.webp  탭 · 칩을 ① 크기 그대로 다시 받은 것 (민수 님, 2026-11-24). 탭 · 칩은 여기서.
                          안 고른 탭의 오른쪽 끝은 닫기 버튼에 가려 있어, 왼쪽 절반을 뒤집어 오른쪽을 채운다 (좌우 대칭 판).
  장수목록_완성화면.webp  비교용

부품이 모두 "테두리 + 고른 속"이라 9-slice로 쓴다: 가장자리(여백 px)는 그대로, 가운데만 늘어난다.
그래서 크기가 달라도 장수 · 병사 목록, 가방, 상점 등 어디에나 쓴다 (Px.nine · PxButton nine).
- dlg_frame   큰 창 틀 (app.gd 다이얼로그 틀)
- dlg_tab_on / dlg_tab_off    탭 (W.tabs)
- dlg_chip_on / dlg_chip_off  작은 고르기 칩 (진영 · 종류 거르기)
- dlg_card    카드 칸 (장수 · 병사 · 장비 칸)
그림은 화면 배율(572 x 1024 -> 1024 x 1792)로 한 번만 키운다. 닫기는 공용 btn_close.
오른쪽 아래 반짝이(워터마크)는 작은 덩어리라 버린다.

Usage: python tools/import_dialog_ui.py
"""
import json
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

# 9-slice 여백 (화면 px): 테두리 · 귀퉁이 징이 들어가는 폭
MARGIN = {"dlg_frame": 52, "dlg_tab_on": 16, "dlg_tab_off": 16, "dlg_chip_on": 14, "dlg_chip_off": 14, "dlg_card": 22}
PARTS = ["dlg_tab_on", "dlg_tab_off", "dlg_chip_on", "dlg_chip_off", "dlg_card"]


def take(src, min_area):
    a = L.load(src)
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, min_area)
    out = []
    for comp in sorted(comps, key=lambda c: c[2]):
        im, box = L.cut(col, alpha, lab, comp)
        out.append(L.scale_rgba(im, round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky)))
    return out


def tabs_and_chips():
    """버튼2 그림: 위 줄 = 고른 탭 · 안 고른 탭 · 닫기 (한 덩어리로 붙어 있다), 아래 줄 = 고른 칩 · 안 고른 칩 4개."""
    a = L.load("장수목록_UI_버튼2.webp")
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, 300)
    comps = [c for c in comps if c[2] < 400]
    top = max(comps, key=lambda c: c[3] - c[1])                  # 탭 + 닫기 덩어리
    chips = sorted([c for c in comps if c is not top], key=lambda c: c[1])
    rgba = np.dstack([col, alpha * 255.0])

    def scaled(arr):
        h, w = arr.shape[:2]
        return L.scale_rgba(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)), round(w * kx), round(h * ky))

    out = {}
    # 탭: 고른 탭의 줄 범위 (닫기보다 아래에서 시작) 안에서, 비어 있는 세로줄로 두 탭을 가른다
    _, x0, y0, x1, y1 = top
    solid = alpha > 0.5
    left_col = solid[y0:y1, x0 + 4]
    ty = np.where(left_col)[0]
    ty0, ty1 = y0 + int(ty.min()), y0 + int(ty.max()) + 1
    band = solid[ty0:ty1, x0:x1]
    # 두 탭은 맞붙어 있다: 가운데 근처(덩어리 폭의 40~60%)에서 불투명 칸이 가장 적은 세로줄이 경계
    cover = band.sum(axis=0)
    lo, hi = int(band.shape[1] * 0.4), int(band.shape[1] * 0.6)
    gap = x0 + lo + int(np.argmin(cover[lo:hi]))
    out["dlg_tab_on"] = scaled(rgba[ty0:ty1, x0:gap].copy())
    w_on = gap - x0
    off0 = gap + 1
    off = rgba[ty0:ty1, off0:off0 + w_on].copy()
    half = w_on // 2
    off[:, w_on - half:] = off[:, :half][:, ::-1]               # 오른쪽 절반 = 왼쪽 절반을 뒤집은 것
    out["dlg_tab_off"] = scaled(off)
    for name, comp in (("dlg_chip_on", chips[0]), ("dlg_chip_off", chips[1])):
        im, box = L.cut(col, alpha, lab, comp)
        out[name] = L.scale_rgba(im, round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky))
    return out


def main():
    made = {}
    frames = take("장수목록_UI_창틀.webp", 20000)
    made["dlg_frame"] = max(frames, key=lambda im: im.width * im.height)
    parts = [im for im in take("장수목록_UI_버튼.webp", 1500)]
    assert len(parts) == len(PARTS), [p.size for p in parts]
    made.update(dict(zip(PARTS, parts)))
    if os.path.exists(os.path.join(L.SRC, "장수목록_UI_버튼2.webp")):
        made.update(tabs_and_chips())
    for name, im in made.items():
        im.save(os.path.join(L.UI, name + ".png"))
        print("%-14s %s  여백 %d" % (name, im.size, MARGIN[name]))
    path = os.path.join(L.UI, "nine.json")
    nine = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    nine.update(MARGIN)
    json.dump(nine, open(path, "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
