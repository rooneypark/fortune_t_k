# 운빨삼국 (fortune_t_k)

Godot 4.7 세로형(1024 × 1792) 모바일 게임. 출정마다 군량으로 **천명 슬롯 3×3(5줄)** 을 돌려
같은 병종 줄을 맞추면 병사를, 그 줄에 장수가 끼면 장수를 영입하고, 10웨이브 동안 성을 지킨다.
전투 밖은 장수·병종 수집과 성장(성급·강화·보물), 군웅대전, 상점.

> **그림 안내** — 배경(`assets/bg`)을 뺀 캐릭터·초상·아이콘은 `tools/draw_art.py`로 직접 그린 **임시 그림**이다.
> 버튼·판은 그림 없이 선 + 글자(`Px.LINE_UI`). 밸런스를 잡은 뒤 전부 다시 그린다.

## 실행

| 방법 | 명령 |
|---|---|
| 게임 | `run_game.cmd` (winget Godot 4.7.2 경로, 없으면 PATH의 `godot`) · 또는 Godot 4.7에서 `project.godot` 열고 F5 |
| 테스트 | `run_tests.cmd` · `godot --headless --path . -s res://tests/run_tests.gd` |
| 스크립트 검사 | `godot --headless --path . res://tools/check_scripts.tscn` |
| 데이터 다시 만들기 | `python tools/build_data.py` · `python tools/strings_ko.py` (JSON은 손으로 고치지 않는다) |
| 임시 그림 다시 그리기 | `python tools/draw_art.py` (캐릭터·초상·아이콘) · `python tools/make_bones.py` (뼈대) |
| 배치 지도 + 점검 | `bash tools/layout_map.sh` → `design/ux/배치-지도/` (점검 0건이 목표) |

저장은 `user://save.json` (설정 → 계정에서 초기화).

## 구조

```
project.godot        세로 1024×1792, canvas_items + expand, 최근접 필터
src/autoload/        Game(프로필·저장·설정), Sfx
src/core/            DB · Profile(계정 행동) · SlotMachine · RunState · Gacha · MetaRules · Art   ← 노드 없이 테스트
src/battle/          BattleField · SlotView · Fighter
src/app/             App: 화면 전환, 로비 위 대화창, 팝업, 배치 기록(--layout)
src/ui/kit/          Px(팔레트·폰트·선 UI·기록) · PxButton · PxPopup · Guide · W(공용 위젯)
src/ui/screens/      intro · lobby · stage · battle · heroes · hero · troop · recruit · shop · arena
src/ui/popups/       lineup(출정 편성) · settings · pause · wave_clear · result · absorb · reward · confirm
                     treasure · recruit_result · odds · purchase · mail · missions · profile · arena_shop
data/*.json          tools/build_data.py, tools/strings_ko.py 가 만든다
assets/              bg(배경) · units/portraits/ui(임시 그림) · fonts(Galmuri, OFL) · sfx(tools/make_sfx.py)
design/              기획서(gdd) · 화면(ux, 배치 지도) · 그림(art, 뼈대 bones)
tests/unit/          슬롯 · 런 · 메타 · 모집 · 프로필 · 데이터 · 전투
```

## 기획 문서 (읽는 순서)

1. `design/gdd/병종-장수-재설계.md` — 병종 10 · 장수 32(B/A/S/SS) · 슬롯 규칙 · 출정 편성 · 모집 3종 (**최신, 다른 문서보다 우선**)
2. `design/gdd/운빨삼국-GDD_v5.md` — 전투 · 흡수 · 특성 · 성 · 부활
3. `design/gdd/메타-성장-과금.md`, `design/gdd/콘텐츠-기획-v5.md` — 성장 · 재화 순환 · 군공 · 콘텐츠 수치
4. `design/ux/UI-테마-기획서.md`, `design/ux/배치-지도/README.md` — UI 그림 의뢰 기준과 모든 화면의 자리
5. `design/art/bones/README.md` — 캐릭터 크기 기준과 뼈대

## 원칙

- 다이아로 군량·슬롯·군공·런 결과를 살 수 없다. 확률형(장수 모집·보물 상자)은 확률과 천장을 게임 안에 공개한다.
- 777·슬롯머신 아이콘을 쓰지 않는다.
- 다른 게임의 그림·이름·수치를 가져오지 않는다. 장수 이름은 역사 인물.
- 결제는 개발용 가상 결제(스토어 연동 전).
