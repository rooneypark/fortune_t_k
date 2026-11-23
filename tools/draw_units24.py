#!/usr/bin/env python3
"""운빨삼국 임시 캐릭터 그림 — 24도트 규격 (design/art/캐릭터-도트-컨셉.md, 2026-11-23).

외부 그림 없이 코드로 직접 찍는다. 다른 게임의 그림을 쓰지 않는다. 출시 전에 교체한다.

- 걷는 캐릭터 24 x 24 도트, 기병 32 x 28, 괴력 장수 32 x 32. 도트 1칸 = 4px로 저장 (96 / 128 x 112 / 128).
- 2등신, 바깥 테두리 1도트(짙은 남색), 눈은 점 두 개. 전부 오른쪽을 본다.
- 동작: 대기 2장 · 걷기(run) 4장 · 공격 3장 (당김 → 뻗음 → 돌아옴).
- 병종 16 · 장수 32 · 적 9 = 57종 + 보스 11명(40 x 40 도트, boss_<id>).
- 얼굴 아이콘(portraits/<id>.png, <id>_head.png) 32 x 32 도트, 장수 큰 그림(<id>_lihui.png)은
  대기 그림을 크게 키운 것(임시).
- assets/units/art.json 을 새로 쓴다 (칸 크기 · 장수 · 초당 장수).

Usage: python tools/draw_units24.py
"""
import json, math, os, shutil
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNITS = os.path.join(ROOT, "assets", "units")
PORTRAITS = os.path.join(ROOT, "assets", "portraits")
DOT = 4  # 도트 1칸 = 4px

OUT = (27, 27, 42, 255)       # 테두리: 짙은 남색 (순수 검정 아님)
SKIN = (244, 200, 160, 255)
SKIN_D = (206, 152, 116, 255)
EYE = (30, 24, 34, 255)
WOOD = (150, 100, 58, 255)
WOOD_D = (104, 68, 40, 255)
STEEL = (208, 214, 224, 255)
STEEL_D = (136, 146, 164, 255)
GOLD = (232, 190, 78, 255)
WHITE = (240, 240, 232, 255)
RED = (208, 68, 52, 255)
BLACK = (40, 34, 44, 255)


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def dark(c, k=0.7):
    return (int(c[0] * k), int(c[1] * k), int(c[2] * k), 255)


def light(c, k=0.35):
    return (int(c[0] + (255 - c[0]) * k), int(c[1] + (255 - c[1]) * k), int(c[2] + (255 - c[2]) * k), 255)


class Cv:
    """도트 캔버스. 좌표는 도트, (0, 0) = 왼쪽 위."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.im.load()

    def dot(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(min(y0, y1)), int(max(y0, y1)) + 1):
            for x in range(int(min(x0, x1)), int(max(x0, x1)) + 1):
                self.dot(x, y, c)

    def line(self, x0, y0, x1, y1, c, w=1):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n)
            y = round(y0 + (y1 - y0) * i / n)
            for k in range(w):
                self.dot(x, y + k, c) if abs(x1 - x0) >= abs(y1 - y0) else self.dot(x + k, y, c)

    def outlined(self):
        src = self.im.copy().load()
        for y in range(self.h):
            for x in range(self.w):
                if src[x, y][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and src[nx, ny][3] != 0:
                        self.px[x, y] = OUT
                        break
        return self.im


# ------------------------------------------------------------------ 캐릭터 정의
ARMY = {"cloth": "#7a7468", "armor": "#9aa4b2", "pants": "#3a3f4a", "hair": "#2b2220"}
CLASS_COL = {"pike": "#c8a04a", "inf": "#6f8fb0", "arc": "#6fbf5a", "cav": "#d86a4a", "str": "#9a6ad8"}
FACTION = {"wei": "#3b74d6", "shu": "#3fa860", "wu": "#d04a3a", "qun": "#8a5ad0"}
# 병종 16종: 무기 실루엣으로 구분한다. 옷은 수수한 회갈색, 어깨띠만 분류색.
TROOPS = {
    "spear":     {"cls": "pike", "weapon": "spear", "hat": "helmet"},
    "halberd":   {"cls": "pike", "weapon": "halberd", "hat": "helmet", "armor": "#b7a27a"},
    "longspear": {"cls": "pike", "weapon": "longspear", "hat": "cap"},
    "sword":     {"cls": "inf", "weapon": "sword", "hat": "headband"},
    "shield":    {"cls": "inf", "weapon": "sword_shield", "hat": "helmet"},
    "axe":       {"cls": "inf", "weapon": "axe_shield", "hat": "bandana", "marks": ["fat"]},
    "vine":      {"cls": "inf", "weapon": "vine_shield", "hat": "bare_head", "cloth": "#6a5a3a"},
    "archer":    {"cls": "arc", "weapon": "bow", "hat": "cap", "marks": ["quiver"]},
    "crossbow":  {"cls": "arc", "weapon": "crossbow", "hat": "helmet"},
    "catapult":  {"cls": "arc", "weapon": "sling", "hat": "bandana"},
    "rider":     {"cls": "cav", "weapon": "spear", "hat": "helmet", "mount": "light"},
    "heavy":     {"cls": "cav", "weapon": "lance", "hat": "helmet_big", "mount": "heavy", "armor": "#7c8796"},
    "harcher":   {"cls": "cav", "weapon": "bow", "hat": "cap", "mount": "light", "marks": ["quiver"]},
    "fire":      {"cls": "str", "weapon": "staff_fire", "hat": "scholar", "marks": ["robe"], "cloth": "#c8553d"},
    "thunder":   {"cls": "str", "weapon": "staff_thunder", "hat": "scholar", "marks": ["robe"], "cloth": "#4a6fc8"},
    "medic":     {"cls": "str", "weapon": "gourd", "hat": "cap", "marks": ["robe"], "cloth": "#e8ecf2"},
}
# 장수 32명: (세력, 병종, 고유 무기 또는 None, 표식, 갑옷/장식 색 또는 None)
HEROES = {
    "zhugeliang": ("shu", "fire", "fan", ["scholar_hat", "robe"], "#e8ecf2"),
    "guanyu": ("shu", "spear", "guandao", ["hat_soft", "long_beard"], "#2f8a46"),
    "zhaoyun": ("shu", "rider", None, ["helmet_plume", "cape"], "#e8ecf2"),
    "zhangfei": ("shu", "halberd", "snake_spear", ["headband", "spiky_beard"], "#3b3b46"),
    "huangzhong": ("shu", "archer", None, ["helmet", "long_beard_white", "quiver"], None),
    "liubei": ("shu", "sword", "jian", ["hat_soft", "short_beard"], "#e8c86a"),
    "guanping": ("shu", "spear", None, ["helmet"], None),
    "caocao": ("wei", "heavy", "jian", ["crown", "cape", "short_beard"], "#b0302c"),
    "simayi": ("wei", "heavy", "fan", ["scholar_hat", "cape", "long_beard"], "#2a2a46"),
    "zhangliao": ("wei", "rider", "halberd", ["helmet", "short_beard"], None),
    "xiahoudun": ("wei", "spear", None, ["helmet", "eye_patch"], None),
    "xiahouyuan": ("wei", "crossbow", None, ["helmet", "quiver"], None),
    "xuchu": ("wei", "axe", None, ["bare_head", "fat"], None),
    "caoren": ("wei", "shield", None, ["helmet", "short_beard"], None),
    "zhanghe": ("wei", "longspear", None, ["helmet_plume"], None),
    "sunce": ("wu", "heavy", None, ["tiger_helmet", "cape"], "#e0a030"),
    "sunquan": ("wu", "shield", None, ["crown", "short_beard"], None),
    "zhouyu": ("wu", "fire", "jian", ["hat_soft", "robe"], None),
    "luxun": ("wu", "fire", "jian", ["scholar_hat", "robe"], "#f0e0c0"),
    "ganning": ("wu", "axe", None, ["feather", "bells"], None),
    "taishici": ("wu", "harcher", None, ["headband", "quiver"], None),
    "huanggai": ("wu", "fire", "club", ["headband", "long_beard_white"], None),
    "handang": ("wu", "archer", None, ["headband", "quiver"], None),
    "lvbu": ("qun", "halberd", "fangtian", ["helmet", "pheasant_feathers"], "#b0302c"),
    "diaochan": ("qun", "thunder", "ribbon_fan", ["hair_bun", "robe"], "#e88ab4"),
    "dongzhuo": ("qun", "shield", None, ["crown", "short_beard", "fat"], "#6b3a2a"),
    "yuanshao": ("qun", "catapult", "jian", ["crown", "cape"], "#c9a33b"),
    "menghuo": ("qun", "vine", None, ["feather", "bare_head", "fat"], "#6b4a2a"),
    "huaman": ("qun", "crossbow", None, ["hair_bun", "feather"], "#c0603a"),
    "zhangjiao_h": ("qun", "thunder", None, ["yellow", "long_beard", "robe"], "#d9b43a"),
    "zuoci": ("qun", "thunder", None, ["scholar_hat", "long_beard_white", "robe"], "#e8ecf2"),
    "yuji": ("qun", "medic", None, ["headband", "long_beard_white", "robe"], "#d8d0b0"),
}
# 적 (황건적): 노란 두건.
ENEMIES = {
    "enemy_mob": {"weapon": "club", "hat": "yellow", "cloth": "#8a6a48", "small": True},
    "enemy_sword": {"weapon": "sword", "hat": "yellow", "cloth": "#8a5a38"},
    "enemy_spear": {"weapon": "spear", "hat": "yellow", "cloth": "#7a5a3a"},
    "enemy_archer": {"weapon": "bow", "hat": "yellow", "cloth": "#6f6a3a", "marks": ["quiver"]},
    "enemy_shield": {"weapon": "sword_shield", "hat": "yellow", "cloth": "#6a4a30", "marks": ["fat"]},
    "enemy_rider": {"weapon": "spear", "hat": "yellow", "cloth": "#7a5a3a", "mount": "light"},
    "enemy_mage": {"weapon": "staff_thunder", "hat": "yellow", "cloth": "#5a4a7a", "marks": ["robe"]},
    "enemy_brute": {"weapon": "club", "hat": "yellow", "cloth": "#7a3a2a", "marks": ["fat", "bare_head"], "big": True},
    "enemy_zhangjiao": {"weapon": "staff_thunder", "hat": "yellow", "cloth": "#c9a33b", "marks": ["long_beard", "robe"]},
}
HAT_MARKS = ("helmet", "helmet_big", "helmet_plume", "cap", "bandana", "headband", "scholar", "scholar_hat", "hat_soft",
             "yellow", "crown", "hair_bun", "bare_head", "tiger_helmet")


def build_specs():
    specs = {}
    for tid, t in TROOPS.items():
        specs[tid] = {"weapon": t["weapon"], "hat": t["hat"], "mount": t.get("mount"), "marks": list(t.get("marks", [])),
                      "cloth": rgb(t.get("cloth", ARMY["cloth"])), "armor": rgb(t.get("armor", ARMY["armor"])), "sash": rgb(CLASS_COL[t["cls"]]),
                      "pants": rgb(ARMY["pants"]), "hair": rgb(ARMY["hair"]), "hero": False}
    for hid, (fac, troop, wpn, marks, accent) in HEROES.items():
        t = TROOPS[troop]
        hat = next((m for m in marks if m in HAT_MARKS), "none")
        beard_white = "long_beard_white" in marks
        specs[hid] = {"weapon": wpn or t["weapon"], "hat": hat, "mount": t.get("mount"),
                      "marks": [m for m in marks if m not in HAT_MARKS] + [m for m in t.get("marks", []) if m not in marks],
                      "cloth": rgb(FACTION[fac]), "armor": rgb(accent) if accent else rgb("#d8b04a"), "sash": rgb("#e8c86a"),
                      "pants": rgb("#2f2a34"), "hair": rgb("#e8e8e8") if beard_white else rgb("#241c1a"), "hero": True,
                      "white_horse": hid == "zhaoyun"}
    for eid, e in ENEMIES.items():
        specs[eid] = {"weapon": e["weapon"], "hat": e["hat"], "mount": e.get("mount"), "marks": list(e.get("marks", [])),
                      "cloth": rgb(e["cloth"]), "armor": rgb("#8a7a5a"), "sash": rgb("#d9b43a"), "pants": rgb("#4a3a2a"),
                      "hair": rgb("#2b2220"), "hero": False, "small": e.get("small", False), "big": e.get("big", False)}
    # 보스 11명: 40 x 40 도트 전용 그림 (boss_<id>). 말 없이 크게 그린다.
    def boss(src, **kw):
        s = dict(specs[src]) if src else {"marks": [], "hero": True, "pants": rgb("#2f2a34"), "hair": rgb("#241c1a"), "sash": rgb("#e8c86a")}
        s["marks"] = list(kw.pop("marks", s["marks"]))
        for key in ("cloth", "armor"):
            if key in kw:
                kw[key] = rgb(kw[key])
        s.update(kw)
        s.update({"mount": None, "boss": True, "big": False, "small": False})
        return s
    specs["boss_zhangjiao"] = boss("enemy_zhangjiao", marks=["long_beard", "robe", "cape"], armor="#8a5a20")
    specs["boss_chengyuanzhi"] = boss("enemy_brute", marks=["fat", "spiky_beard"], hat="yellow")
    specs["boss_lvbu_b"] = boss("lvbu", marks=["pheasant_feathers", "cape"])
    specs["boss_jiling"] = boss(None, weapon="fangtian", hat="helmet_big", marks=["short_beard", "fat"], cloth="#b08a30", armor="#8a8f9a")
    specs["boss_yanwen"] = boss(None, weapon="guandao", hat="helmet_plume", marks=["spiky_beard", "cape"], cloth="#c9a33b", armor="#6a4a2a")
    specs["boss_caoren"] = boss("caoren", hat="helmet_big", marks=["short_beard", "cape"], armor="#7c8796")
    specs["boss_xiahouyuan_b"] = boss("xiahouyuan", weapon="bow", marks=["quiver", "short_beard"])
    specs["boss_zhouyu_b"] = boss("zhouyu", marks=["robe", "cape"], armor="#e8ecf2")
    specs["boss_menghuo_b"] = boss("menghuo")
    specs["boss_simayi_b"] = boss("simayi", marks=["long_beard", "robe", "cape"])
    specs["boss_caocao_b"] = boss("caocao")
    return specs


# ------------------------------------------------------------------ 몸 치수
BOSS = {"hw": 14, "hh": 13, "bw": 15, "bh": 11, "lh": 6}     # 보스 40 x 40
FOOT = {"hw": 10, "hh": 9, "bw": 8, "bh": 6, "lh": 4}        # 24 x 24: 키 19 + 머리 장식
SMALL = {"hw": 9, "hh": 8, "bw": 7, "bh": 5, "lh": 4}        # 잡병: 조금 작다
BIG = {"hw": 12, "hh": 11, "bw": 12, "bh": 9, "lh": 5}       # 괴력 장수 32 x 32
RIDER = {"hw": 9, "hh": 8, "bw": 7, "bh": 5, "lh": 0}        # 말 위의 상체
BUST = {"hw": 20, "hh": 18, "bw": 22, "bh": 9, "lh": 0}      # 얼굴 아이콘 32 x 32


def draw_figure(cv, spec, d, cx, base, pose):
    """발 기준점 (cx, base)에 사람을 그린다. pose: bob, lean, legs(걷기 0~3), phase(idle/wind/strike/recover)."""
    marks = spec["marks"]
    k = max(1, round(d["hw"] / 10))  # 머리 크기에 따른 장식 배율 (얼굴 아이콘 = 2)
    fat = "fat" in marks
    bw = d["bw"] + (2 * k if fat else 0)
    bh, hw, hh, lh = d["bh"], d["hw"], d["hh"], d["lh"]
    bob = pose.get("bob", 0)
    lean = pose.get("lean", 0)
    robe = "robe" in marks
    cloth, cloth_d = spec["cloth"], dark(spec["cloth"])
    bx0 = cx - bw // 2 + lean
    bx1 = bx0 + bw - 1
    by1 = base - lh + (0 if lh else 0)
    by0 = by1 - bh + 1 + bob
    hx0 = cx - hw // 2 + lean + k
    hx1 = hx0 + hw - 1
    hy1 = by0 - 1
    hy0 = hy1 - hh + 1
    # ---- 망토 (몸 뒤)
    if "cape" in marks:
        cape = spec["armor"]
        cv.rect(bx0 - 2 * k, by0, bx0, base - (1 if lh else 0) + (0 if lh else 0), cape)
        cv.rect(bx0 - 2 * k, by0, bx0 - 2 * k, base - 1, dark(cape))
    # ---- 화살통 (등)
    if "quiver" in marks:
        cv.rect(bx0 - 2 * k, by0 - k, bx0 - k, by0 + 3 * k, WOOD_D)
        cv.dot(bx0 - 2 * k, by0 - 2 * k, WHITE)
        cv.dot(bx0 - k, by0 - 2 * k, RED)
    # ---- 다리 / 옷자락
    if lh > 0:
        step = pose.get("legs", -1)
        lw = max(2, bw // 2 - 1)
        if robe:
            sway = (0, 1, 0, -1)[step] if step >= 0 else 0
            cv.rect(bx0 + sway, by1 + 1, bx1 + sway, base - 1, cloth)
            cv.rect(bx0 + sway, base, bx1 + sway, base, cloth_d)
            cv.rect(bx0 + sway, by1 + 1, bx0 + sway, base, cloth_d)
        else:
            back_dx, front_dx, lift_b, lift_f = ((0, 0, 0, 0), (-1, 1, 0, 0), (0, 0, 1, 0), (1, -1, 0, 0), (0, 0, 0, 1))[step + 1]
            for x0, lift in ((bx0 + back_dx, lift_b), (bx1 - lw + 1 + front_dx, lift_f)):
                cv.rect(x0, by1 + 1, x0 + lw - 1, base - 1 - lift, spec["pants"])
                cv.rect(x0, base - lift, x0 + lw, base - lift, dark(spec["pants"], 0.6))  # 신발 (앞으로 1칸)
    # ---- 몸통
    cv.rect(bx0, by0, bx1, by1, cloth)
    cv.rect(bx0, by0, bx0, by1, cloth_d)
    if spec["hero"] or spec["hat"] in ("helmet", "helmet_big", "helmet_plume"):
        cv.rect(bx0 + 1, by0, bx1, by0 + max(1, bh // 3), spec["armor"])        # 어깨 갑옷
    cv.rect(bx0, by0 + bh * 2 // 3, bx1, by0 + bh * 2 // 3, spec["sash"])        # 허리띠 = 분류색 / 금
    if "bells" in marks:
        cv.dot(bx0 + 1, by0 + bh * 2 // 3 + 1, GOLD)
        cv.dot(bx1 - 1, by0 + bh * 2 // 3 + 1, GOLD)
    # ---- 머리
    cv.rect(hx0, hy0, hx1, hy1, SKIN)
    for x, y in ((hx0, hy0), (hx1, hy0), (hx0, hy1), (hx1, hy1)):
        cv.dot(x, y, (0, 0, 0, 0))
    cv.rect(hx0 + 1, hy1, hx1 - 1, hy1, SKIN_D)                                   # 턱 그늘
    hair = spec["hair"]
    back = max(2, hw * 3 // 10)
    cv.rect(hx0, hy0 + 1, hx0 + back - 1, hy1 - 1, hair)                           # 뒷머리
    cv.rect(hx0 + 1, hy0, hx1 - 1, hy0 + max(1, hh // 5), hair)                     # 윗머리
    ey = hy0 + hh // 2 + (0 if hh % 2 else 0)
    for ex in (hx1 - 1 * k - (k - 1), hx1 - 3 * k - (k - 1)):
        cv.rect(ex, ey, ex + k - 1, ey + k - 1, EYE)
    draw_hat(cv, spec, hx0, hy0, hx1, hy1, hw, hh, k)
    # ---- 표식: 수염 · 안대
    if "eye_patch" in marks:
        ex = hx1 - 1 * k - (k - 1)
        cv.rect(ex - 1, ey - 1, ex + k, ey + k, BLACK)
        cv.rect(hx0, ey - 1, ex - 1, ey - 1, BLACK)
    beard = None
    if "long_beard" in marks:
        beard = BLACK
    if "long_beard_white" in marks:
        beard = WHITE
    if beard:
        cv.rect(hx1 - 4 * k, hy1, hx1 - k, hy1 + 4 * k, beard)
        cv.rect(hx1 - 3 * k, hy1 + 4 * k, hx1 - 2 * k, hy1 + 5 * k, beard)
    if "short_beard" in marks:
        cv.rect(hx1 - 4 * k, hy1, hx1 - k, hy1, BLACK)
        cv.rect(hx1 - 3 * k, hy1 + 1, hx1 - 2 * k, hy1 + k, BLACK)
    if "spiky_beard" in marks:
        cv.rect(hx1 - 5 * k, hy1 - k, hx1, hy1, BLACK)
        for i in range(0, 6 * k, 2):
            cv.dot(hx1 - i, hy1 + 1, BLACK)
        cv.dot(hx1 + 1, hy1 - k, BLACK)
    return {"bx0": bx0, "bx1": bx1, "by0": by0, "by1": by1, "hx0": hx0, "hx1": hx1, "hy0": hy0, "hy1": hy1, "k": k}


def draw_hat(cv, spec, hx0, hy0, hx1, hy1, hw, hh, k):
    hat = spec["hat"]
    marks = spec["marks"]
    arm, arm_d, arm_l = spec["armor"], dark(spec["armor"]), light(spec["armor"])
    top = hy0 + hh // 2 - 1
    if hat in ("helmet", "helmet_big", "helmet_plume", "tiger_helmet"):
        col = rgb("#e0a030") if hat == "tiger_helmet" else arm
        cv.rect(hx0, hy0, hx1, top, col)
        cv.rect(hx0, hy0, hx0 + 2 * k - 1, hy1 - k, col)                 # 뒷목 가리개
        cv.rect(hx0 + 1, hy0 - 1, hx1 - 1, hy0 - 1, col)
        cv.rect(hx0 + 2 * k, hy0, hx1 - k, hy0, light(col))                # 윗면 빛
        cv.rect(hx0, top, hx1 + (k if hat != "tiger_helmet" else 0), top, dark(col))   # 챙
        cv.rect((hx0 + hx1) // 2, hy0 - 2 * k, (hx0 + hx1) // 2 + k - 1, hy0 - 2, dark(col))  # 꼭지
        if hat == "helmet_big":
            cv.rect(hx1 - k, top, hx1, hy1 - k, col)                       # 볼 가리개
        if hat == "helmet_plume":
            cv.rect((hx0 + hx1) // 2 - k, hy0 - 4 * k, (hx0 + hx1) // 2 + k, hy0 - 2 * k, RED)
            cv.rect(hx0, hy0 - 3 * k, (hx0 + hx1) // 2 - k, hy0 - 2 * k, RED)
        if hat == "tiger_helmet":
            cv.rect(hx0 + k, hy0 - 2 * k, hx0 + 2 * k, hy0 - 1, col)       # 귀
            cv.rect(hx1 - 2 * k, hy0 - 2 * k, hx1 - k, hy0 - 1, col)
            for x in range(hx0 + 2 * k, hx1, 3 * k):
                cv.rect(x, hy0, x + k - 1, top - 1, BLACK)                 # 줄무늬
    elif hat == "cap":
        cv.rect(hx0, hy0, hx1, hy0 + 2 * k, spec["sash"])
        cv.rect(hx0 + 1, hy0 - 1, hx1 - 1, hy0 - 1, spec["sash"])
        cv.rect(hx1, hy0 + 2 * k, hx1 + 2 * k, hy0 + 2 * k, dark(spec["sash"]))    # 앞챙
    elif hat in ("bandana", "headband"):
        band = RED if hat == "bandana" else WHITE
        cv.rect(hx0, hy0 + 2 * k, hx1, hy0 + 2 * k + k - 1, band)
        cv.rect(hx0 - 2 * k, hy0 + 2 * k, hx0 - 1, hy0 + 3 * k, band)             # 뒤로 날리는 끈
        cv.rect(hx0 - 2 * k, hy0 + 4 * k, hx0 - 2 * k, hy0 + 4 * k, band)
    elif hat in ("scholar", "scholar_hat"):
        cv.rect(hx0 + 2 * k, hy0 - 3 * k, hx1 - k, hy0, BLACK)
        cv.rect(hx0 + k, hy0, hx1, hy0 + k - 1, BLACK)
        if hat == "scholar_hat":
            cv.rect(hx0 + 3 * k, hy0 - 3 * k, hx1 - 2 * k, hy0 - 3 * k, GOLD)
    elif hat == "hat_soft":
        cv.rect(hx0, hy0, hx1, hy0 + 2 * k, arm)
        cv.rect(hx0 + 1, hy0 - 1, hx1 - 1, hy0 - 1, arm)
        cv.rect(hx0 - k, hy0 + 2 * k, hx0 + 2 * k - 1, hy1 - k, arm)               # 뒤로 늘어진 두건
        cv.rect(hx0, hy0 + 2 * k, hx1, hy0 + 2 * k, arm_d)
    elif hat == "yellow":
        y = rgb("#e0b030")
        cv.rect(hx0, hy0, hx1, hy0 + 3 * k - 1, y)
        cv.rect(hx0 + 1, hy0 - 1, hx1 - 1, hy0 - 1, y)
        cv.rect(hx0 - 2 * k, hy0 + 2 * k, hx0 - 1, hy0 + 4 * k, y)                 # 매듭
        cv.rect(hx0, hy0 + 3 * k - 1, hx1, hy0 + 3 * k - 1, dark(y))
    elif hat == "crown":
        cv.rect(hx0 + k, hy0 - k, hx1 - k, hy0, GOLD)
        for x in range(hx0 + k, hx1 - k + 1, 2 * k + 1):
            cv.rect(x, hy0 - 3 * k, x + k - 1, hy0 - k, GOLD)
        cv.dot((hx0 + hx1) // 2, hy0 - 1, RED)
    elif hat == "hair_bun":
        cv.rect(hx0, hy0 - 3 * k, hx0 + 3 * k, hy0 - 1, spec["hair"])
        cv.rect(hx0 + 3 * k + 1, hy0 - 2 * k, hx0 + 5 * k, hy0 - 2 * k, GOLD)      # 비녀
    elif hat == "bare_head":
        cv.rect(hx0 + 1, hy0, hx1 - 1, hy0 + max(1, hh // 5), SKIN)
        cv.rect(hx0, hy0 + 2 * k, hx0 + k, hy1 - 2 * k, spec["hair"])
    if "pheasant_feathers" in marks:
        for off in (0, 2 * k):
            cv.line(hx0 + 3 * k + off, hy0 - 2, hx0 - k + off, hy0 - 6 * k, RED, k)
            cv.dot(hx0 - k + off, hy0 - 6 * k - 1, GOLD)
    if "feather" in marks:
        cv.line(hx0 + 2 * k, hy0 - 1, hx0 + k, hy0 - 4 * k, WHITE, k)
        cv.dot(hx0 + k, hy0 - 4 * k - 1, RED)


# ------------------------------------------------------------------ 무기
def draw_weapon(cv, spec, b, phase, right):
    """b = draw_figure 가 돌려준 몸 자리. right = 칸의 오른쪽 끝 도트."""
    w = spec["weapon"]
    k = b["k"]
    hx = b["bx1"] + 2          # 손
    hy = b["by0"] + 2
    arm = spec["cloth"] if not spec["hero"] else spec["armor"]
    wl = 1.5 if spec.get("boss") else 1.0                   # 보스는 무기도 길다
    pole = ("spear", "halberd", "longspear", "lance", "guandao", "snake_spear", "fangtian")
    if w in pole:
        length = {"longspear": 22, "lance": 20, "spear": 17, "halberd": 17, "guandao": 17, "snake_spear": 18, "fangtian": 18}[w]
        length = int(length * wl)
        if phase == "idle":      # 세워 든다
            x0, y0, x1, y1 = hx, hy + 5, hx + 1, hy + 5 - length
        elif phase == "wind":    # 뒤로 당김
            x0, y0, x1, y1 = hx - 8, hy + 3, hx - 8 + int(length * 0.92), hy - 4
        elif phase == "strike":  # 곧게 뻗음
            x0, y0, x1, y1 = hx - 4, hy + 1, min(right, hx - 4 + length), hy + 1
        else:                    # 돌아옴
            x0, y0, x1, y1 = hx - 5, hy + 3, hx - 5 + int(length * 0.85), hy - 3
        cv.line(x0, y0, x1, y1, WOOD)
        tip_blade(cv, w, x1, y1, x1 - x0, y1 - y0)
        cv.dot(hx - (0 if phase == "idle" else 1), hy + (2 if phase == "idle" else 1), SKIN)
        cv.line(b["bx1"], b["by0"] + 1, hx - 1, hy + 1, arm)
    elif w in ("sword", "jian", "club"):
        blade = WOOD if w == "club" else STEEL
        thick = 2 if w == "club" else 1
        n = int((7 if w != "club" else 6) * wl)
        thick = int(thick * wl + 0.5)
        if phase == "idle":
            pts = (hx, hy + 1, hx + 1, hy + 1 - n)
        elif phase == "wind":
            pts = (hx - 2, hy - 1, hx - 6, hy - 1 - n + 2)
        elif phase == "strike":
            pts = (hx, hy + 1, min(right, hx + n + 1), hy + 2)
        else:
            pts = (hx, hy + 2, hx + n - 2, hy + 5)
        cv.line(pts[0], pts[1], pts[2], pts[3], blade, thick)
        if w != "club":
            cv.dot(pts[2], pts[3], WHITE)
            cv.rect(pts[0] - 1, pts[1], pts[0] + 1, pts[1], GOLD if w == "jian" else WOOD_D)
        cv.line(b["bx1"], b["by0"] + 1, pts[0] - 1, pts[1], arm)
        cv.dot(pts[0], pts[1] + 1, SKIN)
    elif w in ("sword_shield", "axe_shield", "vine_shield"):
        # 뒤에서 휘두르는 무기
        if phase == "idle":
            pts = (hx - 1, hy, hx, hy - 6)
        elif phase == "wind":
            pts = (hx - 3, hy - 1, hx - 7, hy - 6)
        elif phase == "strike":
            pts = (hx, hy, min(right, hx + 7), hy)
        else:
            pts = (hx, hy + 1, hx + 5, hy + 3)
        cv.line(pts[0], pts[1], pts[2], pts[3], WOOD if w == "axe_shield" else STEEL)
        if w == "axe_shield":
            cv.rect(pts[2] - 1, pts[3] - 1, pts[2] + 1, pts[3] + 2, STEEL)
            cv.dot(pts[2] + 1, pts[3], WHITE)
        else:
            cv.dot(pts[2], pts[3], WHITE)
        # 앞에 든 방패 (몸 절반을 가린다)
        sx = b["bx1"] - 1 + (1 if phase == "strike" else 0)
        sy = b["by0"]
        if w == "vine_shield":
            cv.rect(sx, sy, sx + 4, sy + 6, rgb("#6a7a3a"))
            for i in range(0, 7, 2):
                cv.rect(sx, sy + i, sx + 4, sy + i, rgb("#8a9a4a"))
            cv.rect(sx + 2, sy + 2, sx + 2, sy + 4, WOOD_D)
        else:
            col = spec["sash"] if not spec["hero"] else spec["cloth"]
            cv.rect(sx, sy, sx + 4, sy + 6, STEEL_D)
            cv.rect(sx + 1, sy + 1, sx + 3, sy + 5, col)
            cv.dot(sx + 2, sy + 3, GOLD)
    elif w == "bow":
        bx = hx + 2
        pull = {"idle": 0, "wind": 3, "strike": 0, "recover": 1}[phase]
        for i, dx in enumerate((0, 1, 2, 2, 2, 2, 2, 1, 0)):
            cv.dot(bx + dx, hy - 4 + i, WOOD)
        cv.line(bx, hy - 4, bx - pull, hy, WHITE)
        cv.line(bx - pull, hy, bx, hy + 4, WHITE)
        if phase == "wind":
            cv.line(bx - pull, hy, bx + 3, hy, WOOD_D)
            cv.dot(bx + 4, hy, STEEL)
        if phase == "strike":
            cv.line(min(right - 4, bx + 2), hy, min(right - 1, bx + 5), hy, WOOD_D)
            cv.dot(min(right, bx + 6), hy, WHITE)
        cv.line(b["bx1"], b["by0"] + 1, bx - 1, hy, arm)
        cv.dot(bx - pull, hy, SKIN)
    elif w == "crossbow":
        kick = {"idle": 0, "wind": -1, "strike": 1, "recover": 0}[phase]
        cv.line(hx - 2 + kick, hy + 1, hx + 4 + kick, hy + 1, WOOD, 2)
        for dy in (-3, -2, -1, 0, 1, 2, 3, 4):
            cv.dot(hx + 4 + kick + (0 if abs(dy - 0.5) < 3 else -1), hy + dy, STEEL_D)
        if phase != "strike":
            cv.line(hx + kick, hy, hx + 4 + kick, hy, WHITE)
        else:
            cv.line(min(right - 3, hx + 6), hy + 1, min(right, hx + 9), hy + 1, WHITE)
        cv.line(b["bx1"], b["by0"] + 1, hx - 2 + kick, hy + 1, arm)
    elif w == "sling":
        if phase == "idle":
            pts = (hx, hy + 2, hx + 1, hy - 5)
        elif phase == "wind":
            pts = (hx - 2, hy, hx - 7, hy - 5)
        elif phase == "strike":
            pts = (hx, hy, hx + 5, hy - 5)
        else:
            pts = (hx, hy + 1, hx + 4, hy + 1)
        cv.line(pts[0], pts[1], pts[2], pts[3], WOOD)
        cv.rect(pts[2] - 1, pts[3] - 1, pts[2], pts[3], WOOD_D)                    # 줄 주머니
        stone = (pts[2], pts[3] - 2) if phase != "strike" else (min(right - 1, pts[2] + 4), pts[3] - 3)
        cv.rect(stone[0] - 1, stone[1] - 1, stone[0], stone[1], STEEL_D)
        cv.line(b["bx1"], b["by0"] + 1, pts[0] - 1, pts[1], arm)
    elif w in ("staff_fire", "staff_thunder"):
        orb = rgb("#ff8a3a") if w == "staff_fire" else rgb("#ffe14a")
        tilt = {"idle": 0, "wind": -2, "strike": 4, "recover": 2}[phase]
        cv.line(hx, hy + 6, hx + tilt, hy - 7, WOOD)
        ox, oy = hx + tilt, hy - 8
        cv.rect(ox - 1, oy - 1, ox + 1, oy + 1, orb)
        cv.dot(ox, oy, WHITE)
        if phase == "strike":                                                       # 구슬이 번쩍
            for dx, dy in ((2, -2), (3, 0), (2, 2), (-2, -2)):
                cv.dot(min(right, ox + dx), oy + dy, orb)
        cv.line(b["bx1"], b["by0"] + 1, hx - 1, hy + 1, arm)
        cv.dot(hx, hy + 2, SKIN)
    elif w == "gourd":
        lift = {"idle": 0, "wind": 1, "strike": -4, "recover": -2}[phase]
        gx, gy = hx + 1, hy + 1 + lift
        cv.rect(gx - 1, gy, gx + 1, gy + 2, rgb("#68a04e"))
        cv.rect(gx, gy - 2, gx, gy - 1, rgb("#68a04e"))
        cv.dot(gx, gy - 3, WOOD)
        if phase == "strike":
            cv.dot(gx + 2, gy - 4, rgb("#7cff7c"))
            cv.dot(gx + 3, gy - 2, rgb("#7cff7c"))
        cv.line(b["bx1"], b["by0"] + 1, gx - 2, gy + 1, arm)
    elif w in ("fan", "ribbon_fan"):
        col = WHITE if w == "fan" else rgb("#e88ab4")
        fwd = {"idle": 0, "wind": -2, "strike": 4, "recover": 2}[phase]
        fx, fy = hx + fwd, hy - (0 if phase != "strike" else 2)
        cv.rect(fx, fy - 3, fx + 3, fy, col)
        cv.dot(fx, fy - 3, (0, 0, 0, 0))
        cv.rect(fx, fy + 1, fx, fy + 2, WOOD)
        cv.dot(fx + 3, fy - 3, dark(col, 0.8))
        cv.line(b["bx1"], b["by0"] + 1, fx - 1, fy + 1, arm)


def tip_blade(cv, w, x, y, dx, dy):
    """자루 끝의 날. (dx, dy) = 자루 방향."""
    up = abs(dy) > abs(dx)
    sx = 1 if dx >= 0 else -1
    if w in ("spear", "longspear", "lance", "snake_spear"):
        if up:
            cv.rect(x - 1, y - 1, x + 1, y - 1, STEEL)
            cv.rect(x, y - 3, x, y - 2, STEEL)
            cv.dot(x, y - 3, WHITE)
            if w == "snake_spear":
                cv.dot(x + 1, y - 3, STEEL)
                cv.dot(x - 1, y - 4, STEEL)
            cv.dot(x - 1, y + 1, RED)
        else:
            cv.rect(x, y - 1, x, y + 1, STEEL)
            cv.rect(x + sx, y, x + 2 * sx, y, STEEL)
            cv.dot(x + 2 * sx, y, WHITE)
            if w == "snake_spear":
                cv.dot(x + 2 * sx, y - 1, STEEL)
            cv.dot(x - 2 * sx, y + 1, RED)
    elif w in ("halberd", "fangtian", "guandao"):
        if up:
            cv.rect(x, y - 3, x, y, STEEL)
            cv.rect(x + 1, y - 2, x + 2, y, STEEL)            # 초승달 날
            cv.dot(x + 2, y - 2, WHITE)
            if w == "fangtian":
                cv.rect(x - 2, y - 2, x - 1, y - 1, STEEL)
            if w == "guandao":
                cv.rect(x + 1, y - 4, x + 2, y - 3, STEEL)
                cv.dot(x - 1, y + 1, RED)
        else:
            cv.rect(x, y, x + 3 * sx, y, STEEL)
            cv.rect(x + sx, y - 2, x + 2 * sx, y - 1, STEEL)
            cv.dot(x + 3 * sx, y, WHITE)
            if w == "fangtian":
                cv.rect(x + sx, y + 1, x + 2 * sx, y + 2, STEEL)
            if w == "guandao":
                cv.rect(x + 2 * sx, y - 3, x + 3 * sx, y - 2, STEEL)


# ------------------------------------------------------------------ 말
def draw_horse(cv, spec, base, step):
    heavy = spec["mount"] == "heavy"
    coat = rgb("#f0ece0") if spec.get("white_horse") else (rgb("#8a6a52") if heavy else rgb("#b0825a"))
    coat_d = dark(coat)
    mane = rgb("#3a2a22") if not spec.get("white_horse") else rgb("#c8c0b0")
    by0, by1 = base - 12, base - 6
    # 다리 4개 (걷기: 번갈아 든다)
    lifts = ((0, 0, 0, 0), (2, 0, 0, 2), (0, 0, 0, 0), (0, 2, 2, 0))[step if step >= 0 else 0]
    for i, x in enumerate((6, 9, 18, 21)):
        lift = lifts[i]
        cv.rect(x, by1 + 1, x + 1, base - 1 - lift, coat_d if i in (0, 2) else coat)
        cv.rect(x, base - lift, x + 1, base - lift, BLACK)
    cv.rect(5, by0, 23, by1, coat)                                   # 몸
    cv.rect(5, by1, 23, by1, coat_d)
    cv.rect(2, by0, 4, by0 + 6, mane)                                # 꼬리
    cv.rect(21, by0 - 5, 24, by0 + 1, coat)                          # 목
    cv.rect(20, by0 - 5, 20, by0, mane)                              # 갈기
    cv.rect(23, by0 - 8, 29, by0 - 4, coat)                          # 머리
    cv.rect(27, by0 - 5, 29, by0 - 4, coat_d)                        # 주둥이
    cv.rect(23, by0 - 10, 24, by0 - 9, coat)                         # 귀
    cv.dot(26, by0 - 7, EYE)
    cv.line(24, by0 - 5, 20, by0 + 1, RED)                           # 고삐
    if heavy:
        arm = spec["armor"]
        cv.rect(6, by0, 22, by1 - 1, arm)                            # 마갑
        cv.rect(6, by1 - 1, 22, by1 - 1, dark(arm))
        for x in range(8, 22, 4):
            cv.dot(x, by0 + 2, light(arm))
        cv.rect(24, by0 - 8, 28, by0 - 7, arm)                       # 말 투구
        cv.rect(21, by0 - 4, 24, by0 - 1, arm)
    else:
        cv.rect(10, by0, 15, by0 + 1, spec["cloth"])                 # 안장 깔개
    return by0


def render(spec, phase="idle", bob=0, legs=-1):
    """한 장을 도트 크기로 그린다 (테두리 포함)."""
    if spec.get("mount"):
        W, H = 32, 28
        cv = Cv(W, H)
        base = H - 1
        back = draw_horse(cv, spec, base, legs) + bob
        lean = {"idle": 0, "wind": -1, "strike": 1, "recover": 0}[phase]
        b = draw_figure(cv, spec, RIDER, 13, back - 1, {"lean": lean})
        cv.rect(12, back, 13, back + 4, spec["pants"])               # 말 옆구리의 다리
        cv.rect(12, back + 5, 14, back + 5, dark(spec["pants"], 0.6))
        draw_weapon(cv, spec, b, phase, W - 1)
        return cv.outlined()
    if spec.get("boss"):
        W, H, d, cx = 40, 40, BOSS, 15
    elif spec.get("big"):
        W, H, d, cx = 32, 32, BIG, 13
    elif spec.get("small"):
        W, H, d, cx = 24, 24, SMALL, 10
    else:
        W, H, d, cx = 24, 24, FOOT, 10
    cv = Cv(W, H)
    lean = {"idle": 0, "wind": -1, "strike": 1, "recover": 0}[phase]
    b = draw_figure(cv, spec, d, cx, H - 1, {"bob": bob, "lean": lean, "legs": legs})
    draw_weapon(cv, spec, b, phase, W - 1)
    return cv.outlined()


def bust(spec):
    """얼굴 아이콘 32 x 32 도트: 머리와 어깨."""
    cv = Cv(32, 32)
    s = dict(spec)
    s["marks"] = [m for m in spec["marks"] if m != "quiver"]
    draw_figure(cv, s, BUST, 14, 31, {})
    return cv.outlined()


def up(im, k=DOT):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def save_unit(uid, spec, art):
    frames = {
        "idle": [render(spec, "idle", 0), render(spec, "idle", 1)],
        "run": [render(spec, "idle", i % 2, i) for i in range(4)],
        "attack": [render(spec, "wind"), render(spec, "strike"), render(spec, "recover")],
    }
    d = os.path.join(UNITS, uid)
    if os.path.isdir(d):
        shutil.rmtree(d)
    for act, lst in frames.items():
        os.makedirs(os.path.join(d, act))
        for i, im in enumerate(lst):
            up(im).save(os.path.join(d, act, "%03d.png" % i))
    w, h = frames["idle"][0].size
    face = up(bust(spec))
    face.save(os.path.join(PORTRAITS, uid + ".png"))
    face.save(os.path.join(PORTRAITS, uid + "_head.png"))
    if spec["hero"] and not spec.get("boss"):
        up(frames["idle"][0], 16).save(os.path.join(PORTRAITS, uid + "_lihui.png"))   # 임시: 대기 그림을 크게
    art[uid] = {
        "dir": "res://assets/units/" + uid,
        "actions": {"idle": {"frames": 2, "fps": 3.0}, "run": {"frames": 4, "fps": 8.0}, "attack": {"frames": 3, "fps": 10.0}},
        "alias": {"idle": "idle", "walk": "run", "run": "run", "attack": "attack", "skill": "attack", "hit": "idle", "die": "idle"},
        "frame_w": w * DOT, "frame_h": h * DOT, "target_h": h * DOT,
        "portrait": "res://assets/portraits/%s.png" % uid, "head": "res://assets/portraits/%s_head.png" % uid,
        "illustration": "res://assets/portraits/%s_lihui.png" % uid if spec["hero"] and not spec.get("boss") else "",
        "_source": "tools/draw_units24.py",
    }
    return frames


def main():
    specs = build_specs()
    os.makedirs(UNITS, exist_ok=True)
    os.makedirs(PORTRAITS, exist_ok=True)
    for f in os.listdir(PORTRAITS):                                  # 예전 그림(64칸)과 그 import 파일을 지운다
        os.remove(os.path.join(PORTRAITS, f))
    art, shots = {}, {}
    for uid, spec in specs.items():
        shots[uid] = save_unit(uid, spec, art)
    json.dump(art, open(os.path.join(UNITS, "art.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    # 앱 아이콘: 관우 얼굴
    app = Image.new("RGBA", (64, 64), rgb("#121820"))
    app.alpha_composite(bust(specs["guanyu"]).resize((64, 64), Image.NEAREST), (0, 0))
    app.save(os.path.join(ROOT, "icon.png"))
    # 한눈에 보기: 캐릭터마다 대기 · 걷기 · 뻗음 + 얼굴 (도트 x4)
    ids = list(specs.keys())
    cols, cw, ch = 6, 32 * 3 * DOT + 40 * DOT + 24, 40 * DOT + 16
    sheet = Image.new("RGBA", (cols * cw, math.ceil(len(ids) / cols) * ch), rgb("#6b5a3e"))
    for i, uid in enumerate(ids):
        x0, y0 = (i % cols) * cw + 8, (i // cols) * ch + 8
        for j, im in enumerate((shots[uid]["idle"][0], shots[uid]["run"][1], shots[uid]["attack"][1])):
            big = up(im)
            sheet.alpha_composite(big, (x0 + j * 40 * DOT, y0 + 40 * DOT - big.height))
        sheet.alpha_composite(up(bust(specs[uid])), (x0 + 3 * 40 * DOT, y0))
    os.makedirs(os.path.join(ROOT, "design", "art"), exist_ok=True)
    sheet.save(os.path.join(ROOT, "design", "art", "drawn_units.png"))
    print("units", len(specs), "-> assets/units, assets/portraits, design/art/drawn_units.png")


if __name__ == "__main__":
    main()
