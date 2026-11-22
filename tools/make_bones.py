#!/usr/bin/env python3
"""운빨삼국 캐릭터 뼈대(본) 시트 — 일반병 10 · 장수 20 · 적 9.

각 유닛마다 옆모습(오른쪽을 봄) 6자세(대기 · 달리기 2 · 공격 · 맞음 · 쓰러짐)의 뼈대와
게임 크기 표(머리 · 몸 · 다리 · 무기 픽셀), 게임 그림 칸(64x64 / 기병 96x80)과 발 기준점을 그린다.
자세와 크기는 tools/draw_art.py와 같은 값을 쓴다 (한 곳에서 바꾸면 둘 다 바뀐다).
Codex로 그 위에 캐릭터를 그리고 PixelLab으로 스프라이트를 뽑는 기준이다.

정확히 표시하는 것: 얼굴(눈 · 입 · 보는 방향), 손(쥐는 방향), 발(발끝 방향),
무기(종류 · 길이 · 쥐는 위치), 말(기병), 장수 고유 표식(수염 · 깃털 · 모자 등).
비율 기준: 2.5등신 귀여운 체형 (머리 지름 = 몸 전체 높이의 약 40 %).
비율은 2.5등신 귀여운 체형 기준으로 새로 정했다.

Usage: python tools/make_bones.py   ->  design/art/bones/*.png, bones.json, _all.png
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import draw_art as DA  # noqa: E402  (same poses, sizes and unit list as the game art)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "design", "art", "bones")
FONT = os.path.join(ROOT, "assets", "fonts", "Galmuri11-Bold.ttf")
S = 256            # one pose panel (px) = bone units (1 unit = 0.24 game px)
GROUND = 226

C = {  # colours by part (PixelLab/Codex에서 부위 구분용)
    "head": (255, 92, 92), "face": (255, 255, 255), "body": (255, 210, 70),
    "arm_f": (90, 220, 120), "arm_b": (40, 140, 80), "leg_f": (90, 170, 255), "leg_b": (40, 100, 190),
    "hand": (255, 255, 255), "foot": (255, 255, 255), "weapon": (235, 235, 235),
    "blade": (255, 140, 40), "horse": (200, 150, 255), "mark": (255, 120, 220), "ground": (90, 90, 100),
}

# ------------------------------------------------------------------ poses (from draw_art)
def _with_chest(p):
    q = dict(p)
    n, h = p["neck"], p["hip"]
    q["chest"] = (n[0] + (h[0] - n[0]) * 0.22, n[1] + (h[1] - n[1]) * 0.22)
    return q


POSES = [("idle", "대기", DA.IDLE), ("run_a", "달리기 1", DA.run_pose(1)), ("run_b", "달리기 2", DA.run_pose(4)),
         ("attack", "공격", DA.ATTACK), ("hit", "맞음", DA.hit_pose()), ("die", "쓰러짐", DA.die_pose())]
HEAD_R = 32


def mounted(p):
    return DA.mounted(p)


# ------------------------------------------------------------------ units
# troop: weapon kind, body, mount. heroes add marks (accessories).
TROOPS = {
    "spear":   {"name": "창병", "weapon": "spear", "body": "normal"},
    "halberd": {"name": "극병", "weapon": "halberd", "body": "normal"},
    "shield":  {"name": "방패병", "weapon": "sword_shield", "body": "normal"},
    "axe":     {"name": "도부수", "weapon": "axe_shield", "body": "stout"},
    "archer":  {"name": "궁병", "weapon": "bow", "body": "slim"},
    "crossbow": {"name": "노병", "weapon": "crossbow", "body": "normal"},
    "rider":   {"name": "경기병", "weapon": "spear", "body": "slim", "mount": "light"},
    "heavy":   {"name": "중기병", "weapon": "lance", "body": "stout", "mount": "heavy"},
    "fire":    {"name": "화공술사", "weapon": "staff_fire", "body": "robe"},
    "thunder": {"name": "뇌공술사", "weapon": "staff_thunder", "body": "robe"},
}
# id: (name, troop, weapon override or None, marks)
HEROES = {
    "liubei": ("유비", "rider", "jian", ["hat_soft", "short_beard"]),
    "guanping": ("관평", "spear", None, ["helmet"]),
    "simayi": ("사마의", "heavy", "feather_fan", ["scholar_hat", "cape", "long_beard"]),
    "caoren": ("조인", "shield", None, ["helmet", "short_beard"]),
    "zhanghe": ("장합", "halberd", None, ["helmet_plume"]),
    "luxun": ("육손", "fire", "jian", ["hat_soft", "robe_long"]),
    "huanggai": ("황개", "fire", "club", ["long_beard_white", "headband"]),
    "handang": ("한당", "archer", None, ["headband", "quiver"]),
    "menghuo": ("맹획", "axe", None, ["fat", "feather", "bare_head"]),
    "huaman": ("화만", "crossbow", None, ["hair_bun", "feather"]),
    "zuoci": ("좌자", "thunder", None, ["scholar_hat", "long_beard_white", "robe_long"]),
    "yuji": ("우길", "thunder", None, ["long_beard_white", "robe_long", "headband"]),
    "guanyu": ("관우", "spear", "guandao", ["long_beard", "hat_soft"]),
    "xiahoudun": ("하후돈", "spear", None, ["eye_patch", "helmet"]),
    "zhangfei": ("장비", "halberd", "snake_spear", ["spiky_beard", "headband"]),
    "lvbu": ("여포", "halberd", "fangtian", ["pheasant_feathers", "helmet"]),
    "sunquan": ("손권", "shield", None, ["crown", "short_beard"]),
    "dongzhuo": ("동탁", "shield", None, ["fat", "short_beard", "crown"]),
    "xuchu": ("허저", "axe", None, ["fat", "bare_head"]),
    "ganning": ("감녕", "axe", None, ["bells", "feather"]),
    "huangzhong": ("황충", "archer", None, ["long_beard_white", "helmet"]),
    "taishici": ("태사자", "archer", None, ["headband", "quiver"]),
    "xiahouyuan": ("하후연", "crossbow", None, ["helmet", "quiver"]),
    "yuanshao": ("원소", "crossbow", None, ["crown", "cape"]),
    "zhaoyun": ("조운", "rider", None, ["helmet_plume", "cape"]),
    "zhangliao": ("장료", "rider", "halberd", ["helmet", "short_beard"]),
    "caocao": ("조조", "heavy", "jian", ["crown", "cape", "short_beard"]),
    "sunce": ("손책", "heavy", None, ["headband", "cape"]),
    "zhugeliang": ("제갈량", "fire", "feather_fan", ["scholar_hat", "robe_long"]),
    "zhouyu": ("주유", "fire", "jian", ["hat_soft", "robe_long"]),
    "diaochan": ("초선", "thunder", "ribbon_fan", ["hair_bun", "robe_long"]),
    "zhangjiao_h": ("장각", "thunder", None, ["yellow_scarf", "long_beard"]),
}
MARK_NAMES = {
    "long_beard": "긴 수염", "long_beard_white": "흰 긴 수염", "spiky_beard": "뻗친 수염", "short_beard": "짧은 수염",
    "hat_soft": "두건 모자", "helmet": "투구", "helmet_plume": "깃 장식 투구", "headband": "머리띠", "crown": "관 (왕관)",
    "eye_patch": "왼눈 안대", "pheasant_feathers": "꿩깃 2개", "fat": "큰 배", "bare_head": "민머리",
    "bells": "허리 방울", "feather": "깃털", "quiver": "등 화살통", "cape": "망토", "scholar_hat": "윤건",
    "robe_long": "긴 도포", "hair_bun": "올림머리", "yellow_scarf": "황건",
}
WEAPON_NAMES = {
    "spear": "창 (몸 1.6배)", "halberd": "극 (창날 + 옆날)", "sword_shield": "칼 + 큰 방패", "axe_shield": "도끼 + 둥근 방패",
    "bow": "활", "crossbow": "쇠뇌", "lance": "기병창 (길고 굵음)", "staff_fire": "불꽃 지팡이", "staff_thunder": "번개 지팡이",
    "guandao": "청룡언월도", "snake_spear": "장팔사모 (뱀 날)", "fangtian": "방천화극 (양쪽 초승달 날)", "jian": "곧은 검",
    "feather_fan": "깃털 부채", "ribbon_fan": "비단 부채 + 리본", "club": "몽둥이",
}
WEAPON_LEN = {"spear": 160, "lance": 190, "halberd": 170, "guandao": 170, "snake_spear": 170, "fangtian": 170,
              "sword_shield": 50, "axe_shield": 50, "bow": 108, "crossbow": 60, "staff_fire": 124, "staff_thunder": 124,
              "jian": 80, "feather_fan": 40, "ribbon_fan": 40, "club": 60}


# ------------------------------------------------------------------ drawing helpers
def pt(p, o):
    return (p[0] + o[0], p[1] + o[1])


def line(d, a, b, col, w=5):
    d.line([a, b], fill=col, width=w)
    for q in (a, b):
        d.ellipse([q[0] - w // 2 - 1, q[1] - w // 2 - 1, q[0] + w // 2 + 1, q[1] + w // 2 + 1], fill=col)


def dot(d, p, r, col, outline=None):
    d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col, outline=outline)


def along(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def unit(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy) or 1.0
    return dx / n, dy / n


def ext(a, b, length):
    ux, uy = unit(a, b)
    return (a[0] + ux * length, a[1] + uy * length)


def hand(d, p, toward):
    """Fist with knuckle line showing grip direction."""
    dot(d, p, 7, C["hand"], (0, 0, 0))
    ux, uy = unit(p, toward)
    d.line([p, (p[0] + ux * 9, p[1] + uy * 9)], fill=(0, 0, 0), width=2)


def foot(d, ankle, toes_right=True):
    tx = 14 if toes_right else -14
    d.polygon([(ankle[0] - 5, ankle[1] - 2), (ankle[0] + tx, ankle[1] + 2), (ankle[0] + tx, ankle[1] + 6), (ankle[0] - 5, ankle[1] + 6)],
              fill=C["foot"], outline=(0, 0, 0))


def head(d, p, marks, pose):
    r = HEAD_R
    d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], outline=C["head"], width=4)
    # face: eye + mouth on the right side (facing right), nose tip shows direction
    eye = (p[0] + 14, p[1] - 2)
    if "eye_patch" in marks:
        d.rectangle([eye[0] - 6, eye[1] - 5, eye[0] + 6, eye[1] + 5], fill=C["mark"])
        d.line([(p[0] - r + 4, p[1] - 14), (p[0] + r - 2, p[1] - 6)], fill=C["mark"], width=2)
    else:
        dot(d, eye, 4, C["face"])
        dot(d, (eye[0] + 1, eye[1]), 2, (0, 0, 0))
    d.line([(p[0] + 12, p[1] + 14), (p[0] + 22, p[1] + 13)], fill=C["face"], width=2)   # mouth
    d.polygon([(p[0] + r - 2, p[1] + 2), (p[0] + r + 6, p[1] + 6), (p[0] + r - 2, p[1] + 9)], fill=C["face"])  # nose = facing
    d.line([(p[0] - 4, p[1] - r + 6), (p[0] - 4, p[1] + r - 6)], fill=(120, 60, 60), width=1)  # ear line (back of face)


def marks_draw(d, j, marks):
    h = j["head"]
    r = HEAD_R
    for m in marks:
        if m in ("long_beard", "long_beard_white"):
            col = (240, 240, 240) if m == "long_beard_white" else C["mark"]
            d.polygon([(h[0] + 6, h[1] + 18), (h[0] + 26, h[1] + 16), (h[0] + 18, h[1] + 64), (h[0] + 10, h[1] + 60)], outline=col, width=3)
        elif m == "spiky_beard":
            for i in range(5):
                d.line([(h[0] + 8 + i * 4, h[1] + 20), (h[0] + 4 + i * 6, h[1] + 36)], fill=C["mark"], width=3)
        elif m == "short_beard":
            d.arc([h[0] + 2, h[1] + 8, h[0] + 30, h[1] + 34], 20, 120, fill=C["mark"], width=3)
        elif m in ("helmet", "helmet_plume"):
            d.arc([h[0] - r - 2, h[1] - r - 4, h[0] + r + 2, h[1] + r], 180, 360, fill=C["mark"], width=5)
            if m == "helmet_plume":
                d.line([(h[0], h[1] - r - 2), (h[0] - 14, h[1] - r - 26)], fill=C["mark"], width=5)
        elif m == "pheasant_feathers":
            d.arc([h[0] - r - 2, h[1] - r - 4, h[0] + r + 2, h[1] + r], 180, 360, fill=C["mark"], width=5)
            for dx in (-6, 6):
                d.line([(h[0] + dx, h[1] - r), (h[0] + dx - 40, h[1] - r - 50)], fill=C["mark"], width=3)
        elif m == "hat_soft":
            d.polygon([(h[0] - r, h[1] - 8), (h[0] - 6, h[1] - r - 16), (h[0] + r - 4, h[1] - 14)], outline=C["mark"], width=3)
        elif m == "scholar_hat":
            d.rectangle([h[0] - 18, h[1] - r - 20, h[0] + 14, h[1] - r + 4], outline=C["mark"], width=3)
        elif m == "crown":
            d.polygon([(h[0] - 14, h[1] - r + 2), (h[0] - 14, h[1] - r - 14), (h[0] - 4, h[1] - r - 6), (h[0] + 6, h[1] - r - 16), (h[0] + 14, h[1] - r - 4)], outline=C["mark"], width=3)
        elif m in ("headband", "yellow_scarf"):
            col = (255, 230, 60) if m == "yellow_scarf" else C["mark"]
            d.line([(h[0] - r, h[1] - 10), (h[0] + r, h[1] - 14)], fill=col, width=5)
            d.line([(h[0] - r, h[1] - 10), (h[0] - r - 18, h[1] + 4)], fill=col, width=4)
        elif m == "hair_bun":
            dot(d, (h[0] - 16, h[1] - r - 6), 12, None, C["mark"])
            d.line([(h[0] - 16, h[1] - r - 6), (h[0] + 4, h[1] - r - 20)], fill=C["mark"], width=3)
        elif m == "bare_head":
            d.arc([h[0] - r + 6, h[1] - r + 4, h[0] + r - 6, h[1] + r - 6], 200, 320, fill=C["mark"], width=2)
        elif m == "fat":
            c, hp = j["chest"], j["hip"]
            xs, ys = sorted((c[0] - 6, c[0] + 34)), sorted((c[1] + 4, hp[1] + 2))
            if ys[1] - ys[0] > 6:
                d.ellipse([xs[0], ys[0], xs[1], ys[1]], outline=C["mark"], width=3)
        elif m == "bells":
            for i in range(3):
                dot(d, (j["hip"][0] - 10 + i * 10, j["hip"][1] + 4), 4, None, C["mark"])
        elif m == "feather":
            d.line([(h[0] - 10, h[1] - r), (h[0] - 30, h[1] - r - 30)], fill=C["mark"], width=4)
        elif m == "quiver":
            c = j["chest"]
            d.rectangle([c[0] - 26, c[1] - 14, c[0] - 14, c[1] + 30], outline=C["mark"], width=3)
            for i in range(3):
                d.line([(c[0] - 24 + i * 4, c[1] - 14), (c[0] - 28 + i * 4, c[1] - 26)], fill=C["mark"], width=2)
        elif m == "cape":
            n = j["neck"]
            d.polygon([(n[0] - 4, n[1] + 4), (n[0] - 40, n[1] + 70), (n[0] - 12, n[1] + 66)], outline=C["mark"], width=3)
        elif m == "robe_long":
            hp = j["hip"]
            d.polygon([(hp[0] - 20, hp[1] - 6), (hp[0] + 22, hp[1] - 6), (hp[0] + 32, GROUND - 8 if hp[1] > 140 else hp[1] + 50), (hp[0] - 30, GROUND - 8 if hp[1] > 140 else hp[1] + 50)], outline=C["mark"], width=3)


def clip_len(a, b, want):
    """Longest length <= want from a toward b that stays inside the panel."""
    ux, uy = unit(a, b)
    L = want
    while L > 20:
        x, y = a[0] + ux * L, a[1] + uy * L
        if 6 <= x <= S - 6 and 6 <= y <= S - 6:
            return L
        L -= 2
    return L


def weapon(d, j, kind, pose="idle"):
    hf, hb = j["ha_f"], j["ha_b"]
    W, B = C["weapon"], C["blade"]
    if kind in ("spear", "lance", "halberd", "guandao", "snake_spear", "fangtian"):
        length = {"lance": 190, "spear": 160}.get(kind, 170)
        if pose == "idle":
            # 대기: 자루를 세워 든다 (앞손이 쥠, 날이 머리 위)
            butt = (hf[0] + 2, min(GROUND - 2, hf[1] + 46))
            tip = (hf[0] - 6, max(30, butt[1] - length))
        else:
            # 공격: 뒷손에서 앞손 방향으로 찌른다 (칸 밖으로 나가지 않게 길이 조절)
            butt = ext(hf, hb, 40)
            tip = ext(butt, hf, clip_len(butt, hf, length) - 26)
        line(d, butt, tip, W, 7 if kind == "lance" else 5)
        ux, uy = unit(butt, tip)
        nx, ny = -uy, ux
        if kind in ("spear", "lance"):
            d.polygon([pt(tip, (ux * 20, uy * 20)), pt(tip, (nx * 7, ny * 7)), pt(tip, (-nx * 7, -ny * 7))], fill=B)
        elif kind == "snake_spear":
            pts = [pt(tip, (ux * k * 4 + nx * (5 if k % 2 else -5), uy * k * 4 + ny * (5 if k % 2 else -5))) for k in range(7)]
            d.line(pts, fill=B, width=5)
        elif kind == "guandao":
            base = pt(tip, (-ux * 10, -uy * 10))
            d.polygon([base, pt(tip, (ux * 34 + nx * 4, uy * 34 + ny * 4)), pt(tip, (ux * 10 + nx * 22, uy * 10 + ny * 22)), pt(base, (nx * 16, ny * 16))], fill=B)
        else:  # halberd / fangtian: point + crescent(s)
            d.polygon([pt(tip, (ux * 22, uy * 22)), pt(tip, (nx * 6, ny * 6)), pt(tip, (-nx * 6, -ny * 6))], fill=B)
            sides = (1, -1) if kind == "fangtian" else (1,)
            for sgn in sides:
                c0 = pt(tip, (-ux * 4 + nx * 10 * sgn, -uy * 4 + ny * 10 * sgn))
                d.polygon([c0, pt(c0, (nx * 14 * sgn - ux * 8, ny * 14 * sgn - uy * 8)), pt(c0, (nx * 14 * sgn + ux * 12, ny * 14 * sgn + uy * 12)), pt(c0, (ux * 6, uy * 6))], fill=B)
    elif kind in ("sword_shield", "axe_shield"):
        # shield on the front arm, weapon in the back hand
        if kind == "sword_shield":
            d.rectangle([hf[0] - 4, hf[1] - 34, hf[0] + 16, hf[1] + 24], outline=B, width=4)
        else:
            d.ellipse([hf[0] - 14, hf[1] - 22, hf[0] + 18, hf[1] + 10], outline=B, width=4)
        top = (hb[0] + 18, hb[1] - 44)
        line(d, hb, top, W, 4)
        if kind == "axe_shield":
            d.polygon([top, pt(top, (14, 4)), pt(top, (14, 22)), pt(top, (0, 16))], fill=B)
        else:
            d.polygon([top, pt(top, (6, -10)), pt(top, (4, 2))], fill=B)
    elif kind == "club":
        tip = (hf[0] + 30, hf[1] - 50)
        line(d, hf, tip, W, 7)
        dot(d, tip, 10, B)
    elif kind == "jian":
        top = ext(hb if hb != hf else (hf[0] - 1, hf[1]), hf, math.dist(hb, hf) + 70)
        line(d, hf, top, B, 4)
        d.line([pt(hf, (-6, -8)), pt(hf, (6, 8))], fill=W, width=4)  # guard
    elif kind == "bow":
        c = hf
        d.arc([c[0] - 18, c[1] - 52, c[0] + 18, c[1] + 52], 270, 90, fill=W, width=4)
        d.line([(c[0], c[1] - 52), hb, (c[0], c[1] + 52)], fill=B, width=2)
        line(d, hb, (c[0] + 30, c[1]), B, 2)  # arrow
    elif kind == "crossbow":
        line(d, hb, (hf[0] + 30, hf[1] - 2), W, 6)
        d.arc([hf[0] + 8, hf[1] - 30, hf[0] + 36, hf[1] + 26], 270, 90, fill=B, width=4)
    elif kind in ("staff_fire", "staff_thunder"):
        top = (hf[0] + 8, hf[1] - 80)
        line(d, (hf[0] - 4, hf[1] + 40), top, W, 5)
        if kind == "staff_fire":
            d.polygon([pt(top, (-10, 2)), pt(top, (0, -26)), pt(top, (10, 2))], fill=B)
        else:
            d.line([pt(top, (-8, -24)), pt(top, (4, -10)), pt(top, (-4, -8)), pt(top, (8, 8))], fill=(120, 220, 255), width=4)
    elif kind in ("feather_fan", "ribbon_fan"):
        c = pt(hf, (10, -16))
        d.pieslice([c[0] - 26, c[1] - 30, c[0] + 26, c[1] + 22], 200, 340, outline=B, width=4)
        line(d, hf, c, W, 3)
        if kind == "ribbon_fan":
            d.line([hb, pt(hb, (-26, 24)), pt(hb, (-10, 44))], fill=C["mark"], width=3)


def horse(d, j, heavy):
    hip = j["hip"]
    cx, cy = hip[0] + 4, hip[1] + 22
    L = 62 if heavy else 56
    d.ellipse([cx - L, cy - 20, cx + L, cy + 22], outline=C["horse"], width=4)              # body
    neck0 = (cx + L - 14, cy - 10)
    hd = (cx + L + 22, cy - 50)
    line(d, neck0, hd, C["horse"], 8)                                                          # neck
    d.polygon([hd, pt(hd, (28, 12)), pt(hd, (24, 22)), pt(hd, (-4, 12))], outline=C["horse"], width=3)  # head -> right
    dot(d, pt(hd, (10, 4)), 3, C["face"])                                                      # horse eye
    for i, x in enumerate((cx - L + 16, cx - L + 32, cx + L - 30, cx + L - 14)):
        col = C["horse"] if i % 2 else tuple(v // 2 for v in C["horse"])
        knee = (x + (6 if i >= 2 else -4), cy + 40)
        line(d, (x, cy + 14), knee, col, 6)
        line(d, knee, (knee[0] + 2, GROUND - 4), col, 6)
        d.rectangle([knee[0] - 4, GROUND - 6, knee[0] + 8, GROUND], fill=C["foot"])          # hooves
    d.line([(cx - L, cy - 6), (cx - L - 22, cy + 26)], fill=C["horse"], width=4)              # tail
    if heavy:
        d.rectangle([cx - L + 10, cy - 18, cx + L - 10, cy + 6], outline=C["mark"], width=2)  # barding


def body(d, j, build):
    w = {"slim": 5, "normal": 7, "stout": 9, "robe": 6}.get(build, 7)
    line(d, j["neck"], j["hip"], C["body"], w)
    line(d, j["sh_b"], j["sh_f"], C["body"], 5)
    line(d, j["hp_b"], j["hp_f"], C["body"], 5)


def limbs(d, j, mounted_):
    # back limbs first (behind the body)
    line(d, j["sh_b"], j["el_b"], C["arm_b"], 6); line(d, j["el_b"], j["ha_b"], C["arm_b"], 6)
    line(d, j["hp_b"], j["kn_b"], C["leg_b"], 7); line(d, j["kn_b"], j["an_b"], C["leg_b"], 7)
    foot(d, j["an_b"])
    hand(d, j["ha_b"], j["ha_f"])


def front_limbs(d, j):
    line(d, j["hp_f"], j["kn_f"], C["leg_f"], 7); line(d, j["kn_f"], j["an_f"], C["leg_f"], 7)
    foot(d, j["an_f"])
    line(d, j["sh_f"], j["el_f"], C["arm_f"], 6); line(d, j["el_f"], j["ha_f"], C["arm_f"], 6)
    hand(d, j["ha_f"], ext(j["el_f"], j["ha_f"], 40))


def panel_h(spec):
    """Mounted units get a taller panel so the rider's head fits (same 16-unit grid)."""
    return S + (MOUNT_YOFF if spec.get("mount") else 0)


MOUNT_YOFF = 48


def _shift(p, dy):
    return {k: (v[0], v[1] + dy) for k, v in p.items()}


def draw_pose(spec, pose_name, pose):
    global GROUND
    yoff = MOUNT_YOFF if spec.get("mount") else 0
    ph = S + yoff
    im = Image.new("RGB", (S, ph), (24, 26, 32))
    d = ImageDraw.Draw(im)
    for x in range(0, S, 16):
        d.line([(x, 0), (x, ph)], fill=(32, 35, 42))
    for y in range(ph % 16, ph, 16):
        d.line([(0, y), (S, y)], fill=(32, 35, 42))
    base_ground = GROUND
    GROUND = base_ground + yoff
    try:
        return _draw_pose(d, im, spec, pose_name, pose, yoff)
    finally:
        GROUND = base_ground


def _draw_pose(d, im, spec, pose_name, pose, yoff):
    d.line([(0, GROUND), (S, GROUND)], fill=C["ground"], width=2)
    j = _with_chest(_shift(pose, yoff))
    mount = spec.get("mount") if pose_name != "die" else None
    if mount:
        j = _with_chest(_shift(mounted(pose), yoff))
        horse(d, j, mount == "heavy")
    if "cape" in spec["marks"] or "quiver" in spec["marks"]:
        marks_draw(d, j, [m for m in spec["marks"] if m in ("cape", "quiver")])
    limbs(d, j, bool(mount))
    body(d, j, "stout" if "fat" in spec["marks"] else spec["body"])
    if "robe_long" in spec["marks"] or spec["body"] == "robe":
        marks_draw(d, j, ["robe_long"])
    if pose_name != "die":
        weapon(d, j, spec["weapon"], "attack" if pose_name in ("attack",) else "idle")
    front_limbs(d, j)
    head(d, j["head"], spec["marks"], pose_name)
    marks_draw(d, j, [m for m in spec["marks"] if m not in ("cape", "quiver", "robe_long")])
    return im, j


def size_rows(spec):
    k = DA.SIZES["mount" if spec.get("mount") else "foot"][2]
    fw, fh = DA.SIZES["mount" if spec.get("mount") else "foot"][:2]
    th = DA.TARGET_H["mount" if spec.get("mount") else "foot"] * 2.4
    rows = [
        ("그림 칸", "%d × %d px" % (fw, fh)),
        ("발 기준점", "칸 아래 가운데 (%d, %d)" % (fw // 2, fh - 1)),
        ("머리 지름", "%d px" % round(HEAD_R * 2 * k)),
        ("키 (머리끝~발)", "%d px" % round((GROUND - (DA.IDLE["head"][1] - HEAD_R)) * k)),
        ("몸 (목~엉덩이)", "%d px" % round((DA.IDLE["hip"][1] - DA.IDLE["neck"][1]) * k)),
        ("다리 (엉덩이~발)", "%d px" % round((GROUND - DA.IDLE["hip"][1]) * k)),
        ("팔 (어깨~손)", "%d px" % round(math.dist(DA.IDLE["sh_f"], DA.IDLE["el_f"]) * k + math.dist(DA.IDLE["el_f"], DA.IDLE["ha_f"]) * k)),
        ("무기 길이", "%d px" % round(WEAPON_LEN.get(spec["weapon"], 100) * k)),
        ("화면 표시", "칸 높이 %d px → 전투 %d px (×%.2f)" % (fh, round(th), th / fh)),
    ]
    if spec.get("mount"):
        rows.insert(5, ("말 (몸 길이)", "%d px" % round((124 if spec["mount"] == "heavy" else 112) * k)))
    return rows


def sheet(uid, spec, font, small):
    cols, gap = 3, 8
    info_w = 330
    ph = panel_h(spec)
    W = cols * (S + gap) + gap + info_w
    H = 2 * (ph + 26) + 90
    im = Image.new("RGB", (W, H), (14, 16, 20))
    d = ImageDraw.Draw(im)
    d.text((12, 8), "%s  (%s)" % (spec["name"], uid), font=font, fill=(255, 212, 71))
    d.text((12, 38), "병종: %s   무기: %s" % (spec["troop_name"], WEAPON_NAMES.get(spec["weapon"], spec["weapon"])), font=small, fill=(220, 220, 220))
    joints = {}
    for i, (key, ko, pose) in enumerate(POSES):
        x0 = gap + (i % cols) * (S + gap)
        y0 = 62 + (i // cols) * (ph + 26)
        p, j = draw_pose(spec, key, pose)
        im.paste(p, (x0, y0 + 20))
        d.text((x0 + 4, y0), ko, font=small, fill=(255, 255, 255))
        joints[key] = {k: [int(v[0]), int(v[1])] for k, v in j.items()}
    # info column: size table + game-size preview with frame box and anchor
    ix = cols * (S + gap) + gap + 6
    d.text((ix, 64), "게임 크기 (원본 픽셀)", font=small, fill=(255, 212, 71))
    for r, (a, b) in enumerate(size_rows(spec)):
        d.text((ix, 88 + r * 22), a, font=small, fill=(170, 170, 180))
        d.text((ix + 118, 88 + r * 22), b, font=small, fill=(255, 255, 255))
    marks = ", ".join(MARK_NAMES.get(m, m) for m in spec["marks"]) or "-"
    d.text((ix, 88 + 11 * 22), "표식: " + marks, font=small, fill=(255, 120, 220))
    fw, fh = DA.SIZES["mount" if spec.get("mount") else "foot"][:2]
    spr_path = os.path.join(ROOT, "assets", "units", uid, "idle", "000.png")
    py = 88 + 13 * 22
    d.text((ix, py), "지금 게임 그림 (임시) ×3, 칸 · 발 기준점", font=small, fill=(170, 170, 180))
    if os.path.exists(spr_path):
        spr = Image.open(spr_path).convert("RGBA")
        sc = 3
        big = spr.resize((spr.width * sc, spr.height * sc), Image.NEAREST)
        bx, by = ix, py + 22
        bg = Image.new("RGBA", big.size, (40, 70, 40, 255))
        bg.alpha_composite(big)
        im.paste(bg.convert("RGB"), (bx, by))
        d.rectangle([bx, by, bx + fw * sc - 1, by + fh * sc - 1], outline=(255, 212, 71), width=1)
        ax, ay = bx + (fw // 2) * sc, by + (fh - 1) * sc
        d.line([(ax - 8, ay), (ax + 8, ay)], fill=(255, 60, 60), width=2)
        d.line([(ax, ay - 8), (ax, ay + 2)], fill=(255, 60, 60), width=2)
    legend = ["오른쪽을 봄 · 칸 16 = 뼈대 16단위 (= 게임 약 4px)", "머리 빨강(코 = 보는 방향) · 몸 노랑",
              "앞팔/앞다리 밝게 · 뒤 어둡게 · 손 흰 원", "무기 흰 자루 + 주황 날 · 말 보라 · 분홍 = 표식"]
    for k, t in enumerate(legend):
        d.text((12, H - 4 - (len(legend) - k) * 0 - 18), "", font=small)
    d.text((12, H - 42), " · ".join(legend[:2]), font=small, fill=(150, 150, 160))
    d.text((12, H - 22), " · ".join(legend[2:]), font=small, fill=(150, 150, 160))
    return im, joints


def main():
    os.makedirs(OUT, exist_ok=True)
    font = ImageFont.truetype(FONT, 22)
    small = ImageFont.truetype(FONT, 14)
    specs = {}
    for tid, t in TROOPS.items():
        specs[tid] = {"name": t["name"], "troop": tid, "troop_name": t["name"], "weapon": t["weapon"],
                      "body": t["body"], "mount": t.get("mount"), "marks": [], "kind": "soldier"}
    ENEMY_NAMES = {"enemy_mob": "황건 잡병", "enemy_sword": "황건 검병", "enemy_spear": "황건 창병", "enemy_archer": "황건 궁병",
                   "enemy_shield": "황건 방패병", "enemy_rider": "황건 기병", "enemy_mage": "요술사", "enemy_brute": "괴력 장수",
                   "enemy_zhangjiao": "장각 (보스)"}
    for eid, e in DA.ENEMIES.items():
        specs[eid] = {"name": ENEMY_NAMES[eid], "troop": "-", "troop_name": "적 (황건적)", "weapon": e["weapon"],
                      "body": e["body"], "mount": e.get("mount"), "marks": ["yellow_scarf"] + e.get("marks", []), "kind": "enemy"}
    for hid, (name, troop, wpn, marks) in HEROES.items():
        t = TROOPS[troop]
        specs[hid] = {"name": name, "troop": troop, "troop_name": t["name"], "weapon": wpn or t["weapon"],
                      "body": t["body"], "mount": t.get("mount"), "marks": marks, "kind": "hero"}
    data = {"_about": "운빨삼국 뼈대(본). 좌표 = 뼈대 단위(256 칸), 오른쪽을 봄, 바닥선 y=%d. 게임 px = 단위 x 0.24. tools/make_bones.py" % GROUND,
            "unit_to_px": DA.SIZES["foot"][2], "frame": {"foot": DA.SIZES["foot"][:2], "mount": DA.SIZES["mount"][:2]},
            "anchor": "frame bottom centre", "poses": [p[0] for p in POSES], "parts": list(_with_chest(DA.IDLE).keys()), "units": {}}
    thumbs = []
    for uid, spec in specs.items():
        im, joints = sheet(uid, spec, font, small)
        im.save(os.path.join(OUT, "%s_%s.png" % (spec["kind"], uid.replace("enemy_", ""))))
        data["units"][uid] = {"name": spec["name"], "kind": spec["kind"], "troop": spec["troop"], "weapon": spec["weapon"],
                              "mount": spec["mount"], "marks": spec["marks"], "joints": joints}
        thumbs.append(im)
    json.dump(data, open(os.path.join(OUT, "bones.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    cols = 4
    tw = max(t.size[0] for t in thumbs)
    th = max(t.size[1] for t in thumbs)
    sc = 0.4
    allim = Image.new("RGB", (int(tw * sc) * cols, int(th * sc) * math.ceil(len(thumbs) / cols)), (0, 0, 0))
    for i, t in enumerate(thumbs):
        allim.paste(t.resize((int(tw * sc), int(th * sc)), Image.NEAREST), ((i % cols) * int(tw * sc), (i // cols) * int(th * sc)))
    allim.save(os.path.join(OUT, "_all.png"))
    print("bones:", len(specs))


if __name__ == "__main__":
    main()
