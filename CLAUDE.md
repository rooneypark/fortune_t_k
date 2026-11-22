# 운빨삼국 — 작업 규칙 (Claude Code)

- **한국어로 답한다.** 사용자는 기획자(민수). 짧고 쉬운 말로, 표를 잘 쓴다.
- **커밋·푸시는 사용자가 시킬 때만.**
- 엔진: Godot 4.7(GDScript). Godot 실행 파일이 PATH에 없을 수 있다 (`run_game.cmd`가 winget 경로를 찾는다).
- 데이터는 `tools/build_data.py`, 문구는 `tools/strings_ko.py`에서 고치고 다시 실행한다. `data/*.json`을 직접 고치지 않는다.
- 화면을 바꾸면 `bash tools/layout_map.sh`로 배치 지도와 점검을 다시 뽑는다. **점검 0건**을 유지한다.
- 화면 변경은 스크린샷으로 확인한다 (`--route=<화면> --shot=<png> --shot_window=512x896`, App 스크린샷 모드).
- 테스트: `godot --headless --path . -s res://tests/run_tests.gd` (모두 통과 유지).
- 그림은 지금 전부 임시(`tools/draw_art.py`). 다른 게임에서 뽑은 그림·리소스는 절대 넣지 않는다.
- 최신 기획: `design/gdd/병종-장수-재설계.md`가 다른 기획서보다 우선.
- 현재 상태와 다음 할 일: `HANDOFF.md`.
