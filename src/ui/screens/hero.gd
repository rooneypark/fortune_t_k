extends PxScreen
## 장수 상세 (메타 §3.4·3.5·3.8): 일러스트·이름·희귀도·성급·세력·병종·전투력,
## 이전/다음 장수, 탭 성장(별 6칸, 성급 경험, 군주 레벨 효과, 인연) ·
## 속성(속성 칸, 상성) · 보물(칸 3개, 자동 장착, 합계).
## 성급과 속성은 여기서 올릴 수 없다: 전투 중 흡수로만 오른다 (개편 §9.1).

const STATS := ["atk", "def", "hp"]
const STAT_ICON := {"atk": "ic_sword", "def": "ic_shield", "hp": "ic_heart"}

var id := ""
var tab := 0
var slot := "weapon"
var _t := 0.0
var _flash := 0.0


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.45
	id = String(params.get("id", "guanyu"))
	tab = int(params.get("tab", 0))
	_rebuild()
	set_process(true)


func back() -> bool:
	var from := String(params.get("from", "heroes"))
	if from == "lobby" and dialog:
		Game.app.close_dialog()
	else:
		Game.app.goto(from)
	return true


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 2.0)
	for c in get_children():
		if c is DrawLayer and c.has_meta("anim"):
			c.queue_redraw()


func _owned() -> bool:
	return Game.profile.owns(id)


## 8차 시안 좌표(화면 px 그대로)로 짠 화면이다 — app.gd 가 창 틀 안에 그대로 놓는다. 배치는 Detail8 (병종 상세와 공용).
func native8() -> bool:
	return true


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("hero.title"))
	Detail8.build(self, id, tab, slot,
		func(i: int) -> void:
			tab = i
			_rebuild(),
		func(s: String) -> void:
			slot = s
			tab = 2
			_rebuild(),
		_rebuild,
		func(side: int) -> void:
			var list := _nav_list()
			id = String(list[posmod(list.find(id) + side, list.size())])
			_rebuild())


func _nav_list() -> Array:
	var out: Array = []
	for h: String in DB.hero_ids():
		if Game.profile.owns(h) == _owned():
			out.append(h)
	if not out.has(id):
		out.append(id)
	return out
