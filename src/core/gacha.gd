class_name Gacha
extends RefCounted
## 장수 모집 (병종-장수-재설계): grade first (B 55 / A 30 / S 12 / SS 3 %), then a
## hero of that grade with equal odds. Pity: after 60 pulls without SS the next is
## SS. A 10-pull holds at least one S or better. Gold recruit: weaker odds, no pity.
## Also the 보물 상자 roll (콘텐츠 §6.1).

## 장수 등급 낮은 것부터 (2026-11-22: B < A < S < SS).
const ORDER := ["b", "a", "s", "ss"]


## Grade index (b 0 … ss 3), -1 if unknown.
static func grade_rank(g: String) -> int:
	return ORDER.find(g)


static func odds() -> Dictionary:
	DB.ensure()
	return DB.meta["recruit"]["odds"]


static func pity_max() -> int:
	return int(DB.meta["recruit"]["pity"])


## Per-hero chance in percent for the odds table.
static func hero_chance(rarity: String) -> float:
	var n := DB.hero_ids_of_rarity(rarity).size()
	return float(odds()[rarity]) / float(maxi(1, n))


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


static func pick_of(rng: RandomNumberGenerator, rarity: String) -> String:
	var ids := DB.hero_ids_of_rarity(rarity)
	ids.sort()
	return String(ids[rng.randi_range(0, ids.size() - 1)])


## One pull. [param pity] = pulls since the last SS before this one.
## Returns {id, rarity, pity} where pity is the new counter.
static func pull(rng: RandomNumberGenerator, pity: int) -> Dictionary:
	var top := String(DB.meta["recruit"]["pity_grade"])
	var rarity := top if pity >= pity_max() else roll_rarity(rng, odds())
	var id := pick_of(rng, rarity)
	return {"id": id, "rarity": rarity, "pity": 0 if rarity == top else pity + 1}


## [param count] pulls; a 10-pull guarantees S+ (the last card is upgraded).
static func pull_many(rng: RandomNumberGenerator, pity: int, count: int) -> Dictionary:
	var cards: Array = []
	var p := pity
	for i in count:
		var c := pull(rng, p)
		p = int(c["pity"])
		cards.append(c)
	if count >= 10:
		var has_good := false
		var need := grade_rank(String(DB.meta["recruit"]["ten_guarantee"]))
		for c: Dictionary in cards:
			if grade_rank(String(c["rarity"])) >= need:
				has_good = true
		if not has_good:
			var last: Dictionary = cards[cards.size() - 1]
			last["rarity"] = String(DB.meta["recruit"]["ten_guarantee"])
			last["id"] = pick_of(rng, last["rarity"])
	return {"cards": cards, "pity": p}


## 골드 장수 모집: grade by gold odds, no pity (다이아 모집보다 약함).
static func pull_gold(rng: RandomNumberGenerator) -> Dictionary:
	var rarity := roll_rarity(rng, DB.meta["gold_recruit"]["odds"])
	return {"id": pick_of(rng, rarity), "rarity": rarity}


## Per-hero chance (%) in the gold recruit.
static func gold_hero_chance(rarity: String) -> float:
	var n := DB.hero_ids_of_rarity(rarity).size()
	return float(DB.meta["gold_recruit"]["odds"][rarity]) / float(maxi(1, n))


## 병사 모집 (골드): tier by odds (기본 / 정예), then a troop of that tier with equal odds.
static func pull_soldier(rng: RandomNumberGenerator) -> String:
	var tier := roll_rarity(rng, DB.meta["soldier_recruit"]["odds"])
	var ids := DB.soldier_ids_of_tier(tier)
	return String(ids[rng.randi_range(0, ids.size() - 1)])


## Per-troop chance in percent for the 병사 모집 odds table.
static func soldier_chance(id: String) -> float:
	var tier := String(DB.soldier(id).get("tier", "basic"))
	var n := DB.soldier_ids_of_tier(tier).size()
	return float(DB.meta["soldier_recruit"]["odds"][tier]) / float(maxi(1, n))


## 보물 상자: rarity by odds, 영웅+ guaranteed after [pity] boxes. Returns {tid, rarity, pity}.
static func roll_box(rng: RandomNumberGenerator, pity: int) -> Dictionary:
	var box: Dictionary = DB.meta["treasure"]["box"]
	var rarity := roll_rarity(rng, box["odds"])
	if pity + 1 >= int(box["pity"]) and (rarity == "common" or rarity == "rare"):
		rarity = "epic"
	var pool := DB.treasures_of_rarity(rarity)
	var t: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var good := rarity == "epic" or rarity == "legend"
	return {"tid": String(t["id"]), "rarity": rarity, "pity": 0 if good else pity + 1}
