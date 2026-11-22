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
    "start_rice": 300, "spin_base": 100, "spin_step": 20, "nudge_ratio": 0.25,
    "strip_length": 18, "weight_soldier": 4, "weight_hero": 1,
    "faction_line_atk": 0.15, "max_rank_refund_ratio": 0.5,
    "rank_max": 3, "rank_absorbs": [0, 2, 5], "rank_mult": [1.0, 1.6, 2.5],
    "absorb_same_unit": 2, "absorb_same_class": 1, "jackpot_xp": 4,
    "respawn_soldier": 5.0, "respawn_hero": 12.0, "respawn_per_rank": 2.0,
    "castle_hp": 1000, "castle_regen": 0.1, "castle_attack_interval": 1.2,
    "wave_income_base": 280, "wave_income_step": 20, "wave_clear_bonus": 80,
    "field_cap_base": 6, "field_cap_costs": [100, 140, 180, 220, 260, 300],
    "hero_quota_base": 3, "hero_quota_costs": [], "hero_lineup_max": 3, "troop_lineup": 4,
    "bench_size": 8, "waves_per_stage": 10, "judge_wave": 5,
    "speeds": [1, 2, 3],
    "energy_max": 100, "energy_per_attack": 20, "energy_per_hit": 5,
    "burn_tick": 0.5, "burn_ratio": 0.2, "slow_ratio": 0.45,
    "crit_mult": 2.0, "wave_scale": 1.08, "spawn_gap": 0.55,
    # 2026-11-22 재설계: 장수 없이 시작, 편성 = 병종 4 + 장수 최대 3
    "default_lineup": [], "default_advisor": "",
    "soldiers_base": ["spear", "shield", "archer", "rider"],
    "field": {"left": 70, "right": 954, "spawn_top": 236, "line_y": 810, "ally_top": 830, "ally_bottom": 1150,
              "castle_y": 1150, "respawn_y": 1160},
    "visual_boost": 2.4,
    # 메타-성장-과금 §3.10 [제안]: 런이 끝날 때 남은 군량 -> 골드, 주공 레벨로 시작 군량 +
    "rice_to_gold": 2, "start_rice_lord": [[10, 20], [20, 20], [30, 20]],
}
dump("rules.json", rules)

# ------------------------------------------------------------------ units
classes = {
    "inf": {"name": "보병", "spd": 70, "aspd": 0.9, "icon": "class_inf", "hp_k": 1.15, "atk_k": 0.95, "range": 44},
    "arc": {"name": "궁병", "spd": 62, "aspd": 0.8, "icon": "class_arc", "hp_k": 0.75, "atk_k": 1.1, "range": 250},
    "cav": {"name": "기병", "spd": 120, "aspd": 1.0, "icon": "class_cav", "hp_k": 0.95, "atk_k": 1.05, "range": 46},
    "str": {"name": "책사", "spd": 56, "aspd": 0.6, "icon": "class_str", "hp_k": 0.8, "atk_k": 1.15, "range": 230},
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
soldiers = {
    # 보병
    "spear":   {"name": "창병", "cls": "inf", "tier": "basic", "hp": 300, "atk": 22, "def": 5, "art": "spear", "vs_cav": 1.5, "desc": "긴 창으로 앞줄을 지킨다. 기병에게 1.5배."},
    "halberd": {"name": "극병", "cls": "inf", "tier": "elite", "hp": 340, "atk": 28, "def": 8, "art": "halberd", "cleave": 0.4, "desc": "넓게 휘두른다. 주변 적에게 40% 피해."},
    "shield":  {"name": "방패병", "cls": "inf", "tier": "basic", "hp": 460, "atk": 12, "def": 25, "art": "shield", "taunt": True, "ranged_resist": 0.6, "desc": "적을 끌어당긴다. 원거리 피해 -40%."},
    "axe":     {"name": "도부수", "cls": "inf", "tier": "elite", "hp": 420, "atk": 24, "def": 18, "art": "axe", "armor_break": 0.3, "desc": "도끼와 방패. 맞은 적 방어 -30%."},
    # 궁병
    "archer":  {"name": "궁병", "cls": "arc", "tier": "basic", "hp": 180, "atk": 24, "def": 0, "art": "archer", "desc": "멀리서 쏜다. 붙으면 약하다."},
    "crossbow": {"name": "노병", "cls": "arc", "tier": "elite", "hp": 200, "atk": 30, "def": 2, "art": "crossbow", "pierce": True, "aspd_k": 0.75, "desc": "느리지만 관통 사격."},
    # 기병
    "rider":   {"name": "경기병", "cls": "cav", "tier": "basic", "hp": 250, "atk": 26, "def": 5, "art": "rider", "backline": True, "desc": "적 궁병과 요술사를 먼저 노린다."},
    "heavy":   {"name": "중기병", "cls": "cav", "tier": "elite", "hp": 420, "atk": 30, "def": 15, "art": "heavy", "first_hit": 1.8, "desc": "느린 돌격. 첫 공격 1.8배."},
    # 책사(술사)
    "fire":    {"name": "화공술사", "cls": "str", "tier": "elite", "hp": 200, "atk": 18, "def": 0, "art": "fire", "splash": 0.5, "burn_on_hit": 2.0, "desc": "불꽃 범위 공격. 화상 2초."},
    "thunder": {"name": "뇌공술사", "cls": "str", "tier": "elite", "hp": 200, "atk": 20, "def": 0, "art": "thunder", "stun_chance": 0.15, "desc": "번개. 15% 확률로 잠깐 기절."},
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
 ("liubei","유비","shu","a","rider", S("인덕","체력이 가장 낮은 아군 35% 회복","heal_ally",heal=0.35), "",0),
 ("guanping","관평","shu","b","spear", S("부자 협공","앞의 적을 베어 2배 피해","line",length=150,width=100,mult=2.0), "",0),
 # 위 8
 ("caocao","조조","wei","ss","heavy", S("패왕의 호령","아군 전체 공격 +30% (5초)","ally_all",atk_mult=1.3,time=5.0), "",0),
 ("simayi","사마의","wei","s","heavy", S("매복","무작위 적 셋에게 낙석","random_strike",count=3,mult=2.2,radius=70), "",0),
 ("zhangliao","장료","wei","s","rider", S("요래 돌격","가장 많은 적에게 돌진","aoe_target",radius=140,mult=2.0), "",0),
 ("xiahoudun","하후돈","wei","a","spear", S("발목 분노","체력 30% 회복, 4초간 공격 +40%","self_buff",heal=0.3,atk_mult=1.4,time=4.0), "",0),
 ("xiahouyuan","하후연","wei","a","crossbow", S("질풍 사격","빠른 화살 연사 (5발)","multi_shot",count=5,mult=1.2), "",0),
 ("xuchu","허저","wei","a","axe", S("호치","받는 피해 크게 감소 (5초 -50%)","self_guard",dmg_taken=0.5,time=5.0), "",0),
 ("caoren","조인","wei","b","shield", S("철벽 수비","주변 아군 받는 피해 -20% (4초)","ally_aura",radius=160,dmg_taken=0.8,time=4.0), "",0),
 ("zhanghe","장합","wei","b","halberd", S("교묘한 진퇴","빠르게 베고 물러남 (2배)","snipe",mult=2.0), "",0),
 # 오 8
 ("sunce","손책","wu","ss","heavy", S("소패왕","처치할 때마다 공격 속도 상승 (6초간 +40%)","self_buff",aspd_mult=1.4,atk_mult=1.2,time=6.0,heal=0.1), "",0),
 ("sunquan","손권","wu","s","shield", S("강동 진형","주변 아군 받는 피해 -25% (4초)","ally_aura",radius=200,dmg_taken=0.75,time=4.0), "",0),
 ("zhouyu","주유","wu","s","fire", S("적벽 화공","넓은 범위 화상 (4초)","aoe_target",radius=150,mult=1.5,burn=4.0), "",0),
 ("luxun","육손","wu","s","fire", S("연영 화공","일렬로 불길","line",length=420,width=90,mult=1.8,burn=3.0), "",0),
 ("ganning","감녕","wu","a","axe", S("백기 야습","치명 일격 (3배)","snipe",mult=3.0), "",0),
 ("taishici","태사자","wu","a","archer", S("신궁","관통 화살 (2.5배)","line",length=500,width=50,mult=2.5), "",0),
 ("huanggai","황개","wu","b","fire", S("고육계","체력을 써서 주변 적에게 화염","stun_aoe",radius=140,mult=1.6,stun=0.0,burn=3.0,self_cost=0.1), "",0),
 ("handang","한당","wu","b","archer", S("노장의 화살","가장 가까운 적 셋에게 화살","multi_shot",count=3,mult=1.3), "",0),
 # 군웅 9
 ("lvbu","여포","qun","ss","halberd", S("무쌍 돌격","일직선으로 돌진하며 큰 피해","line",length=360,width=110,mult=3.2), "",0),
 ("diaochan","초선","qun","s","thunder", S("경국","적 하나를 잠시 홀려 멈추게 함 (4초)","charm",time=4.0,mult=1.0), "",0),
 ("dongzhuo","동탁","qun","a","shield", S("폭정","주변 적 공격 감소, 자신 체력 회복","debuff_aoe",radius=160,enemy_atk=0.7,time=5.0,heal=0.25), "",0),
 ("yuanshao","원소","qun","a","crossbow", S("사세삼공","아군 궁병 공격 상승 (6초)","ally_class",cls="arc",atk_mult=1.35,time=6.0), "",0),
 ("zhangjiao_h","장각","qun","b","thunder", S("태평요술","낙뢰 3발","random_strike",count=3,mult=1.8,radius=80,stun=0.8), "",0),
 ("menghuo","맹획","qun","b","axe", S("남만왕","받는 피해 감소 (5초 -40%)","self_guard",dmg_taken=0.6,time=5.0), "",0),
 ("huaman","화만","qun","b","crossbow", S("비도","가장 약한 적에게 2.5배","snipe",mult=2.5), "",0),
 ("zuoci","좌자","qun","b","thunder", S("둔갑","적 하나를 잠시 멈추게 함 (3초)","charm",time=3.0,mult=1.0), "",0),
 ("yuji","우길","qun","b","thunder", S("부적","체력이 가장 낮은 아군 30% 회복","heal_ally",heal=0.3), "",0),
]
heroes = {}
for (hid, name, fac, rar, troop, skill, art, hue) in roster:
    art, hue = hid, 0  # 2026-11-22: 모든 장수가 자기 그림을 가진다 (tools/draw_art.py)
    cls = soldiers[troop]["cls"]
    tier = rarities[rar]["tier"]
    c = classes[cls]
    hp = round((520 + 150 * tier) * c["hp_k"])
    atk = round((42 + 13 * tier) * c["atk_k"])
    df = 20 if cls != "inf" else 26
    heroes[hid] = {"name": name, "fac": fac, "rarity": rar, "cls": cls, "troop": troop, "hp": hp, "atk": atk, "def": df,
                   "range": c["range"] + (10 if cls in ("inf", "cav") else 20), "skill": skill, "art": art, "hue": hue}
# advisor skills (GDD §3.3b, 제안): heroes that can be 책사 (str class) each have a slot skill.
advisors = {
    "zhugeliang": {"name": "한 줄 다시", "desc": "꽝일 때 릴 하나를 공짜로 다시 돌린다", "type": "respin"},
    "zhouyu":     {"name": "동남풍", "desc": "꽝일 때 한 칸 밀기를 공짜로 1회", "type": "free_nudge"},
    "luxun":      {"name": "화계", "desc": "꽝일 때 릴 하나를 공짜로 다시 돌린다", "type": "respin"},
    "diaochan":   {"name": "연환계", "desc": "다음 돌리기 장수 칸 확률 2배", "type": "hero_boost"},
    "zhangjiao_h":{"name": "태평도", "desc": "꽝일 때 릴 하나를 공짜로 다시 돌린다", "type": "respin"},
    "zuoci":      {"name": "둔갑술", "desc": "다음 돌리기 장수 칸 확률 2배", "type": "hero_boost"},
    "yuji":       {"name": "기우", "desc": "꽝일 때 한 칸 밀기를 공짜로 1회", "type": "free_nudge"},
    "huanggai":   {"name": "화선", "desc": "꽝일 때 한 칸 밀기를 공짜로 1회", "type": "free_nudge"},
}
traits = {
    "inf": [{"id": "iron", "name": "철벽", "desc": "받는 피해 -15%", "dmg_taken": 0.85},
            {"id": "taunt", "name": "도발", "desc": "근처 적이 먼저 노림", "taunt": True},
            {"id": "tough", "name": "강골", "desc": "최대 체력 +20%", "hp": 1.2}],
    "arc": [{"id": "longbow", "name": "장궁", "desc": "사거리 +40", "range": 40},
            {"id": "rapid", "name": "속사", "desc": "공격 속도 +20%", "aspd": 1.2},
            {"id": "pierce", "name": "관통", "desc": "공격이 뒤의 적 1명까지 맞음", "pierce": True}],
    "cav": [{"id": "gallop", "name": "질주", "desc": "이동 속도 +30%", "spd": 1.3},
            {"id": "charge", "name": "돌격", "desc": "첫 공격 피해 ×2", "first_hit": 2.0},
            {"id": "raid", "name": "기습", "desc": "적 원거리·책사를 먼저 노림", "backline": True}],
    "str": [{"id": "wit", "name": "지략", "desc": "기력 획득 +40%", "energy": 1.4},
            {"id": "fire", "name": "화공", "desc": "공격에 작은 범위 피해(50%)", "splash": 0.5},
            {"id": "heal", "name": "의술", "desc": "6초마다 근처 아군 체력 5% 회복", "heal_aura": 0.05}],
}
synergies = [
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
    "mob":    {"name": "황건 잡병", "hp": 120, "atk": 8, "spd": 55, "def": 0, "range": 40, "art": "enemy_mob", "scale": 0.92},
    "sword":  {"name": "황건 검병", "hp": 240, "atk": 16, "spd": 55, "def": 5, "range": 40, "art": "enemy_sword"},
    "spear":  {"name": "황건 창병", "hp": 220, "atk": 20, "spd": 55, "def": 5, "range": 46, "art": "enemy_spear", "vs_cav": 1.5},
    "archer": {"name": "황건 궁병", "hp": 170, "atk": 18, "spd": 55, "def": 0, "range": 220, "aspd": 0.8, "art": "enemy_archer"},
    "shield": {"name": "황건 방패병", "hp": 420, "atk": 12, "spd": 46, "def": 25, "range": 40, "ranged_resist": 0.5, "art": "enemy_shield"},
    "rider":  {"name": "황건 기병", "hp": 220, "atk": 18, "spd": 105, "def": 5, "range": 46, "beh": "assassin", "cls": "cav", "art": "enemy_rider"},
    "mage":   {"name": "요술사", "hp": 220, "atk": 10, "spd": 46, "def": 0, "range": 170, "aspd": 0.6, "beh": "support", "heal": 60, "art": "enemy_mage"},
    "brute":  {"name": "괴력 장수", "hp": 1600, "atk": 45, "spd": 46, "def": 10, "range": 50, "elite": True, "art": "enemy_brute", "scale": 1.25},
}
bosses = {
    "zhangjiao": {"name": "장각", "hp": 9000, "atk": 55, "spd": 28, "def": 20, "range": 200, "aspd": 0.7, "art": "enemy_zhangjiao", "scale": 1.0, "mech": "lightning", "rule": "6초마다 낙뢰를 떨어뜨린다"},
    "chengyuanzhi": {"name": "정원지", "hp": 4200, "atk": 48, "spd": 40, "def": 15, "range": 52, "art": "enemy_brute", "hue": 0.1, "scale": 1.45, "mech": "stomp", "rule": "주변을 내리찍어 아군을 기절시킨다"},
    "lvbu_b": {"name": "여포", "hp": 15000, "atk": 80, "spd": 60, "def": 30, "range": 60, "art": "zhaoyun", "hue": 0.78, "scale": 1.6, "mech": "stomp", "rule": "돌진해 주변을 쓸어 버린다"},
    "jiling": {"name": "기령", "hp": 24000, "atk": 90, "spd": 30, "def": 60, "range": 56, "art": "xiahoudun", "hue": 0.2, "scale": 1.6, "mech": "stomp", "rule": "단단한 방패 진형, 받는 피해 감소"},
    "yanwen": {"name": "안량·문추", "hp": 38000, "atk": 120, "spd": 44, "def": 40, "range": 60, "art": "guanyu", "hue": 0.78, "scale": 1.6, "mech": "stomp", "rule": "두 장수가 번갈아 돌격한다"},
    "caoren": {"name": "조인", "hp": 62000, "atk": 150, "spd": 30, "def": 80, "range": 56, "art": "xiahoudun", "hue": 0.62, "scale": 1.6, "mech": "stomp", "rule": "철벽: 받는 피해를 일부 되돌린다"},
    "xiahouyuan_b": {"name": "하후연", "hp": 90000, "atk": 200, "spd": 34, "def": 50, "range": 260, "art": "huangzhong", "hue": 0.6, "scale": 1.6, "mech": "lightning", "rule": "멀리서 화살비를 퍼붓는다"},
}
for _sid, _sd in soldiers.items():
    _sd["art"] = _sid
    _sd.pop("hue", None)
# 보스: 자체 그림이 있는 장수·적 그림을 빌린다
for _bid, _art in {"lvbu_b": "lvbu", "xiahouyuan_b": "xiahouyuan", "jiling": "enemy_shield",
                   "yanwen": "enemy_rider", "caoren": "enemy_shield", "chengyuanzhi": "enemy_brute"}.items():
    bosses[_bid]["art"] = _art
    bosses[_bid].pop("hue", None)
units = {"_source": "GDD v5 §3.4b, §3.7 / 장수-명단-v5 / 콘텐츠-기획-v5 §3-5 / slice_units.json",
         "classes": classes, "factions": factions, "rarities": rarities, "soldiers": soldiers, "heroes": heroes,
         "advisors": advisors, "traits": traits, "synergies": synergies, "bonds": bonds, "enemies": enemies,
         "bosses": bosses, "enemy_aspd": 0.85,
         "boss_mech": {"lightning": {"every": 6.0, "warn": 1.2, "radius": 90, "dmg": 140, "stun": 1.0},
                       "stomp": {"every": 7.0, "warn": 0.9, "radius": 150, "dmg": 120, "stun": 1.2}}}
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
chapters = [
    {"id": 1, "name": "황건의 난", "enemy": "황건적", "hue": 0.0, "boss": "zhangjiao", "elite": "chengyuanzhi",
     "stages": ["탁현 들판", "숲속 매복", "황건적 야영지", "성문 공방", "광종 외곽", "영천 평야", "곡양 산길", "광종성 결전"]},
    {"id": 2, "name": "반동탁 연합", "enemy": "동탁군", "hue": 0.85, "boss": "lvbu_b", "elite": "chengyuanzhi",
     "stages": ["산조 집결", "사수관 앞", "화웅의 도발", "호로관 길", "낙양 외곽", "불타는 낙양", "형양 매복", "호로관 결전"]},
    {"id": 3, "name": "군웅할거", "enemy": "원술군", "hue": 0.55, "boss": "jiling", "elite": "chengyuanzhi",
     "stages": ["서주 들판", "소패 성채", "하비 물길", "수춘 외곽", "방패 대열", "원술의 창고", "회수 강변", "수춘성 결전"]},
    {"id": 4, "name": "관도대전", "enemy": "원소군", "hue": 0.25, "boss": "yanwen", "elite": "chengyuanzhi",
     "stages": ["백마 구원", "연진 나루", "관도 진지", "오소 습격", "화살비 평원", "토산 공방", "창정 추격", "관도 결전"]},
    {"id": 5, "name": "적벽대전", "enemy": "조조군", "hue": 0.62, "boss": "caoren", "elite": "chengyuanzhi",
     "stages": ["장판 언덕", "하구 나루", "강하 수채", "적벽 강가", "연환선", "동남풍", "화용도", "남군 결전"]},
    {"id": 6, "name": "한중 쟁탈", "enemy": "장로·조조 연합", "hue": 0.4, "boss": "xiahouyuan_b", "elite": "chengyuanzhi",
     "stages": ["양평관", "가맹관", "탕거 산길", "와구관", "천탕산", "정군산 기슭", "한수 강변", "정군산 결전"]},
]
stages = {"_source": "콘텐츠-기획-v5 §2 (적 배율 1.09^(s-1), 5 = 적장, 8 = 장 보스, 첫 클리어 다이아 50)",
          "difficulty_base": 1.09, "count_step": 0.05, "first_clear_diamond": 50,
          "gold_per_wave": 100, "gold_victory": 500, "lord_exp_per_wave": 10,
          "star_rules": ["클리어", "성 체력 50% 이상", "성 체력 90% 이상"],
          "chapter_chests": [{"stars": 8, "gold": 5000}, {"stars": 16, "tickets": 1}, {"stars": 24, "diamond": 150}],
          "recommended_power": 8000, "recommended_step": 1.8,
          "waves_template": waves_template, "chapters": chapters}
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
treasures = []
for slot, by in treasure_names.items():
    for rar, names in by.items():
        for i, n in enumerate(names):
            treasures.append({"id": f"{slot}_{rar}_{i}", "name": n, "slot": slot, "rarity": rar,
                              "exclusive": exclusive.get(n, "")})
meta = {
    "_source": "메타-성장-과금 §3-4, 콘텐츠-기획-v5 §6, §10",
    "start": {"gold": 15750, "diamond": 480, "tickets": 1, "heroes": [],
              "troops": ["spear", "shield", "archer", "rider"]},
    "recruit": {"cost_one": 300, "cost_ten": 2700, "odds": {"b": 55.0, "a": 30.0, "s": 12.0, "ss": 3.0},
                "pity": 60, "pity_grade": "ss", "ten_guarantee": "s", "tutorial_hero": "guanyu"},
    # 골드 장수 모집 (2026-11-22): 1회 10,000 · 하루 5회 · 천장 없음. 무과금 하루 골드 약 2~3만 기준.
    "gold_recruit": {"cost_one": 10000, "daily_max": 5, "odds": {"b": 75.0, "a": 21.0, "s": 3.7, "ss": 0.3}},
    # 병사 모집 (골드, 2026-11-22 [제안]): 기본 4종 70%, 정예 6종 30%. 이미 있는 병종이면 카드 +1.
    "soldier_recruit": {"cost_one": 3000, "cost_ten": 27000, "odds": {"basic": 70.0, "elite": 30.0}, "max_star_gold": 500},
    "star": {"max": 6, "cards": [1, 2, 3, 5, 8], "mult": 1.15},
    "upgrade": {"per_level": 0.04, "cost_base": 50, "cost_exp": 1.5, "cap_per_star": 10},
    "barracks": {"per_level": 0.03, "cost_base": 30, "cost_exp": 1.45, "cap_per_lord_lv": 2},
    "treasure": {"slots": ["weapon", "armor", "charm"], "slot_names": {"weapon": "무기", "armor": "갑옷", "charm": "보패"},
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
                 "box": {"cost": 150, "odds": {"common": 50.0, "rare": 35.0, "epic": 12.0, "legend": 3.0}, "pity": 30},
                 "list": treasures},
    "lord": {"exp_base": 200, "exp_exp": 1.3, "max": 40,
             "unlocks": [[1, "로비·출정·장수 목록"], [3, "편성·모집"], [5, "편성 칸 +1 (7명)·보물"], [8, "병영 강화·노병"],
                         [10, "상점·임무"], [12, "군웅대전"], [15, "도사·편성 칸 +1 (8명)"], [20, "강화 상한 해제"]],
             "lineup_slots": [[1, 6], [5, 7], [15, 8]]},
    "power": {"atk": 10, "def": 8, "hp": 1},
    # 콘텐츠-기획-v5 §7, §7.1 / 메타 §3.10 [제안]: 하루 무료 5회(04:00), 군공, 군웅 상점(주간)
    "arena": {"free_per_day": 5, "extra_cost": 20, "extra_max": 5,
              "win_honor": 20, "lose_honor": 5, "dup_honor": 30,
              "shop": [{"id": "card", "kind": "hero_card", "cost": {"b": 60, "a": 100, "s": 150, "ss": 250}, "limit": 5},
                       {"id": "treasure", "kind": "treasure", "rarity": "rare", "cost": 200, "limit": 1},
                       {"id": "tickets", "kind": "tickets", "amount": 1, "cost": 150, "limit": 2},
                       {"id": "gold", "kind": "gold", "amount": 10000, "cost": 30, "limit": 5}]},
}
dump("meta.json", meta)

# ------------------------------------------------------------------ shop / missions / pass / mail
shop = {
    "_source": "화면-배치표 07-shop / 메타 §3.9. 결제는 개발용 가상 결제 (스토어 연동 전).",
    "first_double": True,
    "monthly": {"id": "monthly", "name": "월정액", "desc": "매일 다이아 100 · 30일", "price": 5500, "now": 300, "daily": 100, "days": 30},
    "diamonds": [
        {"id": "d60", "amount": 60, "price": 1200}, {"id": "d300", "amount": 300, "price": 5900},
        {"id": "d980", "amount": 980, "price": 19000}, {"id": "d1980", "amount": 1980, "price": 38000},
        {"id": "d3280", "amount": 3280, "price": 59000}, {"id": "d6480", "amount": 6480, "price": 119000}],
    "gold_daily_limit": 3,
    "gold": [
        {"id": "g1", "gold": 10000, "cost": 50}, {"id": "g2", "gold": 60000, "cost": 280}, {"id": "g3", "gold": 150000, "cost": 650}],
    "packages": [
        {"id": "p_start", "name": "출정 준비 꾸러미", "desc": "모집권 5 · 골드 50,000", "price": 4400, "tickets": 5, "gold": 50000, "limit": 1},
        {"id": "p_hero", "name": "명장 성장 꾸러미", "desc": "모집권 10 · 다이아 500", "price": 22000, "tickets": 10, "diamond": 500, "limit": 1},
        {"id": "p_treasure", "name": "보물 상자 묶음", "desc": "보물 상자 5회", "price": 9900, "boxes": 5, "limit": 3}],
    "box_cost": 150,
}
dump("shop.json", shop)
missions = {
    "_source": "콘텐츠-기획-v5 §8",
    "daily": [
        {"id": "d_run", "name": "출정 3회", "stat": "runs", "need": 3, "reward": {"gold": 2000}, "go": "stage"},
        {"id": "d_spin", "name": "슬롯 20회 돌리기", "stat": "spins", "need": 20, "reward": {"diamond": 20}, "go": "stage"},
        {"id": "d_absorb", "name": "흡수 5회", "stat": "absorbs", "need": 5, "reward": {"gold": 1500}, "go": "stage"},
        {"id": "d_upgrade", "name": "장수 강화 3회", "stat": "upgrades", "need": 3, "reward": {"gold": 1500}, "go": "heroes"},
        {"id": "d_recruit", "name": "장수 모집 1회", "stat": "recruits", "need": 1, "reward": {"diamond": 20}, "go": "recruit"},
        {"id": "d_all", "name": "일일 임무 모두 완료", "stat": "daily_done", "need": 5, "reward": {"diamond": 30}, "go": ""}],
    "weekly": [
        {"id": "w_clear", "name": "스테이지 15회 클리어", "stat": "clears", "need": 15, "reward": {"tickets": 1}, "go": "stage"},
        {"id": "w_jackpot", "name": "3연 대박 10회", "stat": "jackpots", "need": 10, "reward": {"diamond": 50}, "go": "stage"},
        {"id": "w_treasure", "name": "보물 강화 10회", "stat": "treasure_ups", "need": 10, "reward": {"gold": 20000}, "go": "heroes"},
        {"id": "w_kills", "name": "적 500명 처치", "stat": "kills", "need": 500, "reward": {"diamond": 80}, "go": "stage"},
        {"id": "w_days", "name": "일일 임무 완료 5일", "stat": "daily_days", "need": 5, "reward": {"tickets": 1}, "go": ""},
        {"id": "w_all", "name": "주간 임무 모두 완료", "stat": "weekly_done", "need": 5, "reward": {"diamond": 100}, "go": ""}],
    "achievements": [
        {"id": "a_ch1", "name": "1장 완료", "stat": "chapter1", "need": 1, "reward": {"diamond": 100}, "go": "stage"},
        {"id": "a_hero10", "name": "장수 10명 수집", "stat": "heroes_owned", "need": 10, "reward": {"diamond": 50}, "go": "recruit"},
        {"id": "a_hero20", "name": "장수 20명 수집", "stat": "heroes_owned", "need": 20, "reward": {"diamond": 100}, "go": "recruit"},
        {"id": "a_star4", "name": "4성 장수 1명", "stat": "star4", "need": 1, "reward": {"diamond": 50}, "go": "heroes"},
        {"id": "a_jack50", "name": "3연 대박 누적 50회", "stat": "jackpots_total", "need": 50, "reward": {"diamond": 100}, "go": "stage"},
        {"id": "a_trait30", "name": "특성 흡수 누적 30회", "stat": "traits_total", "need": 30, "reward": {"diamond": 60}, "go": "stage"},
        {"id": "a_legend", "name": "전설 보물 획득", "stat": "legend_treasure", "need": 1, "reward": {"diamond": 200}, "go": "shop"}],
    "attendance": [{"gold": 5000}, {"diamond": 30}, {"boxes": 1}, {"gold": 10000}, {"diamond": 50}, {"tickets": 1}, {"diamond": 100}],
}
dump("missions.json", missions)
pass_ = {"_source": "콘텐츠-기획-v5 §9", "season": 1, "name": "황건 토벌 시즌", "days": 28, "tiers": 30, "exp_per_tier": 1000,
         "premium_price": 11000, "free": [], "premium": []}
for t in range(1, 31):
    pass_["free"].append({"tickets": 1} if t % 5 == 0 else ({"gold": 3000 + 200 * t} if t % 2 else {"diamond": 10}))
    pass_["premium"].append({"boxes": 1} if t in (10, 20) else ({"skin": "시즌 한정 외형"} if t == 30 else {"diamond": 20 + (t % 3) * 20}))
# pass removed
mail = {"_source": "우편 (시안 10-mail)", "welcome": [
    {"id": "m_welcome", "title": "출시 기념 선물", "body": "운빨삼국에 오신 것을 환영합니다!", "reward": {"diamond": 300}, "days": 7},
    {"id": "m_check", "title": "점검 보상", "body": "불편을 드려 죄송합니다.", "reward": {"gold": 10000}, "days": 5},
    {"id": "m_ticket", "title": "주공 취임 축하", "body": "모집권을 드립니다.", "reward": {"tickets": 2}, "days": 14}]}
dump("mail.json", mail)
print("ok", len(heroes), "heroes", len(treasures), "treasures")
