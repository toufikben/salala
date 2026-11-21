"""Draw the Play feature graphic and the store icon from one source.

Play's feature graphic is 1024x500 and it is cropped differently on every
surface that shows it — the carousel, the search card, the collection tile —
so nothing important may live near an edge. The layout below keeps the mark at
the left third and the words inside a safe box, which is what survives a crop.

Run: python tool/make_feature_graphic.py
"""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'store', 'icon')

PINE = (31, 92, 77)
PINE_DEEP = (18, 58, 48)
CLAY = (180, 98, 60)
PAPER = (251, 247, 241)
ON_PINE = (245, 241, 233)
ON_PINE_DIM = (186, 208, 199)

_DEJAVU = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
_DEJAVU_BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def _first(paths):
    for p in paths:
        if os.path.exists(p):
            return p
    raise SystemExit('no usable font; looked for ' + ', '.join(paths))


FONT = _first([r'C:\Windows\Fonts\segoeui.ttf', r'C:\Windows\Fonts\arial.ttf', _DEJAVU])
FONT_BOLD = _first([r'C:\Windows\Fonts\segoeuib.ttf', r'C:\Windows\Fonts\arialbd.ttf', _DEJAVU_BOLD])


def draw_mark(d, cx, cy, size, colour_top, colour_stem, colour_leaf):
    """The pedigree fork: two parents above, one animal below, a shared line.

    Drawn rather than pasted so the same function can produce the launcher icon
    and this banner at different sizes without a raster scaling step.
    """
    unit = size / 100.0

    def node(x, y, r):
        d.ellipse([x - r, y - r, x + r, y + r], fill=colour_leaf)

    r = 15 * unit
    top_y = cy - 26 * unit
    bot_y = cy + 30 * unit
    lx = cx - 24 * unit
    rx = cx + 24 * unit

    # the stem: parents converge, the animal descends
    w = max(2, int(7 * unit))
    d.line([lx, top_y + r, cx, cy + 2 * unit], fill=colour_stem, width=w)
    d.line([rx, top_y + r, cx, cy + 2 * unit], fill=colour_stem, width=w)
    d.line([cx, cy, cx, bot_y - r], fill=colour_stem, width=w)

    node(lx, top_y, r)
    node(rx, top_y, r)
    node(cx, bot_y, 19 * unit)


def feature_graphic():
    w, h = 1024, 500
    img = Image.new('RGB', (w, h), PINE)
    d = ImageDraw.Draw(img)

    # A diagonal wash so the flat field is not dead, kept subtle enough that a
    # crop anywhere still looks deliberate.
    for i in range(h):
        t = i / float(h)
        col = tuple(int(PINE[k] + (PINE_DEEP[k] - PINE[k]) * t) for k in range(3))
        d.line([(0, i), (w, i)], fill=col)

    draw_mark(d, 168, 250, 260, PINE, CLAY, PAPER)

    title_font = ImageFont.truetype(FONT_BOLD, 76)
    sub_font = ImageFont.truetype(FONT, 30)
    kick_font = ImageFont.truetype(FONT_BOLD, 21)

    x = 360
    right = w - 48          # the safe margin: Play crops this banner
    d.text((x, 148), 'Companion', font=title_font, fill=ON_PINE)
    d.text((x, 240), 'Breeder records that live on your phone',
           font=sub_font, fill=ON_PINE_DIM)

    # The keyword line shrinks until it clears the right margin rather than
    # running off it. Measured, not guessed: "Buyers" was cut in half on the
    # first draft because the size was chosen before the string was.
    kw = 'Litters  ·  Whelping  ·  Pedigree  ·  Health  ·  Buyers'
    size = 30
    while size > 18:
        f = ImageFont.truetype(FONT, size)
        if d.textlength(kw, font=f) <= right - x:
            break
        size -= 1
    kw_font = ImageFont.truetype(FONT, size)
    d.text((x, 300), kw, font=kw_font, fill=ON_PINE_DIM)
    d.text((x, 372), 'WORKS OFFLINE', font=kick_font, fill=CLAY)

    img.save(os.path.join(OUT, 'feature-graphic-1024x500.png'), 'PNG', optimize=True)
    return 'feature-graphic-1024x500.png'


def main():
    os.makedirs(OUT, exist_ok=True)
    print('wrote', feature_graphic(), 'into', OUT)


if __name__ == '__main__':
    main()
