#!/usr/bin/env python3
"""UI 실측표: design/ux/규격/raw/*.json (tools/layout_dump.tscn 이 만든다) -> design/ux/규격/측정표.md

화면마다 실제로 그려진 버튼 · 그림 · 글자의 자리와 크기를 표로 적는다.
좌표는 논리 화면 1024 x 1792 (왼쪽 위가 0,0). 창 없이 기록하면 화면이 가로로 넓게 잡혀서
가운데 정렬된 만큼(384px) 밀려 있으므로 그만큼 빼서 적는다.

    python tools/ui_spec.py
"""
import glob, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "design", "ux", "규격")
RAW = os.path.join(DIR, "raw")
W, H = 1024, 1792
TITLES = {
    "01_intro": "인트로", "02_lobby": "로비", "04_pop_difficulty": "난이도 창",
    "05_battle_prep": "전투 — 준비", "06_battle_fight": "전투 — 싸움", "07_pop_absorb": "흡수 창 (속성 선택)",
    "08_pop_wave_clear": "웨이브 승리 창", "09_pop_pause": "일시정지 창", "10_pop_result_win": "결과 — 승리", "11_pop_result_lose": "결과 — 패배",
    "12_units_heroes": "장수 화면 — 장수 탭", "13_units_soldiers": "장수 화면 — 병사 탭", "14_items": "아이템 화면",
    "15_hero_growth": "장수 상세 — 성장", "16_hero_traits": "장수 상세 — 속성", "17_hero_gear": "장수 상세 — 장비", "18_hero_unowned": "장수 상세 — 미보유",
    "19_troop_growth": "병사 상세 — 성장", "20_troop_gear": "병사 상세 — 장비", "21_pop_treasure": "장비 상세 창", "22_pop_synth": "합성 창",
    "23_shop_rec": "상점 — 추천", "24_shop_gold": "상점 — 금", "25_shop_rice": "상점 — 군량", "26_shop_pack": "상점 — 꾸러미",
    "27_arena": "군웅대전", "28_pop_arena_shop": "군웅 상점 창", "29_pop_settings": "설정 창", "30_pop_mail": "우편 창", "31_pop_missions": "임무 창",
    "32_pop_profile": "주공 정보 창", "33_pop_odds": "확률 정보 창", "34_pop_confirm": "확인 창", "35_pop_purchase": "구매 창", "36_pop_reward": "보상 창",
}
# 로비 위에 뜨는 화면(대화창)과 팝업은 아래에 깔린 로비 것이 같이 기록된다: 로비에만 있는 노드는 뺀다.
LOBBY_ONLY = ("/screen_layer/",)
DIALOGS = ( "12_", "13_", "14_", "15_", "16_", "17_", "18_", "19_", "20_", "21_", "22_", "23_", "24_", "25_", "26_", "27_", "28_", "33_", "35_")
LIMIT = {"button": 60, "image": 50, "text": 60}


def load(name):
    d = json.load(open(os.path.join(RAW, name + ".json"), encoding="utf-8"))
    off = round((float(d["canvas"][0]) - W) / 2)
    out = []
    for it in d["items"]:
        if it["kind"] == "area":
            continue
        if name.startswith(DIALOGS) and any(k in it.get("node", "") for k in LOBBY_ONLY):
            continue
        it = dict(it)
        it["x"] -= off
        it["label"] = str(it["label"]).replace("\n", " ").replace("|", "/")
        out.append(it)
    return out


def table(items, kind):
    seen, rows = set(), []
    for it in sorted([i for i in items if i["kind"] == kind], key=lambda i: (i["y"], i["x"])):
        key = (it["label"], it["w"], it["h"])
        if key in seen:
            continue
        seen.add(key)
        size = it.get("extra", {}).get("req")
        rows.append("| %s | %d, %d | %d × %d |%s" % (it["label"][:28] or "(이름 없음)", it["x"], it["y"], it["w"], it["h"],
                                                   (" %s |" % (int(size) if size else "")) if kind == "text" else ""))
    more = len(rows) - LIMIT[kind]
    rows = rows[:LIMIT[kind]]
    if more > 0:
        rows.append("| … 그 밖 %d개 | | |%s" % (more, " |" if kind == "text" else ""))
    return rows


def main():
    out = ["# UI 실측표 (자동 생성)", "",
           "- `tools/layout_dump.tscn`이 창 없이 기록한 값을 `tools/ui_spec.py`가 표로 만든 것이다. 손으로 고치지 않는다.",
           "- 좌표는 논리 화면 **1024 × 1792** 기준 (x, y = 왼쪽 위). 같은 이름 · 같은 크기는 한 번만 적는다.",
           "- 로비 위에 뜨는 화면과 팝업에서는 아래에 깔린 로비의 것을 뺐다.", ""]
    for path in sorted(glob.glob(os.path.join(RAW, "*.json"))):
        name = os.path.splitext(os.path.basename(path))[0]
        items = load(name)
        out += ["## %s — %s" % (name[:2], TITLES.get(name, name)), ""]
        for kind, head in (("button", "버튼"), ("image", "그림"), ("text", "글자")):
            rows = table(items, kind)
            if not rows:
                continue
            if kind == "text":
                out += ["**%s**" % head, "", "| 내용 | x, y | 칸 크기 | 글자 크기 |", "|---|---|---|---|"] + rows + [""]
            else:
                out += ["**%s**" % head, "", "| 이름 | x, y | 크기 |", "|---|---|---|"] + rows + [""]
    with open(os.path.join(DIR, "측정표.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    print("ok", len(glob.glob(os.path.join(RAW, "*.json"))), "screens -> design/ux/규격/측정표.md")


if __name__ == "__main__":
    main()
