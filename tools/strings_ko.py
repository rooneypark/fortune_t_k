# -*- coding: utf-8 -*-
"""Korean UI strings -> data/strings_ko.json. Run: python3 tools/strings_ko.py"""
import json, os

S = {
 # common
 # 임시 글자 버튼 (그림 없는 UI 틀, 2026-11-22)
 "btn.btn_settings": "설정", "btn.btn_mail": "우편", "btn.btn_mission": "임무", "btn.btn_bag": "장수",
 "btn.btn_recruit": "아이템", "btn.sign_battle": "출정", "btn.btn_arena": "군웅", "btn.sign_arena": "군웅",
 "btn.btn_pause": "멈춤", "btn.btn_plus": "+", "btn.btn_battle": "전투 시작", "btn.btn_nudge": "밀기",
 "btn.btn_advisor": "책사", "btn.btn_speed": "배속", "btn.btn_bench": "배치", "btn.lever": "돌리기",
 "common.ok": "확인", "common.cancel": "취소", "common.buy": "구매", "common.no_gold": "금이 부족해요",
 
 "game.title": "운빨삼국", "game.subtitle": "천명 슬롯 삼국지",
 "intro.tap": "화면을 눌러 시작", "intro.tagline": "레버를 당겨 천하의 장수를 모아라!",
 "intro.proto": "임시 그림 · 내부 시험판",
 "guide.tap": "눌러서 계속",
 "quit.title": "게임 종료", "quit.text": "게임을 종료할까요?\n진행 상황은 자동 저장돼요.", "quit.ok": "종료",
 "reward.title": "획득!",
 # tabs
 "tab.heroes": "장수", "tab.items": "아이템", "tab.arena": "군웅대전", "tab.shop": "상점",
 # lobby
 "lobby.mail": "우편", "lobby.missions": "임무", "lobby.bag": "장수", "lobby.recruit": "아이템", "lobby.arena": "군웅대전", "lobby.sortie": "출정", "lobby.gate_stage": "출정", "lobby.gate_stage_sub": "스테이지 %d", "lobby.gate_arena": "군웅대전", "lobby.gate_arena_sub": "남은 입장 %d",
 "lobby.attendance": "출석 %d일차", "lobby.monthly": "월정액 금 +%d",
 # battle
 "battle.no_rice": "군량이 부족해요 · 위의 군량을 눌러 금으로 채울 수 있어요", "battle.no_spins": "이번 전투의 돌리기를 다 썼어요",
 "battle.new_unit": "%s 합류! (도감에 추가)", 
 "battle.field_full": "전장이 가득 찼어요 · 흡수해서 자리를 비우세요",
 "battle.wave_n": "웨이브 %d / %d", "battle.start": "전투 시작", 
 "battle.advisor": "책사", 
 "battle.rank": "★%d", "battle.refund": "잭팟! 군량 +%d",
 "battle.lost": "자리가 없어 %s 영입 실패",
 "battle.slot_max": "더 늘릴 수 없어요", "battle.buy_army": "전장 칸 늘리기",
 "battle.buy_text": "금 %d을 써서 전장을 한 칸 늘릴까요?\n(이번 출정 동안만 유지)",
 "battle.need_unit": "먼저 슬롯을 돌려 병력을 모으세요", "battle.judge": "판정 웨이브!",
 "battle.judge_sub": "양옆에서 기병이 기습해요", "battle.continued": "이어하기!",
 "battle.boss": "보스 출현", "battle.boss_short": "보스", "battle.tap_start": "눌러서 전투 시작",
 "battle.no_absorb_fight": "전투 중에는 흡수할 수 없어요",
 "absorb.max_star": "이미 최고 성급이에요", "absorb.guest": "손님 장수는 흡수할 수 없어요", "absorb.trait_max": "이미 최고 레벨이에요",
 "absorb.title": "흡수", "absorb.rank_label": "흡수 · 성급 경험", "absorb.trait_label": "흡수 · 속성 얻기",
 "absorb.rank_gain": "같은 병종 흡수 · 성급 경험 +%d", "absorb.rank_up": "★%d 달성!",
 "absorb.do": "흡수하기", "absorb.pick": "%s의 속성 하나를 고르세요", "absorb.slots": "속성 칸 %d / %d",
 "absorb.new": "새 속성", "absorb.star_banner": "%s ★%d 달성!", "absorb.stat_delta": "공격 %s → %s · 체력 %s → %s",
 "absorb.xp_hint": "%s 성급 경험 %d / %d", "absorb.trait_got": "%s · %s Lv.%d",
 "growth.star_hint": "전투에서 같은 병종을 흡수하면 올라요", "growth.lord_fx": "군주 Lv.%d · 기초 능력치 +%d%%",
 "growth.base": "기초 공격 %s · 방어 %s · 체력 %s", "growth.slots": "속성 칸 %d / %d", "growth.slot_empty": "빈 칸",
 "growth.slot_locked": "★%d에 열려요", "growth.trait_hint": "전투에서 다른 병종을 흡수하면 속성을 고를 수 있어요",
 "growth.strong": "강함: %s", "growth.weak": "약함: %s", "growth.none": "없음",
 "absorb.owned": "최고 레벨", "absorb.replace": "칸이 가득 찼어요 · 바꿀 속성을 고르세요",
 "slot.miss": "꽝", "slot.jackpot": "잭팟!", "slot.jackpot_sub": "3칸 모두 당첨 · 군량을 돌려받아요",
 "slot.nudge_tip": "꽝 줄의 위아래 칸을 누르면 그 칸을 끌어와요 (군량 1)", "slot.respin_tip": "다시 돌릴 꽝 칸을 누르세요",
 "slot.win_one": "%s 영입!", "slot.win_many": "%d명 영입!", "slot.no_blank": "다시 돌릴 꽝 칸이 없어요",
 "wave.title": "웨이브 %d 승리!", "wave.rice": "남은 돌리기", "wave.castle": "성 체력 회복", "wave.kills": "처치",
 "wave.mvp": "이번 웨이브 활약", "wave.mvp_line": "피해 %s · 처치 %d", "wave.next": "다음 웨이브 %d / %d",
 "wave.next_btn": "준비하기",
 "pause.title": "일시정지", "pause.resume": "계속하기", "pause.settings": "설정", "pause.give_up": "출정 포기",
 "pause.give_up_text": "출정을 포기할까요?\n지금까지 깬 웨이브만큼 보상을 받아요.", "pause.give_up_ok": "포기",
 "result.victory": "승리", "result.defeat": "패배", "result.clear": "스테이지 %s 클리어!",
 "result.fallen": "성이 함락되었다…", "result.waves": "웨이브", "result.kills": "처치", "result.spins": "돌리기",
 "result.jackpots": "대박", "result.mvp": "최고 활약", "result.rewards": "보상", "result.exp": "경험 %d",
 "result.first": "첫 클리어 %d", "result.continue": "이어하기", "result.lobby": "로비로", "result.next": "다음 스테이지",
 "result.again": "다시 출정", 
 "odds.tier_basic": "기본", "odds.tier_elite": "정예",
 "slot.hero_line": "%s 합류!", "slot.hero_sub": "장수가 나왔다!", "result.after": "출정을 마치면 깬 웨이브만큼 금을 받아요",
 # settings
 "settings.title": "설정", "settings.sound": "소리", "settings.play": "게임", "settings.bgm": "배경음", "settings.sfx": "효과음",
 "settings.slot": "슬롯 연출", "settings.fast": "빠르게", "settings.normal": "보통", "settings.off": "끄기",
 "settings.font": "글자 크기", "settings.small": "작게", "settings.large": "크게",
 "settings.vibrate": "진동", "settings.shake": "화면 흔들림", "settings.notify": "알림",
 "settings.support": "고객센터", "settings.terms": "약관", "settings.account": "계정",
 "settings.support_text": "개발 빌드입니다.\n문의는 개발 팀 채널로 남겨 주세요.",
 "settings.terms_text": "이용 약관 · 개인정보 처리방침은\n출시 전에 연결됩니다.",
 "settings.account_text": "계정 연동은 서버 연동 후 열려요.\n이 기기의 저장 데이터를 초기화할까요?",
 "settings.reset": "초기화", "settings.version": "버전 %s", "settings.proto": "내부 시험판 · 캐릭터 그림은 임시(출시 전 교체)",
 # tutorial
 "tut.gate": "주공! 황건적이 성으로 몰려옵니다.\n출정 팻말을 눌러 성을 지키십시오!",
 "tut.spin": "군량 1을 써서 천명 슬롯을 돌립니다.\n레버를 당기십시오!",
 "tut.jackpot": "첫 칸이 당첨!\n창병 1명이 전장에 섰습니다. 나머지 두 칸은 꽝입니다.",
 "tut.spin_again": "한 번 더! 한 전투에 열 번까지 돌릴 수 있습니다.",
 "tut.nudge": "세 칸 모두 꽝이군요. 위아래로 살짝 보이는 칸을\n누르면 그 칸을 끌어올 수 있습니다.",
 "tut.nudge_reel": "세 번째 줄 위에 보이는 궁병을 눌러\n가운데로 끌어내리십시오!",
 "tut.nudge_done": "궁병 영입! 재배치는 한 번 돌릴 때 한 번,\n위아래 어느 쪽이든 군량 1이 듭니다.",
 "tut.spin_third": "이번엔 장수가 나오기를 노려 봅시다!",
 "tut.drag": "관우가 도우러 왔습니다!\n당첨된 유닛은 바로 전장에 섭니다.",
 "tut.battle": "준비 완료! 전투 시작을 누르십시오.",
 "tut.wave": "적이 성벽에 닿으면 성 체력이 줄어요. 끝까지 지키십시오!",
 "tut.castle": "성벽이 공격받고 있어요! 병력을 앞쪽에 세우세요.",
 "tut.respawn": "쓰러진 유닛은 왼쪽 원의 시간이 지나면 부활해요.",
 "tut.absorb": "유닛을 다른 유닛 위로 끌어다 놓으면 흡수!\n같은 병종 = 성급 경험, 다른 병종 = 속성 하나를 얻어요.",
 "tut.free": "이제 자유롭게 싸우십시오. 10웨이브를 버티면 승리!",
 # stage
 "stage.n": "스테이지 %d", 
 "stage.locked_diff": "앞 난이도를 먼저 깨야 해요",
 "stage.back": "스테이지 되돌리기", "stage.back_ask": "금 %s을 내고 스테이지 %d (%s)로 되돌릴까요?\n다시 깨면 다음 스테이지로 넘어가요.", "stage.back_done": "스테이지 %d로 되돌렸어요", "stage.back_first": "첫 스테이지예요",
 
 # heroes
 "heroes.tab_heroes": "장수", "heroes.tab_troops": "병사", "heroes.mine": "내것만",
 "heroes.troop_hint": "칸을 누르면 병종 정보 · 가진 병종은 모두 슬롯에 나와요",
 "heroes.troop_owned": "보유 병종 %d / %d",
 "troop.title": "병종 정보", "troop.heroes": "이 병종 장수", 
 "heroes.all": "전체",
 "slot.weapon": "무기", "slot.armor": "갑옷", "slot.charm": "장신구",
 "stat.atk": "공격", "stat.def": "방어", "stat.hp": "체력", "stat.crit": "치명타", "stat.crit_dmg": "치명 피해",
 "stat.aspd": "공속", "stat.energy": "기력", "stat.guard": "피해 감소", "stat.spd": "이속",
 "rarity_t.common": "일반", "rarity_t.rare": "희귀", "rarity_t.epic": "영웅", "rarity_t.legend": "전설",
 # hero
 "hero.title": "장수 정보", "hero.not_owned": "아직 만나지 못한 장수예요.\n전투 중 슬롯에서 나오면 합류해요.", "troop.not_owned": "아직 없는 병종이에요.\n전투 중 슬롯에서 나오면 합류해요.",
 "dex.heroes": "장수 도감 %d / %d", "dex.items": "아이템 도감 %d / %d",
 "rice.full": "군량이 가득 차 있어요", "rice.title": "군량 채우기", "rice.ask": "금 %s으로 군량을 가득 채울까요?\n(지금 %d / %d · 5분에 1씩 저절로 차요)", "rice.done": "군량을 가득 채웠어요",
 "rice.name": "군량 즉시 충전", "rice.desc": "군량 1 = 금 %d · 지금 %d / %d", "rice.next": "다음 군량까지 %s", "rice.rule": "군량은 5분에 1씩 저절로 차요. 슬롯을 한 번 돌릴 때 1을 쓰고, 한 전투에 열 번까지 돌려요.",
 "hero.tab_up": "성장", "hero.tab_star": "속성", "hero.tab_treasure": "장비",
 "hero.advisor": "책사 기술 · %s", "hero.skill": "필살기 · %s", "hero.bonds": "인연", "hero.no_bond": "인연 없음",
 
 "hero.max_star": "최고 성급이에요", "hero.star_step": "★%d → ★%d",
 "hero.star_fx1": "기본 능력치 +%d%%", 
 "hero.auto_equip": "자동 장착", "hero.unequip": "해제", "hero.bag_slot": "가방 · %s", "hero.treasure_sum": "장비 효과 합계",
 # treasure
 "treasure.title": "장비", "treasure.exclusive": "전용 · %s", "treasure.main": "주 능력치", "treasure.subs": "부가 능력치",
 "treasure.unlock_at": "+%d에서 열림", "treasure.worn": "%s 장착 중", "treasure.enhance": "강화",
 "treasure.equip_to": "%s에게 장착", "treasure.equipped": "장착했어요", "treasure.equip_hint": "장수 · 병종 정보의 장비 탭에서 장착해요",
 "treasure.dismantle": "분해", "treasure.dismantle_text": "%s을(를) 분해할까요?\n금 %d을 돌려받아요.",
 "treasure.empty": "장비가 없어요",
 "treasure.got": "장비 획득!",
 "gear.normal": "일반 장비", "gear.special": "특수 능력 · %s", "gear.troop_hint": "병종이 장착하면 그 병종의 모든 병사가 효과를 받아요",
 "treasure.max": "최대 강화",
 "synth.title": "합성", "synth.open": "합성", "synth.mats": "재료 합성 · 같은 종류·등급 %d개 → 그 등급 장비 1개",
 "synth.fuse": "장비 합성 · 같은 등급 %d개 → 한 단계 위 장비 1개 (영웅부터 보물)", "synth.fuse_hint": "장착하지 않은 장비 중 강화가 낮은 것부터 써요",
 "synth.fuse_row": "%s %d개 → %s", "synth.have": "보유 %d", "synth.do": "합성",
 "synth.no_mats": "재료가 %d개 있어야 해요", "synth.no_treasures": "장착하지 않은 장비가 %d개 있어야 해요", "synth.top": "전설은 더 합성할 수 없어요",
 "synth.odds": "나오는 장비는 그 종류·등급 안에서 같은 확률이에요", "synth.mat_name": "%s %s 재료",
 "synth.summary": "재료 %d개", "result.mats": "재료 %d개",
 # recruit
 
 
 
 
 
 
 # odds
 "odds.title": "확률 정보", "odds.slot_rule": "슬롯 3칸 · 칸마다 당첨 확률 %d%% (전장이 비어 있으면 최소 1칸 당첨)",
 "odds.slot_hero": "당첨 칸의 %d%%는 장수, 나머지는 병사", "odds.slot_grades": "장수 등급 · B %s%% · A %s%% · S %s%% · SS %s%%", "odds.slot_tiers": "병사 · 기본 %s%% · 정예 %s%%",
 "odds.slot_new": "처음 나온 장수와 병종은 그 자리에서 합류해요", "odds.per_win": "당첨 칸 하나에서 나올 확률", "stage.odds": "확률", 
 
 # shop
 "shop.t_rec": "추천", "shop.t_dia": "금", "shop.t_gold": "군량", "shop.t_pack": "패키지",
 "shop.banner": "출정 준비,\n여기서 끝!", "shop.monthly_now": "즉시 금 %s", "shop.monthly_left": "%d일 남음",
 "shop.value": "총 금 %s",
 "shop.first": "첫 구매 2배", "shop.dia_name": "금 %s", "shop.dia_desc": "금 %s",
 "shop.first_desc": "첫 구매 보너스로 금 %s!", 
 "shop.bought": "구매 완료!",
 "shop.limit": "구매 %d / %d", "shop.sold_out": "구매 완료",
 "shop.mock_note": "개발용 가상 결제 — 실제 결제는 이루어지지 않아요.",
 "purchase.title": "구매 확인", "purchase.pay": "가상 결제", "purchase.done": "구매 완료!",
 "purchase.mock": "개발용 가상 결제예요. 스토어 결제 연동 전이라 실제 돈은 나가지 않아요.",
 # arena
 "arena.title": "군웅대전", 
 "arena.desc": "다른 주공과 겨뤄 군공을 모으자!\n하루 무료 5회 · 매일 04:00 초기화",
 "arena.power": "출전 전투력 %s", "arena.entries": "입장권 %d / %d", "arena.refill": "초기화까지 %s", "arena.fight": "도전하기", "arena.no_entry": "입장권이 부족해요", "arena.win": "군웅대전 승리! 군공 +%d", 
 "arena.buy": "추가 입장", "arena.buy_confirm": "금 %d으로 입장권 1장을 살까요? (오늘 %d / %d)", "arena.buy_limit": "오늘은 더 살 수 없어요",
 "arena.honor": "군공 %s", "arena.shop": "군웅 상점",
 "arena_shop.title": "군웅 상점", "arena_shop.note": "군공으로만 살 수 있어요 · 매주 월요일 04:00 초기화",
 "arena_shop.treasure": "영웅 보물",
 "arena_shop.treasure_desc": "영웅 등급 보물 1개", "arena_shop.rice": "군량 10", "arena_shop.rice_desc": "슬롯 열 번",
 "arena_shop.gold": "금 10,000", "arena_shop.gold_desc": "남은 군공 쓰기", "arena_shop.limit": "이번 주 %d / %d",
 "arena_shop.sold_out": "이번 주 구매 완료", "arena_shop.not_owned": "보유한 장수만 고를 수 있어요",
 "arena_shop.max_star": "이미 최고 성급이에요", "arena_shop.no_honor": "군공이 부족해요", "arena_shop.pick": "카드를 살 장수를 고르세요",
 "arena_shop.bought": "%s 카드 +1",
 # profile / mail / missions / pass
 "profile.title": "주공 정보", "profile.lv": "주공 Lv.%d", "profile.power": "편성 전투력 %s",
 "profile.runs": "출정", "profile.victories": "승리", "profile.jackpots": "3연 대박", "profile.kills": "처치",
 "profile.heroes": "보유 장수", "profile.honor": "군공", "profile.avatar": "대표 장수",
 "mail.title": "우편함", "mail.empty": "우편이 없어요", "mail.left": "%d일 남음", "mail.get": "받기", "mail.claimed": "받음",
 "mail.get_all": "모두 받기", "mail.delete": "읽은 우편 삭제",
 "missions.title": "임무", "missions.daily": "일일", "missions.weekly": "주간", "missions.achieve": "업적", "missions.go": "이동",
}


out = os.path.join(os.path.dirname(__file__), "..", "data", "strings_ko.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(S, f, ensure_ascii=False, indent=1, sort_keys=True)
print(len(S), "strings")
