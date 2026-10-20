#!/usr/bin/env python3
"""Prepare the Blood Moon backdrop and app icons from the supplied image.

`blood-moon-upscaled.png` is a 4x super-resolution of the exact source photo
used for the moon-only app icon. `blood-moon-superres-8x.webp` is a second
super-resolution pass of that same photo for the 4K background. No moon is
generated or composited. Requires Pillow and NumPy.
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
UPSCALED = ROOT / "resources" / "blood-moon-upscaled.png"
BACKDROP_SOURCE = ROOT / "resources" / "blood-moon-superres-8x.webp"
BACKDROP = ROOT / "resources" / "blood-moon-background.png"
ICON_CUTOUT = ROOT / "resources" / "blood-moon-cutout.png"
ICON_SIDE = 360
ICON_RADIUS = 156
MASK_SUPERSAMPLE = 4


def cutout() -> Image.Image:
    source = Image.open(UPSCALED).convert("RGB")
    cx, cy = source.width * 0.494, source.height * 0.484
    left = round(cx - ICON_SIDE / 2)
    top = round(cy - ICON_SIDE / 2)
    moon = source.crop((left, top, left + ICON_SIDE, top + ICON_SIDE)).convert("RGBA")
    moon = moon.filter(ImageFilter.UnsharpMask(radius=0.9, percent=120, threshold=3))

    # Feather only the edge; every pixel inside it comes from the user's photo.
    size = ICON_SIDE * MASK_SUPERSAMPLE
    coords = (np.arange(size, dtype=np.float32) + 0.5) / MASK_SUPERSAMPLE
    x, y = np.meshgrid(coords - (cx - left), coords - (cy - top))
    radius = np.sqrt(x * x + y * y)
    t = np.clip((radius - (ICON_RADIUS - 2.4)) / 2.4, 0.0, 1.0)
    t = t * t * (3.0 - 2.0 * t)
    alpha = Image.fromarray(((1.0 - t) * 255.0).astype(np.uint8), "L")
    alpha = alpha.resize((ICON_SIDE, ICON_SIDE), Image.Resampling.LANCZOS)
    moon.putalpha(alpha)
    return moon


def main() -> None:
    if not UPSCALED.is_file():
        raise SystemExit(f"Missing 4x source photo: {UPSCALED}")
    if not BACKDROP_SOURCE.is_file():
        raise SystemExit(f"Missing high-resolution source photo: {BACKDROP_SOURCE}")

    source = Image.open(BACKDROP_SOURCE).convert("RGB")
    backdrop = ImageOps.fit(source, (3840, 2160), Image.Resampling.LANCZOS,
                            centering=(0.5, 0.5))
    # Downsample the same upscaled photograph gently; keep the real moon edge
    # clear without adding a synthetic glow or changing its surface.
    backdrop = backdrop.filter(ImageFilter.UnsharpMask(radius=0.9, percent=72, threshold=3))
    backdrop.save(BACKDROP, optimize=True)

    moon = cutout()
    moon.save(ICON_CUTOUT, optimize=True)
    icon_art = moon.resize((1024, 1024), Image.Resampling.LANCZOS)
    icon_art.save(ROOT / "packaging" / "icons" / "swiftify.icon" / "Assets" / "blood-moon.png",
                  optimize=True)
    # Keep the area around the disk transparent, including in the Windows ICO.
    icon = icon_art

    targets = [(ROOT / "resources" / "swiftify-icon.png", 1024)]
    targets.extend((ROOT / "packaging" / "icons" / f"swiftify-{size}.png", size)
                   for size in (32, 48, 64, 128, 256, 512))
    for target, size in targets:
        target.parent.mkdir(parents=True, exist_ok=True)
        icon.resize((size, size), Image.Resampling.LANCZOS).save(target, optimize=True)

    icon.save(ROOT / "packaging" / "icons" / "swiftify.ico", format="ICO",
              sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64),
                     (128, 128), (256, 256)])
    print(f"Prepared the 4K backdrop from {BACKDROP_SOURCE} and refreshed {len(targets)} icons from {UPSCALED}.")


if __name__ == "__main__":
    main()
