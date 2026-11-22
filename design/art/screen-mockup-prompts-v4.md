# 운빨삼국 — 화면 시안 프롬프트 v4 (세로, 카툰 2D)

- 2026-11-22. 정본 기획: `design/gdd/운빨삼국-GDD_v5.md`, `design/gdd/메타-성장-과금.md`. v3(픽셀)은 폐기.
- **참고 이미지는 모든 화면에서 한 장**: `docs/screens/v4/00-style-reference-lobby.webp` (민수가 확정한 카툰 로비 시안).
- **쓰는 법**: 이미지 크기 1024×1792(세로) → 참고 이미지 1장 첨부 → 코드 블록 하나를 통째로 붙여 넣기.
- 받은 시안은 `docs/screens/v4/` 에 화면 번호로 저장 (예: `02-hero-list.png`).
- **구현용 부품·아이콘·배경 의뢰**는 `design/art/asset-prompts-v4.md` (시안과 별도로 받아야 구현 가능).
- **캐릭터**: 시안 속 캐릭터는 분위기용이다. 게임에는 지금 연결된 임시 그림을 쓰고, 나중에 전부 새로 그린다. 그래서 프롬프트는 캐릭터 생김새를 자세히 정하지 않는다.
- **시안의 글자·메뉴 이름이 틀려도 괜찮다.** 구현할 때 기획서 기준(장수·편성·군웅대전·모집·상점, 출정 등)으로 넣는다. 그림체·배치·부품 모양만 맞으면 된다.
- 프롬프트에 퍼센트 숫자와 영어 강조 단어를 쓰지 않는다(그림에 글자로 찍힌다).
- **상단 공통 (2026-11-22)**: 나무 바 없이 간결하게. 왼쪽 작은 동그란 주공 초상(로비만, 작은 Lv 배지), 오른쪽에 어두운 반투명 캡슐 칩(큰 아이콘이 왼쪽 끝에 걸침 + 흰 숫자 + 작은 초록 +): 골드, 다이아. 민수가 준 스테이지 선택 시안의 상단과 같은 방식.

## 화면 목록

| 번호 | 화면 | 하단 탭 |
|---|---|---|
| 01 | 로비 (참고 시안 보정판) | 있음 |
| 01-B | 스테이지 선택 (출정 누르면) | 없음 |
| 02 | 장수 목록 (장수 / 병졸 / 보물 탭) | 있음 |
| 03-A | 장수 상세 — 강화 | 없음 |
| 03-B | 장수 상세 — 성급 | 없음 |
| 03-C | 장수 상세 — 보물 | 없음 |
| 04 | 편성 | 있음 |
| 05-A | 모집 | 있음 |
| 05-B | 모집 결과 (10회) | 없음 |
| 05-C | 확률 정보 (팝업) | 없음 |
| 06-A | 보물 가방 (장수 화면 보물 탭) | 있음 |
| 06-B | 보물 상세·강화 (팝업) | 없음 |
| 07 | 상점 | 있음 |
| 08 | 임무 | 없음 |
| 09 | 전공 패스 | 없음 |
| 10 | 우편 | 없음 |
| 11 | 주공 정보 (팝업) | 없음 |
| 12 | 설정 (팝업) | 없음 |
| 13-A | 전투 — 기본 | 없음 |
| 13-B | 전투 — 꽝 + 한 칸 밀기 | 없음 |
| 13-C | 전투 — 같은 장수 3연 대박 | 없음 |
| 14 | 웨이브 승리 (팝업) | 없음 |
| 15 | 보스 경고 (팝업) | 없음 |
| 16 | 일시정지 (팝업) | 없음 |
| 17-A | 결과 — 승리 | 없음 |
| 17-B | 결과 — 패배 | 없음 |
| 18 | 군웅대전 | 기획 후 작성 (서버 필요) |

---

## 01. 로비 (보정판 — 필요할 때만)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Keep its art style, colors, castle courtyard and UI shapes exactly. Redraw the same lobby with only these changes:
- The big yellow button says "출정". Above it a small parchment ribbon says "스테이지 3-7".
- The bottom tab bar touches both screen edges with no empty space at the sides: five equal wooden tabs, from left to right: helmet "장수", three soldier heads "편성", crossed swords "군웅대전", scroll with a red seal "모집", market stall "상점". The first tab "장수" is a raised bright yellow plate; the others are brown wood.
- Simple top row with no wooden bar and no exp bar: on the left a small round portrait of the lord with a tiny "Lv.4" badge; next to it two small dark see-through rounded pill chips, each with a big icon overlapping its left end, a white number and a tiny green "+": gold coin "12,500" and blue diamond "350".
- Keep the right-side column: gear, envelope "우편" with a red dot, checklist "임무", medal "패스".
- Three cute heroes stand in the courtyard and two small soldiers stand on the wall, like the reference.
Write only these Korean words: Lv.4, 12,500, 350, 우편, 임무, 패스, 스테이지 3-7, 출정, 장수, 편성, 군웅대전, 모집, 상점. No other text, no numbers like percentages, no English words.
```

---

## 01-B. 스테이지 선택

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering with a dark outline, cute chibi Three Kingdoms characters. Do not copy its layout; build the screen below.

SCREEN: stage select, opened from the lobby's 출정 button. No bottom tab bar.
Background: a soft, slightly blurred bird's-eye view of green hills, a winding river and a distant castle.
Top row: a wooden back-arrow button on the left; small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
A big hanging parchment scroll with wooden rods at the top and bottom, and a dark wooden plate title on top "3장 황건의 난". Small wooden arrow buttons on the left and right edges of the scroll to change chapters.
Inside the scroll, a vertical list of four stage cards, each a wide picture card with a thick dark brown outline showing the place:
- "3-5 탁현 들판": sunny field with a wooden fence; a green check badge "클리어".
- "3-6 숲속 매복": shady forest path; a green check badge "클리어".
- "3-7 황건적 야영지": tents and yellow flags with a big angry Yellow Turban brute and small enemy soldiers; this card is chosen: a thick bright yellow border and a small red "NEW" tag.
- "3-8 성문 공방": a castle gate picture, greyed out with a small padlock.
Under the list, a small parchment strip for the chosen stage: "적 웨이브 10", "보스 장각", and first-clear rewards with icons "첫 클리어" diamond "50", gold "1,500".
Main button overlapping the bottom of the scroll: a wide, plump bright yellow button "출정".

Write only these Korean words and numbers: 12,500, 350, 3장 황건의 난, 3-5 탁현 들판, 3-6 숲속 매복, 3-7 황건적 야영지, 3-8 성문 공방, 클리어, NEW, 적 웨이브 10, 보스 장각, 첫 클리어, 50, 1,500, 출정. No other text, no English words except NEW.
```

---

## 02. 장수 목록

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the chosen or main button, bold rounded Korean lettering with a dark outline, cute chibi Three Kingdoms characters. Do not copy its layout; build the screen below.

SCREEN: hero list.
At the top: a wooden back-arrow button on the left, a parchment ribbon title "장수" in the middle, small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
Under the title: three wooden tabs "장수" (bright yellow, chosen), "병졸", "보물".
Under the tabs: a row of small round filter buttons: "전체" (yellow), then round colored badges "위" blue, "촉" green, "오" red, "군웅" purple, and a small wooden sort button "등급순" on the right. A small line "보유 18/40".
The main area: a parchment board holding a 4-column grid of hero cards. Each card: a cute chibi hero on a background in its faction color, a small faction badge in the top-left corner, the hero name on a wooden plate under the picture, 1 to 6 small gold stars, and "Lv.12" in a tiny tag. A few cards are dark silhouettes with a small lock (not owned). Two cards have a small red dot.
At the very bottom: the full-width wooden tab bar touching both screen edges: "장수" (raised yellow), "편성", "군웅대전", "모집", "상점".

Write only these Korean words: 장수, 병졸, 보물, 전체, 위, 촉, 오, 군웅, 등급순, 보유 18/40, 12,500, 350, 편성, 군웅대전, 모집, 상점, hero names and Lv numbers. No other text, no English words.
```

## 03-A. 장수 상세 — 강화

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering with a dark outline, cute chibi Three Kingdoms characters. Do not copy its layout; build the screen below.

SCREEN: hero detail, upgrade tab. No bottom tab bar on this screen.
At the top: wooden back-arrow button, parchment ribbon title "장수 정보", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
Hero stage: a big cute chibi general with a long glaive standing on a round wooden pedestal, a soft green banner behind him. Beside him: a green round badge "촉", a wooden name plate "관우", a small tag "명장", three gold stars out of six. Small wooden arrow buttons on the left and right edges to switch heroes.
Three wooden tabs under the stage: "강화" (bright yellow, chosen), "성급", "보물".
A parchment panel with three rows. Each row: an icon, a name, the value with an arrow to the next value, a small level text, a gold coin cost, and a small yellow button "강화":
- sword icon "공격" 120 → 125, "Lv 18/30", 1,230
- shield icon "방어" 80 → 83, "Lv 12/30", 980
- heart icon "체력" 1,640 → 1,705, "Lv 15/30", 1,100
Under the rows: a wide yellow button "모두 강화" and a wooden plate "전투력 3,250".
At the bottom: a skill box with a square skill icon, the name "청룡참" and the line "앞의 적을 크게 벤다".

Write only the Korean words and numbers listed here. No other text, no English words.
```

## 03-B. 장수 상세 — 성급

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering with a dark outline. Do not copy its layout; build the screen below.

SCREEN: hero detail, star-up tab. No bottom tab bar.
Same top part as the hero detail screen: back arrow, title "장수 정보", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them, a big cute chibi general with a long glaive on a round wooden pedestal with a green banner, badge "촉", name "관우", tag "명장", three gold stars out of six.
Tabs: "강화", "성급" (bright yellow, chosen), "보물".
A parchment panel:
- A row of six large star slots: three filled gold, the fourth glowing softly (next), two empty. Under it: "3성 → 4성".
- A small hero-card icon with a progress bar "2/3".
- A list with small icons: "기본 능력치 ×1.15", "강화 한도 30 → 40", "기술 강화".
- A wide yellow button "성급 올리기" shown greyed out (not enough cards), and a small wooden button "모집하러 가기".

Write only the Korean words and numbers listed here. No other text, no English words.
```

## 03-C. 장수 상세 — 보물

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering with a dark outline. Do not copy its layout; build the screen below.

SCREEN: hero detail, treasure tab. No bottom tab bar.
Same top part as the hero detail screen: back arrow, title "장수 정보", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them, the chibi general with a long glaive on a wooden pedestal with a green banner, badge "촉", name "관우", tag "명장", three gold stars out of six.
Tabs: "강화", "성급", "보물" (bright yellow, chosen).
Three big rounded-square slots in a row with colored rims by rarity (grey, blue, purple, gold):
- "무기": purple rim, a cartoon glaive, "+7"
- "갑옷": blue rim, cartoon armor, "+3"
- "보패": empty slot with a faint jade pendant outline and a "+" sign
A parchment info panel for the chosen item: item icon, name "청룡도", tag "영웅", main stat "공격 +86", two small stats "치명타 +4%" and "공격속도 +6%", buttons "강화" (yellow) and "해제" (wood).
At the bottom: a wooden plate "보물 합계 공격 +86 방어 +40" and a wide yellow button "자동 장착".

Write only the Korean words and numbers listed here. No other text, no English words.
```

---

## 04. 편성

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main or chosen button, bold rounded Korean lettering with a dark outline, cute chibi Three Kingdoms characters. Do not copy its layout; build the screen below.

SCREEN: lineup. The player picks which heroes go onto the slot machine reels and one strategist.
At the top: back arrow, ribbon title "편성", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
A wide parchment card "책사": a round portrait of a chibi strategist with a feather fan, name "제갈량", one line "웨이브마다 한 줄 다시 돌리기", small wooden button "교체".
A parchment board titled "슬롯 장수 6/8": a 4 x 2 grid of big slots; six hold chibi hero cards on faction-colored backgrounds (3 green, 2 blue, 1 red), two are empty with a dashed outline and a "+".
A small wooden strip with four soldier icons (spear, shield, bow, horse) and the words "기본 병졸 항상 포함".
A row of synergy chips: "촉 3" glowing green, "위 2" blue, "오 1" red.
A scrollable grid of owned hero cards (5 columns, small); chosen ones are dimmed with a yellow check mark.
At the very bottom: the full-width wooden tab bar touching both screen edges: "장수", "편성" (raised yellow), "군웅대전", "모집", "상점".

Write only the Korean words and numbers listed here, plus hero names. No other text, no English words.
```

---

## 05-A. 모집

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering with a dark outline, cute chibi Three Kingdoms characters. Do not copy its layout; build the screen below.

SCREEN: recruit (draw hero cards).
At the top: back arrow, ribbon title "모집", small dark see-through rounded pill chips on the right with a big icon overlapping the left end and a white number: blue diamond "350" and recruit ticket "5". No bar behind them.
Two wooden tabs: "일반 모집" (yellow), "기간 한정".
A big banner scene: a cozy recruiting hall with a wooden notice board, three featured cute chibi heroes in front, a few simple sparkles. A small round wooden button "확률" in the banner's top-right corner.
A wooden plate "기린아 확정까지 37회" with a yellow progress bar.
Two big buttons side by side: a wooden button "1회 모집" with a ticket icon "1" or diamond "300", and a bigger bright yellow button "10회 모집" with diamond "2,700" and a small red ribbon "명장 이상 1명 확정".
A small line "중복 장수는 장수 카드로 바뀝니다".
At the very bottom: the full-width wooden tab bar touching both screen edges: "장수", "편성", "군웅대전", "모집" (raised yellow), "상점".

Write only the Korean words and numbers listed here. No other text, no English words.
```

## 05-B. 모집 결과 (10회)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bold rounded Korean lettering. Do not copy its layout.

SCREEN: 10 recruit results. No bottom tab bar.
A parchment ribbon title "모집 결과" at the top.
Ten hero cards in two rows of five. Each card: a cute chibi hero on its faction-colored background with a frame by rarity: silver frame, purple frame, and one gold frame with gentle sparkles and a small red "NEW" tag. Two cards have a small tag "카드 +1".
Two buttons at the bottom: a wooden button "확인" and a bright yellow button "10회 더" with diamond "2,700".

Write only: 모집 결과, NEW, 카드 +1, 확인, 10회 더, 2,700, and hero names. No other text.
```

## 05-C. 확률 정보 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bold rounded Korean lettering. Do not copy its layout.

SCREEN: a popup over the recruit screen, which is darkened behind it.
A large parchment popup with a wooden frame, a ribbon title "확률 정보" and a round red close button with an X.
Inside: a table with three rows and a small rarity frame icon in each: "기린아 3%", "명장 17%", "장수 80%".
Two small lines: "10회 모집 시 명장 이상 1명 확정", "60회 안에 기린아 1명 확정".
A scrollable list of hero names with their odds, for example "제갈량 1.5%", "조조 1.5%", "관우 4.25%", "조운 4.25%".

Write only the Korean words and numbers listed here. No other text.
```

---

## 06-A. 보물 가방 (장수 화면 — 보물 탭)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the chosen button, bold rounded Korean lettering. Do not copy its layout.

SCREEN: the hero screen with the treasure tab open.
At the top: back arrow, ribbon title "장수", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
Three wooden tabs: "장수", "병졸", "보물" (bright yellow, chosen).
Small round filter buttons: "전체" (yellow), "무기", "갑옷", "보패", and a wooden sort button "등급순".
A parchment board with a 5-column grid of cartoon treasure icons (glaives, swords, bows, armors, helmets, jade pendants, seals) on rounded squares with rims by rarity (grey, blue, purple, gold), each with a small "+N". Some have a tiny hero face in the corner (equipped).
A small line "보유 46/200".
At the very bottom: the full-width wooden tab bar touching both screen edges: "장수" (raised yellow), "편성", "군웅대전", "모집", "상점".

Write only the Korean words and numbers listed here. No other text, no English words.
```

## 06-B. 보물 상세·강화 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering. Do not copy its layout.

SCREEN: a popup over the treasure bag, which is darkened behind it.
A parchment popup with a wooden frame and a round red close button.
Inside: a big cartoon glaive in a purple rarity frame, name "청룡도", tag "영웅", "무기", level "+7/+15".
Main stat "공격 +86 → +92". Small stats: "치명타 +4%", "공격속도 +6%", and a greyed line with a lock "+10에서 열림".
A small row "장착: 관우" with a tiny hero face.
Buttons: a bright yellow "강화" with a gold coin "2,400" and a wooden "장착 변경".

Write only the Korean words and numbers listed here. No other text.
```

---

## 07. 상점

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main or chosen button, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: shop.
At the top: back arrow, ribbon title "상점", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
Wooden tabs: "추천" (yellow), "다이아", "골드", "패키지".
A featured banner: a happy chibi merchant with a pile of blue diamonds, big text "첫 결제 2배".
A wide parchment card "월정액": "매일 다이아 100 · 30일", a yellow price button "₩5,500".
A 3-column grid of diamond packs on parchment cards, each with a pile of diamonds that grows bigger, the amount and a yellow price button: "60" ₩1,200, "300" ₩5,900, "980" ₩19,000, "1,980" ₩38,000, "3,280" ₩59,000, a treasure chest "6,480" ₩119,000.
A small line "확률형 상품은 확률 정보를 확인하세요".
At the very bottom: the full-width wooden tab bar touching both screen edges: "장수", "편성", "군웅대전", "모집", "상점" (raised yellow).

Write only the Korean words, numbers and prices listed here. No other text, no English words.
```

---

## 08. 임무

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering. Do not copy its layout.

SCREEN: missions. No bottom tab bar.
At the top: back arrow, ribbon title "임무", small dark see-through rounded pill chips on the right, each with a big icon overlapping its left end, a white number and a tiny green "+" at the icon's lower corner: gold coin "12,500" and blue diamond "350". No bar behind them.
Wooden tabs: "일일" (yellow), "주간", "업적".
A progress bar with four small treasure chests along it; the first chest is open.
A list of parchment mission rows. Each row: an icon, the mission text, progress, the reward icon with amount, and a button ("받기" bright yellow when done, "이동" wood when not):
- "출정 3회" 2/3, gold 500, 이동
- "슬롯 20회 돌리기" 20/20, diamond 20, 받기
- "장수 강화 5회" 1/5, gold 800, 이동
- "스테이지 1-5 클리어" 0/1, ticket 1, 이동
- "군웅대전 1회" 0/1, gold 400, 이동
A wide bright yellow button at the bottom "모두 받기".

Write only the Korean words and numbers listed here. No other text.
```

## 09. 전공 패스

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: season pass. No bottom tab bar.
At the top: back arrow, ribbon title "전공 패스", a small dark see-through rounded pill chip on the right with a big blue diamond icon overlapping its left end and "350". No bar behind it.
A header banner: a chibi hero in a festive outfit, "시즌 1", "남은 기간 23일", "Lv 12" with a yellow progress bar.
Two column labels: "무료" (wood) and "특별" (yellow with a small lock), and a yellow button "특별 패스 열기 ₩11,000".
A vertical reward track: each row has a level number in the middle, a free reward on the left and a special reward on the right (gold coins, diamonds, tickets, treasure chests, a hero outfit at level 30). Claimed rewards have a green check; locked special rewards have a small lock.
A wide yellow button at the bottom "모두 받기".

Write only the Korean words and numbers listed here. No other text.
```

## 10. 우편

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering. Do not copy its layout.

SCREEN: mailbox. No bottom tab bar.
At the top: back arrow, ribbon title "우편".
A list of parchment mail rows. Each row: a sealed envelope icon (opened ones look grey), a title, a reward icon with amount, time left, and a small yellow button "받기":
- "출시 기념 선물", diamond 300, "6일 남음"
- "점검 보상", gold 5,000, "2일 남음"
- "임무 보상", ticket 1, "13일 남음"
Two buttons at the bottom: wooden "읽은 우편 삭제" and bright yellow "모두 받기".

Write only the Korean words and numbers listed here. No other text.
```

## 11. 주공 정보 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: a popup over the darkened lobby.
A parchment popup with a wooden frame and a round red close button.
Inside: a big round portrait of a cute chibi lord with a small pencil button, name "주공", "Lv.4", a green exp bar "320/500".
Stats in two columns on small wooden plates: "최고 스테이지 3-7", "군웅대전 승리 12", "보유 장수 18", "최대 연속 대박 5연".
A row "다음 보상: Lv.5 편성 칸 +1".
Two small wooden buttons: "초상 변경", "계정 연동".

Write only the Korean words and numbers listed here. No other text.
```

## 12. 설정 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bright yellow for chosen options, bold rounded Korean lettering. Do not copy its layout.

SCREEN: a settings popup over the darkened lobby.
A parchment popup with a wooden frame, a ribbon title "설정" and a round red close button.
Rows, each with a small icon on the left:
- "배경음" with a wooden slider, yellow fill
- "효과음" with a wooden slider
- "슬롯 연출" with three wooden toggle buttons "빠르게", "보통" (yellow), "끄기"
- "진동" with an on/off switch, on (yellow)
- "화면 흔들림" with an on/off switch, off (grey)
- "글자 크기" with three toggles "작게", "보통" (yellow), "크게"
- "알림" with an on/off switch
At the bottom: small wooden buttons "고객센터", "약관", "계정" and a tiny "v0.1.0".

Write only the Korean words listed here. No other text.
```

---

## 13-A. 전투 — 기본

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering, cute chibi Three Kingdoms characters. Do not copy its layout; build the screen below.

SCREEN: battle. An auto-battle runs in the upper half; the player spins a 3 x 3 slot machine in the lower half to recruit warriors. No bottom tab bar.

Top strip: a rice sack icon "300", a soldier icon "5/8", a helmet icon "2/4", a flag icon "3/10", a small wooden speed button "1x" and a small round pause button on the right. Under it, a castle health bar with a castle icon, red fill about two thirds, "70%".

Upper half, the battlefield seen from the side: our wooden castle gate on the far left edge; a dirt field in the middle with a thin dashed line in the center; cute chibi allies on the left facing right (spearmen, archers, a general with a long glaive, an armored spear general); Yellow Turban enemies with yellow headbands on the right walking left, each with a tiny red health bar. Above two of our units, two thin gold bands (rank up). Next to our gate, two small grey round portraits with white countdown numbers "3" and "9". A small parchment panel in the top-right of the field "다음" with two tiny enemy icons "x4" and "x1".

A thin wooden strip: a small round portrait of a strategist with a feather fan, the name "제갈량", and a small yellow skill button "한 줄 다시" with "1/1".

Lower half, the slot machine: a sturdy wooden cabinet with a parchment ribbon "천명 슬롯" on top. Inside, 3 reels by 3 rows of square tiles; each tile shows a cute chibi unit on its faction-colored background with a tiny faction badge. Five round numbered coins 1 to 5 on both sides mark the paylines. The middle row has three tiles of the same glaive general with a bright yellow line through it. A wooden lever with a red ball on the right side.

Under the slot: a small row "영입 3" with three small unit cards tagged "등급 +1" or "합류".

Bottom controls: a big bright yellow button "돌리기" with a rice sack icon "120"; on its left a small wooden button "대기석 2/8"; on its right a small wooden button "한 칸 밀기" shown greyed out.

No diamonds anywhere on this screen. Write only the Korean words and numbers listed here. No other text, no English words.
```

## 13-B. 전투 — 꽝 + 한 칸 밀기

```
Tall portrait image, 1024 x 1792, a mobile game screen.

Use the attached battle screen as the exact reference for layout and art style. Keep everything the same except:
- The slot shows no matching line. A small grey ribbon above the slot says "꽝".
- Each of the three reels has a small yellow up arrow above it and a down arrow below it, inviting the player to move one reel by one tile.
- The right reel is highlighted, with a faint ghost preview showing that moving it down one tile would make a diagonal line of three spearmen.
- "영입 0".
- The "돌리기" button shows "140". The "한 칸 밀기" button is now bright yellow and active with a rice sack "35" and a small "1회".

Write only the Korean words and numbers already on the screen plus: 꽝, 영입 0, 140, 35, 1회. No other text.
```

## 13-C. 전투 — 같은 장수 3연 대박

```
Tall portrait image, 1024 x 1792, a mobile game screen.

Use the attached battle screen as the exact reference for layout and art style. Keep everything the same except:
- The middle row is three tiles of the same glaive general with a thick bright yellow line and simple sparkles around the slot.
- A big ribbon across the slot says "3연 대박!" with a small flame badge "x2".
- On the battlefield the glaive general flashes gold, has two gold bands above his head and a floating tag "등급 +1".
- The recruit row shows one wide card of the glaive general with "등급 +1".

Write only the Korean words and numbers already on the screen plus: 3연 대박!, x2, 등급 +1. No other text.
```

## 14. 웨이브 승리 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: a popup over the darkened battle screen.
A parchment popup with a yellow ribbon title "웨이브 3 승리".
Rows with icons: "군량 +320", "성 체력 +10%", "처치 24".
A small row "활약" with a chibi glaive general face and "처치 9".
A small preview "다음 웨이브 4" with tiny enemy icons "창병 x6", "기마 x2".
A wide bright yellow button "다음 웨이브".

No diamonds. Write only the Korean words and numbers listed here. No other text.
```

## 15. 보스 경고 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: a warning over the darkened battle screen.
A wide red and wood banner across the middle "보스 출현".
Under it, a cute but scary chibi Yellow Turban leader with a yellow headband and a staff with small lightning sparks, standing on a wooden plate with the name "장각".
One line: "6초마다 낙뢰를 떨어뜨린다".
A small hint at the bottom: "화면을 누르면 시작".

Write only the Korean words listed here. No other text.
```

## 16. 일시정지 (팝업)

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering. Do not copy its layout.

SCREEN: a pause popup over the darkened battle screen.
A parchment popup with a ribbon title "일시정지".
A wide bright yellow button "계속하기".
Small rows: "배경음" slider, "효과음" slider, "슬롯 연출" toggles "빠르게", "보통" (yellow), "끄기".
A wooden button "설정".
A small red button at the bottom "출정 포기" with a tiny warning icon.

Write only the Korean words listed here. No other text.
```

## 17-A. 결과 — 승리

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: victory result.
Top: a big yellow and red ribbon "승리" and a smaller line "스테이지 3-7 클리어", bright sky with simple confetti.
Middle: cute chibi warriors cheering in front of our wooden castle gate; a fallen Yellow Turban flag on the ground.
A parchment panel with stats on small wooden plates: "도달 웨이브 10/10", "남은 성 체력 62%", "슬롯 23회", "최대 연속 대박 5연".
A row "최고 활약" with a chibi glaive general portrait and "처치 47".
A reward row: gold coin "+1,500", exp "+120", treasure chest "보물 x1", ticket "x1" with a small ribbon "첫 클리어".
Two buttons: wooden "로비로" and bright yellow "다시 출정".

Write only the Korean words and numbers listed here. No other text.
```

## 17-B. 결과 — 패배

```
Tall portrait image, 1024 x 1792, a mobile game screen.

The attached image is the style guide for the whole game. Match its art style exactly: hand-drawn 2D cartoon, thick dark brown outlines, warm wood and parchment UI, bright yellow for the main button, bold rounded Korean lettering, cute chibi characters. Do not copy its layout.

SCREEN: defeat result.
Top: a grey cracked ribbon "성이 함락되었다" and a smaller line "스테이지 3-7", dusky sky.
Middle: our wooden castle gate damaged with a little smoke; sad but cute chibi warriors sitting on the ground.
A parchment panel "이어하기": "웨이브 6부터 다시", a yellow button with diamond "100", a wooden button with a small video icon "광고 보고 이어하기", and a small line "출정당 1회".
Stats on small wooden plates: "도달 웨이브 6/10", "성 체력 0%", "슬롯 14회".
A reward row: gold coin "+600", exp "+50".
Two buttons: wooden "로비로" and bright yellow "다시 출정".

Write only the Korean words and numbers listed here. No other text.
```
