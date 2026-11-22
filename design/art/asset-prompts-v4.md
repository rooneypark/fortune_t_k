# 운빨삼국 — 구현용 그림 의뢰 목록 v4 (카툰 2D)

- 2026-11-22. 화면 시안 프롬프트는 `design/art/screen-mockup-prompts-v4.md`. 이 문서는 **시안을 실제 게임으로 만들 때 필요한 그림**(부품·아이콘·배경)을 받기 위한 것이다.
- **왜 따로 받나**: 화면 시안은 한 장으로 뭉쳐 있어서 잘라 쓸 수 없다(글자가 박혀 있고, 크기를 바꾸면 깨진다). 게임은 부품을 하나씩 받아서 조립하고, 글자·숫자는 게임에서 폰트로 넣는다.
- **참고 이미지**: 모든 의뢰에 `docs/screens/v4/00-style-reference-lobby.webp` 한 장.
- **받은 그림 저장**: `assets/ui_v4/raw/` 에 아래 파일 이름으로. 잘라서 쓰는 건 Claude가 한다.

## 공통 규칙 (모든 부품 시트)

- 배경은 **단색 마젠타(#FF00FF)**. 투명 배경을 요청하면 가짜 체크무늬가 그려지는 경우가 많아서, 마젠타를 Claude가 빼낸다.
- 부품끼리 **충분히 띄운다**(최소 40px). 겹치거나 그림자가 배경에 떨어지면 안 된다.
- **글자를 넣지 않는다.** 글자 자리가 필요하면 비워 둔다.
- 버튼은 **기본 상태 한 장만**. 눌림(내려앉기)·꺼짐(회색)은 게임 코드로 만든다.
- 판·틀은 **늘려 쓸 수 있게**: 가운데는 무늬 없이 평평하게, 장식은 네 모서리에만, 가장자리는 길이 방향으로 같은 모양이 반복되게.

## 받을 목록

| 파일 | 내용 | 쓰는 화면 | 우선 |
|---|---|---|---|
| A1-buttons.png | 버튼 | 전부 | 1 |
| A2-panels.png | 판·틀·칩 | 전부 | 1 |
| A3-ribbons-badges.png | 리본·배지·별·잠금 | 전부 | 1 |
| A4-controls.png | 바·슬라이더·스위치·탭 | 전부 | 1 |
| A5-bottom-bar.png | 하단 탭 바 | 하단 탭 화면 | 1 |
| A6-cards.png | 장수 카드 틀·희귀도 틀·보물 칸 | 장수·모집·편성·보물 | 2 |
| B1-icons-menu.png | 메뉴 아이콘 | 로비·하단 탭 | 1 |
| B2-icons-currency.png | 재화·보상 아이콘 | 전부 | 1 |
| B3-icons-stats.png | 능력치·상태 아이콘 | 장수·전투·결과 | 2 |
| B4-icons-treasure.png | 보물 아이콘 | 보물 | 3 |
| B5-icons-units.png | 병종·병졸 아이콘 | 편성·장수·전투 | 2 |
| C1-slot.png | 슬롯 기계 부품 | 전투 | 1 |
| C2-battle-ui.png | 전투 전용 UI | 전투 | 2 |
| D1-bg-lobby.png | 로비 배경 (UI·사람 없음) | 로비 | 1 |
| D2-bg-stage-select.png | 스테이지 선택 배경 | 스테이지 선택 | 2 |
| D3-stage-thumbs.png | 스테이지 그림 카드 4장 | 스테이지 선택 | 2 |
| D4-bg-battle.png | 전장 배경 (옆에서 본 들판) | 전투 | 1 |
| D5-bg-results.png | 승리·패배 배경 2장 | 결과 | 3 |
| D6-banners.png | 모집·상점·패스 배너 그림 | 모집·상점·패스 | 3 |
| D7-bg-room.png | 메뉴 화면 공용 배경 | 장수·편성·상점 등 | 2 |
| E1-effects.png | 반짝임·등급업·낙뢰 등 효과 | 전투·모집 | 3 |

**받지 않는 것 (지금은)**
- **캐릭터**: 지금은 임시 그림을 쓰고, 나중에 전부 새로 그린다. 그때 따로 의뢰서를 만든다.
- **폰트**: 굵고 둥근 한글 무료 폰트 파일 하나가 필요하다. 예: 주아체(Jua, 무료·상업 사용 가능). 민수가 받아서 `assets/fonts/` 에 넣어 주면 된다. 없으면 시스템 굵은 글꼴로 임시 사용.

---

## A1. 버튼

```
Square image, 1024 x 1024. A UI parts sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment, bright yellow main buttons.

BACKGROUND: flat solid magenta (#FF00FF) everywhere around the parts. Keep at least 40 pixels of empty magenta between parts. No shadows on the magenta, no text anywhere, no letters, no numbers.

Draw these buttons, empty (no text, no icon), each with a darker lip under the body for thickness and a soft light band on top:
Row 1: one very wide plump bright yellow main button (rounded rectangle, about 4 times as wide as tall).
Row 2: medium buttons in the same rounded shape: bright yellow, brown wood, green, red.
Row 3: small square wooden icon button with rounded corners; small round wooden button; small round green "plus" button with a white plus sign; small round red close button with a white X.
Row 4: wooden back-arrow button (a rounded square holding a yellow arrow pointing left); a small dark wooden speed button; a small round dark pause button.
```

## A2. 판·틀·칩

```
Square image, 1024 x 1024. A UI parts sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment.

BACKGROUND: flat solid magenta (#FF00FF) everywhere around the parts. At least 40 pixels between parts. No shadows on the magenta, no text anywhere.

Every panel must stretch well: plain flat center with no pattern, decoration only in the four corners, edges that look the same along their length.
Row 1: a large parchment panel with a wooden frame (popup window); a large plain parchment panel without frame.
Row 2: a wooden plank panel (dark wood board); a dark wooden title plate (like a name sign); a small parchment list-row card.
Row 3: a hanging parchment scroll: top wooden rod and bottom wooden rod drawn separately, and the empty parchment sheet separately.
Row 4: a dark see-through rounded pill chip (dark brown at about 70% opacity look) for currency numbers; a small round wooden portrait frame (empty center); a small "Lv" badge (empty).
```

## A3. 리본·배지·별·잠금

```
Square image, 1024 x 1024. A UI parts sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines.

BACKGROUND: flat solid magenta (#FF00FF) around the parts. At least 40 pixels between parts. No shadows on the magenta, no text anywhere.

Row 1: empty title ribbons with folded tails: parchment ribbon, bright yellow ribbon, red ribbon, grey cracked ribbon (defeat).
Row 2: small empty tag shapes: red tag, green tag, dark brown tag; a round green check badge; a small round red notice dot; a red exclamation bubble.
Row 3: star full gold, star empty grey, star glowing outline; padlock; dashed empty slot with a plus.
Row 4: round empty faction badges with a thick outline in five colors: blue, green, red, purple, mustard yellow.
```

## A4. 바·슬라이더·스위치·탭

```
Square image, 1024 x 1024. A UI parts sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, wood and parchment, bright yellow.

BACKGROUND: flat solid magenta (#FF00FF) around the parts. At least 40 pixels between parts. No shadows on the magenta, no text anywhere.

Row 1: an empty progress bar frame (long rounded, dark inside); separate fill strips in yellow, green and red that fit inside it.
Row 2: a slider track (wooden groove) and a round wooden slider knob; an on/off switch in the ON state (yellow) and in the OFF state (grey).
Row 3: top tabs: a wooden tab (not chosen) and a bright yellow tab (chosen), both empty rounded shapes; small round filter chips: wooden and bright yellow.
Row 4: a three-way toggle group (three joined wooden segments) and the same with the middle segment bright yellow.
```

## A5. 하단 탭 바

```
Wide image, 1792 x 1024. A UI parts sheet for a mobile game.

The attached image is the style guide. Match its bottom tab bar style exactly: hand-drawn 2D cartoon, thick dark brown outlines, wood and bright yellow.

BACKGROUND: flat solid magenta (#FF00FF) around the parts. At least 40 pixels between parts. No shadows on the magenta, no text, no icons.

Row 1: the bottom bar background strip: a long dark wooden plank strip that can be stretched sideways, with plain wood in the middle.
Row 2: one tab plate in its normal state (brown wood, square with rounded top corners, empty), and the same tab plate in its chosen state (bright yellow, a little taller so it rises above the strip, empty).
Row 3: a thin vertical wooden divider between tabs.
```

## A6. 카드 틀·희귀도 틀·보물 칸

```
Square image, 1024 x 1024. A UI parts sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines.

BACKGROUND: flat solid magenta (#FF00FF) around the parts. At least 40 pixels between parts. No shadows on the magenta, no text, no characters.

Row 1: empty hero card frames (tall rounded rectangle with a name plate area at the bottom), one for each rarity: silver frame, purple frame, gold frame with a few simple sparkles.
Row 2: empty card backgrounds (the area behind a hero picture) in five colors: blue, green, red, purple, mustard yellow, each with a soft simple pattern.
Row 3: empty rounded-square item slots with rims by rarity: grey, blue, purple, gold; and one empty slot with a faint dashed outline.
Row 4: a dark silhouette card (locked, not owned) with a small padlock.
```

---

## B1. 메뉴 아이콘

```
Square image, 1024 x 1024. An icon sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright full colors.

BACKGROUND: flat solid magenta (#FF00FF) around the icons. Icons in a 4 x 3 grid, all the same size, at least 40 pixels apart. No shadows on the magenta, no text.

Icons: a helmet with a red plume and gold trim (heroes); three small soldier heads (lineup); two crossed swords (player battle); a rolled scroll with a red seal (recruit); a small market stall with a red and cream striped awning (shop); an envelope with a red wax seal (mail); a checklist scroll with green checks (missions); a gold medal with a red ribbon (pass); a wooden gear (settings); a crossed-swords badge on a round shield (start battle); a map with a red flag pin (stages); a treasure chest (treasures).
```

## B2. 재화·보상 아이콘

```
Square image, 1024 x 1024. An icon sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright full colors.

BACKGROUND: flat solid magenta (#FF00FF) around the icons. Icons in a 4 x 3 grid, all the same size, at least 40 pixels apart. No shadows on the magenta, no text.

Icons: a gold coin; a shiny blue diamond; a pile of blue diamonds; a big chest full of blue diamonds; a recruit ticket (orange paper ticket); a rice sack (battle supplies); a green "EXP" style orb without letters (a glowing green gem); a closed treasure chest; an open treasure chest with light; a hero card back; a small video play screen (watch ad); a stack of gold coins.
```

## B3. 능력치·상태 아이콘

```
Square image, 1024 x 1024. An icon sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright full colors.

BACKGROUND: flat solid magenta (#FF00FF) around the icons. Icons in a 4 x 4 grid, all the same size, at least 40 pixels apart. No shadows on the magenta, no text.

Icons: sword (attack); shield (defense); red heart (health); lightning boot (attack speed); red burst star (critical hit); crossed swords with a glow (power); small castle (castle health); red banner flag (wave); soldier head (army size); helmet (hero slots); skull (kills); hourglass (time); fire (streak); up arrow in gold (rank up); two arrows joining in green (merge); lightning bolt (boss strike).
```

## B4. 보물 아이콘

```
Square image, 1024 x 1024. An icon sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright full colors.

BACKGROUND: flat solid magenta (#FF00FF) around the icons. Icons in a 4 x 3 grid, all the same size, at least 40 pixels apart. No shadows on the magenta, no text.

Ancient Chinese treasure items: a long crescent glaive; a straight sword; a recurve bow; a spear with a red tassel; a lamellar armor; a round helmet with a plume; a war cloak; a jade pendant; a gold seal stamp; a feather fan; a bamboo strategy scroll; a small war drum.
```

## B5. 병종·병졸 아이콘

```
Square image, 1024 x 1024. An icon sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright full colors.

BACKGROUND: flat solid magenta (#FF00FF) around the icons. Icons in a 4 x 2 grid, all the same size, at least 40 pixels apart. No shadows on the magenta, no text.

Row 1 (unit classes, simple symbols): a shield with a sword (infantry); a bow with an arrow (archer); a horse head (cavalry); a feather fan (strategist).
Row 2 (basic soldier types, small object icons): a spear; a big round shield; a short bow; a horseshoe.
```

---

## C1. 슬롯 기계 부품

```
Square image, 1024 x 1024. A UI parts sheet for the slot machine in a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, sturdy wood, bright yellow.

BACKGROUND: flat solid magenta (#FF00FF) around the parts. At least 40 pixels between parts. No shadows on the magenta, no text, no characters.

Row 1: the slot machine cabinet: a sturdy wooden cabinet with a dark window showing a 3 x 3 grid of empty square cells, wooden frame, small decorative corners. Drawn empty.
Row 2: empty square reel tiles in six colors: blue, green, red, purple, mustard yellow, plain parchment. Each with a thick outline and rounded corners.
Row 3: a glowing bright yellow tile border (win highlight); a long bright yellow win line strip; a round wooden payline coin (empty) and the same coin lit in yellow.
Row 4: a wooden lever with a red ball in the up position and in the pulled-down position; small yellow up and down arrows (nudge); an empty big bright yellow banner with flames on its ends (jackpot).
```

## C2. 전투 전용 UI

```
Square image, 1024 x 1024. A UI parts sheet for the battle screen of a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines.

BACKGROUND: flat solid magenta (#FF00FF) around the parts. At least 40 pixels between parts. No shadows on the magenta, no text, no characters.

Row 1: a long castle health bar frame with a small castle icon on its left end (empty inside); a small enemy health bar (dark frame, red fill) and a small ally health bar (dark frame, green fill).
Row 2: a round grey portrait frame with a dark overlay (fallen unit, waiting to respawn); two thin gold rank bands that float above a unit (one band, two bands); a small yellow arrow marker above a unit.
Row 3: a small parchment "next wave" panel (empty); a thin wooden strip for the strategist skill (empty); a small round skill button frame.
Row 4: a dashed vertical front-line marker; a small red warning circle (boss strike target area).
```

---

## D1. 로비 배경

```
Tall portrait image, 1024 x 1792.

Use the attached image as the exact reference: the same castle courtyard scene, same camera, same colors, same style.
Redraw ONLY THE BACKGROUND: the wooden castle gate building with the green tiled roof, the wall, the courtyard ground, the small market stall and training dummy at the sides, the sky and hills.
REMOVE everything else: no people, no heroes, no soldiers on the wall, no buttons, no top bar, no currency, no bottom tabs, no text.
Fill the areas where the UI was with more of the same sky and ground so the picture is complete.
Leave the top of the wall clear and flat so small soldiers can be placed walking on it later.
```

## D2. 스테이지 선택 배경

```
Tall portrait image, 1024 x 1792.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm and bright.

A bird's-eye view of a peaceful countryside: green rolling hills, small forests, a winding blue river, dirt roads, and a small castle far away at the top. Calm, slightly soft, with no strong focal point in the middle so a big scroll panel can sit on top. No UI, no text, no people.
```

## D3. 스테이지 그림 카드

```
Wide image, 1792 x 1024.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines.

Four separate wide picture cards (each about 3:1 wide), arranged in a 2 x 2 grid with flat solid magenta (#FF00FF) between them, at least 40 pixels apart. No text, no borders, no UI.
1. A sunny open field with a wooden fence and a dirt path.
2. A shady forest path with big trees.
3. A Yellow Turban camp with tents and yellow flags.
4. A stone castle gate under attack, with ladders against the wall.
```

## D4. 전장 배경

```
Tall portrait image, 1024 x 1792.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright daytime.

A battlefield seen from the SIDE, filling the TOP HALF of the image: on the far LEFT edge our wooden castle gate with a green tiled roof seen from the side, a flat dirt and grass field in the middle where small units will walk left and right, hills and sky behind.
The BOTTOM HALF is a plain dark wood texture (it will be covered by the slot machine panel).
No people, no UI, no text.
```

## D5. 결과 배경 2장

```
Wide image, 1792 x 1024.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines.

Two separate portrait backgrounds side by side (each about 9:16), with flat solid magenta (#FF00FF) between them. No people, no UI, no text.
Left: victory - bright sky with simple confetti, our wooden castle gate standing proud, a fallen yellow enemy flag on the ground.
Right: defeat - dusky grey-blue sky, our wooden castle gate damaged with a little smoke, broken arrows on the ground.
```

## D6. 배너 그림

```
Wide image, 1792 x 1024.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, bright and cheerful.

Three separate wide banner pictures (each about 2:1), with flat solid magenta (#FF00FF) between them, at least 40 pixels apart. No text, no UI, no characters.
1. Recruit: a cozy recruiting hall interior with a wooden notice board and lanterns.
2. Shop: a market stall with a striped awning, piles of blue diamonds and gold coins.
3. Season pass: a festive courtyard with red lanterns and banners.
```

## D7. 메뉴 화면 공용 배경

```
Tall portrait image, 1024 x 1792.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm.

A calm, slightly blurred interior of a wooden command hall: wooden walls and beams, a few hanging scrolls and lanterns, a wooden floor. No strong details in the middle, because UI panels will cover most of it. No people, no UI, no text.
```

---

## E1. 효과

```
Square image, 1024 x 1024. An effects sheet for a mobile game.

The attached image is the style guide. Match its art style exactly: hand-drawn 2D cartoon, thick outlines where useful, bright colors.

BACKGROUND: flat solid magenta (#FF00FF) around the effects. At least 40 pixels apart. No text.
Row 1: a four-point sparkle star (small and big); a burst of yellow confetti pieces; a soft round glow (yellow).
Row 2: a gold upward flash pillar (rank up); a green swirl (merge); a puff of dust cloud (unit landing).
Row 3: a zig-zag yellow lightning bolt (boss strike); a red impact star (hit); a small white smoke puff.
Row 4: coins flying (three coins); diamonds flying (three diamonds).
```

---

## 화면 시안과 부품의 관계

| 화면 | 시안 (screen-mockup-prompts-v4) | 필요한 부품 |
|---|---|---|
| 로비 | 01 (있음) | D1, A1, A2, A3, A5, B1, B2 |
| 스테이지 선택 | 01-B | D2, D3, A1~A3 |
| 장수 목록·상세 | 02, 03-A~C | D7, A1~A6, B3, B5 |
| 편성 | 04 | D7, A1~A6, B5 |
| 모집 | 05-A~C | D6, A1~A6, B2 |
| 보물 | 06-A, 06-B | D7, A6, B4 |
| 상점 | 07 | D6, D7, A1~A4, B2 |
| 임무·패스·우편·주공·설정 | 08~12 | D7, A1~A4, B1~B3 |
| 전투 | 13-A~C, 14~16 | D4, C1, C2, B3, E1 |
| 결과 | 17-A, 17-B | D5, A1~A3, B2, B3 |
