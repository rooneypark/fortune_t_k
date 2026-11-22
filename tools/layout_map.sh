#!/usr/bin/env bash
# 배치 지도: 화면·팝업마다 스크린샷 + 그려진 자리(글자·그림·버튼·판) JSON을 뽑고
# tools/layout_map.py 로 표시 그림과 문서를 만든다.
# Usage: bash tools/layout_map.sh [godot binary]
set -e
cd "$(dirname "$0")/.."
G="${1:-/c/Users/pms10/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="design/ux/배치-지도/raw"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
SEED="$TMP/seed.json"
"$G" --headless --path . -s res://tools/make_seed.gd -- "$SEED" >/dev/null 2>&1
shot() {  # name route [args...]
  local n="$1" r="$2"; shift 2
  local save="$TMP/save.json"
  if [ "$1" = "fresh" ]; then shift; rm -f "$save"; else cp "$SEED" "$save"; fi
  timeout 60 "$G" --path . --audio-driver Dummy -- --route="$r" --shot="$OUT/$n.png" --layout="$OUT/$n.json" \
    --save="$save" --no-save --shot_window=512x896 "$@" 2>&1 | grep -E "SCRIPT ERROR|layout saved" | sed 's/.*배치-지도.raw.//' | head -3
}
B='--params={"chapter":1,"stage":5}'
shot 01_intro intro --shot_after=1.5
shot 02_lobby lobby --shot_after=1.5
shot 03_stage stage --shot_after=1
shot 03b_pop_lineup stage '--popup=lineup' '--popup_params={"chapter":1,"stage":5}' --shot_after=1.5
shot 03c_pop_lineup_new stage fresh '--popup=lineup' '--popup_params={"chapter":1,"stage":1}' --shot_after=1.5
shot 04_battle_prep battle "$B" --demo=prep --shot_after=2
shot 05_battle_fight battle "$B" --demo=fight --shot_after=4
shot 06_heroes_hero heroes --shot_after=1
shot 07_heroes_troop heroes '--params={"tab":1}' --shot_after=1
shot 08_heroes_treasure heroes '--params={"tab":2}' --shot_after=1
shot 08b_troop_up troop '--params={"id":"spear"}' --shot_after=1
shot 08c_troop_star troop '--params={"id":"spear","tab":1}' --shot_after=1
shot 40b_tutorial_nudge battle fresh '--params={"tutorial":true}' --demo=tut_nudge --shot_after=6
shot 09_hero_up hero '--params={"id":"guanyu"}' --shot_after=1
shot 10_hero_star hero '--params={"id":"guanyu","tab":1}' --shot_after=1
shot 11_hero_treasure hero '--params={"id":"guanyu","tab":2}' --shot_after=1
shot 12_recruit_soldier recruit --shot_after=1
shot 13_recruit_hero recruit '--params={"tab":1}' --shot_after=1
shot 13b_recruit_gold recruit '--params={"tab":2}' --shot_after=1
shot 26b_pop_odds_gold recruit '--popup=odds' '--popup_params={"kind":"hero_gold"}' --shot_after=1.5
shot 14_shop_rec shop --shot_after=1
shot 15_shop_dia shop '--params={"tab":1}' --shot_after=1
shot 16_shop_gold shop '--params={"tab":2}' --shot_after=1
shot 17_shop_pack shop '--params={"tab":3}' --shot_after=1
shot 18_arena arena --shot_after=1
shot 20_pop_settings lobby --popup=settings --shot_after=1.5
shot 21_pop_mail lobby --popup=mail --shot_after=1.5
shot 22_pop_missions lobby --popup=missions --shot_after=1.5
shot 24_pop_profile lobby --popup=profile --shot_after=1.5
shot 25_pop_arena_shop arena --popup=arena_shop --shot_after=1.5
shot 26_pop_odds_hero recruit --popup=odds --shot_after=1.5
shot 27_pop_odds_soldier recruit '--popup=odds' '--popup_params={"kind":"soldier"}' --shot_after=1.5
shot 28_pop_odds_box shop '--popup=odds' '--popup_params={"kind":"box"}' --shot_after=1.5
shot 29_pop_confirm lobby '--popup=confirm' '--popup_params={"title":"구매","text":"다이아 50으로 골드 10,000을 살까요?","ok":"구매"}' --shot_after=1.5
shot 30_pop_purchase shop '--popup=purchase' '--popup_params={"id":"p_start","name":"출정 준비 꾸러미","desc":"모집권 5 · 골드 50,000","price":4400}' --shot_after=1.5
shot 31_pop_reward lobby '--popup=reward' '--popup_params={"reward":{"gold":5000,"diamond":30,"tickets":1}}' --shot_after=1.5
shot 32_pop_recruit_result recruit '--popup=recruit_result' '--popup_params={"cards":[{"type":"hero","id":"lvbu","new":true,"rarity":"legend"}],"count":1}' --shot_after=2
shot 33_pop_recruit_ten recruit '--popup=recruit_result' '--popup_params={"kind":"soldier","count":10,"cards":[{"id":"spear"},{"id":"halberd","new":true},{"id":"archer"},{"id":"rider"},{"id":"fire","new":true},{"id":"shield"},{"id":"spear"},{"id":"axe","new":true},{"id":"crossbow"},{"id":"heavy","new":true}]}' --shot_after=3
shot 34_pop_pause battle "$B" --demo=prep --popup=pause --shot_after=2
shot 35_pop_wave_clear battle "$B" --demo=wave_clear --shot_after=2
shot 36_pop_absorb battle "$B" --demo=absorb --shot_after=2
shot 37_pop_result_win battle "$B" --demo=prep --popup=result '--popup_params={"victory":true,"chapter":1,"stage":5,"waves":10,"castle":0.8,"stats":{"kills":120,"spins":24,"jackpots":3},"mvp":"guanyu","out":{"gold":1860,"rice_left":180,"rice_gold":360,"lord_exp":100,"stars":3}}' --shot_after=2
shot 38_pop_result_lose battle "$B" --demo=prep --popup=result '--popup_params={"victory":false,"chapter":1,"stage":5,"waves":6,"castle":0,"stats":{"kills":60},"mvp":"spear","can_continue":true}' --shot_after=2
shot 39_tutorial_lobby lobby fresh '--params={"tutorial":true}' --shot_after=1.5
shot 40_tutorial_battle battle fresh '--params={"tutorial":true}' --demo=tut_drag --shot_after=5
rm -rf "$TMP"
python -I tools/layout_map.py && python -I tools/layout_audit.py
