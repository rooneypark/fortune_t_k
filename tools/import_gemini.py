#!/usr/bin/env python3
"""제미나이 그림 → 게임 부품. 마젠타(#FF00FF) 배경을 투명으로 지우고, 그림이 있는 곳만 잘라
도트 크기(w x h 도트)로 줄인 뒤 4배(최근접)로 키워 저장한다.

Usage:
  python tools/import_gemini.py <원본> <저장 경로(.png)> <가로 도트> <세로 도트> [--maxy N] [--keep-bg]
    --maxy N   : 원본에서 y N 아래는 버린다 (제미나이 반짝이 표시 · 빈 마젠타 영역)
    --keep-bg  : 배경 그림 (마젠타를 지우지 않고 꽉 채워 자른다)
"""
import sys
import numpy as np
from PIL import Image


def magenta_mask(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > 180) & (b > 180) & (g < 110)


def convert(src, dst, w_dots, h_dots, maxy=None, keep_bg=False):
    im = Image.open(src).convert("RGB")
    a = np.array(im)
    if maxy:
        a = a[:maxy]
    if keep_bg:
        rgba = np.dstack([a, np.full(a.shape[:2], 255, np.uint8)])
        box = (0, 0, a.shape[1], a.shape[0])
    else:
        mag = magenta_mask(a)
        alpha = np.where(mag, 0, 255).astype(np.uint8)
        rgba = np.dstack([a, alpha])
        ys, xs = np.where(~mag)
        box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    out = Image.fromarray(rgba, "RGBA").crop(box)
    # 도트 크기로: 칸 가운데를 집는 최근접 샘플 (번진 색 없이)
    small = out.resize((w_dots, h_dots), Image.NEAREST)
    px = np.array(small)
    px[..., 3] = np.where(px[..., 3] > 127, 255, 0)
    # 테두리에 남은 분홍 기운 제거: 아주 분홍인 칸은 지우고, 가장자리 3칸 안은 마젠타 성분을 뺀다 (despill)
    edge = magenta_mask(px[..., :3]) & (px[..., 3] > 0)
    px[edge, 3] = 0
    if not keep_bg:
        clear = px[..., 3] == 0
        near = np.zeros_like(clear)
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                near |= np.roll(np.roll(clear, dy, 0), dx, 1)
        c = px[..., :3].astype(int)
        spill = np.minimum(c[..., 0] - c[..., 1], c[..., 2] - c[..., 1])
        fix = near & (px[..., 3] > 0) & (spill > 0)
        for ch in (0, 2):
            c[..., ch] = np.where(fix, c[..., ch] - spill, c[..., ch])
        px[..., :3] = np.clip(c, 0, 255).astype(np.uint8)
    Image.fromarray(px, "RGBA").resize((w_dots * 4, h_dots * 4), Image.NEAREST).save(dst)
    print("saved", dst, "crop", box, "->", w_dots * 4, "x", h_dots * 4)


if __name__ == "__main__":
    args = sys.argv[1:]
    maxy = None
    keep = "--keep-bg" in args
    if "--maxy" in args:
        maxy = int(args[args.index("--maxy") + 1])
    convert(args[0], args[1], int(args[2]), int(args[3]), maxy, keep)
