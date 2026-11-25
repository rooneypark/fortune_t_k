class_name Growth
extends RefCounted
## 상세 화면이 같이 쓰는 작은 도우미. 성급 · 속성 · 장비 판은 src/ui/kit/detail8.gd 로 옮겼다 (2026-11-25).


static func _names(cls_list: Array) -> String:
	if cls_list.is_empty():
		return DB.t("growth.none")
	var out: Array = []
	for c: String in cls_list:
		out.append(DB.cls_name(c))
	return " · ".join(out)
