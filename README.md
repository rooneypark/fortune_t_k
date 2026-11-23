# 운빨삼국 (fortune_t_k)

Godot 4.7 세로형(1024 × 1792) 모바일 게임. 스테이지마다 군량으로 **슬롯 3칸**을 돌려(칸마다 당첨 33%)
병사와 장수를 얻고, 가로 전장에서 10웨이브 동안 성을 지킨다. 전투 중 흡수로 성급 · 속성을 올리면 계정에 남는다.
전투 밖은 장수 · 병사 도감, 장비(무기 · 갑옷 · 장신구) 합성, 군웅대전, 상점. 재화는 금 하나.

> **그림 안내** — 배경(`assets/bg`)을 뺀 캐릭터·초상(`tools/draw_units24.py`, 24도트 규격)·아이콘(`tools/draw_art.py`)은 코드로 직접 그린 **임시 그림**이다.
> 버튼·판은 그림 없이 선 + 글자(`Px.LINE_UI`). 밸런스를 잡은 뒤 전부 다시 그린다.

## 실행

| 방법 | 명령 |
|---|---|
| 게임 | `run_game.cmd` (winget Godot 4.7.2 경로, 없으면 PATH의 `godot`) · 또는 Godot 4.7에서 `project.godot` 열고 F5 |
| 테스트 | `run_tests.cmd` · `godot --headless --path . -s res://tests/run_tests.gd` |
| 스크립트 검사 | `godot --headless --path . res://tools/check_scripts.tscn` |
| 데이터 다시 만들기 | `python tools/build_data.py` · `python tools/strings_ko.py` (JSON은 손으로 고치지 않는다) |
| 임시 그림 다시 그리기 | `python tools/draw_art.py` (캐릭터 · 얼굴 · 아이콘 전부) · 캐릭터만은 `python tools/draw_units24.py` · 무기 아이콘은 `python tools/draw_weapons.py` |
| 화면 점검 (창 없음) | `godot --headless --path . --audio-driver Dummy res://tools/smoke.tscn -- --no-save --save=<임시 json>` |
| 모의 전투 | 위와 같은 방식으로 `res://tools/sim.tscn` (`--quick`) |
| UI 실측표 | `res://tools/layout_dump.tscn` → `python tools/ui_spec.py` → `design/ux/규격/측정표.md` |

저장은 `user://save.json` (설정 → 계정에서 초기화).

## 구조

```
project.godot        세로 1024×1792 (창은 256×448로 뜬다), canvas_items + expand, 최근접 필터
src/autoload/        Game(프로필·저장·설정), Sfx
src/core/            DB · Profile(계정 행동) · SlotMachine · RunState · UnitState · Gacha(확률) · MetaRules · Art   ← 노드 없이 테스트
src/battle/          BattleField(가로 전장 · 도트 이펙트) · SlotView · Fighter
src/app/             App: 화면 전환, 로비 위 대화창, 팝업
src/ui/kit/          Px(팔레트·폰트·선 UI·기록) · PxButton · PxPopup · PxScreen · W(공용 위젯) · Growth(성급·속성·장비 판)
src/ui/screens/      intro · lobby · battle · heroes(장수/병사/아이템) · hero · troop · shop · arena
src/ui/popups/       difficulty · absorb · synth · treasure · odds · wave_clear · result · pause · confirm · reward
                     purchase · mail · missions · profile · settings · arena_shop
data/*.json          tools/build_data.py, tools/strings_ko.py 가 만든다
assets/              bg(배경) · units/portraits/ui(임시 그림) · fonts(Galmuri, OFL) · sfx(tools/make_sfx.py)
design/              기획서(gdd) · 화면(ux, 규격) · 그림(art) · 옛 문서(_archive)
tests/unit/          슬롯 · 런 · 메타 · 확률 · 프로필 · 데이터 · 전투
tools/               데이터·그림 생성, 창 없는 점검(smoke · sim · layout_dump)
```

## 기획 문서 (읽는 순서)

1. `HANDOFF.md` — 지금 상태와 다음 할 일
2. `design/gdd/스테이지-흡수-합성-개편.md` — **최신 기획, 다른 문서보다 우선**
3. `design/게임-진행-흐름.md` — 전체 흐름과 점검 결과
4. `design/ux/UI-그림-규격.md`, `design/art/캐릭터-도트-컨셉.md` — 도트 규격, 그림 크기
5. `design/gdd/병종-장수-재설계.md`, `운빨삼국-GDD_v5.md`, `메타-성장-과금.md`, `콘텐츠-기획-v5.md` — 개편 전 기획 (개편 문서와 다르면 개편 문서가 맞다)

## 원칙

- 재화는 금 하나. 금으로 사는 것은 군량과 편의(전장 칸, 스테이지 되돌리기)뿐이다. 슬롯 확률은 게임 안에 공개한다.
- 777·슬롯머신 아이콘을 쓰지 않는다.
- 다른 게임의 그림·이름·수치를 가져오지 않는다. 장수 이름은 역사 인물.
- 결제는 개발용 가상 결제(스토어 연동 전).
