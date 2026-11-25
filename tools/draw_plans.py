#!/usr/bin/env python3
"""제미나이에 첨부할 창 배치도 (회색 네모 + 번호). 자리는 지금 게임 코드의 자리 그대로(논리 화면 1024 x 1792).
결과: design/art/ui_src/배치도/<이름>_배치도.png. 요청문은 design/ux/화면별-요청문.md.

창 공통: 창 틀 = panel_rect, 제목 띠 = 가운데 560 x 124 (창 위 끝에서 58 위), 닫기 = 88 x 88 (오른쪽 위, 창 위 끝에서 30 위).
부품 자리 = panel_rect 위치 + 창 안 자리 (src/ui/popups/*.gd 의 put()).

Usage: python tools/draw_plans.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "design", "art", "ui_src", "배치도")
FONT = os.path.join(ROOT, "assets", "fonts", "Galmuri11-Bold.ttf")
W, H = 1024, 1792
SHADE = {"frame": (225, 225, 225), "title": (170, 170, 170), "close": (90, 90, 90), "slot": (190, 190, 190),
         "btn": (110, 110, 110), "btn2": (150, 150, 150), "card": (130, 130, 130)}


def window(panel, title=True, close=True):
    x, y, w, h = panel
    out = [("1", (x, y, w, h), "frame")]
    if title:
        tw = min(560, w - 40)
        out.append(("2", (x + (w - tw) // 2, y - 58, tw, 124), "title"))
    if close:
        out.append(("3", (x + w - 88 - 4, y - 30, 88, 88), "close"))
    return out


def part(panel, num, local, shade):
    return (num, (panel[0] + local[0], panel[1] + local[1], local[2], local[3]), shade)


def draw(name, boxes, note="(뒤: 어둡게 가려진 화면)"):
    im = Image.new("RGB", (W, H), (122, 122, 122))
    d = ImageDraw.Draw(im)
    f_note = ImageFont.truetype(FONT, 26)
    d.text((W // 2, 200), note, font=f_note, fill=(200, 200, 200), anchor="mm")
    for num, (x, y, w, h), shade in boxes:
        fill = SHADE[shade]
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        size = 44 if min(w, h) >= 70 else 30
        f = ImageFont.truetype(FONT, size)
        col = (255, 255, 255) if sum(fill) < 400 else (30, 30, 30)
        if shade == "frame":
            d.text((x + 16, y + h - 50), num, font=f, fill=col)
        else:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=col, anchor="mm")
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + "_배치도.png"))
    print("saved", name)


def absorb():
    """흡수 창 (속성 고르기 모드, src/ui/popups/absorb.gd _build_trait). 성급 모드도 같은 그림을 쓴다."""
    p = (52, 330, 920, 1130)
    w = p[2]
    b = window(p)
    b += [part(p, "4", (w // 2 - 300, 100, 170, 170), "slot"),         # 먹이 얼굴 틀
          part(p, "5", (w // 2 - 110, 130, 220, 110), "btn2"),          # 화살표
          part(p, "6", (w // 2 + 130, 100, 170, 170), "slot")]          # 받는 쪽 얼굴 틀
    for i, n in enumerate(("7", "8", "9")):                             # 속성 카드 3장
        b.append(part(p, n, (30 + i * 290, 420, 270, 250), "card"))
    for i in range(6):                                                  # 속성 칸 6개 (3개씩 두 줄, 칸 = 성급)
        b.append(part(p, "10", (w // 2 - 3 * 135 + (i % 3) * 270, 740 + (i // 3) * 84, 260, 72), "btn2"))
    b.append(part(p, "11", (w // 2 - 165, 980, 330, 120), "btn"))      # 흡수하기 (취소 버튼 없음: 닫기 X가 같은 일)
    draw("흡수창", b, "(뒤: 어둡게 가려진 전투 화면)")


def wave_clear():
    """웨이브 승리 창 (src/ui/popups/wave_clear.gd)."""
    p = (92, 470, 840, 860)
    b = window(p)
    for i in range(3):                                                  # 기록 줄 3개 (아이콘 + 이름 + 숫자)
        b.append(part(p, "4", (60, 100 + i * 84, 720, 72), "slot"))
    b += [part(p, "5", (60, 370, 130, 130), "slot"),                    # 활약 장수 얼굴 틀
          part(p, "6", (210, 370, 560, 130), "slot"),                   # 활약 장수 이름 칸
          part(p, "7", (60, 530, 720, 150), "slot"),                    # 다음 웨이브 적 칸
          part(p, "8", (220, 710, 400, 120), "btn")]                    # 다음 웨이브 버튼
    draw("웨이브승리창", b, "(뒤: 어둡게 가려진 전투 화면)")


def result():
    """결과 창 (src/ui/popups/result.gd): 승리 · 패배가 같은 창. 닫기 없음. 7번(이어하기)은 패배 때만."""
    p = (52, 300, 920, 1260)
    b = window(p, close=False)
    for i in range(4):
        b.append(part(p, "3", (30 + i * 215, 330, 200, 116), "slot"))        # 기록 칸 4
    b += [part(p, "4", (40, 470, 120, 120), "card"),                       # 활약 장수 얼굴 틀
          part(p, "5", (180, 470, 700, 120), "slot"),                      # 활약 장수 칸
          part(p, "6", (30, 610, 860, 190), "slot"),                       # 보상 칸
          part(p, "7", (180, 830, 560, 130), "btn2"),                      # 이어하기 (패배 때만)
          part(p, "8", (60, 1000, 380, 130), "btn2"),                      # 로비로
          part(p, "9", (480, 1000, 380, 130), "btn")]                      # 다음 스테이지 / 다시
    draw("결과창", b, "(뒤: 어둡게 가려진 전투 화면)")


def detail2():
    """장수 · 병사 상세 다시 짠 배치 (2026-11-24 민수 님: 예전 배치는 던져 놓은 느낌).
    정보 판 안에 초상 틀 · 이름 줄 · 능력치 줄 · 필살기 띠를 넣고, 내용 판은 아래 탭 위까지 채운다. 인연은 성급 탭 안으로."""
    im = Image.new("RGB", (W, H), (122, 122, 122))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 38)
    fs = ImageFont.truetype(FONT, 22)

    def box(r, fill, num, label="", dark=False):
        x, y, w, h = r
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        col = (255, 255, 255) if dark else (30, 30, 30)
        if label and h >= 70:
            d.text((x + w // 2, y + h // 2 - 14), num, font=f, fill=col, anchor="mm")
            d.text((x + w // 2, y + h // 2 + 20), label, font=fs, fill=col, anchor="mm")
        elif label:
            d.text((x + 14, y + h // 2), num + "  " + label, font=fs, fill=col, anchor="lm")
        else:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=col, anchor="mm")

    old = (205, 205, 205)
    box((0, 0, W, 200), (90, 90, 90), "", "위 HUD (게임 그대로)", True)
    box((0, 1592, W, H - 1592), (90, 90, 90), "", "아래 탭 (게임 그대로)", True)
    box((16, 212, 992, 1364), (225, 225, 225), "", "")
    # 정보 판과 그 안
    box((48, 236, 928, 524), (150, 150, 150), "", "")
    d.text((70, 262), "1 정보 판", font=fs, fill=(30, 30, 30))
    box((84, 290, 360, 360), (95, 95, 95), "2", "초상 틀 (금테)", True)
    box((476, 290, 150, 48), (110, 110, 110), "3", "등급", True)
    d.text((476, 366), "(이름 · 별 자리)", font=fs, fill=(40, 40, 40))
    box((476, 440, 150, 48), (175, 175, 175), "4", "진영")
    box((640, 440, 190, 48), (175, 175, 175), "4", "병종")
    for i in range(3):
        box((476, 508 + i * 48, 464, 42), (185, 185, 185), "5", "능력치 줄")
    box((84, 670, 856, 72), (165, 165, 165), "6", "필살기 띠")
    box((24, 444, 56, 96), (70, 70, 70), "7", dark=True)
    box((944, 444, 56, 96), (70, 70, 70), "7", dark=True)
    # 탭 (기존)
    for i in range(3):
        box((60 + i * 304, 778, 296, 92), old, "", "탭 (기존)")
    # 내용 판: 아래 탭 위까지
    box((48, 884, 928, 676), (165, 165, 165), "", "")
    d.text((70, 906), "8 내용 판 (예: 장비 탭)", font=fs, fill=(30, 30, 30))
    for i in range(3):
        box((168 + i * 236, 944, 216, 216), old, "", "칸 (기존)")
    box((92, 1184, 412, 92), (110, 110, 110), "9", "자동 장착", True)
    box((520, 1184, 412, 92), (110, 110, 110), "10", "모두 해제", True)
    box((92, 1300, 840, 230), (185, 185, 185), "11", "효과 칸 (장비 합계 · 인연 목록)")
    box((910, 188, 96, 88), (90, 90, 90), "", "", True)
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "상세_배치도2.png"))
    print("saved 상세2")


def heroes2():
    """장수 · 병사 목록 다시 짠 배치 (2026-11-24 민수 님): 상세와 같은 규칙 — 떠 있는 부품 없이 모두 판 안에.
    탭 → 거르기 줄(칩 + 도감 수) → 내용 판(카드 4열, 아래 탭 위까지). 카드 = 얼굴 칸 + 아래 이름 띠."""
    im = Image.new("RGB", (W, H), (122, 122, 122))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 34)
    fs = ImageFont.truetype(FONT, 22)

    def box(r, fill, num, label="", dark=False):
        x, y, w, h = r
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        col = (255, 255, 255) if dark else (30, 30, 30)
        if label and h >= 70:
            d.text((x + w // 2, y + h // 2 - 14), num, font=f, fill=col, anchor="mm")
            d.text((x + w // 2, y + h // 2 + 18), label, font=fs, fill=col, anchor="mm")
        elif label:
            d.text((x + 12, y + h // 2), num + " " + label, font=fs, fill=col, anchor="lm")
        else:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=col, anchor="mm")

    box((0, 0, W, 200), (90, 90, 90), "", "위 HUD (게임 그대로)", True)
    box((0, 1592, W, H - 1592), (90, 90, 90), "", "아래 탭 (게임 그대로)", True)
    box((16, 212, 992, 1364), (225, 225, 225), "", "")
    d.text((26, 1556), "1", font=fs, fill=(60, 60, 60))
    box((60, 236, 408, 88), (110, 110, 110), "3", "고른 탭", True)
    box((478, 236, 408, 88), (165, 165, 165), "4", "안 고른 탭")
    # 거르기 줄 (5): 칩 6 · 7 과 도감 수 칸 8 이 그 안에
    box((48, 338, 928, 92), (150, 150, 150), "", "")
    d.text((60, 384), "5", font=f, fill=(30, 30, 30), anchor="lm")
    box((100, 356, 112, 56), (110, 110, 110), "6", dark=True)
    for i in range(4):
        box((224 + i * 100, 356, 90, 56), (185, 185, 185), "7")
    box((640, 356, 316, 56), (120, 120, 120), "8", dark=True)
    # 내용 판 (9) + 카드 (10 칸 · 11 이름 띠)
    box((48, 444, 928, 1116), (165, 165, 165), "", "")
    d.text((960, 1540), "9", font=f, fill=(30, 30, 30), anchor="rm")
    for r in range(4):
        for c in range(4):
            x, y = 76 + c * 222, 470 + r * 262
            box((x, y, 206, 246), (200, 200, 200), "", "")
            d.text((x + 103, y + 92), "10", font=f, fill=(30, 30, 30), anchor="mm")
            box((x + 8, y + 186, 190, 50), (120, 120, 120), "11", "", True)
    box((910, 188, 96, 88), (90, 90, 90), "2", dark=True)
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "장수목록_배치도2.png"))
    print("saved 장수목록2")


def lobby5():
    """로비 5차 배치 (2026-11-24 민수 님): 버튼에는 글자를 쓰지 않는다 (아이콘만). 글자는 성문 위 현판(스테이지 이름)뿐.
    아래 탭 위 정중앙: 출정 · 쟁패 정사각형 버튼 2개 (같은 크기, 아이콘만). 아래 탭 5개는 아이콘만. 번호만."""
    im = Image.new("RGB", (W, H), (122, 122, 122))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 40)

    def box(r, fill, num, dark=False, ellipse=False):
        x, y, w, h = r
        if ellipse:
            d.ellipse([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        else:
            d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        if num:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=(255, 255, 255) if dark else (30, 30, 30), anchor="mm")

    box((0, 0, W, 470), (205, 215, 225), "")
    box((0, 470, W, 640), (165, 165, 165), "")
    box((300, 300, 424, 230), (150, 150, 150), "")
    box((350, 640, 324, 470), (120, 120, 120), "")
    box((0, 1110, W, 430), (190, 175, 150), "")
    d.text((512, 330), "1", font=f, fill=(30, 30, 30), anchor="mm")
    d.text((512, 1200), "1", font=f, fill=(30, 30, 30), anchor="mm")
    box((13, 7, 181, 212), (90, 90, 90), "2", True)
    box((193, 30, 340, 108), (110, 110, 110), "3", True)
    box((537, 30, 347, 108), (110, 110, 110), "4", True)
    box((890, 30, 115, 114), (90, 90, 90), "5", True, True)
    box((332, 536, 360, 96), (95, 80, 60), "9", True)
    # 아래 탭 위 정중앙: 출정 · 쟁패 정사각형 버튼 2개 (같은 크기)
    box((302, 1236, 200, 200), (120, 40, 40), "", True)
    box((338, 1272, 128, 128), (200, 200, 200), "10")
    box((522, 1236, 200, 200), (60, 60, 110), "", True)
    box((558, 1272, 128, 128), (200, 200, 200), "8")
    # 아래 탭 5개: 아이콘만
    box((0, 1556, W, 236), (70, 70, 70), "", True)
    for i in range(5):
        x = 10 + i * 202
        box((x, 1576, 196, 200), (110, 110, 110), "", True)
        box((x + 38, 1616, 120, 120), (200, 200, 200), "11")
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "로비_배치도5_번호.png"))
    print("saved 로비5")


def lobby6():
    """로비 6차 도면 (2026-11-25 민수 님: 기준 화면에 얽매이지 않고 도면만 주고 새로 뽑는다).
    자리는 지금 게임 그대로 (assets/ui/lobby_layout.json, 성문 = lobby.gd DOORS). 번호만 적는다 — 뜻은 요청문에."""
    import json
    L = json.load(open(os.path.join(ROOT, "assets", "ui", "lobby_layout.json"), encoding="utf-8"))
    im = Image.new("RGB", (W, H), (235, 235, 235))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 40)
    fs = ImageFont.truetype(FONT, 30)

    def box(r, fill, num="", dark=False, ellipse=False, font=f):
        x, y, w, h = [int(v) for v in r]
        (d.ellipse if ellipse else d.rectangle)([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        if num:
            d.text((x + w // 2, y + h // 2), num, font=font, fill=(255, 255, 255) if dark else (30, 30, 30), anchor="mm")

    # 배경 구역 (옅은 회색 띠 + 알파벳)
    for (y0, y1, fill, tag) in ((0, 470, (226, 230, 236), "A"), (470, 880, (196, 196, 196), "B"), (880, 1525, (222, 214, 200), "C")):
        d.rectangle([0, y0, W, y1], fill=fill)
        d.text((60, y1 - 50), tag, font=f, fill=(90, 90, 90), anchor="mm")
    box((300, 250, 424, 200), (170, 170, 170), "D")                 # 성루
    box((377, 565, 271, 315), (140, 140, 140), "E")                 # 성문
    box(L["lobby_plaque"], (95, 80, 60), "7", True, font=fs)        # 현판
    box(L["lobby_portrait"], (90, 90, 90), "1", True)
    box(L["lobby_chip_gold"], (110, 110, 110), "2", True)
    box(L["lobby_chip_rice"], (110, 110, 110), "3", True)
    box(L["lobby_btn_settings"], (90, 90, 90), "4", True, True)
    box(L["lobby_btn_mail"], (90, 90, 90), "5", True, True)
    box(L["lobby_btn_mission"], (90, 90, 90), "6", True, True)
    box(L["lobby_tab_bar"], (70, 70, 70), "", True)
    band = int(L["tab_band"][3])
    for key, num in (("lobby_tab_hero", "8"), ("lobby_tab_bag", "9"), ("lobby_tab_arena", "11"), ("lobby_tab_shop", "12")):
        x, y, w, h = [int(v) for v in L[key]]
        # 아이콘 자리에 밝은 네모를 그리면 제미나이가 빈 네모를 그대로 그린다: 번호만 적는다
        box((x + 6, y + 10, w - 12, h - 20), (110, 110, 110), "", True)
        d.text((x + w // 2, y + 85), num, font=f, fill=(255, 255, 255), anchor="mm")
        box((x + 16, y + int(L["tab_band"][1]), w - 32, band), (60, 60, 60), "", True)
    x, y, w, h = [int(v) for v in L["lobby_tab_stage"]]
    box((x, y, w, h), (150, 50, 45), "", True)
    d.text((x + w // 2, y + 100), "10", font=f, fill=(255, 255, 255), anchor="mm")
    box((x + 18, y + int(L["tab_band_stage"][1]), w - 36, int(L["tab_band_stage"][3])), (90, 30, 28), "", True)
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "로비_도면6.png"))
    print("saved 로비6")


def lobby7():
    """로비 7차 도면 (2026-11-25 민수 님): 형식을 정하지 않고 UI 구역만 정해 준다.
    흰 바탕 = 그림은 자유. 회색 = UI가 들어갈 구역 (자리 · 크기는 지금 게임 그대로). 구역 번호만 적는다."""
    import json
    L = json.load(open(os.path.join(ROOT, "assets", "ui", "lobby_layout.json"), encoding="utf-8"))
    im = Image.new("RGB", (W, H), (250, 250, 250))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 56)
    g, line = (150, 150, 150), (40, 40, 40)

    def area(r, num=""):
        x, y, w, h = [int(v) for v in r]
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=g, outline=line, width=5)
        if num:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=(255, 255, 255), anchor="mm")

    # 1 위쪽 띠: 초상 + 칩 2개
    area(L["lobby_portrait"])
    area(L["lobby_chip_gold"], "1")
    area(L["lobby_chip_rice"])
    # 2 오른쪽 둥근 버튼 3개
    for k, n in (("lobby_btn_settings", ""), ("lobby_btn_mail", "2"), ("lobby_btn_mission", "")):
        x, y, w, h = [int(v) for v in L[k]]
        d.ellipse([x, y, x + w - 1, y + h - 1], fill=g, outline=line, width=5)
        if n:
            d.text((x + w // 2, y + h // 2), n, font=f, fill=(255, 255, 255), anchor="mm")
    # 3 현판
    area(L["lobby_plaque"], "")
    px, py, pw, ph = [int(v) for v in L["lobby_plaque"]]
    d.text((px + pw + 44, py + ph // 2), "3", font=f, fill=(90, 90, 90), anchor="mm")
    # 4 아래 탭 5칸 (가운데가 크다)
    for k in ("lobby_tab_hero", "lobby_tab_bag", "lobby_tab_arena", "lobby_tab_shop"):
        x, y, w, h = [int(v) for v in L[k]]
        area((x + 4, y + 8, w - 8, H - y - 16))
    x, y, w, h = [int(v) for v in L["lobby_tab_stage"]]
    area((x, y, w, H - y - 8), "4")
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "로비_도면7_구역.png"))
    print("saved 로비7")


def battle2():
    """전투 화면 2차 (2026-11-24 민수 님: 로비 2차와 같은 스타일). 번호만 (설명 글자는 제미나이가 따라 쓴다).
    1 배경: 위 하늘, 왼쪽에 긴 성벽 + 성문(아래 판 바로 위까지), 오른쪽은 넓은 흙 전장. 2~8 위 HUD, 9~16 아래 슬롯 · 조작 판."""
    im = Image.new("RGB", (W, H), (122, 122, 122))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 36)

    def box(r, fill, num, dark=False, ellipse=False):
        x, y, w, h = r
        if ellipse:
            d.ellipse([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        else:
            d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill, outline=(20, 20, 20), width=4)
        if num:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=(255, 255, 255) if dark else (30, 30, 30), anchor="mm")

    # 배경
    box((0, 0, W, 560), (205, 215, 225), "")
    box((0, 560, W, 714), (190, 175, 150), "")
    box((0, 300, 190, 974), (150, 150, 150), "")
    box((70, 760, 120, 240), (110, 110, 110), "")
    d.text((95, 420), "1", font=f, fill=(30, 30, 30), anchor="mm")
    d.text((600, 900), "1", font=f, fill=(30, 30, 30), anchor="mm")
    # 위 HUD
    box((16, 28, 218, 104), (110, 110, 110), "2", True)
    box((240, 28, 172, 104), (110, 110, 110), "3", True)
    box((418, 28, 172, 104), (110, 110, 110), "4", True)
    box((596, 28, 172, 104), (110, 110, 110), "5", True)
    box((778, 26, 108, 108), (90, 90, 90), "6", True, True)
    box((896, 26, 108, 108), (90, 90, 90), "7", True, True)
    box((20, 146, 984, 92), (110, 110, 110), "8", True)
    # 아래 판
    box((0, 1274, 537, 518), (80, 80, 90), "", True)
    d.text((26, 1300), "9", font=f, fill=(255, 255, 255))
    for i in range(3):
        x = 45 + i * 152
        box((x + 36, 1334, 64, 50), (200, 200, 200), "11")
        box((x, 1392, 146, 300), (215, 210, 195), "10")
        box((x + 36, 1700, 64, 50), (200, 200, 200), "11")
    box((537, 1274, 487, 518), (80, 80, 90), "", True)
    d.text((560, 1300), "12", font=f, fill=(255, 255, 255))
    box((590, 1330, 116, 300), (120, 120, 120), "13", True)
    box((572, 1644, 152, 70), (110, 110, 110), "14", True)
    box((734, 1336, 266, 196), (150, 60, 60), "15", True)
    box((734, 1552, 266, 190), (60, 60, 110), "16", True)
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "전투_배치도2_번호.png"))
    print("saved 전투2")


def battle3():
    """전투 3차 도면 (2026-11-25 민수 님): 로비 7차와 같은 방식 — UI 구역만. 흰 바탕 = 그림 자유, 회색 = UI 구역.
    옅은 띠 A = 성벽(왼쪽), B = 전장(비움). 번호 1~4 = UI."""
    im = Image.new("RGB", (W, H), (250, 250, 250))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 56)
    g, line = (150, 150, 150), (40, 40, 40)

    def area(r, num="", fill=g, ellipse=False, ink=(255, 255, 255)):
        x, y, w, h = [int(v) for v in r]
        (d.ellipse if ellipse else d.rectangle)([x, y, x + w - 1, y + h - 1], fill=fill, outline=line, width=5)
        if num:
            d.text((x + w // 2, y + h // 2), num, font=f, fill=ink, anchor="mm")

    # 그림 자리 (UI 아님): A 성벽, B 전장
    area((0, 250, 190, 1020), "A", (228, 228, 228), ink=(110, 110, 110))
    d.text((600, 760), "B", font=f, fill=(170, 170, 170), anchor="mm")
    # 1 위: 값 칩 4개 + 둥근 버튼 2개
    for i, x in enumerate((14, 222, 430, 638)):
        area((x, 24, 200, 92), "1" if i == 1 else "")
    area((846, 22, 80, 96), "", ellipse=True)
    area((932, 22, 80, 96), "", ellipse=True)
    # 2 성 체력 막대
    area((14, 130, 996, 84), "2")
    # 3 아래 왼쪽 판: 슬롯 (릴 3칸)
    area((0, 1270, 540, 522))
    d.text((60, 1310), "3", font=f, fill=(255, 255, 255), anchor="mm")
    for i in range(3):
        area((44 + i * 156, 1380, 144, 290), "", (205, 205, 205))
    # 4 아래 오른쪽 판: 레버 + 버튼 2개
    area((544, 1270, 480, 522))
    d.text((604, 1310), "4", font=f, fill=(255, 255, 255), anchor="mm")
    area((580, 1350, 120, 330), "", (205, 205, 205))
    area((724, 1340, 276, 170), "", (205, 205, 205))
    area((724, 1530, 276, 170), "", (205, 205, 205))
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, "전투_도면3_구역.png"))
    print("saved 전투3")


def char_ref():
    """제미나이에 첨부할 캐릭터 기준 그림: 우리 캐릭터의 비율 · 선 · 명암에 화면 그림을 맞추게 한다 (화면에 그리라는 뜻이 아니다)."""
    units = os.path.join(ROOT, "assets", "units")
    names = ["liubei", "guanyu", "caocao", "sword", "spear", "archer", "shield", "enemy_sword", "boss_lvbu_b"]
    k = 4
    ims = []
    for n in names:
        f = os.path.join(units, n, "idle", "000.png")
        if not os.path.exists(f):
            continue
        im = Image.open(f).convert("RGBA")
        im = im.crop(im.getbbox())
        ims.append(im.resize((im.width * k, im.height * k), Image.NEAREST))
    gap = 40
    w = sum(i.width for i in ims) + gap * (len(ims) + 1)
    h = max(i.height for i in ims) + gap * 2
    c = Image.new("RGBA", (w, h), (203, 190, 160, 255))
    x = gap
    for im in ims:
        c.alpha_composite(im, (x, h - gap - im.height))
        x += im.width + gap
    c.convert("RGB").save(os.path.join(os.path.dirname(OUT), "기준_캐릭터.png"))


if __name__ == "__main__":
    # 지금 쓰는 배치도만 (2026-11-24 정리). 옛 배치(1차 장수 목록 · 상세, 로비 2~4차, 1차 전투, 일시정지 창)는 지웠다.
    absorb()
    wave_clear()
    result()
    heroes2()
    detail2()
    lobby5()
    lobby6()
    lobby7()
    battle2()
    battle3()
    char_ref()
