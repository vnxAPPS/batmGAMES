"""Рисует значки vnxLIGHT и картинки для Google Play.

Знак — луч света над светящейся кромкой лампы (как на экране приложения):
мятный и белый на тёмно-синем.

Запуск из mobile/vnxlight:  python tool/make_icons.py   (нужен Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
STORE = ROOT / "store"
FONT_BOLD = "/usr/share/fonts/opentype/inter/Inter-Bold.otf"
FONT_MED = "/usr/share/fonts/opentype/inter/Inter-Medium.otf"

NAVY_TOP = (11, 24, 54)
NAVY_BOTTOM = (2, 6, 15)
MINT = (59, 224, 140)
MINT_LIGHT = (154, 247, 203)
TEXT = (234, 241, 255)
DIM = (141, 155, 192)


def vgradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h), top)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img.convert("RGBA")


def mark(size, monochrome=False):
    """Луч и кромка на прозрачном фоне, size×size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    edge_y = size * 0.70
    half = size * 0.24
    top_half = size * 0.48
    # Луч: вертикальный градиент, собранный из полос, затем мягкая маска.
    beam = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beam)
    steps = 60
    for k in range(steps):
        t0 = k / steps
        t1 = (k + 1) / steps
        y0 = edge_y - t0 * edge_y * 0.92
        y1 = edge_y - t1 * edge_y * 0.92
        w0 = half + (top_half - half) * t0
        w1 = half + (top_half - half) * t1
        if monochrome:
            col = (255, 255, 255, int(255 * (1 - t0) ** 1.4))
        else:
            mix = t0
            rgb = tuple(int(255 * (1 - mix) + MINT_LIGHT[i] * mix) for i in range(3))
            col = rgb + (int(255 * (1 - t0) ** 1.5),)
        c = size / 2
        bd.polygon([(c - w0, y0), (c + w0, y0), (c + w1, y1), (c - w1, y1)], fill=col)
    beam = beam.filter(ImageFilter.GaussianBlur(size * 0.012))
    img.alpha_composite(beam)
    d = ImageDraw.Draw(img)
    # Кромка лампы.
    lw = max(2, round(size * 0.035))
    color = (255, 255, 255, 255) if monochrome else MINT + (255,)
    d.rounded_rectangle(
        (size / 2 - half, edge_y - lw / 2, size / 2 + half, edge_y + lw / 2),
        lw / 2,
        fill=color,
    )
    return img


def background(size):
    bg = vgradient(size, size, NAVY_TOP, NAVY_BOTTOM)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        (size * 0.15, size * 0.05, size * 0.85, size * 0.75), fill=MINT + (55,)
    )
    bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(size * 0.12)))
    return bg


def adaptive():
    dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, k in dens.items():
        side = round(108 * k)
        for mono in (False, True):
            canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            m = mark(round(side * 0.56), monochrome=mono)
            off = (side - m.width) // 2
            canvas.alpha_composite(m, (off, off))
            out = RES / f"drawable-{name}"
            out.mkdir(parents=True, exist_ok=True)
            canvas.save(out / f"ic_launcher_foreground{'_monochrome' if mono else ''}.png")
        legacy = round(48 * k)
        icon = background(legacy)
        m = mark(round(legacy * 0.86))
        icon.alpha_composite(m, ((legacy - m.width) // 2, (legacy - m.height) // 2))
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
    icon = background(512)
    m = mark(440)
    icon.alpha_composite(m, (36, 36))
    icon.convert("RGB").save(STORE / "icon-512.png")

    w, h = 1024, 500
    fg = vgradient(w, h, NAVY_TOP, NAVY_BOTTOM)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((40, -80, 440, 400), fill=MINT + (60,))
    fg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(70)))
    m = mark(380)
    fg.alpha_composite(m, (60, 40))
    d = ImageDraw.Draw(fg)
    x = 470
    fm = ImageFont.truetype(FONT_MED, 92)
    fb = ImageFont.truetype(FONT_BOLD, 92)
    d.text((x, 205), "vnx", font=fm, fill=DIM, anchor="ls")
    d.text((x + d.textlength("vnx", font=fm), 205), "LIGHT", font=fb, fill=MINT, anchor="ls")
    d.text((x, 272), "Фонарик", font=ImageFont.truetype(FONT_BOLD, 42), fill=TEXT, anchor="ls")
    d.text((x, 325), "плавная яркость · без рекламы · без сети", font=ImageFont.truetype(FONT_MED, 26), fill=DIM, anchor="ls")
    fg.convert("RGB").save(STORE / "feature-1024x500.png")


if __name__ == "__main__":
    adaptive()
    store()
    print("готово")
