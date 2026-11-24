#!/usr/bin/env python3
"""[옛 로비 1차 — 지금 로비는 tools/import_lobby2_ui.py. 이 파일은 떼어 내기 함수(load · matte · components · cut · scale_rgba)를
다른 도구들이 같이 쓴다. main()을 돌리면 옛 로비 부품을 다시 만드니 돌리지 않는다.]

로비 UI 그림(마젠타 배경) -> 로비 부품 (assets/ui/lobby_*.png) + 배경 (assets/bg/lobby_bg.png).

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
    raise SystemExit("옛 로비 1차 도구입니다. 지금 로비는 python tools/import_lobby2_ui.py (원본 그림도 지웠다).")


if __name__ == "__main__":
    main()
