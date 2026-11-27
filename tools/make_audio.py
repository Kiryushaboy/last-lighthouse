"""Синтез всех звуков и музыки игры. Запуск: python3 tools/make_audio.py
Нужны numpy и ffmpeg (с libvorbis). Результат — audio/*.wav и audio/music.ogg."""
import os, subprocess, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=None):
    """Быстрая атака и экспоненциальное затухание."""
    x = np.arange(n) / SR
    e = np.minimum(1, x / a)
    d = n / SR
    r = r or d / 4
    return e * np.exp(-x / r)


def sweep(f0, f1, d, shape="sine"):
    x = t(d)
    f = f0 * (f1 / f0) ** (x / d)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "square":
        return np.sign(np.sin(ph)) * 0.6
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def lowpass(x, k):
    """Простой однополюсный фильтр, k от 0 до 1 (меньше — глуше)."""
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def tone(f, d, shape="sine", r=None):
    s = sweep(f, f, d, shape)
    return s * env(len(s), r=r)


def seq(*parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap:
            out.append(np.zeros(int(SR * gap)))
    return np.concatenate(out)


def save(name, x, vol=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * vol
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def sfx():
    s = sweep(1400, 500, 0.09, "tri"); save("shoot", s * env(len(s), r=0.03), 0.35)
    s = lowpass(noise(0.07), 0.5) + 0.5 * sweep(300, 150, 0.07); save("hit", s * env(len(s), r=0.02), 0.5)
    s = lowpass(noise(0.25), 0.25) + sweep(400, 80, 0.25, "tri"); save("death", s * env(len(s), r=0.07), 0.6)
    s = sweep(900, 1500, 0.08); save("xp", s * env(len(s), r=0.04), 0.35)
    s = seq(tone(1320, 0.07, r=0.04), tone(1760, 0.18, r=0.08)); save("shell", s, 0.5)
    notes = [523, 659, 784, 1047]
    s = seq(*[tone(f, 0.11, "tri", r=0.06) for f in notes[:-1]], tone(1047, 0.4, "tri", r=0.15)); save("levelup", s, 0.6)
    s = sweep(220, 90, 0.2, "square"); s = lowpass(s, 0.3) + 0.4 * lowpass(noise(0.2), 0.3); save("hurt", s * env(len(s), r=0.08), 0.7)
    x = t(0.9); s = np.sin(2 * np.pi * 110 * x) * (0.5 + 0.5 * np.sin(2 * np.pi * 6 * x)) + 0.4 * np.sign(np.sin(2 * np.pi * 55 * x))
    s = lowpass(s, 0.2) * np.minimum(1, x / 0.1) * np.minimum(1, (0.9 - x) / 0.2); save("warning", s, 0.7)
    s = lowpass(noise(0.6), 0.08) * 2 + sweep(90, 35, 0.6); save("slam", s * env(len(s), r=0.18), 0.9)
    win = [523, 659, 784, 1047, 784, 1047, 1319]
    s = seq(*[tone(f, 0.16, "tri", r=0.1) for f in win[:-1]], tone(1319, 0.9, "tri", r=0.35)); save("win", s, 0.6)
    s = seq(tone(392, 0.3, "tri", r=0.2), tone(311, 0.3, "tri", r=0.2), tone(262, 0.9, "tri", r=0.4)); save("lose", s, 0.6)
    s = tone(1000, 0.04, r=0.012); save("click", s, 0.35)


def music():
    """Спокойный эмбиент: медленные аккорды, мягкий бас, шум прибоя. Ровно зацикливается."""
    bpm = 72
    beat = 60 / bpm
    chords = [[220, 261.6, 329.6], [174.6, 220, 261.6], [130.8, 196, 261.6], [196, 246.9, 293.7]]
    bar = beat * 4
    total = bar * len(chords) * 2
    n = int(SR * total)
    x = np.arange(n) / SR
    out = np.zeros(n)
    for i in range(len(chords) * 2):
        c = chords[i % len(chords)]
        start = int(i * bar * SR)
        length = int(bar * SR * 1.5)
        idx = (np.arange(length) + start) % n  # хвост переносится в начало: петля без шва
        xx = np.arange(length) / SR
        pad_env = np.minimum(1, xx / 1.2) * np.exp(-xx / (bar * 0.9))
        for f in c:
            v = np.sin(2 * np.pi * f * xx) + 0.3 * np.sin(2 * np.pi * f * 2.003 * xx)
            out[idx] += 0.18 * v * pad_env
        b = np.sin(2 * np.pi * c[0] / 2 * xx) * np.exp(-xx / 1.5) * np.minimum(1, xx / 0.02)
        out[idx] += 0.25 * b
        # Звон маяка: тихие колокольчики на 1 и 3 долю
        for k, f in ((0, c[2] * 2), (2, c[1] * 2)):
            s0 = int((i * bar + k * beat) * SR)
            ln = int(SR * 2)
            ii = (np.arange(ln) + s0) % n
            xb = np.arange(ln) / SR
            out[ii] += 0.06 * np.sin(2 * np.pi * f * xb) * np.exp(-xb / 0.6)
    surf = lowpass(rng.uniform(-1, 1, n), 0.05)
    out += 0.6 * surf * (0.6 + 0.4 * np.sin(2 * np.pi * x / (bar * 2)))
    path = os.path.join(OUT, "_music.wav")
    save("_music", out, 0.55)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", "3",
                    os.path.join(OUT, "music.ogg")], check=True)
    os.remove(path)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sfx()
    music()
    print("готово:", sorted(os.listdir(OUT)))
