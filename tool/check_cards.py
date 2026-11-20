"""Prove no card's text runs off its picture or into the footer.

`make_cards.py` chooses a font size that fits a line count, but a line count is
not the same thing as a height: eight lines at one size can be taller than the
space between the clay rule and the footer. This measures the real bottom of the
real text on every card, at every locale, and fails loudly instead of shipping a
picture with a sentence cut off — which is the failure nobody notices until a
buyer's first impression is a truncated word.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import ImageFont  # noqa: E402

import make_cards as mc  # noqa: E402


def main():
    cards = mc.read_cards()
    heads = mc.read_headings()
    problems = []

    for i, (title, rows) in enumerate(cards, start=1):
        for code, sentence in sorted(rows.items()):
            heading = heads[i][code]
            w, h = 1080, 1920
            margin = int(w * 0.078)
            inner = w - 2 * margin

            # Recompute exactly what draw_card computes, then measure.
            from PIL import Image, ImageDraw
            probe = ImageDraw.Draw(Image.new('RGB', (w, h)))

            name_size = int(h * 0.027)
            head_font, head_lines = mc.fit(probe, heading, True, inner, 3,
                                           int(h * 0.050))
            head_line_h = int(head_font.size * 1.26)
            name_y = int(h * 0.048)
            gap = int(h * 0.055)
            band = name_y + name_size + gap + len(head_lines) * head_line_h + int(h * 0.050)

            body_font, body_lines = mc.fit(probe, sentence, False, inner, 8,
                                           int(h * 0.044))
            body_line_h = int(body_font.size * 1.46)
            body_top = band + int(h * 0.095)
            body_bottom = body_top + len(body_lines) * body_line_h

            foot_y = h - int(h * 0.050)
            if body_bottom > foot_y - 12:
                problems.append(
                    'card %d %s: text bottom %d runs into the footer at %d'
                    % (i, code, body_bottom, foot_y))
            if band > int(h * 0.46):
                problems.append(
                    'card %d %s: the heading band is %d tall, more than 46%% of '
                    'the card' % (i, code, band))
            # The widest single word must fit, or wrap() cannot help.
            widest = max((probe.textlength(word, font=body_font)
                          for word in sentence.split(' ')), default=0)
            if widest > inner:
                problems.append(
                    'card %d %s: one word is %d px wide against a %d px box'
                    % (i, code, widest, inner))

    if problems:
        print('\n'.join(problems))
        raise SystemExit('%d card(s) would ship clipped' % len(problems))
    print('all %d cards fit' % (len(cards) * 8))


if __name__ == '__main__':
    main()
