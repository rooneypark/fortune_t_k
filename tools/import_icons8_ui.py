#!/usr/bin/env python3
"""아이콘 8차 (2026-11-25 민수 님): 8차 완성 화면의 탭 · 버튼 아이콘을 떼어 내 assets/ui/icons 의 같은 이름 그림을 바꾼다.
게임은 아이콘을 이름으로 쓰므로(탭 · 버튼 · 칸), 그림만 바꾸면 모든 화면의 아이콘이 새 그림체로 바뀐다.

떼어 내는 법: 아이콘 둘레 칸을 어림으로 잡고, 칸 가장자리 색(바탕)과 다른 칸만 남긴다 (속의 구멍은 메운다).
가장자리는 seal() 로 마감한다 (바탕색이 묻은 칸 없음, 투명도 0/255).

확인용 (게임 실행 아님): design/art/ui_src/아이콘8_확인.png

Usage: python tools/import_icons8_ui.py
"""
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby4_ui as L4  # noqa: E402

SRC = L4.SRC
ICONS = os.path.join(L4.UI, "icons")
# 이름: (원본, (x0, y0, x1, y1)) — 같은 그림을 여러 이름으로 쓰면 이름을 쉼표로
TABLE = {
    "tab_hero": ("장수목록8_완성화면", (200, 352, 305, 447)),
    "tab_soldier": ("장수목록8_완성화면", (462, 352, 560, 447)),
    "tab_growth,tab_pick,ic_star": ("장수상세8_완성화면", (200, 352, 305, 447)),
    "tab_trait": ("장수상세8_완성화면", (466, 352, 556, 447)),
    "tab_gear": ("장수상세8_완성화면", (682, 352, 794, 447)),
    "ic_sword": ("가방8_완성화면", (176, 352, 284, 447)),
    "ic_shield": ("가방8_완성화면", (392, 352, 500, 447)),
    "ic_orb": ("가방8_완성화면", (612, 352, 708, 447)),
    "act_synth": ("가방8_완성화면", (798, 478, 888, 546)),
    "icon_gold": ("상점8_완성화면", (340, 352, 440, 447)),
    "icon_rice": ("상점8_완성화면", (506, 352, 610, 447)),
    "tab_pack": ("상점8_완성화면", (686, 352, 780, 447)),
    "tab_daily": ("임무8_완성화면", (222, 494, 322, 592)),
    "tab_weekly": ("임무8_완성화면", (462, 488, 564, 588)),
    "tab_trophy,icon_medal": ("임무8_완성화면", (702, 484, 804, 590)),
    "ic_mail": ("우편함8_완성화면", (178, 508, 284, 592)),
    "icon_chest,act_claim_all": ("우편함8_완성화면", (176, 1232, 304, 1344)),
    "act_trash": ("우편함8_완성화면", (548, 1236, 640, 1340)),
    "act_enhance": ("장비상세8_완성화면", (172, 1192, 276, 1292)),
    "act_equip": ("장비상세8_완성화면", (430, 1197, 570, 1287)),
    "act_break": ("장비상세8_완성화면", (676, 1197, 834, 1287)),
    "diff_1": ("난이도8_완성화면", (466, 676, 560, 780)),
    "act_odds": ("난이도8_완성화면", (750, 560, 836, 628)),
    "act_retry": ("주공정보8_완성화면", (172, 1272, 280, 1340)),
    "icon_swords": ("주공정보8_완성화면", (166, 714, 290, 818)),
    "ic_music": ("설정8_시안1", (186, 506, 276, 596)),
    "ic_sound": ("설정8_시안1", (180, 602, 282, 694)),
    "ic_reel": ("설정8_시안2_릴아이콘_링크줄", (706, 498, 858, 584)),
}


def _pick(mask, raw):
    """덩어리 고르기: 큰 덩어리의 4% 넘는 것만 (해의 빛살처럼 떨어진 조각은 남기고 점 · 가는 줄은 버린다)."""
    lab, n = ndimage.label(ndimage.binary_dilation(mask, iterations=2))
    if n == 0:
        return None
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    good = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        hh, ww = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        if sizes[i] >= max(30, sizes.max() * 0.04) and min(hh, ww) > 9:
            good.append(i + 1)
    return np.isin(lab, good) & raw


def cut_icon(a, box):
    """아이콘 = 진한 외곽선이 둘러싼 모양. 외곽선(어두운 칸)을 잡아 속을 채운다 — 바탕색과 비슷한 색의 아이콘(붉은 버튼 위의
    보물 상자 등)도 깎이지 않는다. 외곽선이 끊겨 속이 안 채워지면 바탕과 다른 칸으로 잡는 옛 방법을 쓴다."""
    x0, y0, x1, y1 = box
    reg = a[y0:y1, x0:x1].astype(int)
    h, w = reg.shape[:2]
    lum = reg.mean(axis=2)
    edge = np.concatenate([reg[0], reg[-1], reg[:, 0], reg[:, -1]])
    base = np.median(edge, axis=0)
    dark = lum < min(46.0, base.mean() - 16.0)
    # 탭 · 칸의 테두리 줄: 칸 위아래 끝의 가로로 긴 어두운 줄은 아이콘이 아니다
    for rows in (range(0, 7), range(h - 7, h)):
        for r in rows:
            if dark[r].sum() > w * 0.6:
                dark[r] = False
    diff = np.abs(reg - base).sum(axis=2) > 64
    diff[:2] = diff[-2:] = False
    diff[:, :2] = diff[:, -2:] = False
    for rows in (range(0, 7), range(h - 7, h)):
        for r in rows:
            if diff[r].sum() > w * 0.6:
                diff[r] = False
    out_mask = _pick(dark, dark)
    dif_mask = _pick(diff, diff)
    if out_mask is None and dif_mask is None:
        return None
    filled = ndimage.binary_fill_holes(ndimage.binary_closing(out_mask, iterations=1)) if out_mask is not None else None
    if filled is not None and dif_mask is not None and filled.sum() >= dif_mask.sum() * 0.93:
        keep = filled                                    # 외곽선이 닫혀 있다: 외곽선 안쪽이 곧 아이콘
    else:
        # 외곽선이 끊겼거나(칸 끝에서 잘린 아이콘) 외곽선이 없는 아이콘: 바탕과 다른 칸을 더한다
        both = dif_mask if filled is None else (filled | dif_mask if dif_mask is not None else filled)
        keep = ndimage.binary_fill_holes(ndimage.binary_closing(both, iterations=1))
    ys, xs = np.where(keep)
    by0, by1, bx0, bx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    out = np.dstack([reg, np.where(keep, 255, 0)]).astype(np.uint8)[by0:by1, bx0:bx1]
    return L4.seal(out, rings=1)


def main():
    cache, made = {}, []
    for names, (src, box) in TABLE.items():
        if src not in cache:
            cache[src] = np.array(Image.open(os.path.join(SRC, src + ".png")).convert("RGB"))
        icon = cut_icon(cache[src], box)
        if icon is None:
            print("빈 아이콘:", names)
            continue
        for name in names.split(","):
            Image.fromarray(icon).save(os.path.join(ICONS, name + ".png"))
        made.append((names, icon))
    sheet = Image.new("RGBA", (1500, 520), (110, 86, 62, 255))
    x, y = 10, 10
    for names, icon in made:
        im = Image.fromarray(icon)
        if x + im.width > 1490:
            x, y = 10, y + 130
        sheet.alpha_composite(im, (x, y))
        x += im.width + 14
    sheet.convert("RGB").save(os.path.join(SRC, "아이콘8_확인.png"))
    print("icons:", ", ".join("%s %dx%d" % (n.split(",")[0], i.shape[1], i.shape[0]) for n, i in made))


if __name__ == "__main__":
    main()
