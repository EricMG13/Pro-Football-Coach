#!/usr/bin/env python3
"""Give every packaged mark one keyline and one halo, so its silhouette holds on both pages.

    python3 Tools/TeamLogos/apply_keyline.py [--check]

The delivered set draws in exactly two team colours and carries no outline. Where the darker of the
two forms the outer contour it disappears against the dark register -- 64 of the 166 measured under
1.6 contrast against #07111F, the worst at 1.03, which is invisible. That is what a keyline is for.

Two rings, because one colour cannot serve both pages: a dark keyline that reads on the light page,
and a chalk halo outside it that reads on the dark one. This is the ordinary double outline of a
printed athletics mark, not an invention.

The mark is scaled down before the rings are added. Adding 9px of outline to art that already sits
10px from the edge would leave 1px of margin and break the transparent-edge guarantee the asset
suite enforces, so the content shrinks by however much the rings will grow it.

Idempotent by inspection rather than by flag: a mark that already carries a chalk ring is skipped,
so a second run does not stack a second outline.
"""

import json
import os
import sys
from PIL import Image, ImageFilter

ROOT = "Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets"
MANIFEST = "Tools/TeamLogos/manifest.json"

CANVAS = 256
MARGIN = 10          # the 4 per cent safe area the construction system requires
KEYLINE = 5          # 2 per cent of canvas, the construction system's weight
HALO = 4
INK = (11, 15, 20, 255)
CHALK = (247, 249, 247, 255)


def already_ringed(im):
    """True if a chalk ring is already the outermost thing on the mark."""
    alpha = im.getchannel("A")
    pixels = im.load()
    hits = 0
    checked = 0
    for y in range(0, CANVAS, 4):
        row = [x for x in range(CANVAS) if alpha.getpixel((x, y)) >= 250]
        if not row:
            continue
        checked += 1
        left = pixels[row[0], y][:3]
        if all(abs(a - b) <= 12 for a, b in zip(left, CHALK[:3])):
            hits += 1
    return checked > 0 and hits / checked > 0.6


def ringed(im):
    box = im.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()
    if box is None:
        return im
    left, top, right, bottom = box
    span = max(right - left, bottom - top)
    room = CANVAS - 2 * MARGIN - 2 * (KEYLINE + HALO)
    scale = min(1.0, room / span)

    # Scale about the mark's own centre so the rings have somewhere to go.
    inner = im.crop(box)
    width = max(1, int(round(inner.width * scale)))
    height = max(1, int(round(inner.height * scale)))
    shrunk = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    shrunk.paste(
        inner.resize((width, height), Image.LANCZOS),
        ((CANVAS - width) // 2, (CANVAS - height) // 2),
    )

    mask = shrunk.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    keyline = mask.filter(ImageFilter.MaxFilter(KEYLINE * 2 + 1))
    halo = keyline.filter(ImageFilter.MaxFilter(HALO * 2 + 1))

    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (CANVAS, CANVAS), CHALK), (0, 0), halo)
    out.paste(Image.new("RGBA", (CANVAS, CANVAS), INK), (0, 0), keyline)
    out.alpha_composite(shrunk)
    return out


def border_is_clear(im):
    alpha = im.getchannel("A")
    for i in range(CANVAS):
        if (alpha.getpixel((i, 0)) or alpha.getpixel((i, CANVAS - 1))
                or alpha.getpixel((0, i)) or alpha.getpixel((CANVAS - 1, i))):
            return False
    return True


def main():
    check_only = "--check" in sys.argv
    teams = json.load(open(MANIFEST))["teams"]
    changed = skipped = 0
    for team in teams:
        path = f"{ROOT}/{team['assetName']}.imageset/{team['filename']}"
        im = Image.open(path).convert("RGBA")
        if already_ringed(im):
            skipped += 1
            continue
        out = ringed(im)
        if not border_is_clear(out):
            raise SystemExit(f"{team['filename']} would touch the canvas edge; refusing to write")
        changed += 1
        if not check_only:
            out.save(path, optimize=True)
    verb = "would ring" if check_only else "ringed"
    print(f"{verb} {changed} marks; {skipped} already carried one")
    if not check_only:
        total = sum(
            os.path.getsize(f"{ROOT}/{t['assetName']}.imageset/{t['filename']}") for t in teams
        )
        print(f"catalogue now {total / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
