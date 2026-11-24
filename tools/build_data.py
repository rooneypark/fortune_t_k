#!/usr/bin/env python3
"""Builds data/*.json from the 기획서 tables (GDD v5, 메타-성장-과금, 콘텐츠-기획-v5, 장수-명단-v5).
Every number here is a tuning knob copied from the spec; change it here, re-run, commit the JSON.
Usage: python3 tools/build_data.py
"""
import json, os, math
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data")
os.makedirs(OUT, exist_ok=True)

def dump(name, obj):
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)

# ------------------------------------------------------------------ rules (GDD v5 §3, §7, §10)
rules = {
    "_source": "GDD v5 §3.2-3.6, §7, §10 / v5_rules.json",
    # 군량 (개편 §13): 계정의 것. 시간으로 차고(30분에 1, 2026-11-23: 5분 → 30분), 금으로 바로 채운다. 전투 안에서는 벌지 않는다.
    # 돌리기 1회 = 군량 2, 한 전투의 횟수 제한 없음 (군량이 있는 만큼, 2026-11-23). 재배치(꽝 줄을 위/아래로 한 칸) = 군량 1, 횟수에 안 든다.
    # 재배치는 꽝 칸이 남아 있는 동안 여러 번 (nudges_per_spin: 한 번 돌릴 때 최대 횟수, 0 = 제한 없음).
    "rice_max": 30, "rice_regen_sec": 1800, "rice_price": 300,
    "spin_rice": 2, "respin_rice": 1, "nudges_per_spin": 0,
    # 로비 치료 (2026-11-23): 부대에 의원이 있으면 로비에서 tick초마다 의원 한 명이 가장 다친 유닛을 amount만큼 치료
    "army_heal_tick": 2.0, "army_heal_amount": 0.05,
    # 웨이브 사이 회복 (2026-11-23): 웨이브를 깨면 살아 있는 아군이 최대 체력의 15%를 회복 (성은 10%). 쓰러진 장수는 30%로 일어난다.
    "wave_heal": 0.15,
    "continue_gold": 3000,
    "stage_back_gold": 500,  # 스테이지 되돌리기 한 번 값 (금)
    # 슬롯 3칸 (개편 §9.9): 칸마다 당첨 1/3, 당첨 칸의 5%는 장수 (2026-11-23: 10% -> 5%). 잭팟(3칸) = 돌린 군량 환급.
    "strip_length": 12, "slot_win_chance": 0.3333, "slot_hero_chance": 0.05,
    "jackpot_refund_rice": 2,
    "respawn_soldier": 5.0, "respawn_hero": 12.0, 
    "castle_hp": 1000, "castle_regen": 0.1, "castle_attack_interval": 1.2,
    # 전장 칸 늘리기는 금으로 (그 전투 동안만)
    "field_cap_base": 8, "field_cap_costs": [500, 700, 900, 1100, 1300, 1500],
    "waves_per_stage": 10, "judge_wave": 5,
    "speeds": [1, 2, 3],
    "energy_max": 100, "energy_per_attack": 20, "energy_per_hit": 5,
    "burn_tick": 0.5, "burn_ratio": 0.2, "slow_ratio": 0.45,
    "crit_mult": 2.0, "wave_scale": 1.08, "spawn_gap": 0.55,
    # 2026-11-23 개편: 편성·대기석·장수 칸 없음 (보유 전부가 릴에 나오고 뽑히면 전장에 선다)
    "soldiers_base": ["spear", "sword", "archer", "rider"],
    "field": {"left": 70, "right": 954, "spawn_top": 236, "line_y": 810, "ally_top": 830, "ally_bottom": 1150,
              "castle_y": 1150, "respawn_y": 1160},
    "visual_boost": 1.0,
}
dump("rules.json", rules)

# ------------------------------------------------------------------ units
classes = {
    "pike": {"name": "창병", "spd": 66, "aspd": 0.9, "icon": "class_inf", "hp_k": 1.05, "atk_k": 1.0, "range": 50, "color": "#c8a04a"},
    "inf": {"name": "보병", "spd": 70, "aspd": 0.9, "icon": "class_inf", "hp_k": 1.15, "atk_k": 0.95, "range": 44, "color": "#8a9aa8"},
    "arc": {"name": "궁병", "spd": 62, "aspd": 0.8, "icon": "class_arc", "hp_k": 0.75, "atk_k": 1.1, "range": 250, "color": "#6fbf5a"},
    "cav": {"name": "기병", "spd": 120, "aspd": 1.0, "icon": "class_cav", "hp_k": 0.95, "atk_k": 1.05, "range": 46, "color": "#d86a4a"},
    "str": {"name": "책사", "spd": 56, "aspd": 0.6, "icon": "class_str", "hp_k": 0.8, "atk_k": 1.15, "range": 230, "color": "#9a6ad8"},
}
factions = {
    "wei": {"name": "위", "color": "#3b74d6", "dark": "#1d3f7a"},
    "shu": {"name": "촉", "color": "#3aa65a", "dark": "#1d5a30"},
    "wu":  {"name": "오", "color": "#d6463b", "dark": "#7a1f1a"},
    "qun": {"name": "군웅", "color": "#8b4fd0", "dark": "#47246e"},
}
rarities = {
    "soldier": {"name": "병졸", "color": "#8a8f98", "start_star": 1, "tier": 1},
    # 장수 등급 B < A < S < SS (2026-11-22)
    "b":  {"name": "B", "color": "#9aa4b2", "start_star": 1, "tier": 1.5},
    "a":  {"name": "A", "color": "#3b8fe0", "start_star": 1, "tier": 2},
    "s":  {"name": "S", "color": "#a35be8", "start_star": 2, "tier": 3.5},
    "ss": {"name": "SS", "color": "#ffc93c", "start_star": 3, "tier": 5},
}
# fx = 타고난 특징 (전투가 그대로 읽는다, 속성과 같은 열쇠). ctr = 상성 줄 (§9.5).
soldiers = {
    # 창병
    "spear":     {"name": "창병", "cls": "pike", "tier": "basic", "hp": 300, "atk": 22, "def": 5, "art": "spear", "fx": {}, "desc": "긴 창으로 앞줄을 지킨다. 기병에게 강하다."},
    "halberd":   {"name": "극병", "cls": "pike", "tier": "elite", "hp": 340, "atk": 28, "def": 8, "art": "halberd", "fx": {"splash": 0.4}, "desc": "넓게 휘두른다. 주변 적에게 40% 피해."},
    "longspear": {"name": "장창병", "cls": "pike", "tier": "elite", "hp": 280, "atk": 26, "def": 6, "art": "spear", "hue": 0.12, "range": 78, "fx": {"full_hp_dmg": 1.2}, "desc": "한 칸 뒤에서 찌른다. 멀쩡한 적에게 20% 더 아프다."},
    # 보병
    "sword":     {"name": "검병", "cls": "inf", "tier": "basic", "hp": 320, "atk": 20, "def": 10, "art": "axe", "hue": 0.55, "aspd_k": 1.2, "fx": {}, "desc": "공격이 빠른 균형형."},
    "shield":    {"name": "방패병", "cls": "inf", "tier": "basic", "hp": 460, "atk": 12, "def": 25, "art": "shield", "fx": {"taunt": True, "ranged_resist": 0.6}, "desc": "적을 끌어당긴다. 원거리 피해 -40%."},
    "axe":       {"name": "도부수", "cls": "inf", "tier": "elite", "hp": 420, "atk": 24, "def": 18, "art": "axe", "fx": {"armor_break": 0.3}, "desc": "도끼와 방패. 맞은 적 방어 -30%."},
    "vine":      {"name": "등갑병", "cls": "inf", "tier": "elite", "hp": 400, "atk": 18, "def": 22, "art": "shield", "hue": 0.3, "fx": {"dmg_taken": 0.75, "burn_taken": 1.5}, "desc": "등나무 갑옷. 받는 피해 -25%, 불에는 50% 더 아프다."},
    # 궁병
    "archer":    {"name": "궁병", "cls": "arc", "tier": "basic", "hp": 180, "atk": 24, "def": 0, "art": "archer", "fx": {}, "desc": "멀리서 쏜다. 붙으면 약하다."},
    "crossbow":  {"name": "노병", "cls": "arc", "tier": "elite", "hp": 200, "atk": 30, "def": 2, "art": "crossbow", "aspd_k": 0.75, "fx": {"pierce": 0.7}, "desc": "느리지만 뒤의 적까지 뚫는다."},
    "catapult":  {"name": "투석병", "cls": "arc", "tier": "elite", "hp": 170, "atk": 40, "def": 0, "art": "crossbow", "hue": 0.08, "aspd_k": 0.55, "range": 300, "fx": {"splash": 0.5}, "desc": "아주 느리고 넓게 터진다."},
    # 기병
    "rider":     {"name": "경기병", "cls": "cav", "tier": "basic", "hp": 250, "atk": 26, "def": 5, "art": "rider", "fx": {"backline": True}, "desc": "적 궁병과 요술사를 먼저 노린다."},
    "heavy":     {"name": "중기병", "cls": "cav", "tier": "elite", "hp": 420, "atk": 30, "def": 15, "art": "heavy", "fx": {"first_hit": 1.8}, "desc": "느린 돌격. 첫 공격 1.8배."},
    "harcher":   {"name": "궁기병", "cls": "cav", "tier": "elite", "hp": 230, "atk": 22, "def": 4, "art": "rider", "hue": 0.6, "range": 200, "fx": {}, "desc": "달리면서 쏜다. 기병이면서 원거리."},
    # 책사(술사) — 병종마다 상성이 다르다
    "fire":      {"name": "화공술사", "cls": "str", "ctr": "fire", "tier": "elite", "hp": 200, "atk": 18, "def": 0, "art": "fire", "fx": {"splash": 0.5, "burn": 0.2}, "desc": "불꽃 범위 공격. 화상 2초."},
    "thunder":   {"name": "뇌공술사", "cls": "str", "ctr": "thunder", "tier": "elite", "hp": 200, "atk": 20, "def": 0, "art": "thunder", "fx": {"stun_chance": 0.15}, "desc": "번개. 15% 확률로 잠깐 기절."},
    "medic":     {"name": "의원", "cls": "str", "ctr": "medic", "tier": "elite", "hp": 190, "atk": 8, "def": 0, "art": "thunder", "hue": 0.35, "fx": {"heal_aura": 0.04}, "desc": "6초마다 주변 아군 체력 4% 회복."},
}
for _s in soldiers.values():
    _s.setdefault("ctr", _s["cls"])
    _s.setdefault("hue", 0)
# 상성 (§9.5): 공격하는 쪽 줄 -> 맞는 쪽 분류 -> 피해 배율. 없으면 1.
counters = {
    "pike": {"cav": 1.3, "arc": 0.8},
    "inf": {"arc": 1.3, "cav": 0.8},
    "arc": {"pike": 1.3, "inf": 0.8},
    "cav": {"inf": 1.3, "pike": 0.8},
    "fire": {"pike": 1.3, "inf": 1.3, "cav": 0.8},
    "thunder": {"cav": 1.3, "arc": 0.8},
    "medic": {},
}
# skills: type + numbers. name/desc from 장수-명단-v5 기술 방향.
S = lambda name, desc, typ, **kw: dict(name=name, desc=desc, type=typ, **kw)
roster = [
 # id, name, fac, grade, troop, skill, art, hue — 32명, 병종마다 3~4명 (2026-11-22 [제안])
 # 촉 7
 ("zhugeliang","제갈량","shu","ss","fire", S("팔진","적 무리를 묶어 느리게 하고 피해","aoe_target",radius=170,mult=1.6,slow=4.0), "",0),
 ("guanyu","관우","shu","s","spear", S("청룡참","앞의 적을 크게 벤다 (3배)","line",length=180,width=120,mult=3.0), "",0),
 ("zhaoyun","조운","shu","s","rider", S("단기 돌파","적진을 뚫고 지나가며 2배 피해","line",length=300,width=70,mult=2.0), "",0),
 ("zhangfei","장비","shu","a","halberd", S("장판교 호통","주변 적 2초 기절","stun_aoe",radius=130,mult=1.0,stun=2.0), "",0),
 ("huangzhong","황충","shu","a","archer", S("백발백중","가장 강한 적 저격 (4배)","snipe",mult=4.0), "",0),
 ("liubei","유비","shu","a","sword", S("인덕","체력이 가장 낮은 아군 35% 회복","heal_ally",heal=0.35), "",0),
 ("guanping","관평","shu","b","spear", S("부자 협공","앞의 적을 베어 2배 피해","line",length=150,width=100,mult=2.0), "",0),
 # 위 8
 ("caocao","조조","wei","ss","heavy", S("패왕의 호령","아군 전체 공격 +30% (5초)","ally_all",atk_mult=1.3,time=5.0), "",0),
 ("simayi","사마의","wei","s","heavy", S("매복","무작위 적 셋에게 낙석","random_strike",count=3,mult=2.2,radius=70), "",0),
 ("zhangliao","장료","wei","s","rider", S("요래 돌격","가장 많은 적에게 돌진","aoe_target",radius=140,mult=2.0), "",0),
 ("xiahoudun","하후돈","wei","a","spear", S("발목 분노","체력 30% 회복, 4초간 공격 +40%","self_buff",heal=0.3,atk_mult=1.4,time=4.0), "",0),
 ("xiahouyuan","하후연","wei","a","crossbow", S("질풍 사격","빠른 화살 연사 (5발)","multi_shot",count=5,mult=1.2), "",0),
 ("xuchu","허저","wei","a","axe", S("호치","받는 피해 크게 감소 (5초 -50%)","self_guard",dmg_taken=0.5,time=5.0), "",0),
 ("caoren","조인","wei","b","shield", S("철벽 수비","주변 아군 받는 피해 -20% (4초)","ally_aura",radius=160,dmg_taken=0.8,time=4.0), "",0),
 ("zhanghe","장합","wei","b","longspear", S("교묘한 진퇴","빠르게 베고 물러남 (2배)","snipe",mult=2.0), "",0),
 # 오 8
 ("sunce","손책","wu","ss","heavy", S("소패왕","처치할 때마다 공격 속도 상승 (6초간 +40%)","self_buff",aspd_mult=1.4,atk_mult=1.2,time=6.0,heal=0.1), "",0),
 ("sunquan","손권","wu","s","shield", S("강동 진형","주변 아군 받는 피해 -25% (4초)","ally_aura",radius=200,dmg_taken=0.75,time=4.0), "",0),
 ("zhouyu","주유","wu","s","fire", S("적벽 화공","넓은 범위 화상 (4초)","aoe_target",radius=150,mult=1.5,burn=4.0), "",0),
 ("luxun","육손","wu","s","fire", S("연영 화공","일렬로 불길","line",length=420,width=90,mult=1.8,burn=3.0), "",0),
 ("ganning","감녕","wu","a","axe", S("백기 야습","치명 일격 (3배)","snipe",mult=3.0), "",0),
 ("taishici","태사자","wu","a","harcher", S("신궁","관통 화살 (2.5배)","line",length=500,width=50,mult=2.5), "",0),
 ("huanggai","황개","wu","b","fire", S("고육계","체력을 써서 주변 적에게 화염","stun_aoe",radius=140,mult=1.6,stun=0.0,burn=3.0,self_cost=0.1), "",0),
 ("handang","한당","wu","b","archer", S("노장의 화살","가장 가까운 적 셋에게 화살","multi_shot",count=3,mult=1.3), "",0),
 # 군웅 9
 ("lvbu","여포","qun","ss","halberd", S("무쌍 돌격","일직선으로 돌진하며 큰 피해","line",length=360,width=110,mult=3.2), "",0),
 ("diaochan","초선","qun","s","thunder", S("경국","적 하나를 잠시 홀려 멈추게 함 (4초)","charm",time=4.0,mult=1.0), "",0),
 ("dongzhuo","동탁","qun","a","shield", S("폭정","주변 적 공격 감소, 자신 체력 회복","debuff_aoe",radius=160,enemy_atk=0.7,time=5.0,heal=0.25), "",0),
 ("yuanshao","원소","qun","a","catapult", S("사세삼공","아군 궁병 공격 상승 (6초)","ally_class",cls="arc",atk_mult=1.35,time=6.0), "",0),
 ("zhangjiao_h","장각","qun","b","thunder", S("태평요술","낙뢰 3발","random_strike",count=3,mult=1.8,radius=80,stun=0.8), "",0),
 ("menghuo","맹획","qun","b","vine", S("남만왕","받는 피해 감소 (5초 -40%)","self_guard",dmg_taken=0.6,time=5.0), "",0),
 ("huaman","화만","qun","b","crossbow", S("비도","가장 약한 적에게 2.5배","snipe",mult=2.5), "",0),
 ("zuoci","좌자","qun","b","thunder", S("둔갑","적 하나를 잠시 멈추게 함 (3초)","charm",time=3.0,mult=1.0), "",0),
 ("yuji","우길","qun","b","medic", S("부적","체력이 가장 낮은 아군 30% 회복","heal_ally",heal=0.3), "",0),
]
heroes = {}
for (hid, name, fac, rar, troop, skill, art, hue) in roster:
    art, hue = hid, 0  # 2026-11-22: 모든 장수가 자기 그림을 가진다 (tools/draw_units24.py)
    cls = soldiers[troop]["cls"]
    tier = rarities[rar]["tier"]
    c = classes[cls]
    hp = round((520 + 150 * tier) * c["hp_k"])
    atk = round((42 + 13 * tier) * c["atk_k"])
    df = 26 if cls in ("inf", "pike") else 20
    heroes[hid] = {"name": name, "fac": fac, "rarity": rar, "cls": cls, "troop": troop, "hp": hp, "atk": atk, "def": df,
                   "ctr": soldiers[troop]["ctr"],
                   "range": soldiers[troop].get("range", c["range"]) + (10 if cls in ("inf", "cav", "pike") else 20), "skill": skill, "art": art, "hue": hue}
# 속성: 분류 공통 2개 + 병종 고유 1개 (먹이 병종 기준). v = 레벨 1/2/3 값, fx = 전투가 읽는 열쇠.
def T(tid, name, fx, v, desc, **extra):
    d = {"id": tid, "name": name, "fx": fx, "v": v, "descs": [desc % x for x in extra.pop("show", v)]}
    d.update(extra)
    return d
pct = lambda xs: [round((x - 1) * 100) for x in xs]
cut = lambda xs: [round((1 - x) * 100) for x in xs]
traits = {
    "class": {
        "pike": [T("anti_cav", "대기병", "vs_cav", [1.15, 1.25, 1.35], "기병에게 주는 피해 +%d%%", show=[15, 25, 35]),
                 T("sturdy", "견고", "def_add", [10, 18, 25], "방어 +%d")],
        "inf": [T("tough", "강건", "hp", [1.12, 1.20, 1.28], "최대 체력 +%d%%", show=[12, 20, 28]),
                T("iron", "철벽", "dmg_taken", [0.92, 0.87, 0.82], "받는 피해 -%d%%", show=[8, 13, 18])],
        "arc": [T("longbow", "장궁", "range", [30, 50, 70], "사거리 +%d"),
                T("rapid", "속사", "aspd", [1.10, 1.17, 1.24], "공격 속도 +%d%%", show=[10, 17, 24])],
        "cav": [T("gallop", "질주", "spd", [1.2, 1.3, 1.4], "이동 속도 +%d%%", show=[20, 30, 40]),
                T("charge", "돌격", "first_hit", [1.5, 1.8, 2.1], "첫 공격 피해 ×%s", show=["1.5", "1.8", "2.1"])],
        "str": [T("wit", "지략", "energy", [1.2, 1.35, 1.5], "기력 획득 +%d%%", show=[20, 35, 50]),
                T("focus", "집중", "crit", [0.06, 0.10, 0.14], "치명타 확률 +%d%%", show=[6, 10, 14])],
    },
    "troop": {
        "spear": T("phalanx", "밀집", "phalanx", [1.10, 1.16, 1.22], "같은 병종이 옆에 있으면 공격 +%d%%", show=[10, 16, 22]),
        "halberd": T("sweep", "휩쓸기", "splash", [0.2, 0.3, 0.4], "주변 적에게 %d%% 피해", show=[20, 30, 40]),
        "longspear": T("firststrike", "선제", "full_hp_dmg", [1.15, 1.25, 1.35], "멀쩡한 적에게 피해 +%d%%", show=[15, 25, 35]),
        "sword": T("double", "연격", "double", [0.5, 0.7, 0.9], "20%% 확률로 한 번 더 공격 (피해 %d%%)", show=[50, 70, 90]),
        "shield": T("taunt", "도발", "taunt_guard", [0.95, 0.92, 0.89], "주변 적이 나를 노린다 · 받는 피해 -%d%%", show=[5, 8, 11]),
        "axe": T("sunder", "파갑", "armor_break", [0.15, 0.22, 0.30], "맞은 적 방어 -%d%%", show=[15, 22, 30]),
        "vine": T("vinearmor", "등갑", "ranged_resist", [0.85, 0.78, 0.70], "원거리 피해 -%d%%", show=[15, 22, 30]),
        "archer": T("aim", "정조준", "crit_dmg", [0.25, 0.40, 0.55], "치명타 피해 +%d%%", show=[25, 40, 55]),
        "crossbow": T("pierce", "관통", "pierce", [0.5, 0.7, 0.9], "화살이 뒤의 적 1명을 더 뚫는다 (피해 %d%%)", show=[50, 70, 90]),
        "catapult": T("blast", "폭발", "splash", [0.25, 0.35, 0.45], "공격이 주변에 %d%% 피해", show=[25, 35, 45]),
        "rider": T("raid", "기습", "backline", [1.10, 1.18, 1.26], "적 후열을 먼저 노린다 · 후열에게 피해 +%d%%", show=[10, 18, 26]),
        "heavy": T("trample", "짓밟기", "first_hit_stun", [0.5, 0.8, 1.1], "첫 공격에 맞은 적 %s초 기절", show=["0.5", "0.8", "1.1"]),
        "harcher": T("skirmish", "유격", "skirmish", [1.30, 1.45, 1.60], "공격한 뒤 2초 동안 이동 속도 +%d%%", show=[30, 45, 60]),
        "fire": T("burning", "화상", "burn", [0.15, 0.22, 0.30], "맞은 적이 2초 동안 공격력의 %d%% 피해", show=[15, 22, 30]),
        "thunder": T("shock", "감전", "stun_chance", [0.08, 0.12, 0.16], "%d%% 확률로 0.6초 기절", show=[8, 12, 16]),
        "medic": T("heal", "의술", "heal_aura", [0.03, 0.05, 0.07], "6초마다 주변 아군 체력 %d%% 회복", show=[3, 5, 7]),
    },
}
synergies = [
    {"id": "pike", "kind": "class", "key": "pike", "need": 3, "name": "창병", "desc": "창병 공격 +12%", "atk": 1.12},
    {"id": "inf", "kind": "class", "key": "inf", "need": 3, "name": "보병", "desc": "보병 받는 피해 -15%", "dmg_taken": 0.85},
    {"id": "arc", "kind": "class", "key": "arc", "need": 3, "name": "궁병", "desc": "궁병 공격 속도 +20%", "aspd": 1.2},
    {"id": "cav", "kind": "class", "key": "cav", "need": 2, "name": "기병", "desc": "기병 이동 +30%, 공격 +10%", "spd": 1.3, "atk": 1.1},
    {"id": "str", "kind": "class", "key": "str", "need": 2, "name": "책사", "desc": "책사 기력 획득 +40%", "energy": 1.4},
    {"id": "wei2", "kind": "faction", "key": "wei", "need": 2, "name": "위", "desc": "공격 +12%", "atk": 1.12},
    {"id": "wei4", "kind": "faction", "key": "wei", "need": 4, "name": "위 4", "desc": "공격 +25%", "atk": 1.116},
    {"id": "shu2", "kind": "faction", "key": "shu", "need": 2, "name": "촉", "desc": "받는 피해 -10%", "dmg_taken": 0.9},
    {"id": "shu4", "kind": "faction", "key": "shu", "need": 4, "name": "촉 4", "desc": "받는 피해 -20%", "dmg_taken": 0.889},
    {"id": "wu2", "kind": "faction", "key": "wu", "need": 2, "name": "오", "desc": "공격에 화상 (3초)", "burn_on_hit": 3.0},
    {"id": "wu4", "kind": "faction", "key": "wu", "need": 4, "name": "오 4", "desc": "화상 피해 2배", "burn_mult": 2.0},
    {"id": "qun2", "kind": "faction", "key": "qun", "need": 2, "name": "군웅", "desc": "치명타 +15%", "crit": 0.15},
    {"id": "qun4", "kind": "faction", "key": "qun", "need": 4, "name": "군웅 4", "desc": "치명타 +25%", "crit": 0.10},
]
bonds = [
    {"name": "도원결의", "heroes": ["liubei", "guanyu", "zhangfei"], "need": 3, "desc": "공격 +15%, 받는 피해 -10%", "atk": 1.15, "dmg_taken": 0.9},
    {"name": "도원 형제", "heroes": ["guanyu", "zhangfei"], "need": 2, "desc": "공격 +10%", "atk": 1.1},
    {"name": "오호대장", "heroes": ["guanyu", "zhangfei", "zhaoyun", "huangzhong"], "need": 3, "desc": "3명 공격 +10%", "atk": 1.1},
    {"name": "부자", "heroes": ["guanyu", "guanping"], "need": 2, "desc": "공격 +15%", "atk": 1.15},
    {"name": "수어지교", "heroes": ["liubei", "zhugeliang"], "need": 2, "desc": "기력 획득 +30%", "energy": 1.3},
    {"name": "위의 기둥", "heroes": ["caocao", "xiahoudun", "xiahouyuan", "caoren"], "need": 3, "desc": "체력 +15%", "hp": 1.15},
    {"name": "호위", "heroes": ["caocao", "xuchu"], "need": 2, "desc": "받는 피해 -15%", "dmg_taken": 0.85},
    {"name": "오자양장", "heroes": ["zhangliao", "zhanghe"], "need": 2, "desc": "이동 속도 +20%", "spd": 1.2},
    {"name": "소패왕과 대도독", "heroes": ["sunce", "zhouyu"], "need": 2, "desc": "공격 속도 +20%", "aspd": 1.2},
    {"name": "강동의 호랑이", "heroes": ["sunquan", "sunce"], "need": 2, "desc": "받는 피해 -8%", "dmg_taken": 0.92},
    {"name": "적벽의 불", "heroes": ["zhouyu", "huanggai", "luxun"], "need": 2, "desc": "화상 피해 +50%", "burn_mult": 1.5},
    {"name": "강동 명장", "heroes": ["ganning", "taishici", "handang"], "need": 2, "desc": "치명타 +20%", "crit": 0.2},
    {"name": "인중여포", "heroes": ["lvbu", "diaochan"], "need": 2, "desc": "공격 +30%", "atk": 1.3},
    {"name": "폭군과 명문", "heroes": ["dongzhuo", "yuanshao"], "need": 2, "desc": "체력 +20%", "hp": 1.2},
    {"name": "남만", "heroes": ["menghuo", "huaman"], "need": 2, "desc": "체력 +20%", "hp": 1.2},
    {"name": "방사", "heroes": ["zuoci", "yuji", "zhangjiao_h"], "need": 2, "desc": "기력 획득 +25%", "energy": 1.25},
    {"name": "태평도", "heroes": ["zhangjiao_h"], "need": 1, "soldier": "thunder", "soldier_need": 2, "desc": "기술 범위 +30%", "skill_radius": 1.3},
]
enemies = {
    "mob":    {"name": "황건 잡병", "hp": 120, "atk": 8, "spd": 55, "def": 0, "range": 40, "art": "enemy_mob"},
    "sword":  {"name": "황건 검병", "hp": 240, "atk": 16, "spd": 55, "def": 5, "range": 40, "art": "enemy_sword"},
    "spear":  {"name": "황건 창병", "hp": 220, "atk": 20, "spd": 55, "def": 5, "range": 46, "art": "enemy_spear", "vs_cav": 1.5},
    "archer": {"name": "황건 궁병", "hp": 170, "atk": 18, "spd": 55, "def": 0, "range": 220, "aspd": 0.8, "art": "enemy_archer"},
    "shield": {"name": "황건 방패병", "hp": 420, "atk": 12, "spd": 46, "def": 25, "range": 40, "ranged_resist": 0.5, "art": "enemy_shield"},
    "rider":  {"name": "황건 기병", "hp": 220, "atk": 18, "spd": 105, "def": 5, "range": 46, "beh": "assassin", "cls": "cav", "art": "enemy_rider"},
    "mage":   {"name": "요술사", "hp": 220, "atk": 10, "spd": 46, "def": 0, "range": 170, "aspd": 0.6, "beh": "support", "heal": 60, "art": "enemy_mage"},
    "brute":  {"name": "괴력 장수", "hp": 1600, "atk": 45, "spd": 46, "def": 10, "range": 50, "elite": True, "art": "enemy_brute"},
}
bosses = {
    "zhangjiao": {"name": "장각", "hp": 9000, "atk": 55, "spd": 28, "def": 20, "range": 200, "aspd": 0.7, "art": "enemy_zhangjiao", "scale": 1.0, "mech": "lightning", "rule": "6초마다 낙뢰를 떨어뜨린다"},
    "chengyuanzhi": {"name": "정원지", "hp": 4200, "atk": 48, "spd": 40, "def": 15, "range": 52, "art": "enemy_brute", "hue": 0.1, "scale": 1.25, "mech": "stomp", "rule": "주변을 내리찍어 아군을 기절시킨다"},
    "lvbu_b": {"name": "여포", "hp": 15000, "atk": 80, "spd": 60, "def": 30, "range": 60, "art": "zhaoyun", "hue": 0.78, "scale": 1.6, "mech": "stomp", "rule": "돌진해 주변을 쓸어 버린다"},
    "jiling": {"name": "기령", "hp": 24000, "atk": 90, "spd": 30, "def": 60, "range": 56, "art": "xiahoudun", "hue": 0.2, "scale": 1.6, "mech": "stomp", "rule": "단단한 방패 진형, 받는 피해 감소"},
    "yanwen": {"name": "안량·문추", "hp": 38000, "atk": 120, "spd": 44, "def": 40, "range": 60, "art": "guanyu", "hue": 0.78, "scale": 1.6, "mech": "stomp", "rule": "두 장수가 번갈아 돌격한다"},
    "caoren": {"name": "조인", "hp": 62000, "atk": 150, "spd": 30, "def": 80, "range": 56, "art": "xiahoudun", "hue": 0.62, "scale": 1.6, "mech": "stomp", "rule": "철벽: 받는 피해를 일부 되돌린다"},
    "xiahouyuan_b": {"name": "하후연", "hp": 90000, "atk": 200, "spd": 34, "def": 50, "range": 260, "art": "huangzhong", "hue": 0.6, "scale": 1.6, "mech": "lightning", "rule": "멀리서 화살비를 퍼붓는다"},
    "zhouyu_b": {"name": "주유", "hp": 110000, "atk": 230, "spd": 32, "def": 55, "range": 240, "aspd": 0.7, "art": "zhouyu", "scale": 1.6, "mech": "lightning", "rule": "멀리서 불벼락을 떨어뜨린다"},
    "menghuo_b": {"name": "맹획", "hp": 135000, "atk": 260, "spd": 42, "def": 70, "range": 56, "art": "menghuo", "scale": 1.6, "mech": "stomp", "rule": "주변을 내리찍어 아군을 기절시킨다"},
    "simayi_b": {"name": "사마의", "hp": 160000, "atk": 300, "spd": 50, "def": 75, "range": 60, "art": "simayi", "scale": 1.6, "mech": "lightning", "rule": "6초마다 낙뢰를 떨어뜨린다"},
    "caocao_b": {"name": "조조", "hp": 200000, "atk": 340, "spd": 54, "def": 90, "range": 60, "art": "caocao", "scale": 1.7, "mech": "stomp", "rule": "돌진해 주변을 쓸어 버린다"},
}
for _sid, _sd in soldiers.items():
    _sd["art"] = _sid
    _sd.pop("hue", None)
# 보스: 40도트 전용 그림 boss_<id> (tools/draw_units24.py). 그림 자체가 크므로 배율은 1.0.
for _bid in bosses:
    bosses[_bid]["art"] = "boss_" + _bid
    bosses[_bid]["scale"] = 1.0
    bosses[_bid].pop("hue", None)
units = {"_source": "GDD v5 §3.4b, §3.7 / 장수-명단-v5 / 콘텐츠-기획-v5 §3-5 / slice_units.json",
         "classes": classes, "factions": factions, "rarities": rarities, "soldiers": soldiers, "heroes": heroes,
         "traits": traits, "synergies": synergies, "bonds": bonds, "enemies": enemies,
         "bosses": bosses, "enemy_aspd": 0.85,
         "boss_mech": {"lightning": {"every": 6.0, "warn": 1.2, "radius": 90, "dmg": 140, "stun": 1.0},
                       "stomp": {"every": 7.0, "warn": 0.9, "radius": 150, "dmg": 120, "stun": 1.2}}}
# 적 분류 (상성, §9.5). 요술사는 화공 줄로 친다.
for _eid, _c in {"mob": "inf", "sword": "inf", "spear": "pike", "archer": "arc", "shield": "inf", "rider": "cav",
                 "mage": "str", "brute": "inf"}.items():
    enemies[_eid]["cls"] = _c
    enemies[_eid]["ctr"] = "fire" if _c == "str" else _c
    enemies[_eid].pop("vs_cav", None)
for _bid, (_c, _ctr) in {"zhangjiao": ("str", "thunder"), "chengyuanzhi": ("inf", "inf"), "lvbu_b": ("pike", "pike"),
                         "jiling": ("inf", "inf"), "yanwen": ("cav", "cav"), "caoren": ("inf", "inf"),
                         "xiahouyuan_b": ("arc", "arc"), "zhouyu_b": ("str", "fire"), "menghuo_b": ("inf", "inf"),
                         "simayi_b": ("cav", "cav"), "caocao_b": ("cav", "cav")}.items():
    bosses[_bid]["cls"] = _c
    bosses[_bid]["ctr"] = _ctr
units["counters"] = counters
# 보스 기본 능력치를 완만하게 (2026-11-23): 스테이지 배율(x1.2씩)이 따로 곱해지는데 보스 자체 수치도
# 9,000 -> 200,000으로 뛰어서 스테이지 3에서 막혔다. 처음은 쉽게: 스테이지마다 체력 +20%, 공격 +10%, 방어 30 이하.
for _i, _bid in enumerate(["zhangjiao", "lvbu_b", "jiling", "yanwen", "caoren", "xiahouyuan_b", "zhouyu_b", "menghuo_b", "simayi_b", "caocao_b"]):
    bosses[_bid]["hp"] = round(9000 * (1 + 0.2 * _i))
    bosses[_bid]["atk"] = round(55 * (1 + 0.1 * _i))
    bosses[_bid]["def"] = min(int(bosses[_bid]["def"]), 30)
dump("units.json", units)

# ------------------------------------------------------------------ stages (콘텐츠 §2)
waves_template = [
    {"list": [["mob", 6], ["sword", 2]]},
    {"list": [["sword", 6], ["mob", 5]]},
    {"list": [["sword", 7], ["spear", 3], ["archer", 3]]},
    {"list": [["shield", 4], ["sword", 6], ["archer", 5]]},
    {"list": [["sword", 10], ["archer", 4]], "flank": [["rider", 6]], "judge": True},
    {"list": [["shield", 6], ["archer", 6], ["mage", 2], ["spear", 5]]},
    {"list": [["brute", 1], ["sword", 10], ["rider", 4], ["mage", 2]]},
    {"list": [["brute", 2], ["shield", 6], ["archer", 8], ["mage", 2]]},
    {"list": [["brute", 2], ["sword", 12], ["archer", 6], ["mage", 3]], "flank": [["rider", 8]]},
    {"list": [["sword", 12], ["archer", 6], ["mage", 2]], "boss": "zhangjiao"},
]
stage_list = [
    {"id": 1, "name": "황건적의 난", "enemy": "황건적", "hue": 0.0, "boss": "zhangjiao"},
    {"id": 2, "name": "반동탁 연합", "enemy": "동탁군", "hue": 0.85, "boss": "lvbu_b"},
    {"id": 3, "name": "군웅할거", "enemy": "원술군", "hue": 0.55, "boss": "jiling"},
    {"id": 4, "name": "관도대전", "enemy": "원소군", "hue": 0.25, "boss": "yanwen"},
    {"id": 5, "name": "적벽대전", "enemy": "조조군", "hue": 0.62, "boss": "caoren"},
    {"id": 6, "name": "한중 쟁탈", "enemy": "위군", "hue": 0.4, "boss": "xiahouyuan_b"},
    {"id": 7, "name": "형주 공방", "enemy": "오군", "hue": 0.95, "boss": "zhouyu_b"},
    {"id": 8, "name": "남만 정벌", "enemy": "남만군", "hue": 0.3, "boss": "menghuo_b"},
    {"id": 9, "name": "북벌", "enemy": "위군 정예", "hue": 0.7, "boss": "simayi_b"},
    {"id": 10, "name": "천하통일", "enemy": "연합군", "hue": 0.5, "boss": "caocao_b"},
]
# 난이도 (스테이지-흡수-합성-개편 §3.1, §4): 적 세기 · 적 수 배율.
# 2026-11-23 모의 전투(tools/sim.gd)로 잡은 값: 보통 1.0이면 새 계정이 스테이지 1을 한 번도 못 깼다
# (런 안의 등급 배율 1.6 / 2.5가 없어졌기 때문). 처음은 쉽게: 보통 0.35, 전장 8칸, 스테이지마다 x1.2.
# 밸런스는 나중에 다시 잡는다 (민수 님).
difficulties = [
    {"id": 1, "name": "보통", "mult": 0.35, "count": 1.0},
    {"id": 2, "name": "어려움", "mult": 0.7, "count": 1.15},
    {"id": 3, "name": "지옥", "mult": 1.3, "count": 1.3},
]
stages = {"_source": "스테이지-흡수-합성-개편 §3.1, §4 (스테이지 10 × 난이도 3, 적 배율 1.2^(스테이지-1) × 난이도)",
          "stage_base": 1.32, "first_clear_gold": 2000,
          # 적 수 (2026-11-23): 병사가 무제한이 되어 적도 많이 나온다. 초반은 적게, 스테이지 · 웨이브가 갈수록 늘어난다.
          # 적 수 배율 = count_base x (1 + count_stage x (스테이지-1)) x (1 + count_wave x 웨이브 번호(0~9)) x 난이도 count
          "count_base": 1.0, "count_stage": 0.45, "count_wave": 0.05,
          "gold_per_wave": 100, "gold_victory": 500,
          "star_rules": ["클리어", "성 체력 50% 이상", "성 체력 90% 이상"],
          "recommended_power": 8000,
          "waves_template": waves_template, "stages": stage_list, "difficulties": difficulties}
dump("stages.json", stages)

# ------------------------------------------------------------------ meta (메타-성장-과금 §3-4)
treasure_names = {
 "weapon": {"common": ["낡은 창", "철검", "사냥활", "나무 방망이"], "rare": ["강철 장창", "환두대도", "각궁", "철퇴", "쌍검"],
            "epic": ["사모", "칠성검", "양유기의 활", "철태궁", "방천극 모조품"], "legend": ["청룡언월도", "장팔사모", "방천화극", "의천검", "고정도", "백우선"]},
 "armor": {"common": ["가죽 갑옷", "천 두건", "나무 방패", "짚신"], "rare": ["쇄자갑", "철투구", "등패", "전투화", "무명 망토"],
           "epic": ["명광개", "사자 투구", "철갑 망토", "호랑이 가죽 갑옷", "비늘 갑옷"], "legend": ["백은 갑옷", "서량 철갑", "적토마 안장", "강동 수군 갑옷"]},
 "charm": {"common": ["옥 구슬", "나무 부적", "작은 북", "호리병"], "rare": ["청동 인장", "병법 죽간", "향로", "비취 패", "깃발"],
           "epic": ["손자병법", "태평요술서", "옥새 모조품", "황금 사자상", "전국옥새 조각"], "legend": ["맹덕신서", "적벽 동남풍 부적", "팔진도"]},
}
exclusive = {"청룡언월도": "guanyu", "장팔사모": "zhangfei", "방천화극": "lvbu", "의천검": "caocao", "고정도": "sunquan",
             "백우선": "zhugeliang", "백은 갑옷": "zhaoyun", "팔진도": "zhugeliang"}
# 장비 (개편 §11): 칸 3개(무기 · 갑옷 · 장신구). 일반 · 희귀 = 일반 장비(능력치만),
# 영웅 · 전설 = 보물(능력치 + 특수 능력 하나). 특수 능력은 속성과 같은 열쇠(fx)를 쓴다.
gear_fx = {
    # 무기 보물
    "사모": ("splash", 0.25, "공격이 주변 적에게 25% 피해"),
    "칠성검": ("double", 0.6, "20% 확률로 한 번 더 공격 (피해 60%)"),
    "양유기의 활": ("pierce", 0.6, "공격이 뒤의 적 1명을 더 뚫는다 (피해 60%)"),
    "철태궁": ("range", 40, "사거리 +40"),
    "방천극 모조품": ("armor_break", 0.15, "맞은 적 방어 -15%"),
    "청룡언월도": ("splash", 0.45, "공격이 주변 적에게 45% 피해"),
    "장팔사모": ("full_hp_dmg", 1.35, "멀쩡한 적에게 피해 +35%"),
    "방천화극": ("armor_break", 0.3, "맞은 적 방어 -30%"),
    "의천검": ("double", 0.9, "20% 확률로 한 번 더 공격 (피해 90%)"),
    "고정도": ("crit_dmg", 0.5, "치명타 피해 +50%"),
    "백우선": ("burn", 0.3, "맞은 적이 2초 동안 공격력의 30% 피해"),
    # 갑옷 보물
    "명광개": ("dmg_taken", 0.9, "받는 피해 -10%"),
    "사자 투구": ("hp", 1.12, "최대 체력 +12%"),
    "철갑 망토": ("ranged_resist", 0.8, "원거리 피해 -20%"),
    "호랑이 가죽 갑옷": ("first_hit", 1.5, "첫 공격 피해 ×1.5"),
    "비늘 갑옷": ("def_add", 15, "방어 +15"),
    "백은 갑옷": ("dmg_taken", 0.82, "받는 피해 -18%"),
    "서량 철갑": ("first_hit", 2.0, "첫 공격 피해 ×2"),
    "적토마 안장": ("spd", 1.4, "이동 속도 +40%"),
    "강동 수군 갑옷": ("ranged_resist", 0.65, "원거리 피해 -35%"),
    # 장신구 보물
    "손자병법": ("energy", 1.3, "기력 획득 +30%"),
    "태평요술서": ("stun_chance", 0.08, "8% 확률로 0.6초 기절"),
    "옥새 모조품": ("crit", 0.08, "치명타 확률 +8%"),
    "황금 사자상": ("aspd", 1.12, "공격 속도 +12%"),
    "전국옥새 조각": ("heal_aura", 0.03, "6초마다 주변 아군 체력 3% 회복"),
    "맹덕신서": ("energy", 1.5, "기력 획득 +50%"),
    "적벽 동남풍 부적": ("stun_chance", 0.14, "14% 확률로 0.6초 기절"),
    "팔진도": ("heal_aura", 0.06, "6초마다 주변 아군 체력 6% 회복"),
}
treasures = []
for slot, by in treasure_names.items():
    for rar, names in by.items():
        for i, n in enumerate(names):
            t = {"id": f"{slot}_{rar}_{i}", "name": n, "slot": slot, "rarity": rar,
                 "kind": "treasure" if rar in ("epic", "legend") else "normal",
                 "exclusive": exclusive.get(n, "")}
            if t["kind"] == "treasure":
                key, val, desc = gear_fx[n]
                t["fx"] = [key, val]
                t["fx_desc"] = desc
            treasures.append(t)
meta = {
    "_source": "메타-성장-과금 §3-4, 콘텐츠-기획-v5 §6, §10",
    "start": {"gold": 20000, "heroes": [],
              "troops": ["spear", "sword", "archer", "rider"]},
    # 캐릭터는 전투 중 슬롯에서만 얻는다 (개편 §13). 당첨 칸이 장수면 등급 확률 -> 그 등급 안에서 같은 확률,
    # 병사면 기본 / 정예 확률 -> 그 안에서 같은 확률. 처음 나온 장수 · 병종은 그 자리에서 계정에 합류한다.
    "slot_pool": {"hero_odds": {"b": 55.0, "a": 30.0, "s": 12.0, "ss": 3.0},
                  "soldier_odds": {"basic": 70.0, "elite": 30.0}},
    # 성급 (개편 §9.2): 전투 중 같은 병종을 흡수해 경험을 쌓는다. 복사본(같은 장수) 10, 같은 병종 병사 1.
    "star": {"max": 6, "mult": 1.15, "hero_xp": [10, 20, 30, 50, 80], "troop_xp": [5, 12, 25, 50, 100],
             "xp_copy": 10, "xp_troop": 1, "trait_slots": [1, 2, 3, 4, 5, 6], "trait_max": 3,  # 속성 칸 = 성급 (2026-11-24 민수 님, A안)
             "dup_gold": {"b": 1000, "a": 3000, "s": 10000, "ss": 30000}, "troop_dup_gold": 500},  # 우편 등으로 이미 가진 것을 받을 때만
    "treasure": {"slots": ["weapon", "armor", "charm"], "slot_names": {"weapon": "무기", "armor": "갑옷", "charm": "장신구"},
                 # 전용 보물을 그 장수가 끼면 주 능력치 +30%
                 "exclusive_bonus": 1.3,
                 "main_stat": {"weapon": "atk", "armor": "def", "charm": "hp"},
                 "main_base": {"weapon": {"common": 8, "rare": 14, "epic": 24, "legend": 40},
                               "armor": {"common": 6, "rare": 10, "epic": 18, "legend": 30},
                               "charm": {"common": 80, "rare": 140, "epic": 240, "legend": 400}},
                 "main_per_level": 0.1, "max_level": 15, "sub_slots": {"common": 1, "rare": 2, "epic": 3, "legend": 4},
                 "sub_unlock": [5, 10, 15],
                 "sub_kinds": [{"id": "crit", "name": "치명타 확률", "v": 0.03, "fmt": "pct"},
                               {"id": "crit_dmg", "name": "치명타 피해", "v": 0.1, "fmt": "pct"},
                               {"id": "aspd", "name": "공격 속도", "v": 0.04, "fmt": "pct"},
                               {"id": "energy", "name": "기력 획득", "v": 0.06, "fmt": "pct"},
                               {"id": "guard", "name": "받는 피해 감소", "v": 0.03, "fmt": "pct"},
                               {"id": "spd", "name": "이동 속도", "v": 0.05, "fmt": "pct"}],
                 "level_cost_base": 120, "level_cost_exp": 1.6,
                 "dismantle": {"common": 100, "rare": 300, "epic": 1000, "legend": 3000}, "dismantle_refund": 0.5,
                 "bag_max": 200,
                 # 재료 · 합성 (개편 §3.7~3.8): 스테이지 보상으로 재료, 재료 3 -> 보물, 보물 3 -> 윗등급.
                 "rarity_order": ["common", "rare", "epic", "legend"],
                 "materials": {"per_win": 2, "per_loss": 1, "loss_wave": 5, "craft": 3, "fuse": 3,
                               "first_min": "rare", "reward_rarity": "rare",
                               "odds": [{"common": 75.0, "rare": 22.0, "epic": 3.0, "legend": 0.0},
                                        {"common": 50.0, "rare": 38.0, "epic": 11.0, "legend": 1.0},
                                        {"common": 25.0, "rare": 45.0, "epic": 25.0, "legend": 5.0}]},
                 "list": treasures},
    "lord": {"exp_base": 200, "exp_exp": 1.3, "max": 40,
             # 군주 레벨 (개편 §9.3): 클리어해야 경험, 모든 캐릭터 기초 공·방·체 x (1 + 0.05 x (Lv-1)). 새 계정은 Lv.1.
             "stat_per_level": 0.05, "clear_exp": 100, "diff_exp": [1.0, 1.5, 2.2], "first_mult": 2,
             "unlocks": [[1, "로비·출정·장수 목록"], [3, "편성·모집"], [5, "편성 칸 +1 (7명)·보물"], [8, "병영 강화·노병"],
                         [10, "상점·임무"], [12, "쟁패"], [15, "도사·편성 칸 +1 (8명)"], [20, "강화 상한 해제"]],
             "lineup_slots": [[1, 6], [5, 7], [15, 8]]},
    "power": {"atk": 10, "def": 8, "hp": 1},
    # 콘텐츠-기획-v5 §7, §7.1 / 메타 §3.10 [제안]: 하루 무료 5회(04:00), 군공, 군웅 상점(주간)
    "arena": {"free_per_day": 5, "extra_cost": 1000, "extra_max": 5,
              "win_honor": 20, "lose_honor": 5, "dup_honor": 30,
              # 2026-11-23: 장수 카드 삭제 (성급은 전투에서만), 장비는 영웅 보물.
              "shop": [{"id": "treasure", "kind": "treasure", "rarity": "epic", "cost": 200, "limit": 1},
                       {"id": "rice", "kind": "rice", "amount": 10, "cost": 150, "limit": 2},
                       {"id": "gold", "kind": "gold", "amount": 10000, "cost": 30, "limit": 5}]},
}
dump("meta.json", meta)

# ------------------------------------------------------------------ shop / missions / pass / mail
shop = {
    "_source": "개편 §13: 재화는 금 하나. 금만 현금으로 판다 (개발용 가상 결제, 스토어 연동 전).",
    "first_double": True,
    "monthly": {"id": "monthly", "name": "월정액", "desc": "매일 금 3,000 · 30일", "price": 5500, "now": 9000, "daily": 3000, "days": 30},
    "gold_packs": [
        {"id": "g60", "amount": 2000, "price": 1200}, {"id": "g300", "amount": 10000, "price": 5900},
        {"id": "g980", "amount": 33000, "price": 19000}, {"id": "g1980", "amount": 68000, "price": 38000},
        {"id": "g3280", "amount": 110000, "price": 59000}, {"id": "g6480", "amount": 230000, "price": 119000}],
    "packages": [
        {"id": "p_start", "name": "출정 준비 꾸러미", "desc": "군량 50 · 금 50,000", "price": 4400, "rice": 50, "gold": 50000, "limit": 1},
        {"id": "p_hero", "name": "군량 꾸러미", "desc": "군량 100 · 금 15,000", "price": 22000, "rice": 100, "gold": 15000, "limit": 1},
        {"id": "p_treasure", "name": "보물 재료 묶음", "desc": "희귀 재료 15개", "price": 9900, "mats": 15, "limit": 3}],
}
dump("shop.json", shop)
# 보상은 금 · 군량 · 재료뿐이다 (개편 §13: 재화는 금 하나).
missions = {
    "_source": "콘텐츠-기획-v5 §8",
    "daily": [
        {"id": "d_run", "name": "출정 3회", "stat": "runs", "need": 3, "reward": {"gold": 2000}, "go": "stage"},
        {"id": "d_spin", "name": "슬롯 20회 돌리기", "stat": "spins", "need": 20, "reward": {"gold": 600}, "go": "stage"},
        {"id": "d_absorb", "name": "흡수 5회", "stat": "absorbs", "need": 5, "reward": {"gold": 1500}, "go": "stage"},
        {"id": "d_upgrade", "name": "같은 병종 흡수 3회", "stat": "star_absorbs", "need": 3, "reward": {"gold": 1500}, "go": "stage"},
        {"id": "d_recruit", "name": "새 장수 · 병종 1명 얻기", "stat": "new_units", "need": 1, "reward": {"gold": 600}, "go": "stage"},
        {"id": "d_all", "name": "일일 임무 모두 완료", "stat": "daily_done", "need": 5, "reward": {"gold": 900}, "go": ""}],
    "weekly": [
        {"id": "w_clear", "name": "스테이지 15회 클리어", "stat": "clears", "need": 15, "reward": {"rice": 10}, "go": "stage"},
        {"id": "w_jackpot", "name": "잭팟 3회", "stat": "jackpots", "need": 3, "reward": {"gold": 1500}, "go": "stage"},
        {"id": "w_treasure", "name": "장비 강화 10회", "stat": "treasure_ups", "need": 10, "reward": {"gold": 20000}, "go": "heroes"},
        {"id": "w_kills", "name": "적 500명 처치", "stat": "kills", "need": 500, "reward": {"gold": 2400}, "go": "stage"},
        {"id": "w_days", "name": "일일 임무 완료 5일", "stat": "daily_days", "need": 5, "reward": {"rice": 10}, "go": ""},
        {"id": "w_all", "name": "주간 임무 모두 완료", "stat": "weekly_done", "need": 5, "reward": {"gold": 3000}, "go": ""}],
    "achievements": [
        {"id": "a_ch1", "name": "스테이지 1 클리어", "stat": "chapter1", "need": 1, "reward": {"gold": 3000}, "go": "stage"},
        {"id": "a_hero10", "name": "장수 10명 수집", "stat": "heroes_owned", "need": 10, "reward": {"gold": 1500}, "go": "heroes"},
        {"id": "a_hero20", "name": "장수 20명 수집", "stat": "heroes_owned", "need": 20, "reward": {"gold": 3000}, "go": "heroes"},
        {"id": "a_star4", "name": "4성 장수 1명", "stat": "star4", "need": 1, "reward": {"gold": 1500}, "go": "heroes"},
        {"id": "a_jack50", "name": "잭팟 누적 20회", "stat": "jackpots_total", "need": 20, "reward": {"gold": 3000}, "go": "stage"},
        {"id": "a_trait30", "name": "속성 흡수 누적 30회", "stat": "traits_total", "need": 30, "reward": {"gold": 1800}, "go": "stage"},
        {"id": "a_legend", "name": "전설 보물 획득", "stat": "legend_treasure", "need": 1, "reward": {"gold": 6000}, "go": "heroes"}],
    "attendance": [{"gold": 5000}, {"gold": 900}, {"mats": 3}, {"gold": 10000}, {"gold": 1500}, {"rice": 10}, {"gold": 3000}],
}
dump("missions.json", missions)
mail = {"_source": "우편 (시안 10-mail)", "welcome": [
    {"id": "m_welcome", "title": "출시 기념 선물", "body": "운빨삼국에 오신 것을 환영합니다!", "reward": {"gold": 9000}, "days": 7},
    {"id": "m_check", "title": "점검 보상", "body": "불편을 드려 죄송합니다.", "reward": {"gold": 10000}, "days": 5},
    {"id": "m_ticket", "title": "주공 취임 축하", "body": "군량을 드립니다.", "reward": {"rice": 20}, "days": 14}]}
dump("mail.json", mail)
print("ok", len(heroes), "heroes", len(treasures), "treasures")
