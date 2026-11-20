import sys
from PIL import Image
img = Image.open(sys.argv[1]).convert('RGBA').resize((40, 40), Image.LANCZOS)
chars = ' .:-=+*#%@'
rows = []
for y in range(40):
    line = ''
    for x in range(40):
        r, g, b, a = img.getpixel((x, y))
        if a < 40:
            line += ' '
            continue
        lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        line += chars[min(len(chars) - 1, int(lum * (len(chars) - 1)))]
    rows.append(line)
open(sys.argv[2], 'w', encoding='utf-8').write('\n'.join(rows))
