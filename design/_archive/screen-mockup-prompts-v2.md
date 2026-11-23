# 운빨삼국 — 화면 시안 프롬프트 v2 (코덱스 의뢰용)

> **이력 문서 (2026-11-21).** 정본은 `design/gdd/운빨삼국-GDD_v5.md`. 이 문서와 다르면 v5를 따른다.

- 2026-11-21. 모바일 가로, 천명 슬롯 기준.
- 각 프롬프트는 **통째로 복사**해서 쓴다. 공통 스타일과 참고 이미지 지시가 이미 들어 있다.
- 참고 이미지: 매번 **민수가 받은 전투 슬롯 시안 1장**을 첨부한다. 참고 게임·슬롯바운드 화면은 넣지 않는다.
- 순서: 1 전투(A 완성 / B 배경 / C 부품) → 2 로비 → 3 장수 목록 → 4 편성 → 5 상점 → 6 결과(승리 / 패배) → 7 일시정지·설정.
- 아직 안 정한 것을 가정한 곳: 4 편성(릴에 올릴 장수 고르기), 5 상점(명성으로 장수·강화 구매), 대기석(뺐음).

---

## 1-A. 전투 화면 — 완성 시안

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger/hot (#C8322B), jade green for positive tags (#2E9E5B).
- Faction colors (tile backgrounds and small round badges): Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Currency icon: gold ingot (yuanbao).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area; the outer edges are background only, because wider phones will extend or crop the sides.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image as the exact reference for this scene. Keep its art style, colors and layout, and apply the changes described below.

SCREEN: Battle screen with the "Heaven's Mandate Slot" (천명 슬롯).

Layout, top to bottom:
1. Top HUD bar (full width, about 80px tall, wood frame): gold ingot icon "160", soldier icon "출전 5/8", general icon "장수 2/4", red flag icon "웨이브 3/10", fortress icon with a red HP bar at 70% and the text "70%". Far right: square wood button "1x" (game speed).
2. Under the HUD on the left: small round wood button with a scroll icon, label "본진".
3. Under the HUD on the right: parchment panel titled "다음: 웨이브 4" with small enemy icons "창병 x4" and "기마 x1".
4. Battlefield (middle, about 55% of the height): side-view dirt field, distant mountains, faction banners and a wooden palisade in the back. On the far LEFT edge stands OUR fortress gate (wooden gate tower with a red 漢 banner); enemies that reach it damage it. A dashed red vertical line in the center marks the front line.
   - Left half: our army facing right (spearmen, archers, a red-faced general in a green robe with a long glaive on a horse, a blue-armored spear general).
   - Right half: enemy spearmen, an archer and a cavalryman facing left, each with a small red HP bar.
   - Above some of our units: small dark pill tags "+등급업" (gold text) and "+합류" (green text).
   - Next to our fortress gate: two greyed-out round portraits of fallen units, each with a white countdown number ("3" and "9"). These are respawn timers.
5. Bottom panel (about 38% of the height, wood frame, parchment inside), left to right:
   a. Advisor card: chibi strategist with a feather fan and red robe, name plate "책사 제갈량".
   b. Slot machine: gold header ribbon "천명 슬롯", a red badge on its left "3연 대박!" with a fire icon, a dark badge on its right "창병 3연". 3 reels x 3 visible rows of unit tiles; each tile is a unit sprite on its faction-colored background with a small faction badge ("위", "촉", "오", "군웅"). Round numbered payline coins 1-5 on both sides. The middle row is all green Shu tiles with a bright yellow win line through it. A red-ball lever on the right side of the slot.
   c. Big gold button "돌리기" with a gold ingot icon and "100금" under it, and a small dark plate "사용됨" below it.
   d. Recruit list titled "영입 5명": 5 cards in two rows (3 on top, 2 below). Each card shows a unit sprite, its name, a faction badge, and a tag "+등급업" or "+합류".
Mood: lively and readable, every element clearly separated.
```

## 1-B. 전투 화면 — 배경만

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- Canvas 1920x1080 (16:9).
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image as the exact reference for this scene (same place, same lighting, same palette).

IMAGE: BACKGROUND ONLY of the battle scene: side-view dirt battlefield, distant mountains, faction banners, wooden palisade in the back, and our fortress gate (wooden gate tower with a red 漢 banner) on the far left edge.
- NO UI, NO text, NO units, NO HP bars, NO dashed line, NO slot machine.
- Continue the ground down into the bottom 38% of the image; it will be covered by the UI panel.
- Make the outer 160px on the left and right a simple continuation of the scenery so it can be cropped or extended.
```

## 1-C. 전투 화면 — UI 부품 시트

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold (#F5C431), red lacquer (#C8322B), jade green (#2E9E5B).
- Faction colors: Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image as the exact reference for the look of every part.

IMAGE: UI PARTS SHEET for the battle screen, 2048x2048.
- Flat solid magenta (#FF00FF) background. Every part separated by at least 32px of empty space. No overlaps, NO text anywhere, no drop shadows on the background.
- Arrange in rows:
  Row 1 - Frames (all empty): top HUD bar, large bottom panel frame (wood frame with parchment inside), small parchment info panel, name plate.
  Row 2 - Buttons, each in 3 states side by side (normal / pressed / disabled grey), all empty: big gold button, square wood button, round wood button.
  Row 3 - Slot parts: slot machine frame with 3 empty reel windows; one empty reel tile background in each faction color (blue, green, red, purple, mustard); glowing gold tile border; round payline coin (normal and lit); lever (up and pulled down); gold header ribbon (empty); red hot badge (empty); dark badge (empty).
  Row 4 - Small UI: recruit card frame (empty), dark pill tag (empty), green pill tag (empty), round faction badges in the 5 faction colors (empty), HP bar frame with a red fill and a green fill, round portrait frame plus a greyed-out version.
  Row 5 - Icons, 64x64 each: gold ingot, soldier helmet, general helmet, red flag, fortress, scroll, fire, speed arrows.
  Row 6 - Our fortress gate (wooden gate tower with a red 漢 banner) in 3 states: intact, damaged, heavily damaged.
```

---

## 2. 로비

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger/hot (#C8322B), jade green for positive tags (#2E9E5B).
- Faction colors (tile backgrounds and small round badges): Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Currency icons: gold ingot (yuanbao) for gold, golden scroll for fame (명성).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area; the outer edges are background only, because wider phones will extend or crop the sides.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image only as the style reference (pixel art style, colors, wood-and-parchment UI, chibi characters). Do not copy its layout; follow the layout described below.

SCREEN: Lobby (main menu, our home base) of "운빨삼국".

Background: our walled town at sunset seen from the side: a red-roofed gate tower with a red 漢 banner on the left, small houses, a training yard where chibi soldiers practice, a war drum, lanterns. In the center of the yard stands a large ornate slot-machine altar (wood and brass, three reels showing faction tiles, a red-ball lever) - the symbol of the game.

UI:
1. Top-left: player panel - small round portrait of a chibi lord, name "주공", a fame level bar "명성 Lv 4".
2. Top center-right: currency bar - fame scroll icon "1,250", gold ingot icon "300". Small "+" button next to each.
3. Top-right: three small round icon buttons: folding fan (settings), bamboo-slip letter (mail), drum (notice).
4. Center-top: pixel title logo "운빨삼국" in brush-style lettering with a small red "大吉" seal, small English subtitle "FORTUNE OF THREE KINGDOMS".
5. Bottom-left: menu row of 3 square wood buttons with icon + label: "장수 목록" (book icon), "편성" (slot reel icon), "상점" (merchant stall icon).
6. Bottom-right: the BIGGEST button - red lacquer with gold trim, war-drum shape, text "출정", small line under it "1장 황건의 난".
7. Above the 출정 button: small parchment card "이어하기 · 웨이브 7/10 · 성 62%" (continue run).
Mood: cozy, proud, inviting; the slot altar draws the eye.
```

---

## 3. 장수 목록 (보유 장수·도감)

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger/hot (#C8322B), jade green for positive tags (#2E9E5B).
- Faction colors (tile backgrounds and small round badges): Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Currency icons: gold ingot (yuanbao) for gold, golden scroll for fame (명성).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area; the outer edges are background only, because wider phones will extend or crop the sides.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image only as the style reference (pixel art style, colors, wood-and-parchment UI, chibi characters). Do not copy its layout; follow the layout described below.

SCREEN: Hero Roster / Collection (장수 목록).

Background: a dim study room with bookshelves of bamboo scrolls, softly blurred behind a big parchment board.

UI:
1. Top bar: back arrow button on the left, title ribbon "장수 목록", collection counter "수집 14/24" on the right, fame scroll "1,250".
2. Below the title: filter tabs as wood buttons: "전체", "위", "촉", "오", "군웅", "황건" (each faction tab has its faction color dot); and a small sort button "희귀도순".
3. Left 60%: a 6-column grid of hero cards (portrait cards, rounded wood frame, faction-colored background). Each card: chibi hero bust, name under it, rarity shown by 1-4 small gold stars, faction badge in the corner. Some cards are unowned: dark silhouette with a "?" and a small lock. One card is selected with a glowing gold border.
4. Right 40%: detail panel for the selected hero "관우" (Shu): large chibi full-body sprite on a green banner background, name plate "관우", tags "촉 · 보병 · 명장", stars "★★★☆". Stat rows with small icons: "체력 820", "공격 64", "공속 1.0", "사거리 근접". A skill box with an icon: "청룡언월 - 전방의 적을 크게 벤다". Small line at the bottom: "부활 12초".
5. Bottom-right of the detail panel: gold button "편성에 넣기".
Mood: a satisfying collection book; owned heroes feel bright, unowned ones feel mysterious.
```

---

## 4. 편성 (릴에 올릴 장수 고르기)

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger/hot (#C8322B), jade green for positive tags (#2E9E5B).
- Faction colors (tile backgrounds and small round badges): Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Currency icons: gold ingot (yuanbao) for gold, golden scroll for fame (명성).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area; the outer edges are background only, because wider phones will extend or crop the sides.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image only as the style reference (pixel art style, colors, wood-and-parchment UI, chibi characters). Do not copy its layout; follow the layout described below.

SCREEN: Lineup (편성) - the player chooses which heroes go onto the slot reels before a run.

Background: inside a war tent, a big wooden table with a map, candles, softly blurred.

UI:
1. Top bar: back arrow, title ribbon "편성", text "릴 장수 6/8" on the right.
2. Left (about 30%): advisor slot - a tall card with the chibi strategist (feather fan, red robe), name plate "책사 제갈량", one-line ability text "한 줄을 다시 돌린다", and a small wood button "교체".
3. Center (about 40%): the slot machine reel strip shown flat as 8 large slots in 2 rows of 4. 6 slots are filled with hero tiles on faction-colored backgrounds (3 green Shu, 2 blue Wei, 1 red Wu), each with name and faction badge; 2 slots are empty with a dashed outline and a "+" sign. Basic soldiers (spearman, archer, shield, cavalry) are shown as a small fixed strip under it, labeled "기본 병졸 (항상 포함)".
4. Under the reel strip: a synergy preview bar with faction chips: "촉 3 - 3연 확률 높음" (green, glowing), "위 2", "오 1".
5. Right (about 30%): scrollable list of owned heroes as small cards with faction color, name and stars; heroes already on the reels are dimmed with a check mark.
6. Bottom-right: big red lacquer button "출정".
Mood: planning before battle - calm, clear, strategic.
```

---

## 5. 상점

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger/hot (#C8322B), jade green for positive tags (#2E9E5B).
- Faction colors (tile backgrounds and small round badges): Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Currency icons: gold ingot (yuanbao) for gold, golden scroll for fame (명성).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area; the outer edges are background only, because wider phones will extend or crop the sides.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image only as the style reference (pixel art style, colors, wood-and-parchment UI, chibi characters). Do not copy its layout; follow the layout described below.

SCREEN: Shop (상점) - spend fame earned from runs.

Background: a market street stall with a striped cloth awning, hanging lanterns, crates and jars; a cheerful chibi merchant with a round hat and abacus stands on the left side of the screen.

UI:
1. Top bar: back arrow, title ribbon "상점", fame scroll "1,250" on the right.
2. Tabs under the title: "장수" (selected), "강화".
3. Main area: a 4 x 2 grid of shop item cards on wooden shelves.
   - Hero cards: chibi hero bust on faction-colored background, name, stars, price with fame scroll icon (for example "조운 - 300", "주유 - 300", "하후돈 - 150").
   - One card is already bought: greyed with a green stamp "보유".
   - One card is too expensive: price in red with a small tag "명성 부족".
4. Right side: a small panel "오늘의 진열 · 갱신 까지 3:12:05" with a wood button "새로고침" and a fame cost "50".
5. Speech bubble from the merchant: "좋은 장수 들어왔소!".
Note: no premium currency, no real-money items anywhere on this screen.
Mood: lively market, tempting but fair.
```

---

## 6-A. 결과 화면 — 승리

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, bright and warm, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger/hot (#C8322B), jade green for positive tags (#2E9E5B).
- Faction colors (tile backgrounds and small round badges): Wei = blue (#3B6FC4), Shu = green (#4E9A3A), Wu = red (#B83A32), Warlords = purple (#7A4BB0), Yellow Turbans = mustard (#D9A520).
- Currency icons: gold ingot (yuanbao) for gold, golden scroll for fame (명성).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area; the outer edges are background only, because wider phones will extend or crop the sides.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image only as the style reference (pixel art style, colors, wood-and-parchment UI, chibi characters). Do not copy its layout; follow the layout described below.

SCREEN: Run result - VICTORY (결과 - 승리).

Background: the battlefield at golden sunset, our army cheering with raised weapons, banners waving, the defeated Yellow Turban boss lying in the distance; confetti-like golden sparkles.

UI (one large parchment scroll in the center):
1. Top: big gold-and-red ribbon "천하평정!" with a red "大吉" seal.
2. Left column of the scroll: stats with small icons: "도달 웨이브 10/10", "남은 성 체력 62%", "슬롯 돌린 횟수 23", "최대 연속 대박 5연", "처치한 적 184".
3. Right column: "최고 활약" - a large chibi hero portrait (green-robed glaive general) in a gold frame, name "관우", line "처치 47".
4. Bottom of the scroll: reward row: fame scroll "+320", a "첫 돌파 보너스 +100" green tag, and one new hero card sliding in with a "NEW" ribbon.
5. Under the scroll: two buttons - wood button "본진으로" on the left, big gold button "다시 출정" on the right.
Mood: triumphant and rewarding.
```

## 6-B. 결과 화면 — 패배

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer (#C8322B), jade green (#2E9E5B).
- Currency icons: gold ingot (yuanbao) for gold, golden scroll for fame (명성).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image only as the style reference (pixel art style, colors, wood-and-parchment UI, chibi characters). Do not copy its layout; follow the layout described below.

SCREEN: Run result - DEFEAT (결과 - 패배). Same layout as the victory screen, but:
- Background: dusk with grey-blue tones, our fortress gate broken and smoking, a torn red 漢 banner, Yellow Turban soldiers in the distance.
- Title ribbon: dark red and grey "성이 함락되었다" with a cracked seal "凶".
- Stats: "도달 웨이브 6/10", "성 체력 0%", "슬롯 돌린 횟수 14", "최대 연속 대박 3연", "처치한 적 96".
- "최고 활약" portrait stays bright and proud (the player still feels good about one hero).
- Rewards: fame scroll "+120", no new hero.
- Buttons: "본진으로" and gold "다시 출정".
Mood: a sad but encouraging loss - the player wants to try again right away.
```

---

## 7. 일시정지·설정

```
STYLE (apply to the whole image):
- Cute chibi 16-bit pixel art, Three Kingdoms China theme, landscape mobile game UI.
- Crisp pixel edges, no blur, no soft gradients, limited palette, 2-3px dark brown outlines.
- UI material: dark walnut wood frames with brass rivets and corner caps; inner panels are cream parchment (#F3E6C4) with a soft brown inner border.
- Accent colors: gold buttons (#F5C431) with dark brown text, red lacquer for danger (#C8322B), jade green for ON states (#2E9E5B).
- All in-image text is Korean, bold rounded pixel font, short labels only.
- Canvas 1920x1080 (16:9). Keep every important UI element inside the central 1600x1000 safe area.
- Do not copy any existing game's characters, logos or UI.

REFERENCE: Use the attached image as the background: show it darkened (about 60% black overlay), and use it as the style reference for the panel.

SCREEN: Pause and Settings modal (일시정지) over the battle screen.

UI: one centered parchment panel with a wood frame, about 900x760.
1. Title ribbon "일시정지" with a folding-fan icon; a small red "X" close button at the top-right corner.
2. Big gold button "계속하기" at the top of the panel.
3. Settings rows, each with an icon and label on the left:
   - "배경음" - horizontal slider with a wooden knob, 70%.
   - "효과음" - slider, 80%.
   - "슬롯 연출" - 3-way toggle "빠르게 / 보통 / 끄기", "보통" selected.
   - "진동" - ON/OFF toggle switch, ON (green).
   - "화면 흔들림" - ON/OFF toggle switch, OFF (grey).
   - "글자 크기" - 3-way toggle "작게 / 보통 / 크게".
4. Bottom row: wood button "장수 목록" on the left, red lacquer button "본진으로 (포기)" on the right with a small warning icon.
Mood: clean and calm; easy to tap with a thumb.
```
