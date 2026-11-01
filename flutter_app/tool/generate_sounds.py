#!/usr/bin/env python3
"""Generate the Bright Pluck sound family used by the app.

The family is bright, short, and percussive: a plucked synth body, glass-bell
sparkle, a muted low thud for errors, and a small shared room tail. It stays
original while matching the upbeat feel of a modern language-learning app.

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
F5 = 698.4565
G5 = 783.9909
A5 = 880.0
B5 = 987.7666
C6 = 1046.5023
D6 = 1174.6591
E6 = 1318.5102
G6 = 1567.9817

F3 = 174.6141
G3 = 195.9977
A3 = 220.0
C3 = 130.8128
D3 = 146.8324


def _t(index: int) -> float:
    return index / SAMPLE_RATE


def _attack(t: float, attack: float) -> float:
    return min(1.0, t / max(attack, 1e-6))


def _pluck(
    freq: float,
    dur: float,
    amp: float = 1.0,
    decay: float = 0.22,
    bright: float = 0.9,
) -> list[float]:
    """A short plucked synth: fundamental, bright harmonics, tiny pitch drop."""
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    rng = random.Random(int(freq * 7))
    for i in range(length):
        t = _t(i)
        env = _attack(t, 0.002) * math.exp(-t / max(decay, 1e-6))
        drop = 1.0 + 0.03 * math.exp(-t / 0.025)
        phase = 2.0 * math.pi * freq * drop * t
        value = (
            math.sin(phase)
            + 0.44 * bright * math.sin(phase * 2.0)
            + 0.22 * bright * math.sin(phase * 3.0)
            + 0.10 * bright * math.sin(phase * 4.01)
        )
        click = rng.uniform(-1.0, 1.0) * math.exp(-t / 0.004) * 0.18
        out[i] = amp * env * (value + click)
    return out


def _bell(
    freq: float,
    dur: float,
    amp: float = 1.0,
    decay: float = 0.5,
) -> list[float]:
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    partials = (
        (1.0, 1.0, 1.0),
        (2.01, 0.36, 0.8),
        (3.0, 0.18, 0.62),
        (4.17, 0.10, 0.5),
        (5.43, 0.06, 0.4),
    )
    for i in range(length):
        t = _t(i)
        value = 0.0
        for ratio, gain, factor in partials:
            value += gain * math.sin(2.0 * math.pi * freq * ratio * t) * math.exp(
                -t / max(decay * factor, 1e-6)
            )
        out[i] = amp * value * _attack(t, 0.003)
    return out


def _blip(freq: float, dur: float = 0.06, amp: float = 0.7) -> list[float]:
    return _pluck(freq, dur, amp=amp, decay=0.035, bright=0.5)


def _thud(freq: float, dur: float = 0.3, amp: float = 0.7) -> list[float]:
    rng = random.Random(int(freq * 11))
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    for i in range(length):
        t = _t(i)
        env = _attack(t, 0.003) * math.exp(-t / 0.13)
        pitch = freq * (1.0 - 0.25 * min(t / dur, 1.0))
        body = math.sin(2.0 * math.pi * pitch * t)
        body += 0.22 * math.sin(2.0 * math.pi * pitch * 2.0 * t)
        click = rng.uniform(-1.0, 1.0) * math.exp(-t / 0.016)
        out[i] = amp * env * (body + 0.3 * click)
    return out


def _whoosh(dur: float = 0.35, amp: float = 0.2, rising: bool = True) -> list[float]:
    rng = random.Random(73 if rising else 74)
    length = int(dur * SAMPLE_RATE)
    out = [0.0] * length
    lowpass = 0.0
    for i in range(length):
        t = _t(i)
        progress = min(t / dur, 1.0)
        cutoff = 0.02 + 0.22 * (progress if rising else 1.0 - progress)
        lowpass += cutoff * (rng.uniform(-1.0, 1.0) - lowpass)
        env = math.sin(math.pi * progress) ** 1.4
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


def _room_tail(samples: list[float], amount: float = 0.08) -> list[float]:
    if amount <= 0:
        return samples
    out = samples[:]
    for delay_ms, gain in ((13.0, 0.5), (23.0, 0.32), (37.0, 0.2)):
        delay = int(SAMPLE_RATE * delay_ms / 1000.0)
        for i in range(delay, len(out)):
            out[i] += samples[i - delay] * gain * amount
    return out


def _normalize(samples: list[float], peak: float = 0.86) -> list[float]:
    high = max((abs(sample) for sample in samples), default=0.0)
    if high == 0:
        return samples
    scale = peak / high
    return [sample * scale for sample in samples]


def _fade(
    samples: list[float],
    fade_in: float = 0.0015,
    fade_out: float = 0.02,
) -> list[float]:
    out = samples[:]
    in_count = min(len(out), int(fade_in * SAMPLE_RATE))
    out_count = min(len(out), int(fade_out * SAMPLE_RATE))
    for i in range(in_count):
        out[i] *= i / max(in_count, 1)
    for i in range(out_count):
        out[-1 - i] *= i / max(out_count, 1)
    return out


def _write(name: str, samples: list[float], room: float = 0.08) -> None:
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

    sounds["ui_tap_primary.wav"] = (_blip(880.0, 0.06, 0.7), 0.02)
    sounds["ui_tap_secondary.wav"] = (_blip(660.0, 0.055, 0.55), 0.02)
    sounds["ui_select.wav"] = (_blip(1040.0, 0.05, 0.45), 0.01)
    sounds["ui_navigate.wav"] = (
        _mix(
            0.12,
            [(0.0, _blip(760.0, 0.05, 0.4)), (0.035, _whoosh(0.08, 0.1))],
        ),
        0.02,
    )
    sounds["ui_locked.wav"] = (_thud(150.0, 0.2, 0.5), 0.02)
    sounds["ui_page.wav"] = (_whoosh(0.24, 0.18), 0.02)
    sounds["ui_toggle_on.wav"] = (
        _mix(
            0.12,
            [(0.0, _blip(700.0, 0.05, 0.45)), (0.045, _blip(1050.0, 0.05, 0.4))],
        ),
        0.02,
    )
    sounds["ui_toggle_off.wav"] = (
        _mix(
            0.12,
            [(0.0, _blip(1050.0, 0.05, 0.4)), (0.045, _blip(700.0, 0.05, 0.45))],
        ),
        0.02,
    )
    sounds["tuner_on.wav"] = (
        _mix(
            0.14,
            [(0.0, _blip(620.0, 0.05, 0.5)), (0.04, _pluck(G5, 0.16, 0.2, 0.08))],
        ),
        0.02,
    )
    sounds["tuner_off.wav"] = (
        _mix(
            0.14,
            [(0.0, _blip(760.0, 0.05, 0.45)), (0.04, _pluck(D5, 0.16, 0.18, 0.08))],
        ),
        0.02,
    )
    sounds["copy_success.wav"] = (
        _mix(0.4, [(0.0, _bell(G5, 0.38, 0.24)), (0.09, _bell(C6, 0.34, 0.2))]),
        0.06,
    )
    sounds["error_soft.wav"] = (
        _mix(
            0.24,
            [(0.0, _thud(200.0, 0.2, 0.38)), (0.04, _blip(330.0, 0.06, 0.22))],
        ),
        0.02,
    )

    sounds["lesson_start.wav"] = (
        _mix(
            0.38,
            [
                (0.0, _whoosh(0.28, 0.12)),
                (0.07, _pluck(C5, 0.26, 0.22, 0.12)),
                (0.17, _pluck(E5, 0.28, 0.2, 0.12)),
            ],
        ),
        0.04,
    )

    sounds["answer_correct.wav"] = (
        _mix(
            0.52,
            [
                (0.0, _pluck(C5, 0.42, 0.7, 0.2)),
                (0.0, _bell(C5, 0.36, 0.14)),
                (0.085, _pluck(E5, 0.4, 0.72, 0.2)),
                (0.085, _bell(E5, 0.32, 0.14)),
            ],
        ),
        0.08,
    )
    sounds["answer_correct_combo.wav"] = (
        _mix(
            0.82,
            [
                (0.0, _pluck(C5, 0.4, 0.62, 0.18)),
                (0.075, _pluck(E5, 0.4, 0.68, 0.18)),
                (0.15, _pluck(G5, 0.42, 0.7, 0.2)),
                (0.225, _pluck(C6, 0.42, 0.72, 0.22)),
                (0.225, _bell(E6, 0.36, 0.16)),
            ],
        ),
        0.1,
    )
    sounds["answer_wrong.wav"] = (
        _mix(
            0.48,
            [
                (0.0, _pluck(A4, 0.3, 0.4, 0.16)),
                (0.09, _pluck(F4, 0.32, 0.36, 0.18)),
                (0.0, _thud(140.0, 0.26, 0.24)),
            ],
        ),
        0.04,
    )
    sounds["answer_octave.wav"] = (
        _mix(
            0.58,
            [
                (0.0, _pluck(C5, 0.26, 0.44, 0.16)),
                (0.13, _pluck(C4, 0.32, 0.4, 0.18)),
                (0.13, _thud(175.0, 0.22, 0.14)),
            ],
        ),
        0.05,
    )
    sounds["life_lost.wav"] = (
        _mix(
            0.38,
            [
                (0.0, _thud(155.0, 0.26, 0.42)),
                (0.11, _thud(105.0, 0.26, 0.3)),
                (0.05, _pluck(F4, 0.26, 0.15, 0.14)),
            ],
        ),
        0.03,
    )
    sounds["lesson_complete.wav"] = (
        _mix(
            1.3,
            [
                (0.0, _pluck(C5, 0.7, 0.62, 0.24)),
                (0.1, _pluck(E5, 0.7, 0.66, 0.24)),
                (0.2, _pluck(G5, 0.72, 0.68, 0.26)),
                (0.3, _pluck(C6, 0.9, 0.72, 0.3)),
                (0.3, _bell(C6, 0.8, 0.22)),
                (0.38, _bell(G5, 0.65, 0.14)),
            ],
        ),
        0.14,
    )
    sounds["lesson_perfect.wav"] = (
        _mix(
            1.55,
            [
                (0.0, _pluck(C5, 0.7, 0.6, 0.22)),
                (0.1, _pluck(E5, 0.7, 0.64, 0.22)),
                (0.2, _pluck(G5, 0.72, 0.66, 0.24)),
                (0.3, _pluck(C6, 0.95, 0.72, 0.3)),
                (0.3, _bell(C6, 0.9, 0.22)),
                (0.44, _bell(E6, 0.7, 0.18)),
                (0.55, _bell(G6, 0.65, 0.16)),
                (0.66, _bell(C6, 0.6, 0.12)),
            ],
        ),
        0.16,
    )
    sounds["lesson_failed.wav"] = (
        _mix(
            1.05,
            [
                (0.0, _pluck(A4, 0.5, 0.36, 0.2)),
                (0.16, _pluck(F4, 0.55, 0.34, 0.22)),
                (0.32, _pluck(D4, 0.7, 0.34, 0.26)),
                (0.32, _thud(110.0, 0.45, 0.16)),
            ],
        ),
        0.08,
    )
    sounds["practice_complete.wav"] = (
        _mix(
            0.66,
            [
                (0.0, _pluck(C5, 0.46, 0.52, 0.18)),
                (0.12, _pluck(G5, 0.52, 0.56, 0.2)),
                (0.12, _bell(G5, 0.46, 0.14)),
            ],
        ),
        0.08,
    )
    sounds["reward_streak.wav"] = (
        _mix(
            0.7,
            [
                (0.0, _whoosh(0.4, 0.12)),
                (0.1, _pluck(G4, 0.4, 0.34, 0.15)),
                (0.24, _pluck(C5, 0.44, 0.38, 0.18)),
                (0.24, _bell(G5, 0.4, 0.1)),
            ],
        ),
        0.07,
    )
    sounds["reward_streak_milestone.wav"] = (
        _mix(
            1.2,
            [
                (0.0, _whoosh(0.5, 0.16)),
                (0.1, _pluck(C5, 0.4, 0.38, 0.16)),
                (0.21, _pluck(E5, 0.4, 0.42, 0.16)),
                (0.32, _pluck(G5, 0.45, 0.44, 0.18)),
                (0.43, _pluck(C6, 0.6, 0.48, 0.22)),
                (0.52, _bell(E6, 0.45, 0.14)),
            ],
        ),
        0.12,
    )
    sounds["reward_daily_goal.wav"] = (
        _mix(
            0.8,
            [
                (0.0, _bell(E5, 0.55, 0.28)),
                (0.1, _bell(G5, 0.55, 0.26)),
                (0.2, _bell(C6, 0.55, 0.28)),
                (0.32, _bell(E6, 0.4, 0.16)),
            ],
        ),
        0.1,
    )
    sounds["reward_level_up.wav"] = (
        _mix(
            0.95,
            [
                (0.0, _bell(C5, 0.45, 0.26)),
                (0.09, _bell(E5, 0.45, 0.26)),
                (0.18, _bell(G5, 0.45, 0.28)),
                (0.27, _bell(C6, 0.62, 0.32)),
                (0.27, _pluck(C5, 0.6, 0.26, 0.2)),
            ],
        ),
        0.11,
    )
    sounds["reward_unlock.wav"] = (
        _mix(
            0.66,
            [
                (0.0, _bell(G5, 0.5, 0.26)),
                (0.1, _bell(C6, 0.55, 0.3)),
                (0.2, _bell(G6, 0.45, 0.14)),
            ],
        ),
        0.09,
    )
    sounds["xp_tick.wav"] = (_bell(C6, 0.12, 0.28), 0.02)
    return sounds


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sounds = build_sounds()
    for name, (samples, room) in sounds.items():
        _write(name, samples, room=room)
    print(f"wrote {len(sounds)} sounds to {OUT_DIR}")


if __name__ == "__main__":
    main()
