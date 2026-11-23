"""Generuje ikonę aplikacji (turkusowe tło, mosiężna moneta z literą N) do folderów mipmap.

Uruchamiane w CI po `flutter create`, z katalogu napiwnik/. Wymaga Pillow.
"""
import os
import shutil

from PIL import Image, ImageDraw

TEAL = (31, 111, 120)
BRASS = (184, 134, 43)
LIGHT = (240, 214, 150)
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def draw(size=512):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.22), fill=TEAL)
    c = size / 2
    r = size * 0.30
    d.ellipse([c - r, c - r, c + r, c + r], fill=BRASS)
    r2 = size * 0.235
    d.ellipse([c - r2, c - r2, c + r2, c + r2], outline=LIGHT, width=int(size * 0.025))
    # Litera N narysowana liniami.
    x0, x1 = c - size * 0.08, c + size * 0.08
    y0, y1 = c - size * 0.11, c + size * 0.11
    d.line([(x0, y1), (x0, y0), (x1, y1), (x1, y0)], fill=LIGHT, width=int(size * 0.045), joint="curve")
    return img


def main():
    base = draw()
    res = os.path.join("android", "app", "src", "main", "res")
    # Bez ikony adaptacyjnej Android używa zwykłych PNG na wszystkich wersjach.
    shutil.rmtree(os.path.join(res, "mipmap-anydpi-v26"), ignore_errors=True)
    for name, px in SIZES.items():
        folder = os.path.join(res, f"mipmap-{name}")
        os.makedirs(folder, exist_ok=True)
        base.resize((px, px), Image.LANCZOS).save(os.path.join(folder, "ic_launcher.png"))
    print("Ikona wygenerowana")


if __name__ == "__main__":
    main()
