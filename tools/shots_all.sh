#!/usr/bin/env bash
# Captures every review screenshot into /workspace/grok_fortune3k_shots/.
set -e
cd "$(dirname "$0")/.."
S=tools/shot.sh
godot_bin="$HOME/bin/godot"
rm -f /tmp/f3k_shot_seed.json
xvfb-run -a -s "-screen 0 1280x2000x24" "$godot_bin" --path . res://tools/kit_sheet.tscn >/dev/null 2>&1
# 새 계정 (인트로 · 튜토리얼)
$S 01_intro intro --shot_after=1.5
$S 02a_tutorial_lobby lobby '--params={"tutorial":true}' --shot_after=1
$S 02b_tutorial_jackpot battle '--params={"tutorial":true}' --demo=tut_jackpot --shot_after=5
$S 02c_tutorial_nudge battle '--params={"tutorial":true}' --demo=tut_nudge --shot_after=6
$S 02d_tutorial_drag battle '--params={"tutorial":true}' --demo=tut_drag --shot_after=4
$S 02e_tutorial_recruit recruit --shot_after=1
$S 03_lobby lobby --shot_after=1
# 중반 계정
"$godot_bin" --headless --path . -s res://tools/make_seed.gd >/dev/null 2>&1
$S 03b_lobby_mid lobby --shot_after=1.5
$S 04a_battle_prep battle '--params={"chapter":1,"stage":5}' --demo=prep --shot_after=2
$S 04b_battle_fight battle '--params={"chapter":1,"stage":5}' --demo=fight --shot_after=4
$S 04c_battle_boss battle '--params={"chapter":1,"stage":5}' --demo=boss --shot_after=4
$S 04d_battle_pause battle '--params={"chapter":1,"stage":5}' --demo=prep --popup=pause --shot_after=2
$S 05_stage stage --shot_after=1
$S 06a_bag_heroes heroes --shot_after=1
$S 06b_bag_treasures heroes '--params={"tab":1}' --shot_after=1
$S 07a_hero_up hero '--params={"id":"guanyu"}' --shot_after=1
$S 07b_hero_star hero '--params={"id":"guanyu","tab":1}' --shot_after=1
$S 07c_hero_treasure hero '--params={"id":"guanyu","tab":2}' --shot_after=1
$S 09a_recruit recruit --shot_after=1
$S 09b_recruit_odds recruit --popup=odds --shot_after=1
$S 09c_recruit_result recruit --popup=recruit_result '--popup_params={"count":10,"cards":[{"id":"lvbu","rarity":"legend","new":true},{"id":"zhangfei","rarity":"rare"},{"id":"machao","rarity":"epic"},{"id":"xuchu","rarity":"rare"},{"id":"ganning","rarity":"rare"},{"id":"zhouyu","rarity":"epic","new":true},{"id":"dianwei","rarity":"rare"},{"id":"taishici","rarity":"rare"},{"id":"lvmeng","rarity":"rare"},{"id":"huangzhong","rarity":"rare"}]}' --shot_after=3
$S 10a_shop shop --shot_after=1
$S 10b_shop_diamond shop '--params={"tab":1}' --shot_after=1
$S 10c_shop_gold shop '--params={"tab":2}' --shot_after=1
$S 10d_shop_package shop '--params={"tab":3}' --shot_after=1
$S 10e_purchase shop --popup=purchase '--popup_params={"id":"d980","name":"다이아 980","desc":"첫 구매 보너스로 다이아 1,960개!","price":19000}' --shot_after=1
$S 11_arena arena --shot_after=1
$S 12_settings lobby --popup=settings --shot_after=1
$S 13a_mail lobby --popup=mail --shot_after=1
$S 13b_missions lobby --popup=missions --shot_after=1
$S 13c_profile lobby --popup=profile --shot_after=1
