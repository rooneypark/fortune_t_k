extends PxScreen
## 병종 상세 (병종-장수-재설계 §3.6): 장수 상세와 같은 방식.
## 위: 병종 그림 · 이름 · 기본/정예 · 성급 · 전투력 · 공방체 · 특징, 이 병종 장수 2명, 이전/다음.
## 탭: 성장(별 6칸, 성급 경험, 군주 레벨 효과) · 속성(속성 칸, 상성) · 장비(무기 · 갑옷 · 장신구).
## 병종이 낀 장비는 그 병종의 모든 병사에게 적용된다 (개편 §11).
## 성급과 속성은 전투 중 흡수로만 오른다 (개편 §9.1).
## 영역: 위 정보판 A(60,160 904×540) · 탭 B(60,716 904×96) · 내용 C(60,820 904×600).

const STATS := ["atk", "def", "hp"]
const STAT_ICON := {"atk": "ic_sword", "def": "ic_shield", "hp": "ic_heart"}

var id := ""
var tab := 0
var slot := "weapon"
var _t := 0.0


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.45
	id = String(params.get("id", "spear"))
	tab = int(params.get("tab", 0))
	_rebuild()
	set_process(true)


func back() -> bool:
	Game.app.goto("heroes", {"tab": 1})
	return true


func _process(delta: float) -> void:
	_t += delta
	for c in get_children():
		if c is DrawLayer and c.has_meta("anim"):
			c.queue_redraw()


## 8차 시안 좌표(화면 px 그대로)로 짠 화면이다. 배치는 Detail8 (장수 상세와 공용).
func native8() -> bool:
	return true


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("troop.title"))
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
			var list: Array = DB.soldier_ids()
			id = String(list[posmod(list.find(id) + side, list.size())])
			_rebuild())
