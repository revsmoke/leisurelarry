#!/usr/bin/env python3
"""Render an original 32-second lounge loop. Requires NumPy; no samples or network."""

from pathlib import Path
import hashlib
import json
import wave

import numpy as np


SAMPLE_RATE = 44100
BPM = 90
BEAT = 60.0 / BPM
BARS = 12
DURATION = BEAT * 4 * BARS
FRAMES = round(SAMPLE_RATE * DURATION)
RNG = np.random.default_rng(19810921)
MIX = np.zeros((FRAMES, 2), dtype=np.float64)


def frequency(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def envelope(times, length, decay, attack=0.01, release=0.12):
    attack_curve = np.minimum(times / attack, 1.0)
    release_curve = np.clip((length - times) / release, 0.0, 1.0)
    return attack_curve * release_curve * np.exp(-times / decay)


def place(sound, when, amplitude, pan):
    """Wrap instrument tails around the bar loop for a continuous transition."""
    first = round(when * SAMPLE_RATE)
    positions = (first + np.arange(len(sound))) % FRAMES
    angle = (pan + 1.0) * np.pi / 4
    MIX[positions, 0] += sound * amplitude * np.cos(angle)
    MIX[positions, 1] += sound * amplitude * np.sin(angle)


def rhodes(midi, when, amplitude, length=2.3):
    t = np.arange(round(length * SAMPLE_RATE)) / SAMPLE_RATE
    f = frequency(midi)
    # Gently decaying FM tine with warm low harmonics, entirely synthesized.
    phase = 2 * np.pi * f * t
    strike = 0.62 * np.exp(-t / 0.19) * np.sin(2.01 * phase)
    tone = np.sin(phase + strike) + 0.13 * np.sin(2 * phase) + 0.03 * np.sin(3 * phase)
    tone *= envelope(t, length, 0.78, attack=0.012, release=0.25)
    place(tone, when, amplitude, -0.23)


def bass(midi, when, length, amplitude=0.13):
    t = np.arange(round(length * SAMPLE_RATE)) / SAMPLE_RATE
    phase = 2 * np.pi * frequency(midi) * t
    tone = np.sin(phase) + 0.25 * np.sin(2 * phase) * np.exp(-t / 0.09)
    tone += 0.10 * np.sin(3 * phase) * np.exp(-t / 0.04)
    tone *= envelope(t, length, 0.32, attack=0.013, release=0.08)
    place(tone, when, amplitude, -0.05)


def vibe(midi, when, amplitude=0.031, length=1.75):
    t = np.arange(round(length * SAMPLE_RATE)) / SAMPLE_RATE
    phase = 2 * np.pi * frequency(midi) * t
    tone = np.sin(phase) + 0.18 * np.sin(4.01 * phase) * np.exp(-t / 0.2)
    tone *= (0.88 + 0.12 * np.cos(2 * np.pi * 4.7 * t))
    tone *= envelope(t, length, 0.66, attack=0.008, release=0.2)
    place(tone, when, amplitude, 0.35)


def brush(when, accent=False):
    length = 0.24 if accent else 0.10
    t = np.arange(round(length * SAMPLE_RATE)) / SAMPLE_RATE
    noise = RNG.normal(0, 1, len(t))
    # A band-limited noise sweep, with no sourced percussion sample.
    noise = np.convolve(noise, np.ones(5) / 5, mode="same")
    noise = noise - np.convolve(noise, np.ones(31) / 31, mode="same")
    noise *= envelope(t, length, 0.055 if accent else 0.02, attack=0.003, release=0.035)
    place(noise, when, 0.067 if accent else 0.031, 0.32)


def kick(when):
    length = 0.20
    t = np.arange(round(length * SAMPLE_RATE)) / SAMPLE_RATE
    tone = np.sin(2 * np.pi * (49 * t + 0.62 * (1 - np.exp(-t * 28))))
    tone *= envelope(t, length, 0.045, attack=0.004, release=0.03)
    place(tone, when, 0.035, 0.0)


# Twelve bars of original voicings. No melody is transcribed from another work.
# Each entry: bass root, bass fifth, spread electric-piano voicing, ornament pool.
HARMONY = [
    (36, 43, [52, 57, 62, 67], [76, 79, 81, 86]),  # C6/9
    (45, 40, [55, 61, 64, 70], [73, 76, 79, 82]),  # A13 b9 colour
    (38, 45, [53, 60, 64, 69], [72, 76, 77, 81]),  # Dm9
    (43, 38, [53, 59, 64, 69], [74, 76, 79, 81]),  # G13
    (40, 47, [55, 62, 66, 71], [74, 78, 79, 83]),  # Em9
    (45, 40, [55, 61, 65, 70], [73, 77, 79, 82]),  # A7 altered
    (38, 45, [53, 60, 64, 69], [72, 76, 77, 81]),  # Dm9
    (43, 38, [53, 59, 64, 69], [74, 76, 79, 81]),  # G13
    (41, 36, [57, 60, 64, 67], [72, 76, 79, 81]),  # Fmaj9
    (41, 36, [56, 60, 63, 67], [72, 75, 79, 80]),  # Fm9
    (36, 43, [52, 57, 62, 67], [74, 76, 79, 81]),  # C6/9
    (43, 38, [53, 59, 64, 69], [74, 76, 79, 81]),  # G13 turnaround
]

for bar, (root, fifth, voicing, ornaments) in enumerate(HARMONY):
    start = bar * 4 * BEAT
    for beat in range(4):
        brush(start + beat * BEAT + 0.014, accent=(beat in (1, 3)))
        brush(start + (beat + 0.64) * BEAT)
    kick(start)
    kick(start + 2 * BEAT)
    for beat, note in [(0, root), (1.63, fifth), (2.0, root + 12), (3.6, root + 7)]:
        bass(note, start + beat * BEAT, 0.48 if beat < 3 else 0.25,
             amplitude=0.108 if beat in (0, 2.0) else 0.066)
    for at, strength in [(0.02, 0.034), (1.66, 0.026), (3.01, 0.022)]:
        for voice, note in enumerate(voicing):
            rhodes(note, start + at * BEAT + voice * 0.011, strength)
    # Sparse generated answers leave generous room for dialogue and ambience.
    if bar in (0, 2, 4, 6, 8, 10):
        selected = RNG.choice(ornaments, 3, replace=False)
        for at, note, strength in zip((0.68, 1.65, 2.35), selected, (0.021, 0.032, 0.027)):
            vibe(int(note), start + at * BEAT, strength)

# Circular room reflections keep the loop seamless and work in single-thread Web.
dry = MIX.copy()
for delay, gain in [(0.071, 0.070), (0.113, 0.043), (0.193, 0.028)]:
    MIX += np.roll(dry[:, ::-1], round(delay * SAMPLE_RATE), axis=0) * gain
MIX -= MIX.mean(axis=0)
MIX = np.tanh(MIX * 1.3)
MIX *= 0.48 / np.max(np.abs(MIX))
pcm = np.round(np.clip(MIX, -1, 1) * 32767).astype("<i2")
output = Path(__file__).resolve().parents[1] / "assets/audio/last_call.wav"
output.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(output), "wb") as file:
    file.setnchannels(2)
    file.setsampwidth(2)
    file.setframerate(SAMPLE_RATE)
    file.writeframes(pcm.tobytes())

result = {
    "file": str(output), "seconds": DURATION, "frames": FRAMES,
    "sample_rate": SAMPLE_RATE, "channels": 2, "bits": 16, "bpm": BPM,
    "peak_dbfs": round(20 * np.log10(np.max(np.abs(MIX))), 2),
    "rms_dbfs": round(20 * np.log10(np.sqrt(np.mean(MIX ** 2))), 2),
    "loop_boundary_delta": int(np.max(np.abs(pcm[0].astype(int) - pcm[-1].astype(int)))),
    "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
}
print(json.dumps(result, indent=2))
