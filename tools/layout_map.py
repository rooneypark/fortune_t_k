#!/usr/bin/env python3
"""배치 지도: raw/<화면>.png + raw/<화면>.json (App --layout) -> 표시 그림 + 표.

색: 글자 = 노랑, 그림 = 파랑, 버튼 = 빨강, 판(테두리 틀) = 회색 점선 없이 얇게.
좌표는 논리 화면 1024 x 1792 기준 (세로 모바일).
Usage: python tools/layout_map.py   (tools/layout_map.sh 가 마지막에 부른다)
"""
import glob, json, os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "design", "ux", "배치-지도")
RAW = os.path.join(DIR, "raw")
FONT = os.path.join(ROOT, "assets", "fonts", "Galmuri11-Bold.ttf")
W, H = 1024, 1792
COL = {"text": (255, 214, 0), "image": (60, 160, 255), "button": (255, 70, 70), "panel": (170, 170, 180), "area": (80, 230, 120)}
KIND_KO = {"text": "글자", "image": "그림", "button": "버튼", "panel": "판", "area": "영역"}
ISSUE = (255, 0, 220)
BG_NAMES = {"lobby_bg", "battle_field", "field_plain", "intro_bg", "menu_bg", "recruit_banner", "shop_banner", "stage_bg"}
TITLES = {
    "01_intro": "인트로", "02_lobby": "로비", "03_stage": "스테이지 선택", "03b_pop_lineup": "팝업 — 출정 편성", "03c_pop_lineup_new": "팝업 — 출정 편성 (장수 없음)", "04_battle_prep": "전투 — 준비",
    "05_battle_fight": "전투 — 싸움", "06_heroes_hero": "가방 — 장수", "07_heroes_troop": "가방 — 병종",
    "08_heroes_treasure": "가방 — 보물", "08b_troop_up": "병종 상세 — 강화", "08c_troop_star": "병종 상세 — 성급", "40b_tutorial_nudge": "튜토리얼 — 한 칸 밀기", "09_hero_up": "장수 상세 — 강화", "10_hero_star": "장수 상세 — 성급",
    "11_hero_treasure": "장수 상세 — 보물", "12_recruit_soldier": "모집 — 병사", "13_recruit_hero": "모집 — 장수", "13b_recruit_gold": "모집 — 골드 장수", "26b_pop_odds_gold": "팝업 — 확률(골드 장수)",
    "14_shop_rec": "상점 — 추천", "15_shop_dia": "상점 — 다이아", "16_shop_gold": "상점 — 골드", "17_shop_pack": "상점 — 패키지",
    "18_arena": "군웅대전", "20_pop_settings": "팝업 — 설정", "21_pop_mail": "팝업 — 우편", "22_pop_missions": "팝업 — 임무",
"24_pop_profile": "팝업 — 주공 정보", "25_pop_arena_shop": "팝업 — 군웅 상점",
    "26_pop_odds_hero": "팝업 — 확률(장수)", "27_pop_odds_soldier": "팝업 — 확률(병사)", "28_pop_odds_box": "팝업 — 확률(보물 상자)",
    "29_pop_confirm": "팝업 — 확인", "30_pop_purchase": "팝업 — 구매", "31_pop_reward": "팝업 — 보상",
    "32_pop_recruit_result": "팝업 — 모집 결과 1회", "33_pop_recruit_ten": "팝업 — 모집 결과 10회", "34_pop_pause": "팝업 — 일시정지",
    "35_pop_wave_clear": "팝업 — 웨이브 승리", "36_pop_absorb": "팝업 — 흡수(특성 선택)", "37_pop_result_win": "팝업 — 결과 승리",
    "38_pop_result_lose": "팝업 — 결과 패배", "39_tutorial_lobby": "튜토리얼 — 로비", "40_tutorial_battle": "튜토리얼 — 전투",
}


def what(it):
    lab = str(it["label"]).replace("\n", " ")
    if it["kind"] == "image":
        if lab in BG_NAMES:
            return "배경 " + lab
        if lab.startswith(("icon_", "ic_", "class_", "rarity_", "faction_")):
            return "아이콘 " + lab
        if lab.endswith("_head"):
            return "얼굴 " + lab[:-5]
        if lab.endswith("_lihui"):
            return "큰 그림 " + lab[:-6]
        if lab.isdigit() or lab == "(그림)":
            return "캐릭터 동작 프레임"
        return "초상 " + lab
    if it["kind"] in ("button", "panel"):
        return lab
    return "“%s”" % (lab[:28] + ("…" if len(lab) > 28 else ""))


def keep(it):
    if it["x"] >= W or it["y"] >= H or it["x"] + it["w"] <= 0 or it["y"] + it["h"] <= 0:
        return False
    if it["kind"] == "image" and it["label"].isdigit():
        return it["h"] >= 40   # tiny repeated frames (battle field units) are noise
    return True


def layer(it):
    n = it["node"]
    for k in ("popup_layer", "dialog_layer", "overlay_layer"):
        if "/%s/" % k in n:
            return k
    return "screen_layer"


def _center_in(it, r):
    cx, cy = it["x"] + it["w"] / 2, it["y"] + it["h"] / 2
    return r[0] <= cx <= r[2] and r[1] <= cy <= r[3]


def visible(raw):
    """Only what the player can see: the top layer wins.
    - popup open: popup items only (the screen behind is dimmed)
    - dialog open: dialog items inside the dialog frame + screen items outside it (top bar)
    """
    items = [it for it in raw if keep(it)]
    pop = [it for it in items if layer(it) == "popup_layer"]
    if pop:
        return pop + [it for it in items if layer(it) == "overlay_layer"]
    dlg = [it for it in items if layer(it) == "dialog_layer"]
    if dlg:
        frames = [it for it in dlg if it["kind"] in ("panel", "area") and it["w"] < W]
        f = max(frames, key=lambda it: it["w"] * it["h"]) if frames else None
        if f:
            r = (f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])
            dlg = [it for it in dlg if _center_in(it, r) or it["y"] + it["h"] <= r[1] + 40]
            scr = [it for it in items if layer(it) == "screen_layer" and not _center_in(it, r)]
            return dlg + scr
    return items


def visible_all(raw):
    return visible(raw)


def containers(items):
    """Areas that hold other things (not a button's own box, not full screen)."""
    btn_nodes = {it["node"] for it in items if it["kind"] == "button"}
    out = []
    for a in items:
        if a["kind"] != "area" or a["node"] in btn_nodes or a["w"] >= W:
            continue
        pre = a["node"] + "/"
        has = any(it is not a and (it["node"] == a["node"] or it["node"].startswith(pre)) for it in items if it["kind"] != "area")
        if has:
            out.append(a)
    return out


def main():
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    try:
        from layout_audit import audit
    except Exception:
        audit = None
    font = ImageFont.truetype(FONT, 16)
    names = sorted(os.path.splitext(os.path.basename(p))[0] for p in [q for q in glob.glob(os.path.join(RAW, "*.json")) if not os.path.basename(q).startswith("_")])
    md = ["# 화면 배치 지도 (2026-11-22)", "",
          "게임 화면(논리 1024 × 1792, 세로)마다 **무엇이 어디에 그려지는지** 표시한 지도다. 그림을 새로 그릴 때 이 자리와 크기에 맞춘다.",
          "",
          "| 색 | 종류 | 뜻 |", "|---|---|---|",
          "| 노랑 | 글자 | 게임이 글자를 쓰는 자리. 그림에 글자를 넣지 않는다. 상자 = 글자가 들어갈 수 있는 최대 칸 |",
          "| 파랑 | 그림 | 그림(아이콘 · 초상 · 캐릭터 · 배경)이 들어가는 자리. 비율은 유지하고 칸 안에 맞춘다 |",
          "| 빨강 | 버튼 | 누를 수 있는 영역 전체 (버튼 부품 그림 = 이 크기) |",
          "| 회색 | 판 | 테두리 판(9-slice) 자리 — 부품 이름은 표의 `내용` |",
          "| 초록 | 영역 | 컨테이너. 안의 글자·그림·버튼은 이 상자를 넘지 않는다 (표의 A번호) |",
          "| 분홍 | 문제 | 자동 점검에서 걸린 곳 (넘침·잘림·겹침). `점검.md` |",
          "",
          "- 만드는 법: `bash tools/layout_map.sh` (게임을 점검 모드로 실행해 그리는 순간의 자리를 기록 → `raw/`, 표시 그림 → 이 폴더).",
          "- 좌표 x, y = 왼쪽 위, 단위 = 논리 픽셀. 화면이 더 긴 폰에서는 위 고정 / 아래 고정 요소가 늘어난 만큼 벌어진다 (화면-설계서 §1).",
          "- 스크롤 목록은 보이는 부분만 기록된다. 같은 모양의 칸이 반복되면 첫 줄 크기를 따른다.",
          ""]
    for n in names:
        data = json.load(open(os.path.join(RAW, n + ".json"), encoding="utf-8"))
        items = visible(data["items"])
        shot = os.path.join(RAW, n + ".png")
        base = Image.open(shot).convert("RGB").resize((W, H), Image.NEAREST) if os.path.exists(shot) else Image.new("RGB", (W, H))
        dim = Image.new("RGB", (W, H), (0, 0, 0))
        im = Image.blend(base, dim, 0.45)
        d = ImageDraw.Draw(im)
        order = {"area": -1, "panel": 0, "image": 1, "button": 2, "text": 3}
        conts = containers(items)
        for k, a in enumerate(sorted(conts, key=lambda a: (a["y"], a["x"]))):
            d.rectangle([a["x"], a["y"], a["x"] + a["w"] - 1, a["y"] + a["h"] - 1], outline=COL["area"], width=1)
            tag = "A%d" % (k + 1)
            tw = d.textlength(tag, font=font)
            tx, ty = max(0, a["x"] + a["w"] - tw - 6), max(0, a["y"])
            d.rectangle([tx, ty, tx + tw + 6, ty + 18], fill=COL["area"])
            d.text((tx + 3, ty + 1), tag, font=font, fill=(0, 0, 0))
        items = [it for it in items if it["kind"] != "area"]
        items.sort(key=lambda it: (order[it["kind"]], it["y"], it["x"]))
        rows = []
        idx = 0
        for it in items:
            c = COL[it["kind"]]
            box = [it["x"], it["y"], it["x"] + it["w"] - 1, it["y"] + it["h"] - 1]
            if it["kind"] == "panel":
                d.rectangle(box, outline=c, width=1)
                continue
            if it["kind"] == "image" and str(it["label"]) in BG_NAMES:
                rows.append((0, it))
                continue
            idx += 1
            d.rectangle(box, outline=c, width=3 if it["kind"] == "button" else 2)
            tag = str(idx)
            tw = d.textlength(tag, font=font)
            tx, ty = max(0, it["x"]), max(0, it["y"])
            d.rectangle([tx, ty, tx + tw + 6, ty + 18], fill=c)
            d.text((tx + 3, ty + 1), tag, font=font, fill=(0, 0, 0))
            rows.append((idx, it))
        issues = audit(data["items"]) if audit else []
        for x in issues:
            d.rectangle([x["x"], x["y"], x["x"] + x["w"] - 1, x["y"] + x["h"] - 1], outline=ISSUE, width=3)
        im.save(os.path.join(DIR, n + ".png"), optimize=True)
        md += ["## %s — `%s`" % (TITLES.get(n, n), n), "", "![%s](%s.png)" % (n, n), ""]
        md += ["**영역 (컨테이너)**", "", "| A | x, y | 크기 | 노드 |", "|---|---|---|---|"]
        for k, a in enumerate(sorted(conts, key=lambda a: (a["y"], a["x"]))):
            md.append("| A%d | %d, %d | %d × %d | `%s` |" % (k + 1, a["x"], a["y"], a["w"], a["h"], a["node"].replace("/root/Main/", "")))
        md += ["", "**점검: %s**" % ("문제 없음" if not issues else "%d건 — `점검.md`" % len(issues)), ""]
        md += ["**자리**", "", "| # | 종류 | x, y | 크기 | 내용 |", "|---|---|---|---|---|"]
        for i, it in rows:
            md.append("| %s | %s | %d, %d | %d × %d | %s |" % (i or "배경", KIND_KO[it["kind"]], it["x"], it["y"], it["w"], it["h"], what(it).replace("|", "/")))
        panels = sorted({(it["label"], it["w"], it["h"]) for it in items if it["kind"] == "panel"}, key=lambda p: (-p[1] * p[2]))
        if panels:
            md += ["", "판(테두리 틀): " + ", ".join("`%s` %d×%d" % p for p in panels[:14]) + (" …" if len(panels) > 14 else "")]
        md.append("")
    open(os.path.join(DIR, "README.md"), "w", encoding="utf-8").write("\n".join(md))
    print("layout map:", len(names), "screens")


if __name__ == "__main__":
    main()
