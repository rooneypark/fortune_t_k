#!/usr/bin/env python3
"""창 그림 8차 (2026-11-25 민수 님): 완성 화면(1024 x 1792)에서 창 부품을 직접 떼어 낸다 — 로비 · 전투와 같은 방법.

원본 (design/art/ui_src/): 난이도8_완성화면.png · 흡수8_완성화면.png · 웨이브승리8_완성화면.png
만드는 것 (assets/ui/): difficulty_* · absorb_* · wave_* 그림과 <창>_layout.json (화면 px), 공용 닫기 btn_close.png

떼어 내는 법
- 창 속 부품(어두운 칸 · 버튼): 진한 외곽선이 둘러싼 모양 그대로 (import_lobby4_ui.cut_part). 투명도 0/1, 크기 · 자리 그대로.
- 창 틀 · 제목 띠 · 닫기: 뒤가 어두운 화면이라 외곽선과 배경이 붙어 보인다. 밝은 속(틀 색)을 덩어리로 잡고
  바깥으로 4px 넓혀 그 띠를 외곽선 색으로 칠한다 (배경색이 묻지 않는다).
- 빈 창 틀: 속 부품 · 제목 띠 · 닫기가 덮은 자리를 틀 색으로 메운다. 틀 가장자리 띠(14px)는 그림 그대로 두고,
  제목 띠 · 닫기가 걸친 위쪽 띠는 아래쪽 띠를 뒤집어 쓴다.

확인용 (게임 실행 아님): design/art/ui_src/창8_합성확인_<창>.png

Usage: python tools/import_popups8_ui.py
"""
import json
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_lobby4_ui as L4  # noqa: E402

SRC, UI = L4.SRC, L4.UI
LOOSE = {"absorb_arrow", "wave_foes"}     # 네모가 아닌 조각 (화살표 · 깃발이 튀어나온 칸): 가장자리를 반듯하게 고르지 않는다
RING = 4                         # 외곽선 두께
EDGE = 14                        # 틀 가장자리에서 그림 그대로 두는 띠
SQ = np.ones((3, 3), bool)


def load(name):
    return np.array(Image.open(os.path.join(SRC, name)).convert("RGB"))


def ink_of(a):
    lum = a.astype(float).mean(axis=2)
    return np.median(a[lum < 34], axis=0)


def cut_light(a, box, ink, rect=False):
    """밝은 속을 가진 조각 (틀 · 제목 띠 · 닫기) -> (RGBA, (x, y, w, h), 화면 크기 마스크).
    box = 속(밝은 칸)이 들어 있는 칸 (x, y, w, h). rect = 네모로 메운다 (다른 조각이 걸쳐 파인 자리를 없앤다)."""
    x, y, w, h = box
    pad = 10
    x0, y0, x1, y1 = x - pad, y - pad, x + w + pad, y + h + pad
    reg = a[y0:y1, x0:x1].astype(float)
    light = reg.mean(axis=2) > 88
    light[:pad - 2] = False
    light[-(pad - 2):] = False
    light[:, :pad - 2] = False
    light[:, -(pad - 2):] = False
    lab, n = ndimage.label(light)
    sizes = ndimage.sum(light, lab, range(1, n + 1))
    fill = ndimage.binary_fill_holes(lab == (1 + int(np.argmax(sizes))))
    if rect:
        ys, xs = np.where(fill)
        by0, by1, bx0, bx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        k = 10                                             # 모서리 계단: 아래 왼쪽 모서리 모양을 네 귀퉁이에 쓴다
        corner = fill[by1 - k:by1, bx0:bx0 + k].copy()
        fill[by0:by1, bx0:bx1] = True
        fill[by1 - k:by1, bx0:bx0 + k] = corner
        fill[by1 - k:by1, bx1 - k:bx1] = corner[:, ::-1]
        fill[by0:by0 + k, bx0:bx0 + k] = corner[::-1]
        fill[by0:by0 + k, bx1 - k:bx1] = corner[::-1, ::-1]
    mask = ndimage.binary_dilation(fill, structure=SQ, iterations=RING)
    rgb = reg.copy()
    rgb[mask & ~fill] = ink
    ys, xs = np.where(mask)
    by0, by1, bx0, bx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    out = np.dstack([rgb, np.where(mask, 255, 0)]).astype(np.uint8)[by0:by1, bx0:bx1]
    full = np.zeros(a.shape[:2], bool)
    full[y0:y1, x0:x1] = mask
    return out, (int(x0 + bx0), int(y0 + by0), int(bx1 - bx0), int(by1 - by0)), full, fill[by0:by1, bx0:bx1]


def cut_dark(a, box, straight=True):
    """창 속 부품 (틀 색 위의 외곽선 조각). box = 어림 칸 (x, y, w, h) 또는 (x, y, w, h, 여유) — 바짝 붙은 조각은 여유 0."""
    x, y, w, h = box[:4]
    pad = box[4] if len(box) > 4 else 9
    old = L4.DARK
    L4.DARK = 80
    try:
        img, rect, mask, (ox, oy) = L4.cut_part(a, (x - pad, y - pad, x + w + pad, y + h + pad), straight=straight)
    finally:
        L4.DARK = old
    full = np.zeros(a.shape[:2], bool)
    full[oy:oy + mask.shape[0], ox:ox + mask.shape[1]] = mask
    return img, tuple(int(v) for v in rect), full


def empty_frame(img, rect, inner_fill, covers):
    """빈 창 틀: 다른 조각이 덮은 자리와 속을 틀 색으로."""
    x, y, w, h = rect
    out = img.copy()
    core = ndimage.binary_erosion(inner_fill, structure=SQ, iterations=EDGE)
    cov = covers[y:y + h, x:x + w]
    base = np.median(out[core & ~cov, :3], axis=0)
    band = RING + EDGE + 2
    out[:band] = out[::-1][:band]                           # 위쪽 띠 = 아래쪽 띠를 뒤집은 것 (제목 띠 · 닫기가 걸쳐 있었다)
    out[core, :3] = base
    return out


def window(src, prefix, frame_box, title_box, close_box, parts, keys, close_key="close"):
    a = load(src)
    ink = ink_of(a)
    layout, imgs = {}, {}
    covers = np.zeros(a.shape[:2], bool)
    for name, box in parts.items():
        img, rect, full = cut_dark(a, box, straight=name not in LOOSE)
        imgs[name] = img
        layout[keys.get(name, name)] = list(rect)
        covers |= full
    timg, trect, tfull, _ = cut_light(a, title_box, ink)
    cimg, crect, cfull, _ = cut_light(a, close_box, ink)
    covers |= tfull | cfull
    fimg, frect, _, ffill = cut_light(a, frame_box, ink, rect=True)
    imgs[prefix + "_frame"] = empty_frame(fimg, frect, ffill, ndimage.binary_dilation(covers, iterations=3))
    imgs[prefix + "_title"] = timg
    layout[prefix + "_frame"] = list(frect)
    layout[prefix + "_title"] = list(trect)
    layout[close_key] = list(crect)
    for name, img in imgs.items():
        Image.fromarray(img).save(os.path.join(UI, name + ".png"))
    json.dump(layout, open(os.path.join(UI, prefix + "_layout.json"), "w", encoding="utf-8"), indent=1)
    # 확인용: 어두운 바탕 위에 틀 + 부품 + 제목 + 닫기를 자리대로 (왼쪽 원본, 오른쪽 합성)
    comp = Image.fromarray((a * 0.0 + np.array([30, 34, 44])).astype(np.uint8)).convert("RGBA")
    order = [prefix + "_frame"] + list(parts) + [prefix + "_title"]
    for name in order:
        comp.alpha_composite(Image.fromarray(imgs[name]), tuple(layout[keys.get(name, name)][:2]))
    comp.alpha_composite(Image.fromarray(cimg), tuple(crect[:2]))
    fx, fy, fw, fh = frect
    crop = (max(0, fx - 60), max(0, fy - 110), min(1024, fx + fw + 60), min(1792, fy + fh + 40))
    both = Image.new("RGB", ((crop[2] - crop[0]) * 2 + 10, crop[3] - crop[1]), (255, 0, 255))
    both.paste(Image.fromarray(a).crop(crop), (0, 0))
    both.paste(comp.convert("RGB").crop(crop), (crop[2] - crop[0] + 10, 0))
    both.save(os.path.join(SRC, "창8_합성확인_%s.png" % prefix))
    print(prefix, {k: v for k, v in layout.items()})
    return cimg


def main():
    close = window(
        "난이도8_완성화면.png", "difficulty", (120, 465, 784, 820), (253, 425, 518, 88), (822, 441, 81, 78),
        {"difficulty_slot_foes": (164, 542, 557, 100), "difficulty_btn_odds": (729, 542, 127, 100),
         "difficulty_btn_1": (164, 660, 697, 134), "difficulty_btn_2": (164, 810, 697, 134),
         "difficulty_btn_3": (164, 959, 697, 134), "difficulty_btn_back": (164, 1111, 697, 130)},
        {}, close_key="difficulty_btn_close")
    Image.fromarray(close).save(os.path.join(UI, "btn_close.png"))          # 공용 닫기 (붉은 네모 + 흰 X)
    window(
        "흡수8_완성화면.png", "absorb", (120, 431, 784, 888), (252, 390, 519, 89), (822, 407, 81, 78),
        {"absorb_face_0": (234, 504, 179, 170), "absorb_face_1": (614, 504, 178, 170), "absorb_arrow": (454, 544, 118, 95),
         "absorb_card_0": (153, 692, 233, 246), "absorb_card_1": (397, 692, 233, 246), "absorb_card_2": (640, 692, 232, 246),
         "absorb_slot_0": (153, 957, 233, 93), "absorb_slot_1": (397, 957, 233, 93), "absorb_slot_2": (640, 957, 232, 93),
         "_slot_3": (153, 1052, 233, 94), "_slot_4": (397, 1052, 233, 94), "_slot_5": (640, 1052, 232, 94),
         "absorb_btn_ok": (326, 1165, 373, 133)},
        {"absorb_face_0": "face_food", "absorb_face_1": "face_target", "absorb_card_0": "card_0", "absorb_card_1": "card_1",
         "absorb_card_2": "card_2", "absorb_slot_0": "slot_0", "absorb_slot_1": "slot_1", "absorb_slot_2": "slot_2",
         "_slot_3": "slot_3", "_slot_4": "slot_4", "_slot_5": "slot_5"})
    for i in (3, 4, 5):                                        # 아랫줄 칸은 윗줄 그림을 같이 쓴다
        p = os.path.join(UI, "_slot_%d.png" % i)
        if os.path.exists(p):
            os.remove(p)
    window(
        "웨이브승리8_완성화면.png", "wave", (120, 431, 784, 849), (253, 390, 518, 89), (822, 406, 81, 79),
        {"wave_row_0": (158, 505, 709, 99, 0), "wave_row_1": (158, 605, 709, 100, 0), "wave_row_2": (158, 706, 709, 101, 0),
         "wave_mvp_face": (158, 817, 169, 165), "wave_mvp_info": (345, 829, 522, 147),
         "wave_foes": (158, 990, 709, 142), "wave_btn_next": (318, 1149, 387, 113)},
        {"wave_row_0": "row_0", "wave_row_1": "row_1", "wave_row_2": "row_2", "wave_mvp_face": "mvp_face",
         "wave_mvp_info": "mvp_info", "wave_foes": "foes", "wave_btn_next": "btn_next"})
    L4.seal_all(["difficulty_", "absorb_", "wave_", "btn_close"])


if __name__ == "__main__":
    main()
