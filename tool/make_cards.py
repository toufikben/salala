"""Draw the store explainer cards from `companion-CARDS.md`.

The markdown file is the source of truth: the same sentence a translator edits
is the sentence that lands on the picture, so the listing copy and the image
cannot drift apart. This script only decides how it looks.

Why not "just use the localised app strings": a card is a marketing sentence,
not a UI label. It says what the app is to somebody who has not installed it,
which is a different sentence from the one the app says to itself.

Arabic, and the one thing that has to be got right
-------------------------------------------------
Pillow holds a list of code points and draws them left to right in isolated
forms, so Arabic needs `arabic_reshaper` (joins the letters) and `python-bidi`
(reorders to visual order). Those two are build dependencies of this script and
of nothing in the app.

The order they are applied in is not a detail. Shaping a whole paragraph and
*then* wrapping it puts the end of the sentence on the first line, because
visual order across a paragraph runs right-to-left and a line break is a
left-to-right operation. Measured on the first draft of card 2: the sentence
opened with "فعلًا من ٥٨ إلى ٦٨ يومًا" — its own last clause — and every line
below it walked backwards. So `wrap()` works on the *logical* text and `shape()`
runs per line, after the break has been decided.
"""
import io
import os

from PIL import Image, ImageDraw, ImageFont

try:
    import arabic_reshaper
    from bidi.algorithm import get_display
    _HAS_ARABIC = True
except ImportError:  # pragma: no cover
    _HAS_ARABIC = False

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CARDS_MD = os.path.join(os.path.dirname(ROOT), 'companion-CARDS.md')
OUT = os.path.join(ROOT, 'store', 'cards')

# The app's own palette, so a store card and the app it advertises agree.
PINE = (31, 92, 77)
CLAY = (180, 98, 60)
PAPER = (251, 247, 241)
INK = (26, 28, 30)
MUTED = (110, 106, 99)
ON_PINE_DIM = (188, 208, 199)

RTL = {'ar'}

LOCALE_NAMES = {
    'en': 'English', 'ar': 'العربية', 'fr': 'Français', 'de': 'Deutsch',
    'es': 'Español', 'it': 'Italiano', 'pt': 'Português', 'nl': 'Nederlands',
}

_DEJAVU = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
_DEJAVU_BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def _first(paths):
    for p in paths:
        if os.path.exists(p):
            return p
    raise SystemExit('no usable font; looked for ' + ', '.join(paths))


FONT = _first([r'C:\Windows\Fonts\segoeui.ttf', r'C:\Windows\Fonts\arial.ttf', _DEJAVU])
FONT_BOLD = _first([r'C:\Windows\Fonts\segoeuib.ttf', r'C:\Windows\Fonts\arialbd.ttf', _DEJAVU_BOLD])


def shape(text, locale):
    """One line of Arabic, joined and reordered. Never call this before wrap()."""
    if locale not in RTL:
        return text
    if not _HAS_ARABIC:
        raise SystemExit('pip install arabic-reshaper python-bidi')
    return get_display(arabic_reshaper.reshape(text))


def wrap(draw, text, font, max_width):
    """Break on spaces in logical order. Arabic breaks the same way, by space."""
    words = text.split(' ')
    lines, line = [], ''
    for w in words:
        trial = w if not line else line + ' ' + w
        if draw.textlength(trial, font=font) <= max_width:
            line = trial
        else:
            if line:
                lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines


def fit(draw, text, bold, max_width, max_lines, start, floor=30):
    """Largest size at which the whole sentence fits, in at most max_lines.

    The widest word is measured on its own first: a single unbreakable word
    wider than the box would otherwise loop to the floor and still overflow.
    """
    size = start
    while size > floor:
        font = ImageFont.truetype(FONT_BOLD if bold else FONT, size)
        widest = max((draw.textlength(w, font=font) for w in text.split(' ')),
                     default=0)
        if widest <= max_width and len(wrap(draw, text, font, max_width)) <= max_lines:
            return font, wrap(draw, text, font, max_width)
        size -= 2
    font = ImageFont.truetype(FONT_BOLD if bold else FONT, floor)
    return font, wrap(draw, text, font, max_width)


def read_cards():
    """`## n — title` heads, then `| **xx** | sentence |` rows beneath each.

    The headings table near the end has a locale code per *column*, so its rows
    start with a digit and the rows read here start with `**`. That is what
    keeps the two tables apart without a marker.
    """
    text = io.open(CARDS_MD, encoding='utf-8').read()
    cards, title, rows = [], '', {}
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith('## '):
            if rows:
                cards.append((title, rows))
            title, rows = line[3:].strip(), {}
        elif line.startswith('| **') and line.count('|') >= 3:
            parts = [p.strip() for p in line.strip('|').split('|')]
            if len(parts) < 2:
                continue
            code = parts[0].strip('* ')
            sentence = parts[1]
            if len(code) == 2 and sentence:
                rows[code] = sentence
    if rows:
        cards.append((title, rows))
    return cards


def read_headings():
    """`| 2 | The whelping window | نافذة الولادة | … |` -> {2: {code: heading}}."""
    text = io.open(CARDS_MD, encoding='utf-8').read()
    codes, out = None, {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line.startswith('|'):
            codes = None
            continue
        cells = [c.strip() for c in line.strip('|').split('|')]
        if cells and cells[0] == '#':
            codes = cells[1:]
            continue
        if codes and cells and cells[0].isdigit():
            out[int(cells[0])] = {
                code: cells[i + 1] for i, code in enumerate(codes)
                if i + 1 < len(cells) and cells[i + 1]
            }
    return out


def draw_card(heading, sentence, locale, w, h, index, total):
    img = Image.new('RGB', (w, h), PAPER)
    d = ImageDraw.Draw(img)
    rtl = locale in RTL
    margin = int(w * 0.078)
    inner = w - 2 * margin

    name_font = ImageFont.truetype(FONT_BOLD, int(h * 0.027))
    head_font, head_lines = fit(d, heading, True, inner, 3, int(h * 0.050))
    head_line_h = int(head_font.size * 1.26)
    head_block = len(head_lines) * head_line_h

    # The band is sized from what is actually in it, so a three-line German
    # heading and a one-line English one both sit with the same breathing room
    # instead of one of them touching the clay rule.
    name_y = int(h * 0.048)
    gap = int(h * 0.055)
    band = name_y + name_font.size + gap + head_block + int(h * 0.050)

    d.rectangle([0, 0, w, band], fill=PINE)
    d.rectangle([0, band, w, band + max(5, h // 380)], fill=CLAY)

    name = shape('Companion', locale)
    if rtl:
        d.text((w - margin, name_y), name, font=name_font, fill=ON_PINE_DIM, anchor='ra')
    else:
        d.text((margin, name_y), name, font=name_font, fill=ON_PINE_DIM, anchor='la')

    y = name_y + name_font.size + gap
    for line in head_lines:
        if rtl:
            d.text((w - margin, y), shape(line, locale), font=head_font, fill=PAPER, anchor='ra')
        else:
            d.text((margin, y), line, font=head_font, fill=PAPER, anchor='la')
        y += head_line_h

    body_font, body_lines = fit(d, sentence, False, inner, 8, int(h * 0.044))
    body_line_h = int(body_font.size * 1.46)
    y = band + int(h * 0.095)
    for line in body_lines:
        if rtl:
            d.text((w - margin, y), shape(line, locale), font=body_font, fill=INK, anchor='ra')
        else:
            d.text((margin, y), line, font=body_font, fill=INK, anchor='la')
        y += body_line_h

    foot = ImageFont.truetype(FONT, int(h * 0.021))
    foot_y = h - int(h * 0.050)
    idx = '%d / %d' % (index, total)
    if rtl:
        d.text((w - margin, foot_y), shape(idx, locale), font=foot, fill=MUTED, anchor='ra')
        d.text((margin, foot_y), shape(LOCALE_NAMES[locale], locale), font=foot,
               fill=MUTED, anchor='la')
    else:
        d.text((margin, foot_y), idx, font=foot, fill=MUTED, anchor='la')
        d.text((w - margin, foot_y), LOCALE_NAMES[locale], font=foot, fill=MUTED,
               anchor='ra')
    return img


def main():
    cards = read_cards()
    heads = read_headings()
    if not cards:
        raise SystemExit('no cards parsed out of ' + CARDS_MD)
    os.makedirs(OUT, exist_ok=True)

    total = len(cards)
    written = 0
    for i, (title, rows) in enumerate(cards, start=1):
        for code, sentence in sorted(rows.items()):
            heading = heads.get(i, {}).get(code)
            if not heading:
                raise SystemExit(
                    'card %d has no %s heading in the headings table; an '
                    'untranslated heading is exactly what that table prevents'
                    % (i, code))
            img = draw_card(heading, sentence, code, 1080, 1920, i, total)
            name = 'card-%02d-%s.png' % (i, code)
            img.save(os.path.join(OUT, name), 'PNG', optimize=True)
            # A 16:9 twin for the tablet slots: the 9:16 card centred on paper,
            # never stretched, so no glyph is distorted to fill a wider frame.
            wide = Image.new('RGB', (1920, 1080), PAPER)
            wide.paste(img.resize((608, 1080), Image.LANCZOS), (656, 0))
            wide.save(os.path.join(OUT, name.replace('.png', '-wide.png')),
                      'PNG', optimize=True)
            written += 1
    print('wrote %d card pairs into %s' % (written, OUT))


if __name__ == '__main__':
    main()
