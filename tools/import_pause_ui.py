#!/usr/bin/env python3
"""공용 조작 부품 (2026-11-24): 소리 막대 · 고르기 칸 그림 -> assets/ui/ctl_*.png.

원본은 일시정지 창 그림이다 (design/art/ui_src/일시정지창_UI_버튼.webp). 일시정지 창은 없앴고(일시정지 = 창 없이 토글),
막대 · 칸만 떼어 공용으로 쓴다: PxControls.Slide · Seg 가 이 그림이 있으면 자동으로 쓴다 (설정 창 등).
- 소리 막대: 막대 그림에서 손잡이(ctl_knob)를 떼어 내고, 홈은 두 장 — 빈 홈(ctl_track, 어두운 속을 가로로 이어 붙임)과
  찬 홈(ctl_track_fill, 금색 속). 게임은 빈 홈 위에 찬 홈을 값만큼 잘라 그리고 손잡이를 얹는다. 양끝 테두리 = 16 px.
- 고르기 칸: 보통 칸(ctl_cell) · 고른 칸(ctl_cell_on, 금테).

Usage: python tools/import_pause_ui.py
"""
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

TITLE = (121, 180, 453, 259)
KNOB_C, KNOB_R = (369.5, 297.0), 18.0          # 첫 막대의 손잡이 중심 · 반지름 (원본 px)
GOLD_X, DARK_X = 280, 470                      # 막대 속의 금색 · 어두운 칸 (원본 x)
CAP = 9                                        # 막대 양끝 테두리 폭 (원본 px)


def main():
    a = L.load("일시정지창_UI_창틀.webp")
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    made = {}

    def scaled(rgba):
        h, w = rgba.shape[:2]
        return L.scale_rgba(Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8)), round(w * kx), round(h * ky))

    bcol, balpha = L.matte(L.load("일시정지창_UI_버튼.webp"))
    blab, bcomps = L.components(balpha, 800)
    parts = sorted([c for c in bcomps if c[2] < 900], key=lambda c: (c[2] // 30, c[1]))
    close, bar0, bar1, seg, resume, setting, retreat = parts
    brgba = np.dstack([bcol, balpha * 255.0])

    # 소리 막대: 손잡이 / 빈 홈 / 찬 홈 (첫 막대에서)
    _, bx0, by0, bx1, by1 = bar0
    bar = brgba[by0:by1, bx0:bx1].copy()
    h, w = bar.shape[:2]
    cxk, cyk = KNOB_C[0] - bx0, KNOB_C[1] - by0
    yy, xx = np.mgrid[0:h, 0:w]
    knob = bar.copy()
    knob[..., 3] = np.where((xx + 0.5 - cxk) ** 2 + (yy + 0.5 - cyk) ** 2 <= KNOB_R ** 2, knob[..., 3], 0)
    kxs, kys = int(cxk - KNOB_R - 1), int(cyk - KNOB_R - 1)
    knob = knob[max(0, kys):int(cyk + KNOB_R + 2), max(0, kxs):int(cxk + KNOB_R + 2)]
    made["ctl_knob"] = scaled(knob)
    # 홈의 높이: 손잡이가 위아래로 튀어나온 만큼을 뺀 줄 (막대 왼쪽 끝 열이 불투명한 줄)
    rows = np.where(bar[:, CAP + 2, 3] > 128)[0]
    t0, t1 = int(rows.min()), int(rows.max()) + 1
    groove = bar[t0:t1].copy()
    gl = groove[:, :CAP].copy()                              # 왼쪽 끝 테두리
    gr = groove[:, w - CAP:].copy()                          # 오른쪽 끝 테두리
    dark = groove.copy()
    dark[:, CAP:w - CAP] = groove[:, DARK_X - bx0:DARK_X - bx0 + 1]
    dark[:, :CAP] = gr[:, ::-1]                              # 빈 홈의 왼쪽 끝 = 오른쪽 끝을 뒤집어서 (금색이 없게)
    gold = groove.copy()
    gold[:, CAP:w - CAP] = groove[:, GOLD_X - bx0:GOLD_X - bx0 + 1]
    gold[:, w - CAP:] = gl[:, ::-1]
    made["ctl_track"] = scaled(dark)
    made["ctl_track_fill"] = scaled(gold)

    # 고르기 칸: 보통 칸(왼쪽) · 고른 칸(가운데)
    _, sx0, sy0, sx1, sy1 = seg
    cw = (sx1 - sx0) / 3.0
    cells = [brgba[sy0:sy1, int(round(sx0 + i * cw)):int(round(sx0 + (i + 1) * cw))].copy() for i in range(3)]
    made["ctl_cell"] = scaled(cells[0])
    made["ctl_cell_on"] = scaled(cells[1])

    for name, im in made.items():
        im.save(os.path.join(L.UI, name + ".png"))
        print("%-16s %s  (양끝 테두리 %d px)" % (name, im.size, round(CAP * kx)) if name == "ctl_track" else "%-16s %s" % (name, im.size))


if __name__ == "__main__":
    main()
