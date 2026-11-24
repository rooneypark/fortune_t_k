#!/usr/bin/env python3
"""난이도 선택 창 그림(마젠타 배경) -> 창 부품 (assets/ui/difficulty_*.png) + 자리 (assets/ui/difficulty_layout.json).

원본: design/art/ui_src/
  난이도창_UI.webp        창 전체 (창 틀 · 제목 띠 · 버튼이 다 있는 것)
  난이도창_UI_버튼.webp   버튼만 (닫기 · 적 정보 칸 · 확률 · 난이도 3개 · 되돌리기)
  난이도창_UI_닫기.webp   닫기(X) 버튼을 바꿔서 다시 받은 것 — 닫기 버튼만 여기서 가져온다

받은 그림과 게임이 다른 점을 여기서 맞춘다:
- 창에는 난이도 줄이 4개 그려져 있다 (해골 1개가 두 번). 게임은 3개(보통 · 어려움 · 지옥)다.
  버튼만 있는 그림의 3개를 쓰고, 창에서 한 줄 높이(원본 94px)를 잘라 내 줄이고, 버튼 · 되돌리기 버튼을 그만큼 올린다.
- 빈 창 틀 그림이 없다. 창 속은 가로 널빤지라 줄마다 가로로 같은 색이므로, 버튼이 없는 왼쪽 가장자리 칸의 색을
  줄마다 가로로 이어 붙여 버튼을 지운다. 닫기 버튼이 가린 오른쪽 위 귀퉁이는 왼쪽 위 귀퉁이를 뒤집어 메운다.
- 제목 띠는 창 위에 걸쳐 있다: 원래 그림에서 네모로 떼어 내고, 창 틀에서는 그 자리를 위 방법으로 메운다.

떼어 내는 법은 로비와 같다 (tools/import_lobby_ui.py 의 matte · cut · scale_rgba).

Usage: python tools/import_difficulty_ui.py     (확인용: design/art/ui_src/난이도창_합성확인.png)
"""
import json
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

# 창에서 잘라 낼 한 줄 (원본 px): 첫 난이도 줄(중복)의 위 끝 ~ 다음 줄의 위 끝
CUT_Y0, CUT_Y1 = 376, 470


def main():
    a = L.load("난이도창_UI.webp")
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, 2000)
    win = max(comps, key=lambda c: (c[3] - c[1]) * (c[4] - c[2]))       # 창 (제목 띠 · 닫기 포함)
    _, wx0, wy0, wx1, wy1 = win
    layout, made = {}, {}

    def scaled(rgba, w_src, h_src):
        return L.scale_rgba(Image.fromarray(rgba.astype(np.uint8)), round(w_src * kx), round(h_src * ky))

    # ---- 제목 띠: 창 위로 솟은 부분의 가로 범위 + 금 테두리가 끝나는 줄까지
    rows_top = alpha[wy0:wy0 + 6, :] > 0.5
    xs = np.where(rows_top.any(axis=0))[0]
    tx0, tx1 = int(xs.min()), int(xs.max()) + 1
    # 제목 띠의 아래 끝: 그 아래로는 창 속 널빤지(왼쪽 가장자리 칸과 같은 색)가 이어진다.
    # 제목 띠 왼쪽 끝 근처의 칸들이 왼쪽 가장자리 칸과 달라지는 줄이 제목 띠다 (4줄 넘게 같아지면 끝).
    ref = col[:, wx0 + 28, :]
    diff = np.abs(col[:, tx0 + 3:tx0 + 40, :] - ref[:, None, :]).sum(axis=2).mean(axis=1) > 40
    ty1, same = wy0, 0
    while ty1 < wy0 + 140 and same < 4:
        same = 0 if diff[ty1] else same + 1
        ty1 += 1
    ty1 -= same
    title = np.dstack([col[wy0:ty1, tx0:tx1], alpha[wy0:ty1, tx0:tx1] * 255.0])
    title[title.shape[0] // 2:, :, 3] = 255          # 아래쪽 절반은 창 위에 얹힌 네모
    made["difficulty_title"] = scaled(title, tx1 - tx0, ty1 - wy0)
    layout["difficulty_title"] = [round(tx0 * kx), round(wy0 * ky), made["difficulty_title"].width, made["difficulty_title"].height]

    # ---- 창 틀: 버튼 · 제목 띠를 지운 빈 틀
    fr = np.dstack([col, alpha * 255.0])[wy0:wy1, wx0:wx1].copy()
    fh, fw = fr.shape[:2]
    # 창 틀이 시작하는 줄 (제목 띠만 있는 윗부분 다음): 왼쪽 가장자리가 불투명해지는 첫 줄
    ftop = int(np.where(fr[:, 3, 3] > 128)[0].min())
    cx = 28                                                   # 버튼이 없는 왼쪽 가장자리 칸 (창 왼쪽 끝에서 28px)
    fr[:, cx:fw - cx, :] = fr[:, cx:cx + 1, :]                # 줄마다 가로로 이어 붙인다 (버튼 · 제목 띠가 지워진다)
    fr[:ftop] = 0                                             # 창 틀 위(제목 띠가 솟아 있던 곳)는 투명
    top_h = 70                                                # 닫기 버튼이 가린 오른쪽 위 귀퉁이 ← 왼쪽 위 귀퉁이를 뒤집어서
    fr[ftop:ftop + top_h, fw - cx:, :] = fr[ftop:ftop + top_h, :cx, :][:, ::-1, :]
    c0, c1 = CUT_Y0 - wy0, CUT_Y1 - wy0
    fr = np.concatenate([fr[:c0], fr[c1:]], axis=0)[ftop:]    # 한 줄을 잘라 내 줄이고, 투명한 윗부분을 떼어 낸다
    made["difficulty_frame"] = scaled(fr, fw, fr.shape[0])
    layout["difficulty_frame"] = [round(wx0 * kx), round((wy0 + ftop) * ky), made["difficulty_frame"].width, made["difficulty_frame"].height]

    # ---- 버튼들 (버튼만 있는 그림에서)
    bcol, balpha = L.matte(L.load("난이도창_UI_버튼.webp"))
    blab, bcomps = L.components(balpha, 1200)
    by_y = sorted(bcomps, key=lambda c: (c[2], c[1]))
    close = by_y[0]
    row2 = sorted(by_y[1:3], key=lambda c: c[1])              # 적 정보 칸(왼쪽) · 확률(오른쪽)
    diffs, back = by_y[3:6], by_y[6]
    shift = CUT_Y1 - CUT_Y0
    parts = [("difficulty_btn_close", close, 0), ("difficulty_slot_foes", row2[0], 0), ("difficulty_btn_odds", row2[1], 0),
             ("difficulty_btn_1", diffs[0], shift), ("difficulty_btn_2", diffs[1], shift), ("difficulty_btn_3", diffs[2], shift),
             ("difficulty_btn_back", back, shift)]
    # 닫기(X) 버튼은 나중에 다시 받은 그림(난이도창_UI_닫기.webp: 쇠 테두리 없는 붉은 버튼)의 것을 쓴다
    xsrc = None
    if os.path.exists(os.path.join(L.SRC, "난이도창_UI_닫기.webp")):
        xcol, xalpha = L.matte(L.load("난이도창_UI_닫기.webp"))
        xlab, xcomps = L.components(xalpha, 1200)
        xsrc = (xcol, xalpha, xlab, sorted(xcomps, key=lambda c: (c[2], c[1]))[0])
    for name, comp, up in parts:
        if name == "difficulty_btn_close" and xsrc is not None:
            im, box = L.cut(xsrc[0], xsrc[1], xsrc[2], xsrc[3])
        else:
            im, box = L.cut(bcol, balpha, blab, comp)
        out = L.scale_rgba(im, round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky))
        made[name] = out
        layout[name] = [round(box[0] * kx), round((box[1] - up) * ky), out.width, out.height]
    for name, im in made.items():
        im.save(os.path.join(L.UI, name + ".png"))
        print("%-22s %s" % (name, layout[name]))
    json.dump(layout, open(os.path.join(L.UI, "difficulty_layout.json"), "w", encoding="utf-8"), indent=1)

    # ---- 확인용: 완성 화면 | 게임 합성 (어둡게 한 로비 위에 부품을 자리대로)
    bg = Image.open(os.path.join(L.BG, "lobby_bg.png")).convert("RGBA")
    bg.alpha_composite(Image.new("RGBA", bg.size, (8, 12, 22, 184)))
    for name in ["difficulty_frame", "difficulty_title"] + [p[0] for p in parts]:
        bg.alpha_composite(made[name], (layout[name][0], layout[name][1]))
    orig = Image.open(os.path.join(L.SRC, "난이도창_완성화면.webp")).convert("RGBA").resize((L.CW, L.CH), Image.LANCZOS)
    both = Image.new("RGBA", (L.CW * 2 + 16, L.CH), (0, 0, 0, 255))
    both.paste(orig, (0, 0))
    both.paste(bg, (L.CW + 16, 0))
    both.resize((both.width // 2, both.height // 2), Image.LANCZOS).save(os.path.join(L.SRC, "난이도창_합성확인.png"))


if __name__ == "__main__":
    main()
