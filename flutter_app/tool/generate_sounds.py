#!/usr/bin/env python3
"""Generate the original Warm Mallet sound family used by the app.

The family is intentionally small and coherent: marimba body, glass-bell
partials, muted woodblock transients, and one shared light room tail.

Usage:
    python tool/generate_sounds.py
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"

# C-major note frequencies used across the family.
C4 = 261.6256
D4 = 293.6648
E4 = 329.6276
F4 = 349.2282
G4 = 391.9954
A4 = 440.0
B4 = 493.8833
C5 = 523.2511
D5 = 587.3295
E5 = 659.2551
G5 = 783.9909
A5 = 880.0
C6 = 1046.5023
E6 = 1318.5102
G6 = 1567.9817
F3 = 174.6141
A3 = 220.0
C3 = 130.8128


def _t(index: int) -> float:
    return index / SAMPLE_RATE


def _envelope(t: float, attack: float, decay: float) -> float:
    if t < attack:
        return t / max(attack, 1e-6)
    return math.exp(-(t - attack) / max(decay, 1e-6))


def _mallet(freq: float, dur: float, amp: float = 1.0, decay: float = 0.28) -> list[float]:
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    partials = ((1.0, 1.0), (2.0, 0.32), (3.0, 0.14), (4.08, 0.08))
    for i in range(length):
        t = _t(i)
        env = _envelope(t, 0.003, decay)
        value = 0.0
        for ratio, gain in partials:
            value += gain * math.sin(2.0 * math.pi * freq * ratio * t)
        out[i] = amp * env * value
    return out


def _bell(freq: float, dur: float, amp: float = 1.0, decay: float = 0.45) -> list[float]:
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    partials = (
        (1.0, 1.0, 1.0),
        (2.01, 0.34, 0.8),
        (3.0, 0.18, 0.62),
        (4.16, 0.12, 0.5),
        (5.43, 0.07, 0.4),
    )
    for i in range(length):
        t = _t(i)
        value = 0.0
        for ratio, gain, factor in partials:
            value += gain * math.sin(2.0 * math.pi * freq * ratio * t) * math.exp(
                -t / max(decay * factor, 1e-6)
            )
        out[i] = amp * value * _envelope(t, 0.004, 0.02 + decay)
    return out


def _woodblock(freq: float, dur: float = 0.08, amp: float = 0.8) -> list[float]:
    rng = random.Random(int(freq))
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    for i in range(length):
        t = _t(i)
        env = _envelope(t, 0.001, 0.026)
        pitch = freq * (1.0 - 0.28 * min(t / dur, 1.0))
        body = math.sin(2.0 * math.pi * pitch * t)
        click = rng.uniform(-1.0, 1.0) * math.exp(-t / 0.004)
        out[i] = amp * env * (body + 0.4 * click)
    return out


def _thud(freq: float, dur: float = 0.35, amp: float = 0.7) -> list[float]:
    rng = random.Random(int(freq * 10))
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    for i in range(length):
        t = _t(i)
        env = _envelope(t, 0.004, 0.16)
        pitch = freq * (1.0 - 0.22 * min(t / dur, 1.0))
        body = math.sin(2.0 * math.pi * pitch * t)
        body += 0.18 * math.sin(2.0 * math.pi * pitch * 2.0 * t)
        click = rng.uniform(-1.0, 1.0) * math.exp(-t / 0.018)
        out[i] = amp * env * (body + 0.28 * click)
    return out


def _whoosh(dur: float = 0.4, amp: float = 0.25, rising: bool = True) -> list[float]:
    rng = random.Random(41 if rising else 42)
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    lowpass = 0.0
    for i in range(length):
        t = _t(i)
        progress = min(t / dur, 1.0)
        cutoff = 0.015 + 0.18 * (progress if rising else 1.0 - progress)
        lowpass += cutoff * (rng.uniform(-1.0, 1.0) - lowpass)
        env = math.sin(math.pi * progress) ** 1.5
        out[i] = amp * env * lowpass
    return out


def _mix(length: float, events: list[tuple[float, list[float]]]) -> list[float]:
    total = int(length * SAMPLE_RATE)
    out = [0.0] * total
    for start, samples in events:
        offset = int(start * SAMPLE_RATE)
        for i, sample in enumerate(samples):
            j = offset + i
            if 0 <= j < total:
                out[j] += sample
    return out


def _room_tail(samples: list[float], amount: float = 0.09) -> list[float]:
    """A tiny shared early-reflection bed, not a long reverb."""
    if amount <= 0:
        return samples
    out = samples[:]
    for delay_ms, gain in ((17.0, 0.55), (29.0, 0.35), (43.0, 0.22)):
        delay = int(SAMPLE_RATE * delay_ms / 1000.0)
        for i in range(delay, len(out)):
            out[i] += samples[i - delay] * gain * amount
    return out


def _normalize(samples: list[float], peak: float = 0.82) -> list[float]:
    high = max((abs(sample) for sample in samples), default=0.0)
    if high == 0:
        return samples
    scale = peak / high
    return [sample * scale for sample in samples]


def _fade(samples: list[float], fade_in: float = 0.002, fade_out: float = 0.02) -> list[float]:
    out = samples[:]
    in_count = min(len(out), int(fade_in * SAMPLE_RATE))
    out_count = min(len(out), int(fade_out * SAMPLE_RATE))
    for i in range(in_count):
        out[i] *= i / max(in_count, 1)
    for i in range(out_count):
        out[-1 - i] *= i / max(out_count, 1)
    return out


def _write(name: str, samples: list[float], room: float = 0.09) -> None:
    samples = _fade(_normalize(_room_tail(samples, room)))
    path = OUT_DIR / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SAMPLE_RATE)
        file.writeframes(
            b"".join(
                struct.pack("<h", max(-32768, min(32767, int(sample * 32767))))
                for sample in samples
            )
        )


def build_sounds() -> dict[str, tuple[list[float], float]]:
    sounds: dict[str, tuple[list[float], float]] = {}

    sounds["ui_tap_primary.wav"] = (_woodblock(760.0), 0.03)
    sounds["ui_tap_secondary.wav"] = (_woodblock(540.0, amp=0.62), 0.02)
    sounds["ui_select.wav"] = (_woodblock(930.0, dur=0.05, amp=0.5), 0.01)
    sounds["ui_navigate.wav"] = (
        _mix(0.13, [(0.0, _woodblock(680.0, dur=0.05, amp=0.35)), (0.035, _whoosh(0.09, 0.12))]),
        0.02,
    )
    sounds["ui_locked.wav"] = (_thud(165.0, dur=0.22, amp=0.55), 0.02)
    sounds["ui_page.wav"] = (_whoosh(0.26, 0.2), 0.02)
    sounds["ui_toggle_on.wav"] = (
        _mix(0.12, [(0.0, _woodblock(620.0, dur=0.05, amp=0.4)), (0.045, _woodblock(880.0, dur=0.05, amp=0.35))]),
        0.02,
    )
    sounds["ui_toggle_off.wav"] = (
        _mix(0.12, [(0.0, _woodblock(880.0, dur=0.05, amp=0.35)), (0.045, _woodblock(620.0, dur=0.05, amp=0.4))]),
        0.02,
    )
    sounds["tuner_on.wav"] = (
        _mix(0.15, [(0.0, _woodblock(560.0, amp=0.5)), (0.04, _mallet(G5, 0.18, 0.22, 0.1))]),
        0.02,
    )
    sounds["tuner_off.wav"] = (
        _mix(0.15, [(0.0, _woodblock(700.0, amp=0.4)), (0.04, _mallet(C5, 0.18, 0.18, 0.1))]),
        0.02,
    )
    sounds["copy_success.wav"] = (
        _mix(0.42, [(0.0, _bell(G5, 0.4, 0.25)), (0.1, _bell(C6, 0.35, 0.2))]),
        0.07,
    )
    sounds["error_soft.wav"] = (_mix(0.24, [(0.0, _thud(210.0, 0.2, 0.4)), (0.04, _woodblock(330.0, amp=0.25))]), 0.02)

    sounds["lesson_start.wav"] = (
        _mix(0.4, [(0.0, _whoosh(0.3, 0.14)), (0.08, _mallet(C5, 0.3, 0.2)), (0.18, _mallet(E5, 0.3, 0.16))]),
        0.05,
    )

    sounds["answer_correct.wav"] = (
        _mix(
            0.55,
            [
                (0.0, _mallet(C5, 0.5, 0.7)),
                (0.0, _bell(C5, 0.4, 0.16)),
                (0.1, _mallet(E5, 0.45, 0.72)),
                (0.1, _bell(E5, 0.35, 0.16)),
            ],
        ),
        0.1,
    )
    sounds["answer_correct_combo.wav"] = (
        _mix(
            0.85,
            [
                (0.0, _mallet(C5, 0.45, 0.65)),
                (0.08, _mallet(E5, 0.45, 0.72)),
                (0.16, _mallet(G5, 0.5, 0.7)),
                (0.24, _bell(C6, 0.45, 0.22)),
                (0.24, _bell(E6, 0.4, 0.12)),
            ],
        ),
        0.12,
    )
    sounds["answer_wrong.wav"] = (
        _mix(
            0.5,
            [
                (0.0, _mallet(A3, 0.35, 0.4, 0.18)),
                (0.1, _mallet(F3, 0.35, 0.34, 0.2)),
                (0.0, _thud(125.0, 0.3, 0.28)),
            ],
        ),
        0.05,
    )
    sounds["answer_octave.wav"] = (
        _mix(
            0.6,
            [
                (0.0, _mallet(C5, 0.3, 0.45, 0.2)),
                (0.14, _mallet(C4, 0.35, 0.4, 0.22)),
                (0.14, _thud(180.0, 0.25, 0.16)),
            ],
        ),
        0.06,
    )
    sounds["life_lost.wav"] = (
        _mix(
            0.4,
            [
                (0.0, _thud(150.0, 0.3, 0.45)),
                (0.12, _thud(105.0, 0.3, 0.32)),
                (0.06, _mallet(F3, 0.3, 0.16)),
            ],
        ),
        0.04,
    )
    sounds["lesson_complete.wav"] = (
        _mix(
            1.45,
            [
                (0.0, _mallet(C5, 0.8, 0.65)),
                (0.12, _mallet(E5, 0.8, 0.7)),
                (0.24, _mallet(G5, 0.8, 0.7)),
                (0.36, _mallet(C6, 1.0, 0.72)),
                (0.36, _bell(C6, 0.9, 0.24)),
                (0.44, _bell(G5, 0.7, 0.15)),
            ],
        ),
        0.16,
    )
    sounds["lesson_perfect.wav"] = (
        _mix(
            1.7,
            [
                (0.0, _mallet(C5, 0.8, 0.62)),
                (0.12, _mallet(E5, 0.8, 0.68)),
                (0.24, _mallet(G5, 0.8, 0.68)),
                (0.36, _mallet(C6, 1.1, 0.72)),
                (0.36, _bell(C6, 1.0, 0.24)),
                (0.5, _bell(E6, 0.8, 0.2)),
                (0.62, _bell(G6, 0.75, 0.18)),
                (0.74, _bell(C6, 0.7, 0.14)),
            ],
        ),
        0.18,
    )
    sounds["lesson_failed.wav"] = (
        _mix(
            1.15,
            [
                (0.0, _mallet(A4, 0.55, 0.38, 0.24)),
                (0.18, _mallet(F4, 0.6, 0.36, 0.26)),
                (0.36, _mallet(D4, 0.75, 0.36, 0.28)),
                (0.36, _thud(110.0, 0.5, 0.18)),
            ],
        ),
        0.1,
    )
    sounds["practice_complete.wav"] = (
        _mix(
            0.7,
            [
                (0.0, _mallet(C5, 0.5, 0.55)),
                (0.14, _mallet(G5, 0.6, 0.58)),
                (0.14, _bell(G5, 0.5, 0.16)),
            ],
        ),
        0.1,
    )
    sounds["reward_streak.wav"] = (
        _mix(
            0.75,
            [
                (0.0, _whoosh(0.45, 0.15)),
                (0.12, _mallet(G4, 0.45, 0.35)),
                (0.28, _mallet(C5, 0.5, 0.38)),
                (0.28, _bell(G5, 0.45, 0.12)),
            ],
        ),
        0.08,
    )
    sounds["reward_streak_milestone.wav"] = (
        _mix(
            1.25,
            [
                (0.0, _whoosh(0.55, 0.2)),
                (0.12, _mallet(C5, 0.45, 0.4)),
                (0.24, _mallet(E5, 0.45, 0.45)),
                (0.36, _mallet(G5, 0.5, 0.45)),
                (0.48, _mallet(C6, 0.7, 0.48)),
                (0.58, _bell(E6, 0.5, 0.15)),
            ],
        ),
        0.14,
    )
    sounds["reward_daily_goal.wav"] = (
        _mix(
            0.85,
            [
                (0.0, _bell(E5, 0.6, 0.3)),
                (0.12, _bell(G5, 0.6, 0.28)),
                (0.24, _bell(C6, 0.6, 0.3)),
                (0.36, _bell(E6, 0.45, 0.18)),
            ],
        ),
        0.12,
    )
    sounds["reward_level_up.wav"] = (
        _mix(
            1.0,
            [
                (0.0, _bell(C5, 0.5, 0.28)),
                (0.11, _bell(E5, 0.5, 0.28)),
                (0.22, _bell(G5, 0.5, 0.3)),
                (0.33, _bell(C6, 0.7, 0.34)),
                (0.33, _mallet(C5, 0.7, 0.28)),
            ],
        ),
        0.13,
    )
    sounds["reward_unlock.wav"] = (
        _mix(
            0.7,
            [
                (0.0, _bell(G5, 0.55, 0.28)),
                (0.12, _bell(C6, 0.6, 0.32)),
                (0.24, _bell(G6, 0.5, 0.16)),
            ],
        ),
        0.11,
    )
    sounds["xp_tick.wav"] = (_bell(C6, 0.14, 0.3), 0.03)
    return sounds


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sounds = build_sounds()
    for name, (samples, room) in sounds.items():
        _write(name, samples, room=room)
    print(f"wrote {len(sounds)} sounds to {OUT_DIR}")


if __name__ == "__main__":
    main()
