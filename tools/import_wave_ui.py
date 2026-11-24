#!/usr/bin/env python3
"""웨이브 승리 창 그림(마젠타 배경) -> 창 부품 (assets/ui/wave_*.png) + 자리 (assets/ui/wave_layout.json).

원본: design/art/ui_src/
  웨이브승리창_UI_창틀.webp   창 틀 + 제목 띠(초록 천 포함)만
  웨이브승리창_UI_버튼.webp   버튼 · 칸만 (닫기 · 기록 줄 3 · 활약 장수 얼굴 틀 · 활약 장수 칸 · 다음 웨이브 적 칸 · 다음 웨이브 버튼)
  웨이브승리창_완성화면.webp  비교용 완성 화면

- 버튼 그림 아래쪽의 갈색 띠(y 900 아래)는 요청하지 않은 것이라 버린다.
- 제목 띠는 창 위에 걸쳐 있다: 네모로 떼어 내고, 창 틀에서는 그 자리를 줄마다 왼쪽 칸 색으로 메운다.
- 닫기는 공용 btn_close 를 그림의 닫기 자리에 놓는다.
- 공용 나무 버튼 btn_plain = 다음 버튼에서 ▶ 를 지운 것 (글자 버튼 어디에나).
- 결과 창(승리 · 패배)도 이 부품을 그대로 쓴다 (src/ui/popups/result.gd, 2026-11-24 민수 님).

Usage: python tools/import_wave_ui.py     (확인용: design/art/ui_src/웨이브승리창_합성확인.png)
"""
import json
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

TITLE = (86, 180, 491, 273)          # 제목 띠 + 초록 천 (원본 px)
NAMES = ["close", "row_0", "row_1", "row_2", "mvp_face", "mvp_info", "foes", "btn_next"]


def main():
    a = L.load("웨이브승리창_UI_창틀.webp")
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    layout, made = {}, {}

    def scaled(rgba):
        h, w = rgba.shape[:2]
        return L.scale_rgba(Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8)), round(w * kx), round(h * ky))

    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, 2000)
    _, wx0, wy0, wx1, wy1 = max(comps, key=lambda c: (c[3] - c[1]) * (c[4] - c[2]))
    full = np.dstack([col, alpha * 255.0])
    tx0, ty0, tx1, ty1 = TITLE
    made["wave_title"] = scaled(full[ty0:ty1, tx0:tx1].copy())
    layout["wave_title"] = [round(tx0 * kx), round(ty0 * ky), made["wave_title"].width, made["wave_title"].height]
    fr = full[wy0:wy1, wx0:wx1].copy()
    ftop = int(np.where(fr[:, 4, 3] > 128)[0].min())
    ref = max(14, tx0 - wx0 - 6)                               # 제목 띠 왼쪽 바로 옆 칸 (테두리 · 널빤지가 가로로 같다)
    for y in range(ftop, ty1 - wy0 + 2):
        fr[y, tx0 - wx0 - 2:tx1 - wx0 + 2] = fr[y, ref]
    fr = fr[ftop:]
    made["wave_frame"] = scaled(fr)
    layout["wave_frame"] = [round(wx0 * kx), round((wy0 + ftop) * ky), made["wave_frame"].width, made["wave_frame"].height]

    bcol, balpha = L.matte(L.load("웨이브승리창_UI_버튼.webp"))
    blab, bcomps = L.components(balpha, 1200)
    parts = sorted([c for c in bcomps if c[2] < 900], key=lambda c: (c[2] // 30, c[1]))
    assert len(parts) == len(NAMES), parts
    for name, comp in zip(NAMES, parts):
        _, x0, y0, x1, y1 = comp
        if name == "close":
            layout["close"] = [round(x0 * kx), round(y0 * ky), round((x1 - x0) * kx), round((y1 - y0) * ky)]
            continue
        im, box = L.cut(bcol, balpha, blab, comp)
        out = L.scale_rgba(im, round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky))
        made["wave_" + name] = out
        layout[name] = [round(box[0] * kx), round(box[1] * ky), out.width, out.height]

    # 공용 나무 버튼 (btn_plain): 다음 버튼에서 ▶ 를 지운 것. 글자는 게임이 쓴다 (결과 창 "로비로" 등).
    # ▶ 자리(가로 70~90%)를 줄마다 같은 줄의 가로 40% 자리 색으로 덮는다 (나무 널빤지가 가로로 이어진다).
    nxt = np.array(made["wave_btn_next"]).copy()
    nh, nw = nxt.shape[:2]
    x0, x1 = round(nw * 0.70), round(nw * 0.90)
    for y in range(round(nh * 0.2), round(nh * 0.8)):
        nxt[y, x0:x1] = nxt[y, round(nw * 0.4)]
    made["btn_plain"] = Image.fromarray(nxt)
    for name, im in made.items():
        im.save(os.path.join(L.UI, name + ".png"))
    for k in sorted(layout):
        print("%-12s %s" % (k, layout[k]))
    json.dump(layout, open(os.path.join(L.UI, "wave_layout.json"), "w", encoding="utf-8"), indent=1)

    # ---- 확인용: 완성 화면 | 게임 합성
    bg = Image.open(os.path.join(L.BG, "battle_field.png")).convert("RGBA").resize((L.CW, L.CH))
    bg.alpha_composite(Image.new("RGBA", bg.size, (8, 12, 22, 184)))
    bg.alpha_composite(made["wave_frame"], tuple(layout["wave_frame"][:2]))
    bg.alpha_composite(made["wave_title"], tuple(layout["wave_title"][:2]))
    for name in NAMES[1:]:
        bg.alpha_composite(made["wave_" + name], tuple(layout[name][:2]))
    close_im = Image.open(os.path.join(L.UI, "btn_close.png")).convert("RGBA").resize((layout["close"][2], layout["close"][3]))
    bg.alpha_composite(close_im, tuple(layout["close"][:2]))
    orig = Image.open(os.path.join(L.SRC, "웨이브승리창_완성화면.webp")).convert("RGBA").resize((L.CW, L.CH), Image.LANCZOS)
    both = Image.new("RGBA", (L.CW * 2 + 16, L.CH), (0, 0, 0, 255))
    both.paste(orig, (0, 0))
    both.paste(bg, (L.CW + 16, 0))
    both.resize((both.width // 2, both.height // 2), Image.LANCZOS).save(os.path.join(L.SRC, "웨이브승리창_합성확인.png"))


if __name__ == "__main__":
    main()
