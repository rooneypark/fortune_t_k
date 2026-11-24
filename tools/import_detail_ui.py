#!/usr/bin/env python3
"""장수 · 병사 상세 부품 (2026-11-24) -> assets/ui/*.png + 9-slice 여백 (assets/ui/nine.json).

원본: design/art/ui_src/
  상세_UI_부품.webp   새 부품 9개 (마젠타 바탕): 정보 판 · ◀ · ▶ · 등급 띠 · 표시 판 · 내용 판 · 자동 장착 · 모두 해제 · 인연 띠
  상세_완성화면.webp  비교용
큰 창 틀 · 탭 · 칸 · 닫기는 공용(dlg_* · btn_close, tools/import_dialog_ui.py)을 쓴다.

판 · 띠는 9-slice로 어떤 크기에도 쓴다 (여백 = 테두리 폭, [왼 위 오른 아래] 또는 하나):
- dlg_info    정보 판 (큰 판, 다른 화면의 큰 판으로도)
- dlg_panel   내용 판 (탭 아래 큰 칸, 다른 화면의 칸 판으로도)
- dlg_badge   등급 띠 (보라 · 금테)
- dlg_tag     작은 표시 판 (진영 · 병종)
- dlg_bond    인연 띠 (왼쪽 끝 금색 매듭은 늘어나지 않게 왼쪽 여백을 넓게)
오른쪽 아래 워터마크(반짝이)는 인연 띠에 걸쳐 있어, 띠의 깨끗한 왼쪽 구간으로 덮어 지운다.
그림 그대로 쓰는 버튼 (아이콘이 있어 늘이지 않는다): btn_prev · btn_next (◀ ▶), btn_auto (자동 장착) · btn_unequip (모두 해제).

Usage: python tools/import_detail_ui.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby_ui as L  # noqa: E402

# 위 → 아래, 같은 줄은 왼쪽 → 오른쪽 차례
NAMES = ["dlg_info", "btn_prev", "btn_next", "dlg_badge", "dlg_tag", "dlg_panel", "btn_auto", "btn_unequip", "dlg_bond"]
MARGIN = {"dlg_info": 20, "dlg_panel": 20, "dlg_badge": 14, "dlg_tag": 12, "dlg_bond": [66, 18, 18, 18]}


def main():
    a = L.load("상세_UI_부품.webp")
    # 제미나이 워터마크(반짝이, 원본 x 469~495 · y 900~955)가 인연 띠 오른쪽 아래에 걸쳐 있다.
    # 띠는 가로로 같은 무늬가 이어지므로, 그 세로 구간을 줄마다 바로 왼쪽의 깨끗한 구간으로 덮는다 (띠 아래 마젠타도 함께).
    a[850:970, 455:510] = a[850:970, 390:445]
    sh, sw = a.shape[:2]
    kx, ky = L.CW / sw, L.CH / sh
    col, alpha = L.matte(a)
    lab, comps = L.components(alpha, 1500)
    comps = sorted(comps, key=lambda c: (c[2] // 30, c[1]))
    assert len(comps) == len(NAMES), [c[1:] for c in comps]
    for name, comp in zip(NAMES, comps):
        im, box = L.cut(col, alpha, lab, comp)
        out = L.scale_rgba(im, round((box[2] - box[0]) * kx), round((box[3] - box[1]) * ky))
        out.save(os.path.join(L.UI, name + ".png"))
        print("%-12s %s  여백 %s" % (name, out.size, MARGIN.get(name, "-")))
    path = os.path.join(L.UI, "nine.json")
    nine = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    nine.update(MARGIN)
    json.dump(nine, open(path, "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
