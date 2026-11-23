class_name Gacha
extends RefCounted
## 확률 도우미 (개편 §13). 모집(뽑기)은 없다: 캐릭터는 전투 중 슬롯에서만 나온다.
## 슬롯의 당첨 칸이 장수면 등급 확률(B 55 / A 30 / S 12 / SS 3 %) -> 그 등급 안에서 같은
## 확률, 병사면 기본 / 정예 확률 -> 그 안에서 같은 확률. 재료 등급 굴림도 roll_rarity를 쓴다.

## 장수 등급 낮은 것부터 (B < A < S < SS).
const ORDER := ["b", "a", "s", "ss"]


static func hero_odds() -> Dictionary:
	DB.ensure()
	return DB.meta["slot_pool"]["hero_odds"]


static func soldier_odds() -> Dictionary:
	DB.ensure()
	return DB.meta["slot_pool"]["soldier_odds"]


static func roll_rarity(rng: RandomNumberGenerator, table: Dictionary) -> String:
	var total := 0.0
	for k: String in table:
		total += float(table[k])
	var x := rng.randf() * total
	for k: String in table:
		x -= float(table[k])
		if x < 0.0:
			return k
	return String(table.keys()[table.size() - 1])


## One hero for a winning hero reel, out of [param ids]: grade by hero_odds, then
## equal odds inside the grade (any of [param ids] when that grade has none).
static func slot_hero(rng: RandomNumberGenerator, ids: Array) -> String:
	var grade := roll_rarity(rng, hero_odds())
	var pool: Array = []
	for id: Variant in ids:
		if DB.rarity_of(String(id)) == grade:
			pool.append(id)
	if pool.is_empty():
		pool = ids
	return String(pool[rng.randi_range(0, pool.size() - 1)])


## One troop for a winning soldier reel, out of [param ids]: tier by soldier_odds.
static func slot_soldier(rng: RandomNumberGenerator, ids: Array) -> String:
	var tier := roll_rarity(rng, soldier_odds())
	var pool: Array = []
	for id: Variant in ids:
		if String(DB.soldier(String(id)).get("tier", "basic")) == tier:
			pool.append(id)
	if pool.is_empty():
		pool = ids
	return String(pool[rng.randi_range(0, pool.size() - 1)])


## Chance in percent that a winning hero reel shows this hero (확률 정보).
static func hero_chance(id: String) -> float:
	var r := DB.rarity_of(id)
	return float(hero_odds().get(r, 0.0)) / float(maxi(1, DB.hero_ids_of_rarity(r).size()))


## Chance in percent that a winning soldier reel shows this troop (확률 정보).
static func soldier_chance(id: String) -> float:
	var tier := String(DB.soldier(id).get("tier", "basic"))
	return float(soldier_odds().get(tier, 0.0)) / float(maxi(1, DB.soldier_ids_of_tier(tier).size()))
