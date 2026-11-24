# 운빨삼국 — 작업 규칙 (Claude Code)

- **한국어로 답한다.** 사용자는 기획자(민수). 짧고 쉬운 말로, 표를 잘 쓴다.
- **커밋·푸시는 사용자가 시킬 때만.**
- 엔진: Godot 4.7(GDScript). Godot 실행 파일이 PATH에 없을 수 있다 (`run_game.cmd`가 winget 경로를 찾는다).
- 데이터는 `tools/build_data.py`, 문구는 `tools/strings_ko.py`에서 고치고 다시 실행한다. `data/*.json`을 직접 고치지 않는다.
- 화면을 바꾸면 창 없는 점검을 돌린다: `tools/check_scripts.tscn` → 테스트 → `tools/smoke.tscn`. 자리 값이 필요하면 `tools/layout_dump.tscn` + `python tools/ui_spec.py`.
- 게임 창은 사용자가 직접 띄워서 본다. 스크린샷은 꼭 필요할 때만 최소한으로 (`--position 10000,10000`, `--route=<화면> --shot=<png> --shot_window=256x448`).
- 테스트: `godot --headless --path . -s res://tests/run_tests.gd` (모두 통과 유지).
- 그림: 로비 · 전투 UI는 제미나이 그림(`design/art/ui_src/` → `tools/import_lobby_ui.py` · `import_battle_ui.py`), 나머지는 임시(캐릭터 `tools/draw_units24.py`, 아이콘 `tools/draw_art.py`). 게임 창은 사용자가 직접 띄운다 — 확인은 창 없는 검사와 합성 그림으로. 다른 게임에서 뽑은 그림·리소스는 절대 넣지 않는다.
- 최신 기획: `design/gdd/스테이지-흡수-합성-개편.md`가 다른 기획서보다 우선. 옛 기획서는 `design/_archive/`.
- 현재 상태와 다음 할 일: `HANDOFF.md`.
