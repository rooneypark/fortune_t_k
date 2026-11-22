#!/usr/bin/env python3
"""Synthesises the chiptune sound effects and two BGM loops into assets/sfx (no outside audio)."""
import numpy as np, wave, os
SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx")

def save(name, x):
    x = np.clip(x, -1, 1)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32000).astype(np.int16).tobytes())

def t(d): return np.arange(int(SR * d)) / SR
def sq(f, d, duty=0.5):
    ph = (np.cumsum(np.full(int(SR*d), f) if np.isscalar(f) else f) / SR) % 1.0
    return np.where(ph < duty, 1.0, -1.0)
def tri(f, d):
    ph = (np.cumsum(np.full(int(SR*d), f) if np.isscalar(f) else f) / SR) % 1.0
    return 4 * np.abs(ph - 0.5) - 1
def noise(d): return np.random.uniform(-1, 1, int(SR * d))
def env(n, a=0.005, r=0.1, total=None):
    e = np.ones(n); A = int(SR*a); R = int(SR*r)
    if A: e[:A] = np.linspace(0, 1, A)
    if R: e[-R:] *= np.linspace(1, 0, R)
    return e
def sweep(f0, f1, d): return np.linspace(f0, f1, int(SR*d))
def note(n): return 440.0 * 2 ** ((n - 69) / 12)
def cat(*xs): return np.concatenate(xs)

np.random.seed(3)
save("click", 0.35 * sq(sweep(900, 600, 0.05), 0.05, 0.25) * env(int(SR*0.05), r=0.03))
save("lever", 0.4 * cat(noise(0.04) * env(int(SR*0.04), r=0.03), sq(sweep(220, 110, 0.12), 0.12) * env(int(SR*0.12), r=0.08)))
save("reel", 0.3 * sq(sweep(700, 500, 0.06), 0.06, 0.125) * env(int(SR*0.06), r=0.05))
save("tick", 0.18 * sq(1200, 0.02, 0.25) * env(int(SR*0.02), r=0.015))
save("win", 0.33 * cat(*[sq(note(n), 0.08, 0.25) * env(int(SR*0.08), r=0.03) for n in (72, 76, 79, 84)]))
save("jackpot", 0.33 * cat(*[sq(note(n), 0.09, 0.25) * env(int(SR*0.09), r=0.02) for n in (72, 76, 79, 84, 79, 84, 88)], sq(note(91), 0.35, 0.5) * env(int(SR*0.35), r=0.25)))
save("miss", 0.3 * sq(sweep(330, 160, 0.25), 0.25, 0.5) * env(int(SR*0.25), r=0.15))
save("hit", 0.25 * noise(0.06) * env(int(SR*0.06), r=0.05))
save("castle", 0.45 * cat(noise(0.03), sq(sweep(120, 60, 0.18), 0.18)) * env(int(SR*0.21), r=0.12))
save("pop", 0.35 * sq(sweep(300, 900, 0.09), 0.09, 0.5) * env(int(SR*0.09), r=0.04))
save("rankup", 0.33 * cat(*[tri(note(n), 0.07) * env(int(SR*0.07), r=0.02) for n in (67, 71, 74, 79, 83, 86)]))
save("coin", 0.3 * cat(sq(note(83), 0.05, 0.25), sq(note(88), 0.18, 0.25) * env(int(SR*0.18), r=0.15)))
save("error", 0.3 * cat(sq(180, 0.08), np.zeros(int(SR*0.03)), sq(150, 0.12)) * env(int(SR*0.23), r=0.05))
save("skill", 0.35 * cat(sq(sweep(400, 1600, 0.15), 0.15, 0.25), noise(0.1) * np.linspace(0.6, 0, int(SR*0.1))))
save("boss", 0.45 * cat(*[sq(note(n), 0.18, 0.5) * env(int(SR*0.18), r=0.05) for n in (45, 44, 45, 44)], sq(note(40), 0.5) * env(int(SR*0.5), r=0.4)))
save("victory", 0.33 * cat(*[sq(note(n), d, 0.25) * env(int(SR*d), r=0.03) for n, d in ((72, .12), (72, .12), (72, .12), (76, .3), (74, .12), (76, .12), (79, .5))]))
save("defeat", 0.33 * cat(*[tri(note(n), d) * env(int(SR*d), r=0.05) for n, d in ((67, .25), (66, .25), (65, .25), (64, .6))]))
save("whoosh", 0.25 * noise(0.18) * np.sin(np.linspace(0, np.pi, int(SR*0.18))))
save("bolt", 0.5 * noise(0.25) * env(int(SR*0.25), r=0.22))

def bgm(name, bpm, melody, bass, bars_rep=2):
    beat = 60.0 / bpm / 2  # eighth notes
    def voice(seq, wavef, vol, duty=0.5):
        parts = []
        for n in seq:
            if n is None:
                parts.append(np.zeros(int(SR*beat)))
            else:
                x = (sq(note(n), beat, duty) if wavef == "sq" else tri(note(n), beat))
                parts.append(vol * x * env(len(x), a=0.003, r=beat*0.4))
        return cat(*parts)
    m = voice(melody * bars_rep, "sq", 0.16, 0.25)
    b = voice(bass * bars_rep, "tri", 0.22)
    n = min(len(m), len(b))
    kick = np.zeros(n)
    step = int(SR * beat * 2)
    for i in range(0, n, step):
        L = min(int(SR*0.05), n - i)
        kick[i:i+L] += 0.18 * noise(L / SR)[:L] * np.linspace(1, 0, L)
    save(name, m[:n] + b[:n] + kick)

# pentatonic, cheerful (lobby) and driving (battle)
mel_lobby = [72, 74, 76, 79, 76, 74, 72, None, 69, 72, 74, 76, 74, 72, 69, None,
             67, 69, 72, 74, 76, 74, 72, 69, 72, None, 74, None, 72, None, None, None]
bass_lobby = [48, None, 55, None, 48, None, 55, None, 45, None, 52, None, 45, None, 52, None,
              43, None, 50, None, 43, None, 50, None, 48, None, 55, None, 48, None, 55, None]
bgm("bgm_lobby", 112, mel_lobby, bass_lobby)
mel_battle = [69, 72, 74, 72, 76, 74, 72, 69, 67, 69, 72, 69, 74, 72, 69, 67,
              69, 72, 74, 76, 79, 76, 74, 72, 74, 72, 69, 67, 69, None, 69, None]
bass_battle = [45, 45, 57, 45, 45, 45, 57, 45, 43, 43, 55, 43, 43, 43, 55, 43,
               41, 41, 53, 41, 41, 41, 53, 41, 40, 40, 52, 40, 45, 45, 57, 45]
bgm("bgm_battle", 150, mel_battle, bass_battle)
print("ok")
