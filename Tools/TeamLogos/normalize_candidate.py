#!/usr/bin/env python3
"""Normalize an offline logo candidate to the packaged team-logo contract."""

from __future__ import annotations

import argparse
import io
from collections import deque
from pathlib import Path

from PIL import Image

CANVAS = 256
MARGIN = 10
MAX_BYTES = 196_608
MIN_INTERIOR_OPACITY = 0.90

RGB = tuple[int, int, int]


def _relative_luminance(color: RGB) -> float:
    channels = [value / 255 for value in color]
    linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
              for value in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def _remove_specks(image: Image.Image, minimum: int = 4) -> None:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    visible = {(x, y) for y in range(alpha.height) for x in range(alpha.width) if pixels[x, y]}
    components: list[list[tuple[int, int]]] = []
    while visible:
        component = [visible.pop()]
        pending = deque(component)
        while pending:
            x, y = pending.popleft()
            for point in (
                (x - 1, y - 1), (x, y - 1), (x + 1, y - 1), (x - 1, y),
                (x + 1, y), (x - 1, y + 1), (x, y + 1), (x + 1, y + 1),
            ):
                if point in visible:
                    visible.remove(point)
                    component.append(point)
                    pending.append(point)
        components.append(component)
    if not components:
        return
    for component in components:
        if len(component) < minimum:
            for point in component:
                pixels[point] = 0
    image.putalpha(alpha)


def normalize_candidate(source: Image.Image, primary: RGB, secondary: RGB) -> Image.Image:
    """Return ``source`` centered on a transparent 256px two-color canvas."""
    image = source.convert("RGBA")
    alpha = image.getchannel("A").point(lambda value: 255 if value > 8 else 0)
    image.putalpha(alpha)
    box = alpha.getbbox()
    if box is None:
        raise ValueError("source has no meaningful alpha")
    opaque_pixels = alpha.histogram()[255]
    box_area = (box[2] - box[0]) * (box[3] - box[1])
    if box == (0, 0, image.width, image.height) or (
        opaque_pixels / (image.width * image.height) >= 0.90
    ) or (
        opaque_pixels / box_area >= 0.98
    ):
        raise ValueError("source resembles an opaque background")

    _remove_specks(image)
    box = image.getchannel("A").getbbox()
    if box is None:
        raise ValueError("source contains only tiny alpha specks")
    subject = image.crop(box)
    scale = min((CANVAS - 2 * MARGIN) / subject.width, (CANVAS - 2 * MARGIN) / subject.height)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    subject.putalpha(subject.getchannel("A").point(lambda value: 255 if value > 8 else 0))

    dark, light = sorted((primary, secondary), key=_relative_luminance)
    source_pixels = subject.get_flattened_data()
    chromatic_luminances = [
        _relative_luminance((red, green, blue))
        for red, green, blue, alpha_value in source_pixels
        if alpha_value >= 128 and max(red, green, blue) - min(red, green, blue) > 24
    ]
    role_split = (
        (min(chromatic_luminances) + max(chromatic_luminances)) / 2
        if chromatic_luminances else 0
    )
    mapped = []
    for red, green, blue, alpha_value in source_pixels:
        source_color = (red, green, blue)
        if alpha_value and max(source_color) - min(source_color) <= 24:
            color = dark
        else:
            distance, nearest = min(
                (
                    (
                        sum((value - target) ** 2
                            for value, target in zip(source_color, candidate)),
                        candidate,
                    )
                    for candidate in (primary, secondary)
                ),
                key=lambda match: match[0],
            )
            color = (
                nearest
                if distance <= 24 ** 2
                else dark if _relative_luminance(source_color) <= role_split else light
            )
        mapped.append((*color, alpha_value))
    subject.putdata(mapped)

    result = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    result.paste(subject, ((CANVAS - subject.width) // 2, (CANVAS - subject.height) // 2))
    _remove_specks(result, 16)
    errors = contract_errors(result, primary, secondary)
    if errors:
        raise ValueError("; ".join(errors))
    return result


def contract_errors(
    image: Image.Image,
    primary: RGB,
    secondary: RGB,
    *,
    byte_count: int | None = None,
) -> list[str]:
    """Return every logo-contract violation found in ``image``."""
    errors = []
    if image.mode != "RGBA":
        errors.append("image must be RGBA")
    if image.size != (CANVAS, CANVAS):
        errors.append(f"image must be {CANVAS} x {CANVAS}")
    if byte_count is not None and byte_count > MAX_BYTES:
        errors.append(f"encoded image exceeds {MAX_BYTES} bytes")
    if image.mode != "RGBA" or image.size != (CANVAS, CANVAS):
        return errors

    visible = [pixel for pixel in image.get_flattened_data() if pixel[3]]
    if not visible:
        errors.append("image is empty")
        return errors
    box = image.getchannel("A").getbbox()
    assert box is not None
    clearance = min(box[0], box[1], CANVAS - box[2], CANVAS - box[3])
    if clearance == 0:
        errors.append("image touches a canvas edge")
    elif clearance < MARGIN:
        errors.append(f"image clearance is below {MARGIN} px")
    allowed = {primary, secondary}
    if any(pixel[:3] not in allowed for pixel in visible):
        errors.append("image contains a non-palette RGB value")
    opaque_ratio = sum(pixel[3] == 255 for pixel in visible) / len(visible)
    if opaque_ratio < MIN_INTERIOR_OPACITY:
        errors.append(f"interior-opacity ratio is below {MIN_INTERIOR_OPACITY:.2f}")
    return errors


def _hex_color(value: str) -> RGB:
    text = value.removeprefix("#")
    if len(text) != 6:
        raise argparse.ArgumentTypeError("colors must use six hexadecimal digits")
    try:
        return tuple(bytes.fromhex(text))  # type: ignore[return-value]
    except ValueError as error:
        raise argparse.ArgumentTypeError("colors must use six hexadecimal digits") from error


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("primary", type=_hex_color, metavar="PRIMARY_HEX")
    parser.add_argument("secondary", type=_hex_color, metavar="SECONDARY_HEX")
    args = parser.parse_args()

    with Image.open(args.source) as source:
        result = normalize_candidate(source, args.primary, args.secondary)
    encoded = io.BytesIO()
    result.save(encoded, format="PNG", optimize=True)
    errors = contract_errors(result, args.primary, args.secondary, byte_count=encoded.tell())
    if errors:
        parser.error("; ".join(errors))
    args.output.write_bytes(encoded.getvalue())


if __name__ == "__main__":
    main()
