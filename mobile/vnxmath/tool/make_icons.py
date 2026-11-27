"""Рисует значки vnxMATH и картинки для Google Play.

Знак — квадрат 2×2 со знаками + − × ÷ (как LogoMark в приложении):
мятный и синий на тёмно-синем фоне.

Запуск из apps/vnxmath:  python tool/make_icons.py
Нужен Pillow. Шрифт берётся из assets/fonts/Manrope.ttf.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
STORE = ROOT / "store"
FONT = ROOT / "assets/fonts/Manrope.ttf"

NAVY_TOP = (11, 24, 54)
NAVY_BOTTOM = (4, 10, 26)
MINT = (59, 224, 140)
TEAL = (25, 182, 166)
BLUE = (91, 140, 255)
TEXT = (234, 241, 255)
DIM = (141, 155, 192)


def font(size, weight=800):
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([weight])
    except OSError:
        pass
    return f


def vgradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h), top)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img


def glow(img, center, radius, color, alpha):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = center
    d.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color + (alpha,))
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.45))
    img.alpha_composite(layer)


def logo(size, monochrome=False):
    """Знак 2×2 на прозрачном фоне, size×size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gap = size * 0.12
    tile = (size - gap) / 2
    r = tile * 0.32
    cells = [("+", MINT, True), ("−", BLUE, False), ("×", BLUE, False), ("÷", MINT, False)]
    f = font(round(tile * 0.62))
    for i, (sign, color, filled) in enumerate(cells):
        x = (i % 2) * (tile + gap)
        y = (i // 2) * (tile + gap)
        box = (x, y, x + tile, y + tile)
        if monochrome:
            fill = (255, 255, 255, 255) if filled else None
            d.rounded_rectangle(box, r, fill=fill, outline=(255, 255, 255, 255), width=max(2, round(size * 0.02)))
            sign_color = (0, 0, 0, 0) if filled else (255, 255, 255, 255)
        else:
            fill = color + (255,) if filled else color + (40,)
            d.rounded_rectangle(box, r, fill=fill, outline=color + (220,), width=max(2, round(size * 0.016)))
            sign_color = NAVY_BOTTOM + (255,) if filled else color + (255,)
        cx, cy = x + tile / 2, y + tile / 2
        d.text((cx, cy), sign, font=f, fill=sign_color, anchor="mm")
    return img


def background(size):
    bg = vgradient(size, size, NAVY_TOP, NAVY_BOTTOM).convert("RGBA")
    glow(bg, (size * 0.25, size * 0.2), size * 0.45, MINT, 70)
    glow(bg, (size * 0.85, size * 0.8), size * 0.45, BLUE, 60)
    return bg


def adaptive():
    # Передний план 108dp; безопасная зона — круг 66dp. Знак занимает 42%
    # холста: его углы (≈29.7% от центра) лежат внутри зоны (30.5%),
    # а скругление плиток даёт ещё запас.
    dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, k in dens.items():
        side = round(108 * k)
        for mono in (False, True):
            canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            mark = logo(round(side * 0.42), monochrome=mono)
            off = (side - mark.width) // 2
            canvas.alpha_composite(mark, (off, off))
            out = RES / f"drawable-{name}"
            out.mkdir(parents=True, exist_ok=True)
            suffix = "_monochrome" if mono else ""
            canvas.save(out / f"ic_launcher_foreground{suffix}.png")
        # Старые лаунчеры: квадрат со скруглением.
        legacy = round(48 * k)
        icon = background(legacy)
        mark = logo(round(legacy * 0.62))
        off = (legacy - mark.width) // 2
        icon.alpha_composite(mark, (off, off))
        mask = Image.new("L", (legacy, legacy), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, legacy - 1, legacy - 1), legacy * 0.22, fill=255)
        rounded = Image.new("RGBA", (legacy, legacy), (0, 0, 0, 0))
        rounded.paste(icon, (0, 0), mask)
        (RES / f"mipmap-{name}").mkdir(parents=True, exist_ok=True)
        rounded.save(RES / f"mipmap-{name}/ic_launcher.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_foreground_monochrome" />\n'
        '</adaptive-icon>\n',
        encoding="utf-8",
    )


def store():
    STORE.mkdir(exist_ok=True)
    # Значок для страницы приложения: 512×512, без прозрачности, Play сам
    # скругляет углы.
    icon = background(512)
    mark = logo(300)
    icon.alpha_composite(mark, (106, 106))
    icon.convert("RGB").save(STORE / "icon-512.png")

    # Обложка 1024×500.
    w, h = 1024, 500
    fg = vgradient(w, h, NAVY_TOP, NAVY_BOTTOM).convert("RGBA")
    glow(fg, (180, 90), 300, MINT, 70)
    glow(fg, (900, 420), 320, BLUE, 60)
    mark = logo(220)
    fg.alpha_composite(mark, (110, (h - 220) // 2))
    d = ImageDraw.Draw(fg)
    x = 390
    d.text((x, 200), "vnx", font=font(96, 500), fill=DIM, anchor="ls")
    vnx_w = d.textlength("vnx", font=font(96, 500))
    d.text((x + vnx_w, 200), "MATH", font=font(96, 800), fill=MINT, anchor="ls")
    d.text((x, 270), "Математические загадки", font=font(40, 700), fill=TEXT, anchor="ls")
    d.text((x, 325), "60 уровней · без рекламы · без интернета", font=font(26, 600), fill=DIM, anchor="ls")
    fg.convert("RGB").save(STORE / "feature-1024x500.png")


if __name__ == "__main__":
    adaptive()
    store()
    print("готово")
