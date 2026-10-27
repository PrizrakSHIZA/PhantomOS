#!/usr/bin/env python3
"""Generate the PhantomOS night wallpaper using only Python's standard library."""

from __future__ import annotations

import math
import random
import struct
import zlib
from pathlib import Path

WIDTH = 1920
HEIGHT = 1080
OUTPUT = Path(__file__).with_name("phantomos-night.png")


def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def render() -> None:
    rng = random.Random(17)
    stars: dict[tuple[int, int], int] = {}
    for _ in range(180):
        x = rng.randrange(WIDTH)
        y = rng.randrange(HEIGHT)
        stars[(x, y)] = rng.choice((18, 25, 35, 48))

    output = bytearray()
    for y in range(HEIGHT):
        v = y / HEIGHT
        row = bytearray([0])
        for x in range(WIDTH):
            u = x / WIDTH

            # Deep navy base with broad Tokyo Night blue and violet light.
            blue_haze = math.exp(-(((u - 0.24) / 0.47) ** 2 + ((v - 0.44) / 0.68) ** 2) * 1.35)
            violet_haze = math.exp(-(((u - 0.78) / 0.38) ** 2 + ((v - 0.52) / 0.56) ** 2) * 1.45)
            cyan_haze = math.exp(-(((u - 0.52) / 0.48) ** 2 + ((v - 0.15) / 0.37) ** 2) * 2.4)
            vignette = max(0.35, 1.0 - 0.34 * math.hypot((u - 0.5) / 0.75, (v - 0.52) / 0.78))

            red = (10 + 23 * blue_haze + 33 * violet_haze + 3 * cyan_haze) * vignette
            green = (13 + 31 * blue_haze + 12 * violet_haze + 18 * cyan_haze) * vignette
            blue = (29 + 76 * blue_haze + 80 * violet_haze + 42 * cyan_haze) * vignette

            # A luminous elliptical ring gives the wallpaper a quiet focal point.
            dx = (u - 0.73) / 0.24
            dy = (v - 0.43) / 0.39
            radius = math.sqrt(dx * dx + dy * dy)
            ring = math.exp(-((radius - 1.0) / 0.022) ** 2)
            ring_inner = math.exp(-((radius - 0.91) / 0.009) ** 2)
            red += 23 * ring + 26 * ring_inner
            green += 48 * ring + 55 * ring_inner
            blue += 112 * ring + 138 * ring_inner

            # Two soft, broken aurora ribbons sweep across the lower half.
            wave_a = 0.70 + 0.085 * math.sin(u * 7.0 + 0.35) + 0.035 * math.sin(u * 15.0)
            wave_b = 0.82 + 0.055 * math.sin(u * 5.4 + 2.2)
            glow_a = math.exp(-((v - wave_a) / 0.009) ** 2) * (0.52 + 0.48 * math.sin(u * 11.0 + 1.4) ** 2)
            glow_b = math.exp(-((v - wave_b) / 0.006) ** 2) * (0.40 + 0.60 * math.sin(u * 8.0) ** 2)
            red += 18 * glow_a + 25 * glow_b
            green += 55 * glow_a + 21 * glow_b
            blue += 112 * glow_a + 82 * glow_b

            # Fine diagonal light traces and a restrained field of distant stars.
            trace = (u * 5.2 + v * 2.1) % 1.0
            trace_glow = math.exp(-((trace - 0.08) / 0.0035) ** 2) * 0.10
            red += 14 * trace_glow
            green += 28 * trace_glow
            blue += 67 * trace_glow
            star = stars.get((x, y), 0)
            red += star * 0.36
            green += star * 0.52
            blue += star

            row.extend((clamp(red), clamp(green), clamp(blue)))
        output.extend(row)

    header = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0)
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(png_chunk(b"IHDR", header))
    png.extend(png_chunk(b"sRGB", b"\x00"))
    png.extend(png_chunk(b"IDAT", zlib.compress(bytes(output), level=7)))
    png.extend(png_chunk(b"IEND", b""))
    OUTPUT.write_bytes(png)
    print(f"Created {OUTPUT} ({OUTPUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    render()