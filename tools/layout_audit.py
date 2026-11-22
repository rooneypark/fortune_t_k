#!/usr/bin/env python3
"""배치 점검: design/ux/배치-지도/raw/*.json 을 읽어 영역 문제를 찾는다.

찾는 것 (보이는 층만):
  글자 넘침   글자 실제 폭이 칸보다 김 (줄여도 안 들어감)
  글자 줄어듦 칸이 좁아 글자가 요청 크기의 80% 아래로 작아짐
  여러 줄 넘침 문단이 칸 높이보다 김
  영역 밖     그림·글자·판이 자기 영역(그린 노드 상자) 밖으로 2px 넘게 나감
  부모 밖     영역이 부모 영역 밖으로 나감 (스크롤·잘라내기 영역 안은 제외)
  겹침        같은 영역 안 글자 칸끼리 30% 넘게 겹침
  화면 밖     영역이 화면(1024 x 1792) 밖
Usage: python tools/layout_audit.py  -> 점검 결과 (stdout JSON + 배치-지도/점검.md)
"""
import glob, json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from layout_map import visible_all, RAW, DIR, W, H, TITLES, BG_NAMES  # noqa: E402

# 게임 화면 안에서 움직이는 것(전장 유닛 머리 위 숫자 등)은 점검하지 않는다.
LIVE = ("battle_field", "fx_layer", "slot_view")

TOL = 2


def rect(it):
    return (it["x"], it["y"], it["x"] + it["w"], it["y"] + it["h"])


def inside(a, b, tol=TOL):
    return a[0] >= b[0] - tol and a[1] >= b[1] - tol and a[2] <= b[2] + tol and a[3] <= b[3] + tol


def inter(a, b):
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    return max(0, w) * max(0, h)


def parent_path(p):
    return p.rsplit("/", 1)[0]


def audit(raw):
    items = visible_all(raw)
    areas = {it["node"]: it for it in items if it["kind"] == "area"}
    issues = []

    def clipped(node):
        """True when some ancestor area clips / scrolls (content may overflow by design)."""
        n = node
        while "/" in n:
            n = parent_path(n)
            a = areas.get(n)
            if a and (a.get("extra") or {}).get("clip"):
                return True
        return False

    def live(node):
        a = areas.get(node)
        return a is not None and a["label"] in LIVE

    def add(kind, it, msg):
        issues.append({"type": kind, "x": it["x"], "y": it["y"], "w": it["w"], "h": it["h"], "msg": msg, "node": it["node"]})

    for it in items:
        ex = it.get("extra") or {}
        if it["kind"] == "text":
            lab = str(it["label"]).replace("\n", " ")[:24]
            sx = float(it.get("sx", 1.0) or 1.0)
            if ex.get("para"):
                if ex.get("need_h", 0) * sx > it["h"] + TOL:
                    add("여러 줄 넘침", it, "“%s” %d줄, 필요 높이 %d > 칸 %d" % (lab, ex.get("lines", 0), ex["need_h"] * sx, it["h"]))
            elif "tw" in ex:
                tw = ex["tw"] * sx
                if tw > it["w"] + TOL:
                    add("글자 넘침", it, "“%s” 폭 %d > 칸 %d" % (lab, tw, it["w"]))
                elif ex.get("req") and ex["fs"] < ex["req"] * 0.8:
                    add("글자 줄어듦", it, "“%s” 크기 %d → %d (칸 폭 %d)" % (lab, ex["req"], ex["fs"], it["w"]))
                th = ex.get("th", 0) * sx
                if th > it["h"] + 6:
                    add("글자 넘침", it, "“%s” 높이 %d > 칸 %d" % (lab, th, it["h"]))
        if it["kind"] in ("text", "image", "panel") and str(it["label"]) not in BG_NAMES and not live(it["node"]):
            a = areas.get(it["node"])
            if a and not inside(rect(it), rect(a)) and not (a.get("extra") or {}).get("clip"):
                add("영역 밖", it, "%s `%s`이(가) 영역 %d×%d 밖으로 나감" % (it["kind"], str(it["label"])[:20], a["w"], a["h"]))
    for node, a in areas.items():
        ex = a.get("extra") or {}
        r = rect(a)
        if r[2] <= 0 or r[3] <= 0 or r[0] >= W or r[1] >= H:
            continue
        if (r[0] < -TOL or r[1] < -TOL or r[2] > W + TOL or r[3] > H + TOL) and not clipped(node) and not (a.get("extra") or {}).get("parent_clip"):
            add("화면 밖", a, "영역 `%s` %d,%d %d×%d" % (a["label"], a["x"], a["y"], a["w"], a["h"]))
        par = areas.get(parent_path(node))
        if par and not ex.get("parent_clip") and not inside(r, rect(par)) and par["w"] < W:
            add("부모 밖", a, "`%s`이(가) 부모 `%s` 밖으로 나감" % (a["label"], par["label"]))
    # text overlaps inside the same area
    by_node = {}
    for it in items:
        if it["kind"] == "text":
            by_node.setdefault(it["node"], []).append(it)
    for node, ts in by_node.items():
        if live(node):
            continue
        for i in range(len(ts)):
            for j in range(i + 1, len(ts)):
                a, b = rect(ts[i]), rect(ts[j])
                small = min(ts[i]["w"] * ts[i]["h"], ts[j]["w"] * ts[j]["h"])
                if small and inter(a, b) > 0.3 * small:
                    add("겹침", ts[j], "“%s” 와 “%s” 칸이 겹침" % (str(ts[i]["label"])[:14], str(ts[j]["label"])[:14]))
    # de-duplicate
    seen, out = set(), []
    for x in issues:
        k = (x["type"], x["x"], x["y"], x["w"], x["h"], x["msg"])
        if k not in seen:
            seen.add(k)
            out.append(x)
    return out


def main():
    total = {}
    md = ["# 배치 점검 결과", "", "`python tools/layout_audit.py` 로 다시 뽑는다. 0건이 목표.", ""]
    allres = {}
    for p in sorted([q for q in glob.glob(os.path.join(RAW, "*.json")) if not os.path.basename(q).startswith("_")]):
        n = os.path.splitext(os.path.basename(p))[0]
        res = audit(json.load(open(p, encoding="utf-8"))["items"])
        allres[n] = res
        for x in res:
            total[x["type"]] = total.get(x["type"], 0) + 1
    md.append("| 종류 | 건수 |")
    md.append("|---|---|")
    for k, v in sorted(total.items(), key=lambda kv: -kv[1]):
        md.append("| %s | %d |" % (k, v))
    md.append("")
    for n, res in allres.items():
        if not res:
            continue
        md += ["## %s — `%s` (%d건)" % (TITLES.get(n, n), n, len(res)), "", "| 종류 | 위치 | 내용 | 노드 |", "|---|---|---|---|"]
        for x in res:
            md.append("| %s | %d,%d %d×%d | %s | `%s` |" % (x["type"], x["x"], x["y"], x["w"], x["h"], x["msg"].replace("|", "/"), x["node"].replace("/root/Main/", "")))
        md.append("")
    open(os.path.join(DIR, "점검.md"), "w", encoding="utf-8").write("\n".join(md))
    json.dump(allres, open(os.path.join(DIR, "raw", "_audit.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(json.dumps(total, ensure_ascii=False), sum(total.values()))


if __name__ == "__main__":
    main()
