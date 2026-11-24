#!/usr/bin/env python3
"""로비 성문 열림 연출용 조각 (2026-11-23): 로비 배경(assets/bg/lobby_bg.png)에서 성문 나무 문짝을 잘라
왼쪽 · 오른쪽 문짝 두 장과 문 안쪽 어둠(아치 모양)을 만든다. 게임이 문짝을 양옆으로 접어 연다.
배경을 바꾸면 DOORS(화면 px)를 그 그림의 문 자리로 고치고 다시 돌린다 (lobby.gd 의 DOORS 도 같이).

Usage: python tools/cut_lobby_door.py
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "assets", "bg", "lobby_bg.png")
UI = os.path.join(ROOT, "assets", "ui")
# 성문 (2026-11-23 최종: 하나): 이름 -> (x, y, w, h) 화면 px, 4의 배수 — lobby.gd DOORS 와 같게. 아치 반지름 = 너비의 절반.
DOORS = {"gate1": (392, 796, 240, 292)}


def cut(name, rect, bg):
    x, y, w, h = rect
    ARCH_R = w // 2
    door = bg[y:y + h, x:x + w].copy()
    yy, xx = np.mgrid[0:h, 0:w]
    cx, cy = w / 2.0, float(ARCH_R)
    inside = (yy >= cy) | (((xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2) <= ARCH_R ** 2)
    door[~inside, 3] = 0
    left = door.copy()
    left[:, w // 2:, 3] = 0
    right = door.copy()
    right[:, : w // 2, 3] = 0
    Image.fromarray(left[:, : w // 2]).save(os.path.join(UI, name + "_door_l.png"))
    Image.fromarray(right[:, w // 2:]).save(os.path.join(UI, name + "_door_r.png"))
    hole = np.zeros((h, w, 4), np.uint8)
    hole[inside] = (14, 10, 8, 255)
    hole[inside & (yy > h - 24)] = (40, 30, 22, 255)    # 문턱 쪽은 조금 밝게
    Image.fromarray(hole).save(os.path.join(UI, name + "_hole.png"))


def main():
    bg = np.array(Image.open(BG).convert("RGBA"))
    for name, rect in DOORS.items():
        cut(name, rect, bg)
    print("door pieces cut", DOORS)


if __name__ == "__main__":
    main()
