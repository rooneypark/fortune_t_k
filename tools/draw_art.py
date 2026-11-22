#!/usr/bin/env python3
"""운빨삼국 자체 그림 생성기 (2026-11-22).

외부 그림 없이 코드로 직접 그린다. 배경(assets/bg)만 기존 그림을 쓴다.
- 캐릭터: 일반병 10 · 장수 20 · 적 9. 뼈대(design/art/bones, make_bones.py)와
  같은 관절 자세를 작은 픽셀 크기로 줄여 그린다. 대기 4 · 달리기 6 · 공격 5프레임.
- 초상(portrait) · 얼굴(head) · 큰 그림(illustration)은 같은 캐릭터를 크게 잘라 만든다.
- 아이콘: 16x16 픽셀 아이콘 (assets/ui/icons).
- 전투용 성벽 띠(wall), 부활 고리(ring_respawn), 앱 아이콘(icon.png).

Usage: python tools/draw_art.py   (assets/units, assets/portraits, assets/ui 를 새로 만든다)
"""
import json, math, os, shutil
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNITS = os.path.join(ROOT, "assets", "units")
PORTRAITS = os.path.join(ROOT, "assets", "portraits")
ICONS = os.path.join(ROOT, "assets", "ui", "icons")
UI = os.path.join(ROOT, "assets", "ui")

OUTLINE = (24, 20, 28, 255)
SKIN = (246, 200, 160, 255)
SKIN_D = (214, 160, 122, 255)


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def dark(c, k=0.72):
    return (int(c[0] * k), int(c[1] * k), int(c[2] * k), c[3])


def light(c, k=0.35):
    return (int(c[0] + (255 - c[0]) * k), int(c[1] + (255 - c[1]) * k), int(c[2] + (255 - c[2]) * k), c[3])


def outline(im):
    """1px dark outline around every opaque pixel (pixel-art look)."""
    a = im.split()[3]
    w, h = im.size
    src = a.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    o = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny] > 0:
                    o[x, y] = OUTLINE
                    break
    out.alpha_composite(im)
    return out


# ------------------------------------------------------------------ poses (bone panel coords, see make_bones.py)
BONE_GROUND = 226
IDLE = {
    "head": (128, 72), "neck": (128, 106), "hip": (128, 160),
    "sh_f": (136, 113), "el_f": (150, 136), "ha_f": (160, 152),
    "sh_b": (120, 113), "el_b": (110, 136), "ha_b": (104, 152),
    "hp_f": (134, 162), "kn_f": (140, 192), "an_f": (140, 222),
    "hp_b": (122, 162), "kn_b": (118, 192), "an_b": (116, 222),
}
ATTACK = {
    "head": (138, 76), "neck": (136, 108), "hip": (124, 160),
    "sh_f": (142, 116), "el_f": (166, 124), "ha_f": (190, 126),
    "sh_b": (126, 114), "el_b": (118, 132), "ha_b": (136, 140),
    "hp_f": (130, 162), "kn_f": (152, 186), "an_f": (160, 222),
    "hp_b": (118, 162), "kn_b": (104, 190), "an_b": (92, 222),
}


def lerp_pose(a, b, t):
    return {k: (a[k][0] + (b[k][0] - a[k][0]) * t, a[k][1] + (b[k][1] - a[k][1]) * t) for k in a}


def run_pose(i, n=6):
    p = dict(IDLE)
    ph = 2 * math.pi * i / n
    s = math.sin(ph)
    p = {k: v for k, v in p.items()}
    lift = abs(math.cos(ph)) * -4
    for k in p:
        p[k] = (p[k][0] + 4, p[k][1] + lift)
    hipx, hipy = p["hip"]
    p["kn_f"] = (hipx + 6 + 16 * s, hipy + 30 - 6 * max(0, s))
    p["an_f"] = (hipx + 4 + 26 * s, BONE_GROUND - 4 - 10 * max(0, s))
    p["kn_b"] = (hipx - 2 - 16 * s, hipy + 30 - 6 * max(0, -s))
    p["an_b"] = (hipx - 4 - 26 * s, BONE_GROUND - 4 - 10 * max(0, -s))
    p["el_f"] = (p["sh_f"][0] + 4 - 12 * s, p["sh_f"][1] + 22)
    p["ha_f"] = (p["sh_f"][0] + 10 - 18 * s, p["sh_f"][1] + 36)
    p["el_b"] = (p["sh_b"][0] - 4 + 12 * s, p["sh_b"][1] + 22)
    p["ha_b"] = (p["sh_b"][0] - 8 + 18 * s, p["sh_b"][1] + 36)
    return p


def hit_pose():
    """맞음: 몸이 뒤로 젖혀지고 팔이 들린다."""
    p = dict(IDLE)
    for k, dx in (("head", -10), ("neck", -6), ("sh_f", -6), ("sh_b", -6)):
        p[k] = (p[k][0] + dx, p[k][1] + 2)
    p["el_f"], p["ha_f"] = (p["el_f"][0] - 4, p["el_f"][1] - 12), (p["ha_f"][0] - 2, p["ha_f"][1] - 24)
    p["el_b"], p["ha_b"] = (p["el_b"][0] - 8, p["el_b"][1] - 8), (p["ha_b"][0] - 12, p["ha_b"][1] - 16)
    return p


def die_pose():
    """쓰러짐: 대기 자세를 발을 축으로 뒤로 눕힌다 (머리가 왼쪽 바닥)."""
    ox, oy = 128, BONE_GROUND - 8
    out = {}
    for k, (x, y) in IDLE.items():
        dx, dy = x - ox, y - oy
        out[k] = (ox + dy + 64, oy - dx * 0.25 - 6)
    return out


def mounted(p):
    q = {k: (v[0], v[1] - 46) for k, v in p.items()}
    hx, hy = q["hip"]
    q["hp_f"], q["kn_f"], q["an_f"] = (hx + 6, hy + 2), (hx + 20, hy + 20), (hx + 14, hy + 40)
    q["hp_b"], q["kn_b"], q["an_b"] = (hx - 4, hy + 2), (hx + 8, hy + 20), (hx + 2, hy + 38)
    return q


# ------------------------------------------------------------------ unit specs
ARMY = {"cloth": "#3f6fb0", "armor": "#9aa4b2", "pants": "#3a3f4a", "hair": "#2b2220"}
FACTION = {"wei": "#3b74d6", "shu": "#3aa65a", "wu": "#d6463b", "qun": "#8b4fd0"}
TROOPS = {
    "spear":   {"weapon": "spear", "hat": "helmet", "body": "normal"},
    "halberd": {"weapon": "halberd", "hat": "helmet", "body": "normal", "armor": "#b7a27a"},
    "shield":  {"weapon": "sword_shield", "hat": "helmet", "body": "normal"},
    "axe":     {"weapon": "axe_shield", "hat": "bandana", "body": "stout", "cloth": "#8a4b2e"},
    "archer":  {"weapon": "bow", "hat": "cap", "body": "slim", "cloth": "#4f8a4a"},
    "crossbow": {"weapon": "crossbow", "hat": "helmet", "body": "normal", "cloth": "#5b6b7e"},
    "rider":   {"weapon": "spear", "hat": "helmet", "body": "slim", "mount": "light"},
    "heavy":   {"weapon": "lance", "hat": "helmet_big", "body": "stout", "mount": "heavy", "armor": "#7c8796"},
    "fire":    {"weapon": "staff_fire", "hat": "scholar", "body": "robe", "cloth": "#c8553d"},
    "thunder": {"weapon": "staff_thunder", "hat": "scholar", "body": "robe", "cloth": "#4a6fc8"},
}
HEROES = {
    "liubei": ("shu", "rider", "jian", ["hat_soft", "short_beard"], "#e8c86a"),
    "guanping": ("shu", "spear", None, ["helmet"], None),
    "simayi": ("wei", "heavy", "feather_fan", ["scholar_hat", "cape", "long_beard"], "#2a2a46"),
    "caoren": ("wei", "shield", None, ["helmet", "short_beard"], None),
    "zhanghe": ("wei", "halberd", None, ["helmet_plume"], None),
    "luxun": ("wu", "fire", "jian", ["hat_soft", "robe_long"], "#f0e0c0"),
    "huanggai": ("wu", "fire", "club", ["long_beard_white", "headband"], None),
    "handang": ("wu", "archer", None, ["headband", "quiver"], None),
    "menghuo": ("qun", "axe", None, ["fat", "feather", "bare_head"], "#6b4a2a"),
    "huaman": ("qun", "crossbow", None, ["hair_bun", "feather"], "#c0603a"),
    "zuoci": ("qun", "thunder", None, ["scholar_hat", "long_beard_white", "robe_long"], "#e8ecf2"),
    "yuji": ("qun", "thunder", None, ["long_beard_white", "robe_long", "headband"], "#d8d0b0"),
    "guanyu": ("shu", "spear", "guandao", ["long_beard", "hat_soft"], "#2f8a46"),
    "xiahoudun": ("wei", "spear", None, ["eye_patch", "helmet"], None),
    "zhangfei": ("shu", "halberd", "snake_spear", ["spiky_beard", "headband"], "#3b3b46"),
    "lvbu": ("qun", "halberd", "fangtian", ["pheasant_feathers", "helmet"], "#b0302c"),
    "sunquan": ("wu", "shield", None, ["crown", "short_beard"], None),
    "dongzhuo": ("qun", "shield", None, ["fat", "short_beard", "crown"], "#6b3a2a"),
    "xuchu": ("wei", "axe", None, ["fat", "bare_head"], None),
    "ganning": ("wu", "axe", None, ["bells", "feather"], None),
    "huangzhong": ("shu", "archer", None, ["long_beard_white", "helmet"], None),
    "taishici": ("wu", "archer", None, ["headband", "quiver"], None),
    "xiahouyuan": ("wei", "crossbow", None, ["helmet", "quiver"], None),
    "yuanshao": ("qun", "crossbow", None, ["crown", "cape"], "#c9a33b"),
    "zhaoyun": ("shu", "rider", None, ["helmet_plume", "cape"], "#e8ecf2"),
    "zhangliao": ("wei", "rider", "halberd", ["helmet", "short_beard"], None),
    "caocao": ("wei", "heavy", "jian", ["crown", "cape", "short_beard"], None),
    "sunce": ("wu", "heavy", None, ["headband", "cape"], None),
    "zhugeliang": ("shu", "fire", "feather_fan", ["scholar_hat", "robe_long"], "#e8ecf2"),
    "zhouyu": ("wu", "fire", "jian", ["hat_soft", "robe_long"], None),
    "diaochan": ("qun", "thunder", "ribbon_fan", ["hair_bun", "robe_long"], "#e88ab4"),
    "zhangjiao_h": ("qun", "thunder", None, ["yellow_scarf", "long_beard"], "#d9b43a"),
}
ENEMIES = {  # 황건적
    "enemy_mob": {"weapon": "club", "hat": "yellow", "body": "slim", "cloth": "#8a6a48"},
    "enemy_sword": {"weapon": "jian", "hat": "yellow", "body": "normal", "cloth": "#8a5a38"},
    "enemy_spear": {"weapon": "spear", "hat": "yellow", "body": "normal", "cloth": "#7a5a3a"},
    "enemy_archer": {"weapon": "bow", "hat": "yellow", "body": "slim", "cloth": "#6f6a3a"},
    "enemy_shield": {"weapon": "sword_shield", "hat": "yellow", "body": "stout", "cloth": "#6a4a30"},
    "enemy_rider": {"weapon": "spear", "hat": "yellow", "body": "slim", "cloth": "#7a5a3a", "mount": "light"},
    "enemy_mage": {"weapon": "staff_thunder", "hat": "yellow", "body": "robe", "cloth": "#5a4a7a"},
    "enemy_brute": {"weapon": "club", "hat": "yellow", "body": "stout", "cloth": "#7a3a2a", "marks": ["fat", "bare_head"]},
    "enemy_zhangjiao": {"weapon": "staff_thunder", "hat": "yellow", "body": "robe", "cloth": "#c9a33b", "marks": ["long_beard", "robe_long"]},
}


def build_specs():
    specs = {}
    for tid, t in TROOPS.items():
        specs[tid] = {"weapon": t["weapon"], "hat": t["hat"], "body": t["body"], "mount": t.get("mount"),
                      "cloth": rgb(t.get("cloth", ARMY["cloth"])), "armor": rgb(t.get("armor", ARMY["armor"])),
                      "pants": rgb(ARMY["pants"]), "hair": rgb(ARMY["hair"]), "marks": [], "hero": False}
    for hid, (fac, troop, wpn, marks, accent) in HEROES.items():
        t = TROOPS[troop]
        hat = "none"
        specs[hid] = {"weapon": wpn or t["weapon"], "hat": hat, "body": t["body"], "mount": t.get("mount"),
                      "cloth": rgb(FACTION[fac]), "armor": rgb(accent) if accent else rgb("#d8b04a"),
                      "pants": rgb("#2f2a34"), "hair": rgb("#e8e8e8" if "long_beard_white" in marks else "#241c1a"),
                      "marks": marks, "hero": True}
    for eid, e in ENEMIES.items():
        specs[eid] = {"weapon": e["weapon"], "hat": e["hat"], "body": e["body"], "mount": e.get("mount"),
                      "cloth": rgb(e["cloth"]), "armor": rgb("#8a7a5a"), "pants": rgb("#4a3a2a"), "hair": rgb("#2b2220"),
                      "marks": e.get("marks", []), "hero": False}
    return specs


# ------------------------------------------------------------------ renderer
class Painter:
    """Draws one frame. Bone coords are mapped to sprite pixels."""

    def __init__(self, w, h, scale, cx, ground):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)
        self.s, self.cx, self.g = scale, cx, ground

    def p(self, q):
        return (round(self.cx + (q[0] - 128) * self.s), round(self.g - (BONE_GROUND - q[1]) * self.s))

    def line(self, a, b, col, w):
        A, B = self.p(a), self.p(b)
        self.d.line([A, B], fill=col, width=w)
        r = w // 2
        for q in (A, B):
            if r > 0:
                self.d.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=col)

    def plinep(self, A, B, col, w=1):
        self.d.line([A, B], fill=col, width=w)

    def dot(self, q, r, col):
        Q = self.p(q)
        self.d.ellipse([Q[0] - r, Q[1] - r, Q[0] + r, Q[1] + r], fill=col)

    def poly(self, pts, col):
        self.d.polygon([self.p(q) for q in pts], fill=col)


def unitv(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy) or 1.0
    return dx / n, dy / n


def draw_horse(P, j, heavy, coat):
    hip = j["hip"]
    cx, cy = hip[0] + 4, hip[1] + 26
    L = 60 if heavy else 54
    leg_col = dark(coat, 0.8)
    for i, x in enumerate((cx - L + 14, cx - L + 30, cx + L - 30, cx + L - 14)):
        col = dark(leg_col, 0.75) if i % 2 == 0 else leg_col
        P.line((x, cy + 8), (x + (4 if i >= 2 else -2), BONE_GROUND - 4), col, max(2, round(10 * P.s)))
        P.line((x + (4 if i >= 2 else -2), BONE_GROUND - 6), (x + (4 if i >= 2 else -2), BONE_GROUND), rgb("#2a2420"), max(2, round(10 * P.s)))
    B = P.p((cx - L, cy - 20)), P.p((cx + L, cy + 20))
    P.d.ellipse([B[0][0], B[0][1], B[1][0], B[1][1]], fill=coat)
    P.line((cx + L - 16, cy - 8), (cx + L + 18, cy - 50), coat, max(3, round(22 * P.s)))   # neck
    hd = (cx + L + 18, cy - 50)
    P.poly([(hd[0] - 6, hd[1] - 8), (hd[0] + 30, hd[1] + 6), (hd[0] + 26, hd[1] + 20), (hd[0] - 6, hd[1] + 12)], coat)
    P.dot((hd[0] + 10, hd[1] + 2), 0, OUTLINE)
    P.line((hd[0] - 10, hd[1] - 6), (hd[0] - 30, hd[1] + 20), rgb("#3a2a20"), max(1, round(8 * P.s)))  # mane
    P.line((cx - L, cy - 8), (cx - L - 20, cy + 24), rgb("#3a2a20"), max(1, round(8 * P.s)))          # tail
    if heavy:
        P.line((cx - L + 10, cy - 4), (cx + L - 10, cy - 4), rgb("#c0c8d4"), max(2, round(14 * P.s)))
    P.line((hip[0] - 14, hip[1] + 10), (hip[0] + 16, hip[1] + 10), rgb("#8a2a2a"), max(2, round(12 * P.s)))  # saddle


def draw_weapon(P, j, kind, cols, pose):
    hf, hb = j["ha_f"], j["ha_b"]
    pole = rgb("#7a5230")
    blade = rgb("#e6edf5")
    gold = rgb("#f2c240")
    W = max(1, round(6 * P.s))
    if kind in ("spear", "lance", "halberd", "guandao", "snake_spear", "fangtian"):
        length = {"lance": 190, "spear": 160}.get(kind, 170)
        if pose == "idle":
            butt = (hf[0] + 2, min(BONE_GROUND - 2, hf[1] + 46))
            tip = (hf[0] - 4, butt[1] - length)
        else:
            ux, uy = unitv(hb, hf)
            butt = (hf[0] - ux * 70, hf[1] - uy * 70)
            tip = (hf[0] + ux * (length - 70), hf[1] + uy * (length - 70))
        P.line(butt, tip, pole, max(2, W) if kind == "lance" else W)
        ux, uy = unitv(butt, tip)
        nx, ny = -uy, ux
        if kind in ("spear", "lance"):
            P.poly([(tip[0] + ux * 22, tip[1] + uy * 22), (tip[0] + nx * 8, tip[1] + ny * 8), (tip[0] - nx * 8, tip[1] - ny * 8)], blade)
            P.line((tip[0] - ux * 4 + nx * 8, tip[1] - uy * 4 + ny * 8), (tip[0] - ux * 4 - nx * 8, tip[1] - uy * 4 - ny * 8), rgb("#c83030"), W)
        elif kind == "snake_spear":
            pts = [(tip[0] + ux * k * 5 + nx * (6 if k % 2 else -6), tip[1] + uy * k * 5 + ny * (6 if k % 2 else -6)) for k in range(6)]
            for a, b in zip(pts, pts[1:]):
                P.line(a, b, blade, W)
        elif kind == "guandao":
            P.poly([(tip[0] - ux * 10, tip[1] - uy * 10), (tip[0] + ux * 40 + nx * 6, tip[1] + uy * 40 + ny * 6),
                    (tip[0] + ux * 12 + nx * 26, tip[1] + uy * 12 + ny * 26), (tip[0] - ux * 10 + nx * 18, tip[1] - uy * 10 + ny * 18)], blade)
            P.line((tip[0] - ux * 12, tip[1] - uy * 12), (tip[0] - ux * 12 + nx * 6, tip[1] - uy * 12 + ny * 6), rgb("#2f8a46"), W)
        else:
            P.poly([(tip[0] + ux * 24, tip[1] + uy * 24), (tip[0] + nx * 7, tip[1] + ny * 7), (tip[0] - nx * 7, tip[1] - ny * 7)], blade)
            for sgn in ((1, -1) if kind == "fangtian" else (1,)):
                c0 = (tip[0] - ux * 2 + nx * 8 * sgn, tip[1] - uy * 2 + ny * 8 * sgn)
                P.poly([c0, (c0[0] + nx * 16 * sgn - ux * 10, c0[1] + ny * 16 * sgn - uy * 10),
                        (c0[0] + nx * 16 * sgn + ux * 14, c0[1] + ny * 16 * sgn + uy * 14), (c0[0] + ux * 8, c0[1] + uy * 8)], blade)
    elif kind in ("sword_shield", "axe_shield"):
        top = (hb[0] + 18, hb[1] - 44)
        P.line(hb, top, pole if kind == "axe_shield" else blade, W)
        if kind == "axe_shield":
            P.poly([top, (top[0] + 18, top[1] + 2), (top[0] + 18, top[1] + 26), (top[0], top[1] + 18)], blade)
        shield = cols["armor"] if kind == "sword_shield" else rgb("#8a5a32")
        if kind == "sword_shield":
            P.poly([(hf[0] - 4, hf[1] - 36), (hf[0] + 18, hf[1] - 36), (hf[0] + 18, hf[1] + 26), (hf[0] - 4, hf[1] + 26)], shield)
            P.line((hf[0] + 7, hf[1] - 30), (hf[0] + 7, hf[1] + 20), light(shield), W)
        else:
            A, B = P.p((hf[0] - 16, hf[1] - 24)), P.p((hf[0] + 20, hf[1] + 12))
            P.d.ellipse([A[0], A[1], B[0], B[1]], fill=shield)
            P.dot((hf[0] + 2, hf[1] - 6), max(1, round(5 * P.s)), gold)
    elif kind == "jian":
        ux, uy = unitv(j["el_f"], hf)
        tip = (hf[0] + ux * 80, hf[1] + uy * 80 - (40 if pose == "idle" else 0))
        P.line(hf, tip, blade, W)
        P.line((hf[0] - 6, hf[1] + 8), (hf[0] + 6, hf[1] - 8), gold, W)
    elif kind == "club":
        tip = (hf[0] + 30, hf[1] - 50)
        P.line(hf, tip, pole, max(2, round(10 * P.s)))
        P.dot(tip, max(2, round(11 * P.s)), rgb("#5a3a22"))
    elif kind == "bow":
        A, B = P.p((hf[0] - 16, hf[1] - 54)), P.p((hf[0] + 20, hf[1] + 54))
        P.d.arc([A[0], A[1], B[0], B[1]], 270, 90, fill=pole, width=W)
        top, bot = P.p((hf[0] + 2, hf[1] - 54)), P.p((hf[0] + 2, hf[1] + 54))
        mid = P.p(hb)
        P.d.line([top, mid, bot], fill=rgb("#e8e0d0"), width=1)
        P.line(hb, (hf[0] + 34, hf[1]), rgb("#c8b090"), 1)
    elif kind == "crossbow":
        P.line(hb, (hf[0] + 30, hf[1] - 2), pole, max(2, W))
        A, B = P.p((hf[0] + 10, hf[1] - 30)), P.p((hf[0] + 36, hf[1] + 26))
        P.d.arc([A[0], A[1], B[0], B[1]], 270, 90, fill=rgb("#4a3a2a"), width=W)
    elif kind in ("staff_fire", "staff_thunder"):
        top = (hf[0] + 8, hf[1] - 84)
        P.line((hf[0] - 4, hf[1] + 40), top, pole, W)
        if kind == "staff_fire":
            P.poly([(top[0] - 12, top[1] + 4), (top[0], top[1] - 28), (top[0] + 12, top[1] + 4)], rgb("#ff8a2a"))
            P.dot((top[0], top[1] - 4), max(1, round(6 * P.s)), rgb("#ffe066"))
        else:
            for a, b in (((top[0] - 10, top[1] - 26), (top[0] + 4, top[1] - 10)), ((top[0] + 4, top[1] - 10), (top[0] - 4, top[1] - 8)), ((top[0] - 4, top[1] - 8), (top[0] + 10, top[1] + 10))):
                P.line(a, b, rgb("#8ad8ff"), W)
    elif kind in ("feather_fan", "ribbon_fan"):
        c = (hf[0] + 12, hf[1] - 18)
        P.line(hf, c, pole, W)
        A, B = P.p((c[0] - 26, c[1] - 30)), P.p((c[0] + 26, c[1] + 22))
        P.d.pieslice([A[0], A[1], B[0], B[1]], 200, 340, fill=rgb("#f4f0e6") if kind == "feather_fan" else rgb("#ff9ac8"))
        if kind == "ribbon_fan":
            P.line(hb, (hb[0] - 24, hb[1] + 24), rgb("#ff9ac8"), W)


def draw_head(P, j, spec):
    h = j["head"]
    r = max(5, round(32 * P.s))
    H = P.p(h)
    skin = SKIN
    P.d.ellipse([H[0] - r, H[1] - r, H[0] + r, H[1] + r], fill=skin)
    hair = spec["hair"]
    hat = spec["hat"]
    marks = spec["marks"]
    # hair: back and top of the head (facing right, so hair on the left)
    if "bare_head" not in marks:
        P.d.pieslice([H[0] - r, H[1] - r, H[0] + r, H[1] + r], 150, 300, fill=hair)
    # eye, mouth, cheek
    ex, ey = H[0] + round(r * 0.45), H[1] - round(r * 0.05)
    if "eye_patch" in marks:
        P.d.rectangle([ex - 1, ey - 1, ex + 1, ey + 1], fill=OUTLINE)
        P.d.line([(H[0] - r, H[1] - r // 2), (ex + 1, ey - 1)], fill=OUTLINE)
    else:
        P.d.rectangle([ex, ey - 1, ex, ey + 1], fill=OUTLINE)
    P.d.point((H[0] + round(r * 0.55), H[1] + round(r * 0.5)), fill=dark(SKIN_D, 0.8))
    P.d.point((H[0] + round(r * 0.2), H[1] + round(r * 0.3)), fill=rgb("#f0a0a0"))
    # hats
    team = spec["armor"] if spec["hero"] else spec["armor"]
    if hat in ("helmet", "helmet_big") or "helmet" in marks or "helmet_plume" in marks:
        col = rgb("#8f99a8") if not spec["hero"] else spec["armor"]
        P.d.pieslice([H[0] - r - 1, H[1] - r - 1, H[0] + r + 1, H[1] + r - 1], 180, 360, fill=col)
        P.d.line([(H[0] - r - 1, H[1] - 1), (H[0] + r + 1, H[1] - 1)], fill=dark(col), width=1)
        if hat == "helmet_big":
            P.d.line([(H[0], H[1] - r - 3), (H[0], H[1] - r)], fill=rgb("#c83030"), width=2)
        if "helmet_plume" in marks:
            P.d.line([(H[0], H[1] - r), (H[0] - r, H[1] - r - 4)], fill=rgb("#d83030"), width=2)
    elif hat == "bandana" or "headband" in marks:
        P.d.line([(H[0] - r, H[1] - r // 2), (H[0] + r, H[1] - r // 2 - 1)], fill=rgb("#c83030"), width=2)
        P.d.line([(H[0] - r, H[1] - r // 2), (H[0] - r - 3, H[1])], fill=rgb("#c83030"), width=1)
    elif hat == "cap":
        P.d.pieslice([H[0] - r, H[1] - r - 1, H[0] + r, H[1] + r - 2], 190, 350, fill=rgb("#4a6a3a"))
    elif hat == "scholar" or "scholar_hat" in marks:
        P.d.rectangle([H[0] - r // 2 - 1, H[1] - r - 4, H[0] + r // 2, H[1] - r + 2], fill=rgb("#2a2a36"))
    elif hat == "yellow" or "yellow_scarf" in marks:
        P.d.pieslice([H[0] - r, H[1] - r - 1, H[0] + r, H[1] + r - 3], 180, 360, fill=rgb("#f0cf3a"))
        P.d.line([(H[0] - r, H[1] - r // 3), (H[0] - r - 3, H[1] + 2)], fill=rgb("#f0cf3a"), width=1)
    for m in marks:
        if m in ("long_beard", "long_beard_white"):
            col = rgb("#f0f0f0") if m == "long_beard_white" else rgb("#1e1816")
            P.d.polygon([(H[0] + 1, H[1] + r // 2), (H[0] + r, H[1] + r // 3), (H[0] + r // 2 + 1, H[1] + r * 2), (H[0] + 1, H[1] + r + 2)], fill=col)
        elif m == "spiky_beard":
            for i in range(4):
                P.d.line([(H[0] + i * 2, H[1] + r // 2), (H[0] - 1 + i * 3, H[1] + r + 2)], fill=rgb("#1e1816"), width=1)
        elif m == "short_beard":
            P.d.arc([H[0], H[1], H[0] + r, H[1] + r], 20, 120, fill=rgb("#2a2020"), width=1)
        elif m == "hat_soft":
            P.d.polygon([(H[0] - r, H[1] - 2), (H[0] - 2, H[1] - r - 4), (H[0] + r - 1, H[1] - r // 2)], fill=spec["armor"])
        elif m == "crown":
            P.d.polygon([(H[0] - 3, H[1] - r + 1), (H[0] - 3, H[1] - r - 3), (H[0], H[1] - r - 1), (H[0] + 3, H[1] - r - 4), (H[0] + 4, H[1] - r + 1)], fill=rgb("#f2c240"))
        elif m == "pheasant_feathers":
            for dx in (-1, 2):
                P.d.line([(H[0] + dx, H[1] - r), (H[0] + dx - 9, H[1] - r - 11)], fill=rgb("#d83030"), width=1)
        elif m == "hair_bun":
            P.d.ellipse([H[0] - r // 2 - 3, H[1] - r - 4, H[0] - r // 2 + 3, H[1] - r + 2], fill=hair)
            P.d.point((H[0] - r // 2 + 3, H[1] - r - 3), fill=rgb("#ff9ac8"))
        elif m == "feather":
            P.d.line([(H[0] - 2, H[1] - r), (H[0] - 6, H[1] - r - 7)], fill=rgb("#ff9a3a"), width=1)


def draw_body(P, j, spec):
    cloth, armor = spec["cloth"], spec["armor"]
    stout = spec["body"] == "stout" or "fat" in spec["marks"]
    w = max(3, round((60 if stout else 46) * P.s))
    n, hp = P.p(j["neck"]), P.p(j["hip"])
    P.d.polygon([(n[0] - w // 2, n[1]), (n[0] + w // 2, n[1]), (hp[0] + w // 2 + (1 if stout else 0), hp[1]), (hp[0] - w // 2, hp[1])], fill=cloth)
    # chest armour plate + belt
    P.d.rectangle([n[0] - w // 2 + 1, n[1] + 1, n[0] + w // 2 - 1, n[1] + max(2, (hp[1] - n[1]) // 2)], fill=armor if spec["body"] != "robe" else light(cloth, 0.2))
    P.d.line([(hp[0] - w // 2, hp[1] - 1), (hp[0] + w // 2, hp[1] - 1)], fill=dark(cloth, 0.55), width=1)
    if "fat" in spec["marks"]:
        P.d.ellipse([hp[0] - 1, n[1] + 3, hp[0] + w // 2 + 3, hp[1]], fill=light(cloth, 0.15))
    if spec["body"] == "robe" or "robe_long" in spec["marks"]:
        g = P.g
        P.d.polygon([(hp[0] - w // 2 - 1, hp[1] - 2), (hp[0] + w // 2 + 1, hp[1] - 2), (hp[0] + w // 2 + 4, g - 2), (hp[0] - w // 2 - 4, g - 2)], fill=cloth)
    if "bells" in spec["marks"]:
        P.d.point((hp[0], hp[1] + 1), fill=rgb("#f2c240"))
    if "cape" in spec["marks"]:
        pass


def draw_limbs(P, j, spec, front):
    cloth, pants = spec["cloth"], spec["pants"]
    lw = max(2, round(14 * P.s))
    aw = max(2, round(12 * P.s))
    if not front:
        P.line(j["hp_b"], j["kn_b"], dark(pants), lw); P.line(j["kn_b"], j["an_b"], dark(pants), lw)
        A = P.p(j["an_b"]); P.d.rectangle([A[0] - 1, A[1] - 1, A[0] + 2, A[1]], fill=rgb("#2a2420"))
        P.line(j["sh_b"], j["el_b"], dark(cloth), aw); P.line(j["el_b"], j["ha_b"], dark(cloth), aw)
        P.dot(j["ha_b"], max(1, aw // 2), SKIN_D)
    else:
        P.line(j["hp_f"], j["kn_f"], pants, lw); P.line(j["kn_f"], j["an_f"], pants, lw)
        A = P.p(j["an_f"]); P.d.rectangle([A[0] - 1, A[1] - 1, A[0] + 2, A[1]], fill=rgb("#2a2420"))
        P.line(j["sh_f"], j["el_f"], cloth, aw); P.line(j["el_f"], j["ha_f"], cloth, aw)
        P.dot(j["ha_f"], max(1, aw // 2), SKIN)


def render(spec, pose, pose_name, w, h, scale):
    cx = w // 2 - (6 if spec["mount"] else 0)
    P = Painter(w, h, scale, cx, h - 1)
    j = mounted(pose) if spec["mount"] else pose
    if "cape" in spec["marks"]:
        n = j["neck"]
        P.poly([(n[0] - 4, n[1] + 2), (n[0] - 38, n[1] + 72), (n[0] - 10, n[1] + 66)], rgb("#b02a2a") if spec["hero"] else spec["cloth"])
    if spec["mount"]:
        coat = rgb("#e8e4da") if spec.get("white_horse") else (rgb("#5a3a26") if spec["mount"] == "heavy" else rgb("#8a5a36"))
        draw_horse(P, j, spec["mount"] == "heavy", coat)
    if "quiver" in spec["marks"]:
        n = j["neck"]
        P.line((n[0] - 18, n[1] + 4), (n[0] - 24, n[1] + 40), rgb("#7a4a2a"), max(2, round(10 * P.s)))
    draw_limbs(P, j, spec, False)
    draw_body(P, j, spec)
    draw_weapon(P, j, spec["weapon"], spec, pose_name)
    draw_limbs(P, j, spec, True)
    draw_head(P, j, spec)
    return outline(P.im)


## 그림 칸 (원본 픽셀): 일반 64x64, 기병 96x80. 발 기준점 = 칸 아래 가운데.
## 뼈대 1단위 = 0.24 픽셀 (머리 지름 64 -> 15px, 키 186 -> 45px). design/art/bones/README.md
SIZES = {"foot": (64, 64, 0.24), "mount": (96, 80, 0.24)}
## 화면 표시 높이(전투, 논리 px) = target_h x visual_boost(2.4) — 칸 높이 기준.
TARGET_H = {"foot": 47, "mount": 58}


def frames_for(spec):
    kind = "mount" if spec["mount"] else "foot"
    w, h, s = SIZES[kind]
    out = {"idle": [], "run": [], "attack": []}
    for i in range(4):
        p = {k: (v[0], v[1] + (2 if i in (1, 2) else 0) * (1 if k in ("head", "neck", "sh_f", "sh_b", "el_f", "el_b", "ha_f", "ha_b") else 0)) for k, v in IDLE.items()}
        out["idle"].append(render(spec, p, "idle", w, h, s))
    for i in range(6):
        out["run"].append(render(spec, run_pose(i), "attack" if spec["weapon"] in ("bow", "crossbow") else "idle", w, h, s))
    for t in (-0.35, 0.4, 1.0, 1.0, 0.5):
        out["attack"].append(render(spec, lerp_pose(IDLE, ATTACK, t), "attack", w, h, s))
    return out, w, h


def save_unit(uid, spec, art):
    fr, w, h = frames_for(spec)
    d = os.path.join(UNITS, uid)
    for act, lst in fr.items():
        os.makedirs(os.path.join(d, act), exist_ok=True)
        for i, im in enumerate(lst):
            im.save(os.path.join(d, act, "%03d.png" % i))
    idle0 = fr["idle"][0]
    # portrait: head + shoulders, 2x
    big = render(spec, IDLE, "idle", w * 3, h * 3, SIZES["mount" if spec["mount"] else "foot"][2] * 3)
    bb = big.getbbox()
    hx, hy = (round(w * 3 / 2 - (18 if spec["mount"] else 0) + (128 - 128) * 0), 0)
    P = Painter(1, 1, SIZES["mount" if spec["mount"] else "foot"][2] * 3, w * 3 // 2 - (18 if spec["mount"] else 0), h * 3 - 1)
    head = P.p(mounted(IDLE)["head"] if spec["mount"] else IDLE["head"])
    r = round(32 * P.s)
    box = (head[0] - r * 2, head[1] - r * 2, head[0] + r * 2, head[1] + r * 2 + r)
    por = big.crop(box)
    por.save(os.path.join(PORTRAITS, uid + ".png"))
    hb = (head[0] - round(r * 1.5), head[1] - round(r * 1.6), head[0] + round(r * 1.5), head[1] + round(r * 1.4))
    big.crop(hb).save(os.path.join(PORTRAITS, uid + "_head.png"))
    ill = big.crop(bb) if bb else big
    ill.save(os.path.join(PORTRAITS, uid + "_lihui.png"))
    art[uid] = {
        "dir": "res://assets/units/" + uid,
        "actions": {a: {"frames": len(l), "fps": 10.0 if a != "idle" else 6.0} for a, l in fr.items()},
        "alias": {"idle": "idle", "walk": "run", "run": "run", "attack": "attack", "skill": "attack", "hit": "idle", "die": "idle"},
        "frame_h": h, "frame_w": w, "target_h": TARGET_H["mount" if spec["mount"] else "foot"],
        "portrait": "res://assets/portraits/%s.png" % uid, "head": "res://assets/portraits/%s_head.png" % uid,
        "illustration": "res://assets/portraits/%s_lihui.png" % uid if spec["hero"] else "",
        "_source": "tools/draw_art.py",
    }


# ------------------------------------------------------------------ icons (16x16)
def icon(draw_fn, size=16):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    draw_fn(d)
    return outline(im)


GOLD, GOLD_D = rgb("#ffd447"), rgb("#c8901c")
ICON_DRAW = {
    "gold": lambda d: (d.ellipse([2, 6, 9, 13], fill=GOLD), d.ellipse([6, 3, 13, 10], fill=GOLD), d.point((9, 6), fill=GOLD_D), d.point((5, 9), fill=GOLD_D)),
    "diamond": lambda d: (d.polygon([(2, 6), (5, 3), (10, 3), (13, 6), (7, 13)], fill=rgb("#4fc3ff")), d.polygon([(5, 3), (7, 6), (10, 3)], fill=rgb("#bfeaff"))),
    "rice": lambda d: (d.polygon([(4, 5), (11, 5), (13, 13), (2, 13)], fill=rgb("#d8b07a")), d.rectangle([5, 2, 10, 5], fill=rgb("#b88a50")), d.line([(5, 9), (10, 9)], fill=rgb("#f4e6c0"))),
    "medal": lambda d: (d.polygon([(4, 1), (7, 7), (9, 7), (12, 1)], fill=rgb("#d83030")), d.ellipse([3, 6, 12, 15], fill=GOLD), d.point((7, 10), fill=GOLD_D)),
    "scroll": lambda d: (d.rectangle([3, 3, 12, 12], fill=rgb("#f2e6c8")), d.rectangle([2, 2, 13, 3], fill=rgb("#b05030")), d.rectangle([2, 12, 13, 13], fill=rgb("#b05030")), d.line([(5, 6), (10, 6)], fill=rgb("#c83030")), d.line([(5, 9), (10, 9)], fill=rgb("#8a6a4a"))),
    "chest": lambda d: (d.rectangle([2, 6, 13, 13], fill=rgb("#a0602e")), d.pieslice([2, 2, 13, 11], 180, 360, fill=rgb("#c07a3a")), d.rectangle([2, 6, 13, 7], fill=GOLD), d.rectangle([7, 7, 8, 9], fill=GOLD)),
    "flag": lambda d: (d.line([(4, 1), (4, 14)], fill=rgb("#7a5230"), width=2), d.polygon([(5, 2), (13, 4), (5, 8)], fill=rgb("#d83030"))),
    "swords": lambda d: (d.line([(2, 2), (12, 12)], fill=rgb("#e6edf5"), width=2), d.line([(13, 2), (3, 12)], fill=rgb("#e6edf5"), width=2), d.line([(9, 13), (13, 9)], fill=GOLD, width=2), d.line([(2, 9), (6, 13)], fill=GOLD, width=2)),
    "sword": lambda d: (d.line([(3, 12), (12, 3)], fill=rgb("#e6edf5"), width=2), d.line([(2, 9), (6, 13)], fill=GOLD, width=2)),
    "gear": lambda d: ([d.line([(7.5 + 6 * math.cos(a), 7.5 + 6 * math.sin(a)), (7.5, 7.5)], fill=rgb("#b8c2d0"), width=3) for a in [k * math.pi / 4 for k in range(8)]], d.ellipse([3, 3, 12, 12], fill=rgb("#b8c2d0")), d.ellipse([6, 6, 9, 9], fill=(0, 0, 0, 0))),
    "mail": lambda d: (d.rectangle([1, 4, 14, 12], fill=rgb("#f2ead8")), d.line([(1, 4), (7, 9), (14, 4)], fill=rgb("#b0a080")), d.ellipse([6, 7, 9, 10], fill=rgb("#d83030"))),
    "bag": lambda d: (d.ellipse([2, 5, 13, 14], fill=rgb("#c89a5a")), d.rectangle([5, 2, 10, 6], fill=rgb("#a87a3a")), d.line([(4, 6), (11, 6)], fill=rgb("#d83030"))),
    "updown": lambda d: (d.polygon([(7, 1), (12, 6), (2, 6)], fill=GOLD), d.polygon([(7, 14), (12, 9), (2, 9)], fill=GOLD)),
    "fan": lambda d: (d.pieslice([1, 1, 14, 14], 200, 340, fill=rgb("#f4f0e6")), d.line([(7, 8), (7, 14)], fill=rgb("#7a5230"), width=2)),
    "fast": lambda d: (d.polygon([(1, 3), (7, 8), (1, 13)], fill=GOLD), d.polygon([(7, 3), (13, 8), (7, 13)], fill=GOLD)),
    "deploy": lambda d: (d.pieslice([2, 2, 13, 13], 180, 360, fill=rgb("#9aa4b2")), d.rectangle([2, 7, 13, 9], fill=rgb("#9aa4b2")), d.line([(7, 1), (7, 4)], fill=rgb("#d83030"), width=2)),
    "helmet": lambda d: (d.pieslice([2, 2, 13, 13], 180, 360, fill=rgb("#9aa4b2")), d.rectangle([2, 7, 13, 9], fill=rgb("#9aa4b2")), d.line([(7, 1), (7, 4)], fill=rgb("#d83030"), width=2)),
    "soldier": lambda d: (d.ellipse([3, 2, 12, 11], fill=SKIN), d.pieslice([3, 1, 12, 10], 180, 360, fill=rgb("#9aa4b2")), d.rectangle([4, 11, 11, 14], fill=rgb("#3f6fb0")), d.point((10, 6), fill=OUTLINE)),
    "hero": lambda d: (d.ellipse([3, 2, 12, 11], fill=SKIN), d.pieslice([3, 1, 12, 10], 180, 360, fill=rgb("#d83030")), d.rectangle([4, 11, 11, 14], fill=GOLD), d.point((10, 6), fill=OUTLINE)),
    "pause": lambda d: (d.rectangle([3, 2, 6, 13], fill=rgb("#f0f0f0")), d.rectangle([9, 2, 12, 13], fill=rgb("#f0f0f0"))),
    "speed": lambda d: (d.polygon([(1, 3), (7, 8), (1, 13)], fill=rgb("#f0f0f0")), d.polygon([(7, 3), (13, 8), (7, 13)], fill=rgb("#f0f0f0"))),
    "plus": lambda d: (d.rectangle([6, 2, 9, 13], fill=rgb("#5fd06a")), d.rectangle([2, 6, 13, 9], fill=rgb("#5fd06a"))),
    "x": lambda d: (d.line([(3, 3), (12, 12)], fill=rgb("#f0f0f0"), width=3), d.line([(12, 3), (3, 12)], fill=rgb("#f0f0f0"), width=3)),
    "lock": lambda d: (d.arc([4, 1, 11, 10], 180, 360, fill=rgb("#b8c2d0"), width=2), d.rectangle([3, 7, 12, 14], fill=GOLD), d.point((7, 10), fill=OUTLINE)),
    "star": lambda d: d.polygon([(7.5, 1), (9.5, 6), (14, 6), (10.5, 9), (12, 14), (7.5, 11), (3, 14), (4.5, 9), (1, 6), (5.5, 6)], fill=GOLD),
    "star_off": lambda d: d.polygon([(7.5, 1), (9.5, 6), (14, 6), (10.5, 9), (12, 14), (7.5, 11), (3, 14), (4.5, 9), (1, 6), (5.5, 6)], fill=rgb("#4a5260")),
    "heart": lambda d: (d.ellipse([1, 3, 8, 10], fill=rgb("#e83a4a")), d.ellipse([7, 3, 14, 10], fill=rgb("#e83a4a")), d.polygon([(1, 7), (14, 7), (7.5, 14)], fill=rgb("#e83a4a"))),
    "heart_off": lambda d: (d.ellipse([1, 3, 8, 10], fill=rgb("#4a5260")), d.ellipse([7, 3, 14, 10], fill=rgb("#4a5260")), d.polygon([(1, 7), (14, 7), (7.5, 14)], fill=rgb("#4a5260"))),
    "shield": lambda d: (d.polygon([(2, 2), (13, 2), (13, 8), (7.5, 14), (2, 8)], fill=rgb("#6f9ad8")), d.line([(7, 3), (7, 12)], fill=rgb("#bcd4f4"))),
    "orb": lambda d: (d.ellipse([2, 2, 13, 13], fill=rgb("#b07ae8")), d.ellipse([4, 4, 7, 7], fill=rgb("#e8d4ff"))),
    "seal": lambda d: (d.rectangle([2, 2, 13, 13], fill=rgb("#c83030")), d.rectangle([5, 5, 10, 10], fill=rgb("#f2d0a0"))),
    "boss": lambda d: (d.ellipse([2, 2, 13, 12], fill=rgb("#e8e0d0")), d.rectangle([4, 11, 11, 14], fill=rgb("#e8e0d0")), d.rectangle([4, 6, 6, 8], fill=OUTLINE), d.rectangle([9, 6, 11, 8], fill=OUTLINE)),
    "castle": lambda d: (d.rectangle([2, 6, 13, 14], fill=rgb("#c8b490")), d.polygon([(1, 6), (7.5, 1), (14, 6)], fill=rgb("#3a5a8a")), d.rectangle([6, 9, 9, 14], fill=rgb("#6a4a2a"))),
    "bow": lambda d: (d.arc([2, 1, 12, 14], 270, 90, fill=rgb("#a07040"), width=2), d.line([(7, 1), (7, 14)], fill=rgb("#e8e0d0"))),
    "horse": lambda d: (d.ellipse([2, 6, 11, 11], fill=rgb("#8a5a36")), d.polygon([(9, 7), (12, 2), (14, 4), (11, 8)], fill=rgb("#8a5a36")), d.line([(3, 10), (3, 14)], fill=rgb("#8a5a36"), width=2), d.line([(10, 10), (10, 14)], fill=rgb("#8a5a36"), width=2)),
    "coin": lambda d: (d.ellipse([2, 2, 13, 13], fill=GOLD), d.rectangle([6, 6, 9, 9], fill=GOLD_D)),
    "class_inf": lambda d: (d.line([(3, 13), (12, 2)], fill=rgb("#e6edf5"), width=2), d.polygon([(10, 1), (14, 1), (14, 5)], fill=rgb("#e6edf5"))),
    "class_arc": lambda d: (d.arc([2, 1, 12, 14], 270, 90, fill=rgb("#a07040"), width=2), d.line([(7, 1), (7, 14)], fill=rgb("#e8e0d0")), d.line([(2, 8), (13, 8)], fill=rgb("#e8e0d0"))),
    "class_cav": lambda d: (d.ellipse([2, 6, 11, 11], fill=rgb("#c89a5a")), d.polygon([(9, 7), (12, 2), (14, 4), (11, 8)], fill=rgb("#c89a5a")), d.line([(3, 10), (3, 14)], fill=rgb("#c89a5a"), width=2), d.line([(10, 10), (10, 14)], fill=rgb("#c89a5a"), width=2)),
    "class_str": lambda d: (d.pieslice([1, 1, 14, 14], 200, 340, fill=rgb("#f4f0e6")), d.line([(7, 8), (7, 14)], fill=rgb("#7a5230"), width=2)),
}
RARITY = {"common": "#9aa4b2", "rare": "#3b8fe0", "epic": "#a35be8", "legend": "#ffc93c"}
FACTIONS = {"none": "#9aa4b2", "wei": "#3b74d6", "shu": "#3aa65a", "wu": "#d6463b", "yellow": "#d9b43a"}
# file name -> drawing key (both ic_ and icon_ names are used by the code)
ICON_FILES = {}
for k in ["gold", "diamond", "rice", "medal", "scroll", "chest", "flag", "swords", "sword", "gear", "mail", "bag", "updown",
          "fan", "fast", "deploy", "helmet", "soldier", "hero", "pause", "plus", "x", "lock", "star", "castle"]:
    ICON_FILES["icon_" + k] = k
for k in ["boss", "bow", "coin", "fan", "flag", "gear", "heart", "heart_off", "horse", "lock", "orb", "pause", "scroll", "seal",
          "shield", "speed", "star", "star_off", "sword", "x"]:
    ICON_FILES["ic_" + k] = k
for k in ["class_inf", "class_arc", "class_cav", "class_str"]:
    ICON_FILES[k] = k


def gem(col):
    return lambda d: (d.polygon([(7.5, 1), (14, 7.5), (7.5, 14), (1, 7.5)], fill=rgb(col)), d.polygon([(7.5, 3), (11, 7.5), (7.5, 7.5)], fill=light(rgb(col), 0.5)))


def banner(col):
    return lambda d: (d.rectangle([3, 1, 12, 12], fill=rgb(col)), d.polygon([(3, 12), (7.5, 15), (12, 12)], fill=rgb(col)), d.rectangle([6, 4, 9, 8], fill=light(rgb(col), 0.6)))


def make_icons():
    os.makedirs(ICONS, exist_ok=True)
    for name, key in ICON_FILES.items():
        icon(ICON_DRAW[key]).save(os.path.join(ICONS, name + ".png"))
    for r, c in RARITY.items():
        icon(gem(c)).save(os.path.join(ICONS, "rarity_%s.png" % r))
    for f, c in FACTIONS.items():
        icon(banner(c)).save(os.path.join(ICONS, "faction_%s.png" % f))
    # battle wall strip (stone) and respawn ring
    wall = Image.new("RGBA", (256, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(wall)
    d.rectangle([0, 8, 255, 39], fill=rgb("#8a8478"))
    for x in range(0, 256, 16):
        d.rectangle([x + 2, 0, x + 10, 8], fill=rgb("#8a8478"))
    for y in range(10, 40, 8):
        off = 0 if (y // 8) % 2 else 8
        for x in range(-8 + off, 256, 16):
            d.rectangle([x + 1, y + 1, x + 14, y + 6], fill=rgb("#a49c8c"))
    outline(wall).save(os.path.join(UI, "wall.png"))
    ring = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    d.ellipse([2, 2, 29, 29], outline=rgb("#e6edf5"), width=3)
    ring.save(os.path.join(UI, "ring_respawn.png"))


def main():
    specs = build_specs()
    specs["zhaoyun"]["white_horse"] = True
    for d in (UNITS, PORTRAITS):
        os.makedirs(d, exist_ok=True)
    art = {}
    for uid, spec in specs.items():
        save_unit(uid, spec, art)
    json.dump(art, open(os.path.join(UNITS, "art.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    make_icons()
    # app icon: 관우 head on a dark tile
    head = Image.open(os.path.join(PORTRAITS, "guanyu_head.png"))
    app = Image.new("RGBA", (64, 64), rgb("#121820"))
    hh = head.resize((56, 56), Image.NEAREST)
    app.alpha_composite(hh, (4, 4))
    app.save(os.path.join(ROOT, "icon.png"))
    # contact sheet for review
    sheet_items = list(specs.keys())
    cols = 8
    cw, ch = 96 * 3, 80 * 3
    sheet = Image.new("RGBA", (cols * cw, math.ceil(len(sheet_items) / cols) * ch), rgb("#3a6a3a"))
    for i, uid in enumerate(sheet_items):
        f = Image.open(os.path.join(UNITS, uid, "idle", "000.png"))
        f = f.resize((f.width * 3, f.height * 3), Image.NEAREST)
        sheet.alpha_composite(f, ((i % cols) * cw + (cw - f.width) // 2, (i // cols) * ch + ch - f.height))
    os.makedirs(os.path.join(ROOT, "design", "art"), exist_ok=True)
    sheet.save(os.path.join(ROOT, "design", "art", "drawn_units.png"))
    print("units", len(specs), "icons", len(ICON_FILES) + len(RARITY) + len(FACTIONS))


if __name__ == "__main__":
    main()
