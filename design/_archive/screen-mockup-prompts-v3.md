# 운빨삼국 — 화면 시안 프롬프트 v3 (세로, 귀여운 픽셀)

> **폐기 (2026-11-22).** 그림체가 카툰 2D로 바뀜. 정본은 `design/art/screen-mockup-prompts-v4.md`.

- 2026-11-22. 정본 기획: `design/gdd/운빨삼국-GDD_v5.md`, `design/gdd/메타-성장-과금.md`.
- **쓰는 법**: 이미지 크기를 **1024×1792(세로)** 로 설정 → 참고 이미지 2장 첨부 → 아래 코드 블록 하나를 통째로 붙여 넣기.
  - 참고 1 (UI): 확정된 로비 시안에서 **하단 메뉴를 잘라낸** 그림
  - 참고 2 (캐릭터): 꼬마 장수 3명이 나온 예전 로비 그림에서 **캐릭터 부분만 잘라낸** 그림 (로비는 이제 캐릭터가 없으므로)
  - 13-B, 13-C는 대신 **받은 13-A 전투 시안**을 참고로 넣는다.
- 하단 메뉴는 모든 화면에서 같다: 상단 바와 같은 스타일의 남색 띠 + 상단 재화 판처럼 나뉜 탭 판 5개, 컬러 아이콘, **장수 · 편성 · 군웅대전 · 모집 · 상점**. 선택된 탭은 얇은 금테.
- 각 프롬프트에 공통 규칙이 다 들어 있다. 화면 제목 "운빨삼국" 로고는 넣지 않는다.
- 받은 시안은 `docs/screens/v3/` 에 화면 번호 이름으로 모은다 (예: `03-hero-detail-upgrade.png`).

## 화면 목록

| 번호 | 화면 | 종류 |
|---|---|---|
| 01 | 로비 | 메인 |
| 02 | 장수 목록 (장수 / 병졸 탭) | 메뉴 |
| 03-A | 장수 상세 — 강화 탭 | 상세 |
| 03-B | 장수 상세 — 성급 탭 | 상세 |
| 03-C | 장수 상세 — 보물 탭 | 상세 |
| 04 | 편성 (장수·책사 고르기) | 메뉴 |
| 05-A | 모집 | 메뉴 |
| 05-B | 모집 결과 (10연) | 팝업 |
| 05-C | 확률 보기 | 팝업 |
| 06-A | 보물 가방 (장수 화면의 보물 탭) | 메뉴 |
| 06-B | 보물 상세·강화 | 팝업 |
| 07 | 상점 | 메뉴 |
| 08 | 임무 | 상단 메뉴 |
| 09 | 전공 패스 | 상단 메뉴 |
| 10 | 우편 | 상단 메뉴 |
| 11 | 주공 정보 | 초상 누르면 |
| 12 | 설정 | 톱니 |
| 13-A | 전투 — 기본 | 전투 |
| 13-B | 전투 — 꽝 + 한 칸 밀기 | 전투 상태 |
| 13-C | 전투 — 같은 장수 3연 대박 | 전투 상태 |
| 14 | 웨이브 결산 | 전투 팝업 |
| 15 | 시험·보스 경고 | 전투 팝업 |
| 16 | 일시정지 | 전투 팝업 |
| 17-A | 결과 — 승리 | 결과 |
| 17-B | 결과 — 패배 (이어하기 제안) | 결과 |
| 18 | 대전 (유저 대전) | 메뉴 — 기획 후 작성 (서버 필요) |

---

## 01. 로비

받을 때: 참고 이미지는 **하단 메뉴를 잘라낸** 로비 그림을 넣는다.

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall, like a phone held upright.

MOST IMPORTANT: the bottom bar labels are exactly 장수 | 편성 | 군웅대전 | 모집 | 상점. Never draw 월드맵, 보관함, 임무, 내정보 or 무장 in the bottom bar.

Create the LOBBY screen of a cute pixel-art Three Kingdoms battle game.

REFERENCE
Use the attached image ONLY for the art style: the cute chibi pixel style, the castle gate, the stone road, the sunset sky, the top bar and the gold button. Ignore its bottom area and its characters.

LAYOUT, TOP TO BOTTOM (percent of image height)
1. 0-7% - TOP BAR (dark navy) with LIGHT decoration: a thin gold line along its bottom edge, a faint darker navy cloud pattern inside the bar, and small gold cloud-scroll ornaments at the two bottom corners and under the lord portrait. Keep it subtle, not heavy:
   - Left: round lord portrait (small cute chibi face) with "Lv.4" and a thin gold bar.
   - Right: gold coin "12,500" with a small round gold "+" button, light-cyan diamond "350" with a small round gold "+" button, then a small round gear button.
2. 7-13% - Right side only: three small round icon buttons with tiny labels: envelope "우편" (small red dot), scroll with a check mark "임무", ribbon medal "패스".
3. 13-75% - The castle gate at the end of a wide stone road, sunset sky behind, plain navy banners with a gold emblem on both sides of the gate, lanterns and small braziers. The road is COMPLETELY EMPTY.
4. 76-86% - The biggest button on the screen: wide plump GOLD button, crossed-swords icon, text "출정" in dark navy.
5. 87-100% - BOTTOM BAR styled like the TOP BAR: dark navy strip with a thin gold line along its TOP edge and the same faint darker cloud pattern. Inside it, five SEPARATE tab plates in a row with small gaps between them; each plate is a rounded dark navy plate with a thin lighter-navy border, exactly like the currency plates in the top bar (no heavy gold frame, no corner ornaments). Each plate holds a small FULL-COLOR cute pixel icon with a short cream label under it, in this order: helmet with a red plume and gold trim "장수", small flag stuck in a parchment map "편성", two crossed spears with red tassels "군웅대전" (center), rolled scroll with a red seal "모집", tiny market stall with a red-and-cream striped awning "상점". The selected plate ("장수") has a thin GOLD border, a slightly lighter navy fill and a gold label.

STYLE RULES
- Clean pixel art, consistent pixel size, flat colors, no blur, no glow.
- No faction letters (魏, 蜀, 吳) and no faction-colored banners.
- Gold is the only accent color. No green, red or blue buttons.
- No game title or logo.

DO NOT ADD
- No characters or people anywhere except the small lord face in the top-left portrait.
- No "이어하기" card. Nothing between the gate road and the 출정 button.
- Bottom bar: no 내정보, 무장, 월드맵, 보관함 or 임무.
- No alliance, events, stamina, other currencies.
- No text other than: Lv.4, 12,500, 350, 우편, 임무, 패스, 출정, 장수, 편성, 군웅대전, 모집, 상점.
```

### 버튼 상태 (구현 기준)

| 상태 | 표현 |
|---|---|
| 기본 | 버튼 그림 그대로. 위쪽 1~2px 밝은 선, 아래쪽 2~3px 어두운 두께 |
| 눌림 | 버튼 전체가 아래로 2px 내려가고, 아래 두께가 사라지고, 위쪽 밝은 선이 없어지며 색이 10% 어두워짐. 손을 떼면 0.08초 만에 돌아옴 + 진동 짧게 |
| 꺼짐 | 회색으로 채도 빼기, 글자 흐리게, 눌러도 내려가지 않음 |
| 선택(하단 메뉴) | 아이콘·글자가 금색, 위에 짧은 금색 막대, 뒤가 조금 밝은 남색 |

눌림·꺼짐은 코드로 만든다(내려가기·어둡게·회색). 그래서 그림은 **기본 상태 한 장**만 있으면 된다.

## 02. 장수 목록

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the HERO LIST screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. Follow the layout below. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

STYLE RULES
- Clean pixel art, consistent pixel size, flat colors, no blur, no glow.
- UI accent color is GOLD. Faction colors appear ONLY on hero cards and filter chips: Wei blue, Shu green, Wu red, Warlords purple.

LAYOUT, TOP TO BOTTOM
1. 0-7% - Top bar: round back-arrow button on the left, title plate "장수" in the center, gold coin "12,500" and light-cyan diamond "350" on the right.
2. 7-12% - Three tabs: "장수" (selected, gold), "병졸", "보물".
3. 12-17% - Filter chips in one row: "전체" (selected), small round faction chips 위 / 촉 / 오 / 군웅 in their faction colors, and a small sort button "등급순" on the right. A counter "보유 18/40" on the left under the chips.
4. 17-86% - A 4-column grid of hero cards (5 rows visible, scrollable). Each card: chibi hero on a faction-colored background, small round faction badge in the top-left corner, name under the portrait, 1 to 6 small gold stars, "Lv.12" in a tiny plate. A few cards are not owned: dark grey silhouette with a "?" and a small lock. Two owned cards show a small red dot (can upgrade).
5. 86-100% - BOTTOM BAR styled like the TOP BAR: dark navy strip with a thin gold line along its TOP edge and the same faint darker cloud pattern. Inside it, five SEPARATE tab plates in a row with small gaps between them; each plate is a rounded dark navy plate with a thin lighter-navy border, exactly like the currency plates in the top bar (no heavy gold frame, no corner ornaments). Each plate holds a small FULL-COLOR cute pixel icon with a short cream label under it, in this order: helmet with a red plume and gold trim "장수", small flag stuck in a parchment map "편성", two crossed spears with red tassels "군웅대전" (center), rolled scroll with a red seal "모집", tiny market stall with a red-and-cream striped awning "상점". The selected plate ("장수") has a thin GOLD border, a slightly lighter navy fill and a gold label.

DO NOT ADD
No text other than: 장수, 병졸, 보물, 전체, 위, 촉, 오, 군웅, 등급순, 보유 18/40, hero names, Lv numbers, 12,500, 350, and the bottom bar labels 장수, 편성, 군웅대전, 모집, 상점.
```

---

## 03-A. 장수 상세 — 강화 탭

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the HERO DETAIL screen (UPGRADE tab) of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

STYLE RULES
- Clean pixel art, consistent pixel size, flat colors, no blur, no glow.
- Gold is the UI accent. The hero's faction color (green for this hero) appears only on the hero showcase background and the faction badge.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "장수 정보", gold coin "12,500", light-cyan diamond "350".
2. 6-40% - Hero showcase: a large chibi general with a long glaive and a long black beard, standing on a small round pedestal, soft green banner background. Left of him: small round faction badge "촉", name plate "관우", rarity tag "명장", gold stars ★★★☆☆☆ (3 of 6). Right of him: small arrow buttons < > to switch heroes.
3. 40-45% - Three tabs: "강화" (selected, gold), "성급", "보물".
4. 45-80% - Upgrade panel (navy, gold trim), three rows, each row: icon, name, current value, an arrow to the next value, level "Lv 18 / 30", a gold coin cost, and a gold "강화" button:
   - sword icon "공격" 120 → 125, cost "1,230"
   - shield icon "방어" 80 → 83, cost "980"
   - heart icon "체력" 1,640 → 1,705, cost "1,100"
   Under the rows: a wide gold button "모두 강화" and a small note area showing total power "전투력 3,250".
5. 80-92% - Skill box: square skill icon (green crescent blade slash), name "청룡참", one short line "앞의 적을 크게 벤다".
6. 92-100% - Empty dark navy footer (no bottom bar on detail screens).

DO NOT ADD
No text other than: 장수 정보, 12,500, 350, 촉, 관우, 명장, 강화, 성급, 보물, 공격, 방어, 체력, the numbers above, 모두 강화, 전투력 3,250, 청룡참, 앞의 적을 크게 벤다.
```

## 03-B. 장수 상세 — 성급 탭

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the HERO DETAIL screen (STAR-UP tab) of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. Keep the same top part as the hero detail screen: hero showcase of a chibi general with a long glaive and a long black beard on a green banner background, faction badge "촉", name "관우", tag "명장", stars ★★★☆☆☆. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "장수 정보", gold coin "12,500", light-cyan diamond "350".
2. 6-40% - Hero showcase (same as above).
3. 40-45% - Tabs: "강화", "성급" (selected, gold), "보물".
4. 45-62% - Big star row: six large star slots, three filled gold, the fourth glowing outline (next), two empty. Under it: "3성 → 4성".
5. 62-74% - Card progress: a small hero card icon with a progress bar "2 / 3" (hero cards owned / needed).
6. 74-86% - Benefit list (navy panel): "기본 능력치 ×1.15", "강화 상한 30 → 40", "기술 강화" with small icons.
7. 86-94% - Wide gold button "성급 올리기" (shown disabled grey because cards are not enough), and a small link-style button "모집하러 가기".
8. 94-100% - Empty dark navy footer.

STYLE RULES
Clean pixel art, consistent pixel size, flat colors, no blur, no glow. Gold accents. Faction color only on the showcase background and badge.

DO NOT ADD
No text other than: 장수 정보, 12,500, 350, 촉, 관우, 명장, 강화, 성급, 보물, 3성 → 4성, 2 / 3, 기본 능력치 ×1.15, 강화 상한 30 → 40, 기술 강화, 성급 올리기, 모집하러 가기.
```

## 03-C. 장수 상세 — 보물 탭

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the HERO DETAIL screen (TREASURE tab) of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference. Keep the same top part as the hero detail screen: chibi general with a long glaive and long black beard on a green banner background, faction badge "촉", name "관우", tag "명장", stars ★★★☆☆☆. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "장수 정보", gold coin "12,500", light-cyan diamond "350".
2. 6-40% - Hero showcase (same as above).
3. 40-45% - Tabs: "강화", "성급", "보물" (selected, gold).
4. 45-62% - Three large equipment slots in a row, each a rounded square with a rarity-colored border (grey common, blue rare, purple epic, gold legendary):
   - "무기": a purple-border slot with a pixel glaive, "+7"
   - "갑옷": a blue-border slot with pixel armor, "+3"
   - "보패": an empty slot with a faint jade-pendant outline and a "+" sign
5. 62-80% - Selected item info (navy panel): item icon, name "청룡도", rarity "영웅", main stat "공격 +86", two sub stats "치명타 +4%", "공격속도 +6%". Buttons: "강화" (gold) and "해제" (navy).
6. 80-92% - Total bonus line: "보물 합계 공격 +86  방어 +40" and a wide gold button "자동 장착".
7. 92-100% - Empty dark navy footer.

STYLE RULES
Clean pixel art, consistent pixel size, flat colors, no blur, no glow. Gold accents. Rarity colors only on item borders.

DO NOT ADD
No text other than the words and numbers listed above.
```

---

## 04. 편성

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the LINEUP screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters. Here the player picks which heroes go onto the slot machine reels for the next battle, and one strategist.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

STYLE RULES
- Clean pixel art, consistent pixel size, flat colors, no blur, no glow.
- Faction colors only on hero cards and synergy chips.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "편성", gold coin "12,500", light-cyan diamond "350".
2. 6-22% - Strategist slot: a wide navy panel with a round portrait of a chibi strategist with a feather fan, label "책사", name "제갈량", one short line "웨이브마다 한 줄 다시 돌리기", and a small "교체" button.
3. 22-50% - Reel heroes: title "슬롯 장수 6 / 8". A 4 x 2 grid of large slots: six filled with chibi hero cards on faction-colored backgrounds (3 green, 2 blue, 1 red), two empty with a dashed outline and a "+" sign.
4. 50-56% - Fixed soldiers row: four small soldier icons (spear, shield, bow, horse) with the label "기본 병졸 (항상 포함)".
5. 56-62% - Synergy chips: "촉 3" (glowing), "위 2", "오 1".
6. 62-86% - Owned heroes list (scrollable 5-column grid of small cards with faction color, stars and level). Heroes already selected are dimmed with a gold check mark.
7. 86-100% - BOTTOM BAR styled like the TOP BAR: dark navy strip with a thin gold line along its TOP edge and the same faint darker cloud pattern. Inside it, five SEPARATE tab plates in a row with small gaps between them; each plate is a rounded dark navy plate with a thin lighter-navy border, exactly like the currency plates in the top bar (no heavy gold frame, no corner ornaments). Each plate holds a small FULL-COLOR cute pixel icon with a short cream label under it, in this order: helmet with a red plume and gold trim "장수", small flag stuck in a parchment map "편성", two crossed spears with red tassels "군웅대전" (center), rolled scroll with a red seal "모집", tiny market stall with a red-and-cream striped awning "상점". The selected plate ("편성") has a thin GOLD border, a slightly lighter navy fill and a gold label.

DO NOT ADD
No text other than: 편성, 12,500, 350, 책사, 제갈량, 웨이브마다 한 줄 다시 돌리기, 교체, 슬롯 장수 6 / 8, 기본 병졸 (항상 포함), 촉 3, 위 2, 오 1, hero names, Lv numbers, 장수, 편성, 군웅대전, 모집, 상점.
```

---

## 05-A. 모집

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the RECRUIT screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters. The player spends diamonds or recruit tickets to draw hero cards.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

STYLE RULES
Clean pixel art, consistent pixel size, flat colors, no blur, no glow. Gold accents.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "모집", light-cyan diamond "350", recruit ticket icon "5".
2. 6-14% - Banner tabs: "일반 모집" (selected), "기간 한정".
3. 14-58% - Banner art: a cozy recruiting hall with a big wooden notice board; three featured chibi heroes in front (a long-bearded glaive general, a strategist with a feather fan, an armored warlord with a halberd), golden sparkles kept simple. Small info button "확률 보기" in the top-right of the banner.
4. 58-66% - Pity bar: "기린아 확정까지 37회" with a gold progress bar.
5. 66-82% - Two large buttons side by side:
   - Left (navy with gold trim): "1회 모집", ticket icon "1" or diamond "300".
   - Right (GOLD, bigger): "10회 모집", diamond "2,700", a small ribbon "명장 이상 1명 확정".
6. 82-86% - Small line: "중복 장수는 장수 카드로 바뀝니다".
7. 86-100% - BOTTOM BAR styled like the TOP BAR: dark navy strip with a thin gold line along its TOP edge and the same faint darker cloud pattern. Inside it, five SEPARATE tab plates in a row with small gaps between them; each plate is a rounded dark navy plate with a thin lighter-navy border, exactly like the currency plates in the top bar (no heavy gold frame, no corner ornaments). Each plate holds a small FULL-COLOR cute pixel icon with a short cream label under it, in this order: helmet with a red plume and gold trim "장수", small flag stuck in a parchment map "편성", two crossed spears with red tassels "군웅대전" (center), rolled scroll with a red seal "모집", tiny market stall with a red-and-cream striped awning "상점". The selected plate ("모집") has a thin GOLD border, a slightly lighter navy fill and a gold label.

DO NOT ADD
No text other than: 모집, 350, 5, 일반 모집, 기간 한정, 확률 보기, 기린아 확정까지 37회, 1회 모집, 1, 300, 10회 모집, 2,700, 명장 이상 1명 확정, 중복 장수는 장수 카드로 바뀝니다, 장수, 편성, 군웅대전, 모집, 상점.
```

## 05-B. 모집 결과 (10연)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the 10x RECRUIT RESULT screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-10% - Title ribbon "모집 결과".
2. 10-80% - Ten hero cards in a 2 x 5 grid, each card a chibi hero on a faction-colored background with a rarity frame (silver for 장수, purple for 명장, gold with a soft shine for 기린아). One card is gold (기린아, a strategist with a feather fan) with a small "NEW" ribbon. Two cards show a small tag "카드 +1" (duplicate turned into a hero card).
3. 80-90% - Two buttons: "확인" (navy) and "10회 더" (gold) with diamond "2,700".
4. 90-100% - Dark navy footer.

STYLE RULES
Clean pixel art, consistent pixel size, flat colors, no blur, no heavy glow. Rarity colors only on card frames.

DO NOT ADD
No text other than: 모집 결과, NEW, 카드 +1, 확인, 10회 더, 2,700, hero names.
```

## 05-C. 확률 보기 (팝업)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the RECRUIT ODDS popup of a cute pixel-art Three Kingdoms battle game. The recruit screen is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
A centered navy panel (about 85% of the width) with a title "확률 정보" and a round "X" close button.
1. Rarity table with three rows: "기린아 3%", "명장 17%", "장수 80%", each with a rarity-colored frame icon.
2. Small lines: "10회 모집 시 명장 이상 1명 확정", "60회 안에 기린아 1명 확정".
3. A scrollable list of heroes with their individual odds, for example "제갈량 1.5%", "조조 1.5%", "관우 4.25%", "조운 4.25%".
Clean pixel art, flat colors, gold accents, very readable.

DO NOT ADD
No text other than the words and numbers listed above.
```

---

## 06-A. 보물 가방 (장수 화면 — 보물 탭)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the HERO screen with the TREASURE tab selected (treasure bag) of a cute pixel-art Three Kingdoms battle game.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title plate "장수", gold coin "12,500", light-cyan diamond "350".
2. 6-10% - Three tabs: "장수", "병졸", "보물" (selected, gold).
2b. 10-14% - Filter chips: "전체" (selected), "무기", "갑옷", "보패", and a small sort button "등급순".
3. 14-82% - A 5-column grid of treasure icons on rounded squares with rarity-colored borders (grey, blue, purple, gold): glaives, swords, bows, armors, helmets, jade pendants, seals. Each shows a small "+N" level. Some show a tiny chibi face in the corner (equipped by that hero).
4. 82-86% - Line: "보유 46 / 200".
5. 86-100% - BOTTOM BAR styled like the TOP BAR: dark navy strip with a thin gold line along its TOP edge and the same faint darker cloud pattern. Inside it, five SEPARATE tab plates in a row with small gaps between them; each plate is a rounded dark navy plate with a thin lighter-navy border, exactly like the currency plates in the top bar (no heavy gold frame, no corner ornaments). Each plate holds a small FULL-COLOR cute pixel icon with a short cream label under it, in this order: helmet with a red plume and gold trim "장수", small flag stuck in a parchment map "편성", two crossed spears with red tassels "군웅대전" (center), rolled scroll with a red seal "모집", tiny market stall with a red-and-cream striped awning "상점". The selected plate ("장수") has a thin GOLD border, a slightly lighter navy fill and a gold label.
Clean pixel art, flat colors, no blur. Rarity colors only on item borders.

DO NOT ADD
No text other than: 장수, 병졸, 보물, 12,500, 350, 전체, 무기, 갑옷, 보패, 등급순, +N levels, 보유 46 / 200, 편성, 군웅대전, 모집, 상점.
```

## 06-B. 보물 상세·강화 (팝업)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the TREASURE DETAIL popup of a cute pixel-art Three Kingdoms battle game. The treasure bag is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
A centered navy panel with a round "X" close button.
1. Large item icon (a pixel glaive) in a purple rarity frame, name "청룡도", rarity "영웅", slot "무기", level "+7 / +15".
2. Main stat: "공격 +86 → +92".
3. Sub stats list: "치명타 +4%", "공격속도 +6%", and a locked line "+10 에서 열림".
4. Equipped by: small chibi face with "관우".
5. Buttons: "강화" (gold) with gold coin "2,400", "장착 변경" (navy).
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words and numbers listed above.
```

---

## 07. 상점

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the SHOP screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "상점", gold coin "12,500", light-cyan diamond "350".
2. 6-12% - Tabs: "추천" (selected), "다이아", "골드", "패키지".
3. 12-30% - Featured banner: "첫 결제 2배" with a pile of light-cyan diamonds and a happy chibi merchant.
4. 30-46% - Monthly card panel: "월정액" — "매일 다이아 100 · 30일", price button "₩5,500".
5. 46-82% - A 3-column grid of diamond packs on navy cards: small pile "60" ₩1,200, "300" ₩5,900, "980" ₩19,000, "1,980" ₩38,000, "3,280" ₩59,000, chest "6,480" ₩119,000. Each card has a price button in gold.
6. 82-86% - Small line: "확률형 상품은 확률 정보를 확인하세요".
7. 86-100% - BOTTOM BAR styled like the TOP BAR: dark navy strip with a thin gold line along its TOP edge and the same faint darker cloud pattern. Inside it, five SEPARATE tab plates in a row with small gaps between them; each plate is a rounded dark navy plate with a thin lighter-navy border, exactly like the currency plates in the top bar (no heavy gold frame, no corner ornaments). Each plate holds a small FULL-COLOR cute pixel icon with a short cream label under it, in this order: helmet with a red plume and gold trim "장수", small flag stuck in a parchment map "편성", two crossed spears with red tassels "군웅대전" (center), rolled scroll with a red seal "모집", tiny market stall with a red-and-cream striped awning "상점". The selected plate ("상점") has a thin GOLD border, a slightly lighter navy fill and a gold label.
Clean pixel art, flat colors, no blur, gold accents.

DO NOT ADD
No text other than the words, numbers and prices listed above, and the bottom bar labels 장수, 편성, 군웅대전, 모집, 상점.
```

---

## 08. 임무

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the MISSIONS screen of a cute pixel-art Three Kingdoms battle game.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "임무", gold coin "12,500", light-cyan diamond "350".
2. 6-12% - Tabs: "일일" (selected), "주간", "업적".
3. 12-22% - Daily progress: a gold bar with four reward chests along it at 25 / 50 / 75 / 100 points; the first chest is open.
4. 22-90% - A list of mission rows (navy cards). Each row: icon, short mission text, progress "2 / 3", reward icon with amount, and a button ("받기" gold when done, "이동" navy when not):
   - "출정 3회" 2/3, gold 500, 이동
   - "슬롯 20회 돌리기" 20/20, diamond 20, 받기
   - "장수 강화 5회" 1/5, gold 800, 이동
   - "스테이지 1-5 클리어" 0/1, recruit ticket 1, 이동
   - "군웅대전 1회" 0/1, gold 400, 이동
   - "보물 강화 1회" 1/1, gold 300, 받기
5. 90-100% - Wide gold button "모두 받기".
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words and numbers listed above.
```

## 09. 전공 패스

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the SEASON PASS screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "전공 패스", light-cyan diamond "350".
2. 6-20% - Header: season art with a chibi hero in a festive outfit, "시즌 1", "남은 기간 23일", current level "Lv 12" with a gold progress bar.
3. 20-28% - Two column labels: "무료" (navy) and "특별" (gold, with a small lock icon), and a gold button "특별 패스 열기 ₩11,000".
4. 28-92% - Vertical reward track (scrollable): each level row has a number in the middle, a free reward on the left and a special reward on the right (gold coins, diamonds, recruit tickets, treasure chests, a hero outfit at level 30). Claimed rewards have a check mark; locked special rewards show a small lock.
5. 92-100% - Wide gold button "모두 받기".
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than: 전공 패스, 350, 시즌 1, 남은 기간 23일, Lv 12, 무료, 특별, 특별 패스 열기 ₩11,000, level numbers, reward amounts, 모두 받기.
```

## 10. 우편

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the MAILBOX screen of a cute pixel-art Three Kingdoms battle game.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-6% - Top bar: back arrow, title "우편".
2. 6-88% - A list of mail rows (navy cards). Each row: a sealed letter icon (opened letters are grey), a title, a short line, the attached reward icon with amount, time left, and a small gold "받기" button:
   - "출시 기념 선물" — "다이아 300" — "6일 남음"
   - "점검 보상" — "골드 5,000" — "2일 남음"
   - "임무 보상" — "모집권 1" — "13일 남음"
3. 88-100% - Two buttons: "읽은 우편 삭제" (navy) and "모두 받기" (gold).
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words and numbers listed above.
```

## 11. 주공 정보

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the PLAYER PROFILE popup of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters. The lobby is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
A centered navy panel with a round "X" close button.
1. Large round lord portrait (cute chibi) with a small pencil button, name "주공", "Lv.4", gold exp bar "320 / 500".
2. Stats in two columns: "최고 스테이지 3-7", "군웅대전 승리 12", "보유 장수 18", "최다 연속 대박 5연".
3. "주공 레벨 보상" row: next unlock "Lv.5 편성 칸 +1".
4. Small buttons: "초상 변경", "계정 연동".
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words and numbers listed above.
```

## 12. 설정

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the SETTINGS popup of a cute pixel-art Three Kingdoms battle game. The lobby is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
A centered navy panel (about 88% of the width) with a title "설정" and a round "X" close button. Rows, each with an icon on the left:
1. "배경음" slider (gold fill) 70%
2. "효과음" slider 80%
3. "슬롯 연출" three-way toggle "빠르게 / 보통 / 끄기" ("보통" selected in gold)
4. "진동" ON/OFF switch (ON, gold)
5. "화면 흔들림" ON/OFF switch (OFF, grey)
6. "글자 크기" three-way toggle "작게 / 보통 / 크게"
7. "알림" ON/OFF switch
Bottom of the panel: small navy buttons "고객센터", "약관", "계정", and a tiny version text "v0.1.0".
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words listed above.
```

---

## 13-A. 전투 — 기본

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the BATTLE screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters. An auto-battle runs on top; the player spins a 3x3 slot machine below to recruit warriors.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

STYLE RULES
- Clean pixel art, consistent pixel size, flat colors, no blur, no glow.
- Gold is the UI accent. Faction colors appear only on slot tiles and recruit cards: Wei blue, Shu green, Wu red, Warlords purple.

LAYOUT, TOP TO BOTTOM (percent of image height)
1. 0-6% - Top bar: rice-sack icon "300" (battle supplies), soldier icon "5/8", helmet icon "2/4", flag icon "3/10", and a small speed button "1x" and a pause button on the right.
2. 6-9% - Castle HP bar: fortress icon, red bar at 70%, "70%".
3. 9-45% - BATTLEFIELD seen from the SIDE: our small stone castle gate on the far LEFT edge; a thin dashed vertical line in the middle; cute chibi allies on the left facing right (3 spearmen, 2 archers, a red-faced general with a long glaive, a blue-armored spear general); chibi Yellow Turban enemies (yellow headbands) on the right walking left, each with a tiny red HP bar. Above two of our units: thin gold bands (rank up). Next to our castle: two small grey round portraits with white numbers "3" and "9" (respawn countdown). Top-right corner of the field: small navy panel "다음" with two tiny enemy icons "x4", "x1".
4. 45-50% - Strategist strip: small round portrait of a strategist with a feather fan, name "제갈량", and a small gold skill button "한 줄 다시" with "1/1".
5. 50-76% - SLOT MACHINE (navy and gold frame): 3 reels x 3 visible rows of square tiles. Each tile = a cute chibi unit on its faction-colored background with a tiny faction badge. Five payline markers (small round numbered coins 1-5) on both sides. The middle row is three green tiles of the same glaive general, with a bright gold win line through it. A short lever with a red ball on the right side.
6. 76-84% - Recruit strip: title "영입 3" and small cards for each recruited unit, each with a tag ("등급 +1" in gold, "합류" in gold).
7. 84-100% - Bottom controls: a big plump GOLD button "돌리기" with a rice-sack icon and "120"; to its left a small square "대기석 2/8" button; to its right a small square "한 칸 밀기" button shown disabled grey.

DO NOT ADD
No extra menus, no diamonds or premium currency anywhere on this screen, no text other than: 300, 5/8, 2/4, 3/10, 1x, 70%, 다음, x4, x1, 3, 9, 제갈량, 한 줄 다시, 1/1, 1-5 on the payline coins, 영입 3, 등급 +1, 합류, 돌리기, 120, 대기석 2/8, 한 칸 밀기.
```

## 13-B. 전투 — 꽝 + 한 칸 밀기

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the BATTLE screen of a cute pixel-art Three Kingdoms battle game, in the "NO MATCH" state where the player may nudge one reel.

REFERENCE
Use the attached image as the exact reference for the battle screen layout and art style. Keep the top bar, castle HP bar, battlefield and strategist strip the same.

CHANGES
1. Slot machine: no line matches. Tiles are mixed factions and units. A small grey ribbon above the slot: "꽝".
2. Each of the three reels shows a small up arrow above it and a small down arrow below it in gold, gently highlighted, inviting the player to nudge one reel by one tile.
3. One reel (the right one) is highlighted, and a ghost preview shows that moving it down one tile would make a diagonal line of three spearmen.
4. Recruit strip: "영입 0".
5. Bottom controls: "돌리기" gold button with a rice-sack icon "140"; the "한 칸 밀기" button is now ACTIVE gold with a rice-sack icon "35" and a small "1회" label.

DO NOT ADD
No diamonds, no extra menus, no text other than what the original battle screen shows plus 꽝, 영입 0, 140, 한 칸 밀기, 35, 1회.
```

## 13-C. 전투 — 같은 장수 3연 대박

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the BATTLE screen of a cute pixel-art Three Kingdoms battle game, in the "JACKPOT" moment.

REFERENCE
Use the attached image as the exact reference for the battle screen layout and art style.

CHANGES
1. Slot machine: the middle row is three tiles of the same green glaive general, with a thick gold win line; small pixel sparkles around the machine (simple, few pixels, no blur).
2. A big ribbon across the slot: "3연 대박!" in cream letters on a gold ribbon, with a small fire icon "x2" streak badge.
3. On the battlefield, the glaive general has a gold flash and two thin gold bands above his head, with a floating tag "등급 +1".
4. Recruit strip: one wide card of the glaive general with "등급 +1".

DO NOT ADD
No diamonds, no extra menus, no text other than what the original battle screen shows plus 3연 대박!, x2, 등급 +1.
```

## 14. 웨이브 결산 (팝업)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the WAVE CLEAR popup of a cute pixel-art Three Kingdoms battle game. The battle screen is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
A centered navy panel with a gold ribbon title "웨이브 3 승리".
1. Rows with icons: "군량 +320", "성 체력 +10%", "처치 24".
2. "활약" row: small chibi portrait of the glaive general with "처치 9".
3. A small preview of the next wave: "다음 웨이브 4" with tiny enemy icons "창병 x6", "기마 x2".
4. One wide gold button "다음 웨이브".
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No diamonds, no text other than the words and numbers listed above.
```

## 15. 시험·보스 경고 (팝업)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the BOSS WARNING banner of a cute pixel-art Three Kingdoms battle game. The battle screen is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
1. A wide dark red and gold banner across the middle of the screen: "보스 출현".
2. Under it, a cute but menacing chibi Yellow Turban leader with a yellow headband, a staff and small lightning sparks, on a navy plate with the name "장각".
3. One short line: "6초마다 낙뢰를 떨어뜨린다".
4. A small tap hint at the bottom: "화면을 누르면 시작".
Clean pixel art, flat colors, no blur.

DO NOT ADD
No text other than: 보스 출현, 장각, 6초마다 낙뢰를 떨어뜨린다, 화면을 누르면 시작.
```

## 16. 일시정지 (팝업)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall.

Create the PAUSE popup of a cute pixel-art Three Kingdoms battle game. The battle screen is visible behind it, darkened.

REFERENCE
Use the attached image as the exact ART STYLE reference: same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT
A centered navy panel with a title "일시정지".
1. Wide gold button "계속하기".
2. Small rows: "배경음" slider, "효과음" slider, "슬롯 연출" toggle "빠르게 / 보통 / 끄기".
3. Navy button "설정".
4. A small dark red button at the bottom "출정 포기" with a tiny warning icon.
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words listed above.
```

## 17-A. 결과 — 승리

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the VICTORY RESULT screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same castle gate, same dark navy UI with thin gold trim, same gold accents. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-22% - Sunset sky with a big gold ribbon "승리" and a smaller line "스테이지 3-7 클리어".
2. 22-40% - Cheering chibi warriors in front of our castle gate, a defeated Yellow Turban flag lying on the ground. Simple confetti pixels.
3. 40-58% - Stats in a navy panel, two columns with icons: "도달 웨이브 10/10", "남은 성 체력 62%", "슬롯 23회", "최대 연속 대박 5연".
4. 58-72% - "최고 활약": chibi glaive general portrait with "처치 47".
5. 72-86% - Rewards row: gold coin "+1,500", lord exp "+120", one treasure chest icon "보물 x1", a recruit ticket "x1" with a small "첫 클리어" ribbon.
6. 86-100% - Two buttons: "로비로" (navy) and "다시 출정" (gold).
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words and numbers listed above.
```

## 17-B. 결과 — 패배 (이어하기 제안)

```
OUTPUT FORMAT: a TALL PORTRAIT image, 1024 wide x 1792 tall. Everything is stacked from top to bottom.

Create the DEFEAT RESULT screen of a cute pixel-art Three Kingdoms battle game with small 2D chibi characters.

REFERENCE
Use the attached image as the exact ART STYLE reference: same cute chibi pixel characters, same castle gate, same dark navy UI with thin gold trim. IMPORTANT: copy only the art style. Do NOT copy the layout, menus, buttons or bottom bar of the reference images. No game title or logo anywhere.

LAYOUT, TOP TO BOTTOM
1. 0-22% - Dusk sky in grey-blue tones, a cracked grey ribbon "성이 함락되었다" and a smaller line "스테이지 3-7".
2. 22-40% - Our castle gate damaged with a little smoke; sad but cute chibi warriors sitting on the ground.
3. 40-56% - "이어하기" offer panel (gold trim): "웨이브 6부터 다시", two buttons: diamond "100" and a small video icon "광고 보고 이어하기", and a small line "출정당 1회".
4. 56-70% - Stats: "도달 웨이브 6/10", "성 체력 0%", "슬롯 14회".
5. 70-84% - Rewards row: gold coin "+600", lord exp "+50".
6. 84-100% - Two buttons: "로비로" (navy) and "다시 출정" (gold).
Clean pixel art, flat colors, gold accents.

DO NOT ADD
No text other than the words and numbers listed above.
```

---

## 구현 준비 메모 (Claude)

- **해상도**: 세로 기준. 시안(1024×1792)을 보고 논리 해상도를 정한다. 후보: 360×640(×3 = 1080×1920), 19.5:9 기기는 위아래로 늘림. 시안 픽셀 밀도에 맞춰 확정한다.
- **부품 분리**: 화면 시안 1장만으로는 부품을 잘라 쓰기 어렵다. 화면 시안이 확정되면 같은 그림체로 **UI 부품 시트**(판, 버튼 3상태, 탭, 아이콘)와 **배경만** 이미지를 따로 받는다.
- **글자**: 시안의 글자는 그림으로 쓰지 않고 게임에서 픽셀 폰트(Galmuri)로 넣는다.
- **구현 순서 제안**: 01 로비 → 13 전투(세로 전환 + 슬롯 + 성·부활) → 14·15·16 전투 팝업 → 17 결과 → 02·03 장수 → 04 편성 → 05 모집 → 06 보물 → 07 상점 → 08~12.
- **임시 그림**: 유닛은 지금 연결된 임시 그림을 쓰고, 최종 캐릭터는 시안 그림체로 새로 만든다.
