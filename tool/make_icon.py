"""Draw Companion's launcher icon at every density, plus the Play Store 512.

The mark: one animal at the bottom, its two parents above it, and the line
carrying on past them in clay. Drawn with supersampling so the 48px copy is
still clean.
"""
import io, os
from PIL import Image, ImageDraw

PINE = (0x1F, 0x5C, 0x4D, 255)
CREAM = (0xFB, 0xF7, 0xF1, 255)
CLAY = (0xB4, 0x62, 0x3C, 255)

RES = os.path.join('android', 'app', 'src', 'main', 'res')
STORE = os.path.join('store', 'icon')

SS = 4                      # supersample factor
BASE = 1024                 # design canvas


def rounded(d, box, r, fill):
    d.rounded_rectangle(box, radius=r, fill=fill)


def mark(draw, cx, cy, size, stroke, dot):
    """Pedigree fork, centred on (cx, cy), spanning `size`."""
    half = size / 2.0
    # bottom node: the animal in the ledger
    by = cy + half * 0.62
    # split point
    sy = cy + half * 0.10
    # parents
    px = half * 0.60
    py = cy - half * 0.42
    # ancestor stub
    ay = cy - half * 0.86

    draw.line([(cx, by), (cx, sy)], fill=CREAM, width=stroke)
    draw.line([(cx, sy), (cx - px, py)], fill=CREAM, width=stroke)
    draw.line([(cx, sy), (cx + px, py)], fill=CREAM, width=stroke)
    draw.line([(cx, sy), (cx, ay)], fill=CREAM, width=stroke)

    def node(x, y, r, colour):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=colour)

    node(cx, by, dot, CREAM)
    node(cx - px, py, dot * 0.86, CREAM)
    node(cx + px, py, dot * 0.86, CREAM)
    node(cx, ay, dot * 0.72, CLAY)


def build(px, rounded_ratio=0.22, pad_ratio=0.185):
    """A full-bleed legacy icon at `px` pixels."""
    w = px * SS
    img = Image.new('RGBA', (w, w), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, [0, 0, w - 1, w - 1], int(w * rounded_ratio), PINE)
    inner = w * (1 - 2 * pad_ratio)
    mark(d, w / 2.0, w / 2.0, inner, int(inner * 0.085), int(inner * 0.088))
    return img.resize((px, px), Image.LANCZOS)


def build_round(px, pad_ratio=0.185):
    w = px * SS
    img = Image.new('RGBA', (w, w), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, w - 1, w - 1], fill=PINE)
    inner = w * (1 - 2 * pad_ratio) * 0.92
    mark(d, w / 2.0, w / 2.0, inner, int(inner * 0.085), int(inner * 0.088))
    return img.resize((px, px), Image.LANCZOS)


LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}

made = []
for bucket, px in LEGACY.items():
    folder = os.path.join(RES, 'mipmap-' + bucket)
    os.makedirs(folder, exist_ok=True)
    for name, img in (('ic_launcher', build(px)), ('ic_launcher_round', build_round(px))):
        path = os.path.join(folder, name + '.png')
        img.save(path, 'PNG', optimize=True)
        made.append('%s %dpx %d bytes' % (path, px, os.path.getsize(path)))

os.makedirs(STORE, exist_ok=True)
for name, img in (('icon-512.png', build(512)), ('icon-round-512.png', build_round(512))):
    path = os.path.join(STORE, name)
    img.save(path, 'PNG', optimize=True)
    made.append('%s %d bytes' % (path, os.path.getsize(path)))

io.open(os.path.join('store', 'icon', 'made.txt'), 'w', encoding='utf-8',
        newline='\n').write('\n'.join(made))
print('\n'.join(made))
