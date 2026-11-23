# 운빨삼국 — UI 테마 기획서 (Codex 의뢰용, 2026-11-22)

이 문서대로 UI 부품 그림을 만들어 주세요. 지금 게임은 부품 그림 없이 **선(테두리)만으로** 그린 임시 UI로 돌아갑니다(`src/ui/kit/px.gd`의 `LINE_UI`). 부품이 오면 이름 그대로 바꿔 끼웁니다.

---

## 1. 테마 한 줄

**"밝은 낮의 픽셀 삼국지 + 깔끔한 남색 판"**
배경(성문, 들판)은 밝고 따뜻한 픽셀 그림입니다. UI는 그 위에 떠 있는 **짙은 남색 판 + 얇고 선명한 밝은 테두리**입니다. 나무 질감, 쇠 리벳, 낡은 종이처럼 무겁고 올드한 장식은 쓰지 않습니다.

| 기준 | 할 것 | 하지 말 것 |
|---|---|---|
| 판 | 짙은 남색 단색 판, 테두리 1~2픽셀 밝은 선, 모서리 1픽셀 깎기 | 나무결, 쇠 리벳, 금박 덩굴 장식 |
| 버튼 | 색 판 + 밝은 테두리 + 아래 2픽셀 어두운 그림자(볼록함) | 광택 그라데이션, 반짝이 |
| 강조 | 금색 테두리 하나 | 금테 + 보석 + 리본 겹치기 |
| 글자 | 흰 글자 + 검은 외곽 1픽셀, 픽셀 폰트(Galmuri) | 붓글씨 장식 글꼴 |
| 아이콘 | 작은 픽셀 아이콘, 바깥 검은 선 | 3D 렌더, 사진풍 |
| 세력색 | 장수 카드 안에서만 (위 파랑, 촉 초록, 오 빨강, 군웅 보라) | 공통 UI에 세력색 |

참고 그림: `docs/screens/v5/00-style-reference-lobby.webp` (배경 그림체 기준). UI만 이 문서의 남색 선 스타일로 바꿉니다.

## 2. 색

| 이름 | 값 | 쓰는 곳 |
|---|---|---|
| 판 바탕 | `#121820` | 큰 창, 대화창 |
| 판 안쪽 | `#0d1117` | 칸, 슬롯, 목록 줄 바탕 |
| 보조 판 | `#171e27` | 작은 판, 재화 칩 |
| 선 밝음 | `#d5dce5` | 큰 창 테두리 |
| 선 보통 | `#a7b2c0` | 작은 판 테두리 |
| 선 어두움 | `#4f5a6a` | 칸 테두리 |
| 금 | `#ffd447` | 선택, 주요 버튼 테두리, 숫자 강조 |
| 빨강 | `#ff6b5b` / 바탕 `#4a1717` | 전투, 위험, 출정 |
| 보라 | `#c79bff` / 바탕 `#2c1d45` | 다이아 관련 |
| 파랑 | `#6fb6ff` / 바탕 `#152536` | 정보, 보조 |
| 회색 글자 | `#cdb994` → 바꿀 것: `#aab4c2` | 설명 글 |

## 3. 버튼 상태

| 상태 | 모습 |
|---|---|
| 기본 | 색 바탕 + 밝은 테두리 + 아래쪽 2픽셀 짙은 그림자 |
| 눌림 | 전체가 3픽셀 아래로, 그림자 없음, 바탕 10% 밝게 |
| 꺼짐 | 채도 0, 밝기 55% |
| 선택 | 바깥에 금색 1픽셀 선 + 검은 1픽셀 선 |
| 알림 | 오른쪽 위 빨간 점 (지름 22, 검은 테) |

각 버튼은 **기본 / 눌림 두 장**을 주세요(`이름.png`, `이름_pressed.png`).

## 4. 부품 목록 (파일 이름 = 코드 이름)

모두 PNG, 투명 배경, **픽셀 배율 3배**(아트 픽셀 1칸 = 화면 3px), 최근접 보간. 9-slice는 모서리 여백을 `cuts.json`에 적어 주세요(예: `{"panel_ctrl": {"margin": 18}}`).

### 4.1 판 (9-slice)

| 이름 | 지금 선 스타일 | 쓰는 곳 | 최소 크기 |
|---|---|---|---|
| `panel_ctrl` | 바탕 #121820, 선 #d5dce5 3px | 대화창, 큰 창, 슬롯 조작판 | 120×120 |
| `panel_wide` | 같음 | 넓은 정보판 | 160×80 |
| `panel_slot` | 바탕 #0d1117, 선 #4f5a6a 2px | 칸, 목록 줄, 진행 막대 바탕 | 60×60 |
| `panel_small` | 바탕 #171e27, 선 #a7b2c0 2px | 작은 판, 목록 줄 | 80×60 |
| `panel_chip` | 같음 | 골드·다이아 칩 | 160×56 |
| `plate_title` | 바탕 #1b222c, 선 금 3px | 창 제목판 | 240×80 |
| `plate_lever` | 같음 | 레버 아래 비용판 | 140×56 |
| `tile` | 바탕 #0d1117 60%, 선 #3a4452 | 전투 대기석 칸 | 118×118 |
| `frame_portrait` | 바탕 #0d1117, 선 #d5dce5 | 초상 틀 | 120×120 |

### 4.2 버튼 (9-slice, 기본 + `_pressed`)

| 이름 | 색 | 쓰는 곳 |
|---|---|---|
| `tab_yellow` | 금 | 주요 행동 (확인, 구매, 출정 준비) |
| `tab_red` | 빨강 | 전투 시작, 출정, 포기 |
| `tab_purple` | 보라 | 다이아로 하는 것 (10회 모집, 추가 입장) |
| `tab_blue` | 파랑 | 정보 (확률 정보) |
| `tab_wood` | 회남색 (이름은 그대로) | 보조 버튼, 안 고른 탭 |
| `tab_wood_on` | 회남색 + 금 테 | 고른 탭 |
| `btn_small` | 보조 판 | 필터 칩, 작은 토글 |

### 4.3 아이콘 버튼 (통째 그림, 기본 + `_pressed`, 정사각)

| 이름 | 안의 아이콘 | 크기 |
|---|---|---|
| `btn_settings` | 톱니 | 96 |
| `btn_mail` / `btn_mission` | 편지 / 두루마리 | 112 |
| `btn_bag` / `btn_recruit` | 가방 / 보물상자 | 112 |
| `sign_battle` / `btn_arena` | 깃발 / 엇갈린 칼 (+ 숫자 자리 오른쪽 비움) | 150×147 |
| `btn_pause` | 두 줄 | 72 |
| `btn_plus` | + | 40 |
| `btn_battle` | 엇갈린 칼 (전투 시작, 빨강) | 250×120 |
| `btn_nudge` / `btn_advisor` / `btn_speed` / `btn_bench` | 위아래 화살표 / 깃털부채 / 빨리감기 / 투구 | 120 |
| `lever` | 레버 (손잡이 빨간 공, 당김 / 안 당김 2장) | 150×300 |

### 4.4 아이콘 (작은 그림, 투명, 64×64 기준)

지금 있는 이름: `icon_gold`, `icon_diamond`, `icon_rice`(군량), `icon_medal`(군공), `icon_scroll`(모집권), `icon_chest`, `icon_flag`, `icon_swords`, `icon_gear`, `icon_mail`, `icon_bag`, `icon_updown`, `icon_fan`, `icon_fast`, `icon_deploy`, `icon_pause`, `ic_star`, `ic_star_off`, `ic_sword`, `ic_heart`, `ic_shield`, `class_inf/arc/cav/str`, `rarity_common/rare/epic/legend`. 같은 스타일로 다시 그려 주세요.

## 5. 화면별로 꼭 맞춰 볼 곳

| 화면 | 확인할 것 |
|---|---|
| 로비 | 위 바(초상·골드·다이아·설정), 왼쪽 우편·임무, 오른쪽 가방·모집, 성문 앞 팻말 2개 |
| 전투 | 위 칩 줄(군량·병사·장수·웨이브·배속·일시정지), 성 체력 막대, 대기석 8칸, 슬롯 3×3 판, 레버판 |
| 가방 | 탭 3개(장수·병종·보물), 깃발 토글, 카드 칸 |
| 모집 | 탭 2개(병사 모집·장수 모집), 1회/10회 버튼, 천장 막대 |
| 팝업 | 제목판 + 닫기 X + 확인/취소 두 버튼 |

**화면 자리: `design/ux/규격/측정표.md`** (옛 배치 지도는 2026-11-23 삭제) (41화면, 초록 A번호 = 컨테이너 영역, 자동 점검 `점검.md` 0건) — 38개 화면·팝업마다 글자(노랑) · 그림(파랑) · 버튼(빨강) · 판(회색) 자리와 크기를 표시한 그림과 표. 부품과 아이콘은 이 크기에 맞춰 그린다. 다시 뽑기: `bash tools/layout_map.sh`.
캐릭터 크기 기준: `design/art/캐릭터-도트-컨셉.md` (24 × 24 도트 / 기병 32 × 28 / 보스 40 × 40, 발 = 칸 아래 가운데).

## 6. Codex 프롬프트 틀

```
Pixel-art mobile game UI kit, 3x pixel scale, transparent background, nearest-neighbor.
Style: clean dark navy panels (#121820) with thin bright 1-2 px outlines (#d5dce5),
1-pixel cut corners, small 2 px drop shadow under buttons. No wood grain, no metal rivets,
no gold filigree, no gradients. Bright daytime Three Kingdoms pixel game, cute but tidy.
Draw: [부품 이름 목록], each as a separate sprite on a grid with 16 px gaps,
plus a pressed variant (moved down 3 px, no shadow). Korean text is NOT drawn on parts.
```

- 글자는 부품에 넣지 마세요. 글자는 게임이 그립니다.
- 한 번에 너무 많이 시키면 스타일이 흔들립니다. 판 → 버튼 → 아이콘 버튼 → 아이콘 순서로 나눠 주세요.
- 마음에 드는 결과를 다음 요청의 참고 이미지로 넣어 같은 스타일을 유지하세요.
