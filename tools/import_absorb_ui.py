#!/usr/bin/env python3
"""흡수 창 그림(마젠타 배경) -> 창 부품 (assets/ui/absorb_*.png) + 자리 (assets/ui/absorb_layout.json).

원본: design/art/ui_src/
  흡수창_UI_창틀.webp   창 틀 + 제목 띠만 (마젠타 바탕)
  흡수창_UI_버튼.webp   버튼 · 칸만 (닫기 · 얼굴 틀 2 · 화살표 · 속성 카드 3 · 속성 칸 3 · 흡수하기)
  흡수창_완성화면.webp  비교용 완성 화면

받은 그림과 게임이 다른 점을 여기서 맞춘다 (2026-11-24 민수 님):
- 속성 칸이 그림에는 한 줄(3개)인데 게임은 6개(3개씩 두 줄, 칸 = 성급)다. 같은 칸 그림을 바로 아래 줄에 한 번 더 쓰고,
  창 틀은 널빤지 한 장 높이(PLANK)를 칸 줄 아래에 끼워 넣어 늘린다 (9-slice처럼 가운데만 늘어난다, 나뭇결은 그대로).
- 취소 버튼은 없다. 닫기는 공용 btn_close 를 그림의 닫기 자리에 놓는다.
- 제목 띠는 창 위에 걸쳐 있다: 네모로 떼어 내고, 창 틀에서는 그 자리를 줄마다 왼쪽 칸 색으로 메운다.

떼어 내는 법은 로비 · 난이도 창과 같다 (tools/import_lobby_ui.py 의 matte · cut · scale_rgba).

Usage: python tools/import_absorb_ui.py     (확인용: design/art/ui_src/흡수창_합성확인.png)
"""
import json
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

TITLE = (121, 180, 453, 259)        # 제목 띠 (원본 px, x0 y0 x1 y1)
PLANK0, PLANK1 = 651, 711           # 끼워 넣을 널빤지 한 장 (원본 y): 칸 줄 바로 아래의 널빤지
PLANK = PLANK1 - PLANK0


def main():
    a = L.load("흡수창_UI_창틀.webp")
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    layout, made = {}, {}

    def scaled(rgba):
        h, w = rgba.shape[:2]
        return L.scale_rgba(Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8)), round(w * kx), round(h * ky))

    def shift(y):
        return y + PLANK if y >= PLANK1 else y

    # ---- 창 틀 · 제목 띠 (창틀 그림)
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, 2000)
    win = max(comps, key=lambda c: (c[3] - c[1]) * (c[4] - c[2]))
    _, wx0, wy0, wx1, wy1 = win
    full = np.dstack([col, alpha * 255.0])
    tx0, ty0, tx1, ty1 = TITLE
    title = full[ty0:ty1, tx0:tx1].copy()
    made["absorb_title"] = scaled(title)
    layout["absorb_title"] = [round(tx0 * kx), round(ty0 * ky), made["absorb_title"].width, made["absorb_title"].height]

    fr = full[wy0:wy1, wx0:wx1].copy()
    ftop = int(np.where(fr[:, 4, 3] > 128)[0].min())          # 창 틀이 시작하는 줄 (왼쪽 테두리)
    # 제목 띠가 덮던 자리: 줄마다 제목 띠 왼쪽(x = 제목 왼쪽 - 20)의 색으로 메운다 (테두리 · 널빤지가 가로로 같다)
    ref = tx0 - wx0 - 20
    for y in range(ftop, ty1 - wy0 + 2):
        fr[y, tx0 - wx0 - 2:tx1 - wx0 + 2] = fr[y, ref]
    fr = fr[ftop:]
    cut = PLANK1 - (wy0 + ftop)
    band = fr[cut - PLANK:cut].copy()                          # 칸 줄 아래 널빤지 한 장을 한 번 더
    fr = np.concatenate([fr[:cut], band, fr[cut:]], axis=0)
    made["absorb_frame"] = scaled(fr)
    layout["absorb_frame"] = [round(wx0 * kx), round((wy0 + ftop) * ky), made["absorb_frame"].width, made["absorb_frame"].height]

    # ---- 버튼 · 칸 (버튼 그림)
    bcol, balpha = L.matte(L.load("흡수창_UI_버튼.webp"))
    blab, bcomps = L.components(balpha, 1200)
    rows = sorted(bcomps, key=lambda c: (c[2] // 30, c[1]))
    close, faces_arrow, cards, slots, ok = rows[0], rows[1:4], rows[4:7], rows[7:10], rows[10]

    def take(name, comp, place=None, dy=0):
        im, box = L.cut(bcol, balpha, blab, comp)
        out = L.scale_rgba(im, round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky))
        made[name] = out
        layout[place or name] = [round(box[0] * kx), round((shift(box[1]) + dy) * ky), out.width, out.height]
        return box

    take("absorb_face_0", faces_arrow[0], "face_food")
    take("absorb_arrow", faces_arrow[1])
    take("absorb_face_1", faces_arrow[2], "face_target")
    for i in range(3):
        take("absorb_card_%d" % i, cards[i], "card_%d" % i)
        box = take("absorb_slot_%d" % i, slots[i], "slot_%d" % i)
        # 둘째 줄: 같은 칸 그림을 널빤지 한 장 아래에
        layout["slot_%d" % (i + 3)] = [layout["slot_%d" % i][0], round((box[1] + PLANK) * ky), made["absorb_slot_%d" % i].width, made["absorb_slot_%d" % i].height]
    take("absorb_btn_ok", ok)
    _, cx0, cy0, cx1, cy1 = close
    layout["close"] = [round(cx0 * kx), round(cy0 * ky), round((cx1 - cx0) * kx), round((cy1 - cy0) * ky)]

    for name, im in made.items():
        im.save(os.path.join(L.UI, name + ".png"))
    for k in sorted(layout):
        print("%-16s %s" % (k, layout[k]))
    json.dump(layout, open(os.path.join(L.UI, "absorb_layout.json"), "w", encoding="utf-8"), indent=1)

    # ---- 확인용: 완성 화면 | 게임 합성 (어둡게 한 전투 배경 위에 부품을 자리대로)
    bg = Image.open(os.path.join(L.BG, "battle_field.png")).convert("RGBA").resize((L.CW, L.CH))
    bg.alpha_composite(Image.new("RGBA", bg.size, (8, 12, 22, 184)))
    for name in ("absorb_frame", "absorb_title", "absorb_arrow", "absorb_btn_ok"):
        bg.alpha_composite(made[name], (layout[name][0], layout[name][1]))
    for spot, img in (("face_food", "absorb_face_0"), ("face_target", "absorb_face_1")):
        bg.alpha_composite(made[img], (layout[spot][0], layout[spot][1]))
    for i in range(3):
        bg.alpha_composite(made["absorb_card_%d" % i], (layout["card_%d" % i][0], layout["card_%d" % i][1]))
    for i in range(6):
        bg.alpha_composite(made["absorb_slot_%d" % (i % 3)], (layout["slot_%d" % i][0], layout["slot_%d" % i][1]))
    close_im = Image.open(os.path.join(L.UI, "btn_close.png")).convert("RGBA").resize((layout["close"][2], layout["close"][3]))
    bg.alpha_composite(close_im, (layout["close"][0], layout["close"][1]))
    orig = Image.open(os.path.join(L.SRC, "흡수창_완성화면.webp")).convert("RGBA").resize((L.CW, L.CH), Image.LANCZOS)
    both = Image.new("RGBA", (L.CW * 2 + 16, L.CH), (0, 0, 0, 255))
    both.paste(orig, (0, 0))
    both.paste(bg, (L.CW + 16, 0))
    both.resize((both.width // 2, both.height // 2), Image.LANCZOS).save(os.path.join(L.SRC, "흡수창_합성확인.png"))


if __name__ == "__main__":
    main()
