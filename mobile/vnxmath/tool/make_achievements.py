"""Рисует значки достижений vnxMATH для сервисов Play Games (512×512).

Список достижений и правила их получения — в store/ACHIEVEMENTS.md.
Значок без текста на языке: число или знак, поэтому один и тот же для
русской и английской версий. Закрытое (ещё не полученное) достижение Google
Play сам показывает серым, отдельная картинка не нужна.

Запуск из mobile/vnxmath:  python tool/make_achievements.py
"""
from PIL import Image, ImageDraw

from make_icons import BLUE, MINT, NAVY_BOTTOM, STORE, TEXT, background, font, logo

AMBER = (255, 200, 87)  # Palette.amber в lib/theme.dart

OUT = STORE / "achievements"
SIZE = 512


def badge(accent):
    """Фон и кольцо достижения; возвращает картинку и её рисовальщик."""
    img = background(SIZE)
    # Полупрозрачную заливку рисуем отдельным слоем: ImageDraw по RGBA не
    # смешивает цвета, а записывает альфу как есть.
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    pad, width = 44, 18
    ImageDraw.Draw(layer).ellipse(
        (pad, pad, SIZE - pad, SIZE - pad), fill=accent + (38,), outline=accent + (255,), width=width
    )
    img.alpha_composite(layer)
    return img, ImageDraw.Draw(img)


def number(value, accent):
    img, d = badge(accent)
    size = 230 if len(value) < 2 else 196
    d.text((SIZE / 2, SIZE / 2 + 6), value, font=font(size), fill=TEXT + (255,), anchor="mm")
    return img


def check(accent):
    """Галочка: решено своим умом, без подсказок."""
    img, d = badge(accent)
    pts = [(160, 266), (228, 334), (360, 190)]
    d.line(pts, fill=accent + (255,), width=46, joint="curve")
    for x, y in (pts[0], pts[-1]):
        d.ellipse((x - 23, y - 23, x + 23, y + 23), fill=accent + (255,))
    return img


def crown(accent):
    """Знак vnxMATH в короне: все уровни без подсказок."""
    img, d = badge(accent)
    mark = logo(170)
    img.alpha_composite(mark, ((SIZE - mark.width) // 2, 236))
    top = [(150, 214), (182, 128), (220, 182), (256, 112), (292, 182), (330, 128), (362, 214)]
    d.polygon(top, fill=accent + (255,))
    d.rectangle((150, 206, 362, 222), fill=accent + (255,))
    for x, y in (top[1], top[3], top[5]):
        d.ellipse((x - 12, y - 12, x + 12, y + 12), fill=accent + (255,), outline=NAVY_BOTTOM + (255,), width=3)
    return img


ACHIEVEMENTS = {
    "first_step": lambda: number("1", MINT),
    "warm_up": lambda: number("10", MINT),
    "in_rhythm": lambda: number("30", BLUE),
    "number_master": lambda: number("60", BLUE),
    "own_mind": lambda: check(MINT),
    "clean_sheet": lambda: crown(AMBER),
}


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for key, draw in ACHIEVEMENTS.items():
        draw().convert("RGB").save(OUT / f"{key}.png")
    print("готово:", ", ".join(ACHIEVEMENTS))
