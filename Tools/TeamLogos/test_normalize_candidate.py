import unittest

from PIL import Image, ImageDraw

from Tools.TeamLogos.normalize_candidate import contract_errors, normalize_candidate


class NormalizeCandidateTest(unittest.TestCase):
    def test_normalizes_a_real_rgba_fixture_to_the_logo_contract(self) -> None:
        source = Image.new("RGBA", (180, 140), (0, 0, 0, 0))
        draw = ImageDraw.Draw(source)
        draw.ellipse((20, 10, 159, 129), fill=(247, 247, 245, 180))
        draw.ellipse((27, 17, 152, 122), fill=(210, 45, 30, 150))
        draw.pieslice((34, 24, 145, 115), 270, 90, fill=(25, 90, 210, 210))
        draw.ellipse((73, 49, 106, 82), fill=(0, 0, 0, 0))
        draw.rectangle((20, 10, 22, 12), fill=(25, 90, 210, 255))
        draw.point((2, 2), fill=(210, 45, 30, 255))

        primary = (245, 126, 32)
        secondary = (18, 31, 55)
        result = normalize_candidate(source, primary, secondary)

        self.assertEqual(result.size, (256, 256))
        self.assertEqual(result.mode, "RGBA")
        alpha = result.getchannel("A")
        self.assertFalse(any(alpha.crop((0, 0, 256, 1)).get_flattened_data()))
        self.assertFalse(any(alpha.crop((0, 255, 256, 256)).get_flattened_data()))
        self.assertFalse(any(alpha.crop((0, 0, 1, 256)).get_flattened_data()))
        self.assertFalse(any(alpha.crop((255, 0, 256, 256)).get_flattened_data()))

        box = alpha.getbbox()
        self.assertIsNotNone(box)
        assert box is not None
        self.assertGreaterEqual(min(box[0], box[1], 256 - box[2], 256 - box[3]), 10)

        pixels = list(result.get_flattened_data())
        visible = [pixel for pixel in pixels if pixel[3]]
        self.assertEqual({pixel[:3] for pixel in visible}, {primary, secondary})
        self.assertGreaterEqual(sum(pixel[3] == 255 for pixel in visible) / len(visible), 0.90)

        center = (128, 128)
        self.assertEqual(alpha.getpixel(center), 0, "the transparent counter must survive")
        self.assertEqual(result.getpixel((128, box[1]))[:3], secondary)

        components = []
        remaining = set(alpha.point(lambda value: 255 if value else 0).getbbox() and (
            (x, y)
            for y in range(256)
            for x in range(256)
            if alpha.getpixel((x, y))
        ) or ())
        while remaining:
            pending = [remaining.pop()]
            component_size = 0
            while pending:
                x, y = pending.pop()
                component_size += 1
                for neighbor_y in range(y - 1, y + 2):
                    for neighbor_x in range(x - 1, x + 2):
                        point = (neighbor_x, neighbor_y)
                        if point in remaining:
                            remaining.remove(point)
                            pending.append(point)
            components.append(component_size)
        self.assertEqual(len(components), 2, "a meaningful separated component must survive")
        self.assertGreater(min(components), 16, "the one-pixel speck must be removed")
        self.assertEqual(contract_errors(result, primary, secondary), [])

        background = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        ImageDraw.Draw(background).rectangle((1, 1, 62, 62), fill=(255, 255, 255, 255))
        with self.subTest("almost-opaque background"):
            with self.assertRaisesRegex(ValueError, "opaque background"):
                normalize_candidate(background, primary, secondary)

        stale = Image.new("RGBA", (60, 30), (0, 0, 0, 0))
        stale_draw = ImageDraw.Draw(stale)
        stale_draw.rectangle((2, 2, 28, 27), fill=(10, 30, 180, 255))
        stale_draw.rectangle((31, 2, 57, 27), fill=(240, 220, 20, 255))
        target_dark = (180, 20, 20)
        target_light = (20, 180, 240)
        rekeyed = normalize_candidate(stale, target_dark, target_light)
        with self.subTest("luminance role re-keying"):
            self.assertEqual(rekeyed.getpixel((64, 128))[:3], target_dark)
            self.assertEqual(rekeyed.getpixel((192, 128))[:3], target_light)

    def test_hardens_downsampled_curves_and_rejects_opaque_fields(self) -> None:
        primary = (240, 120, 30)
        secondary = (20, 30, 70)

        curved = Image.new("RGBA", (1254, 1254), (0, 0, 0, 0))
        curved_draw = ImageDraw.Draw(curved)
        curved_draw.arc((110, 110, 1144, 1144), 35, 325, fill=(24, 40, 120, 255), width=80)
        curved_draw.arc((190, 190, 1064, 1064), 35, 325, fill=(230, 180, 40, 255), width=48)

        result = normalize_candidate(curved, primary, secondary)
        alpha = result.getchannel("A")
        self.assertEqual(set(alpha.get_flattened_data()), {0, 255})
        self.assertEqual(alpha.getpixel((128, 128)), 0, "the C-shaped opening must survive")

        background = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        ImageDraw.Draw(background).rectangle((10, 10, 89, 89), fill=(255, 255, 255, 255))
        with self.assertRaisesRegex(ValueError, "opaque background"):
            normalize_candidate(background, primary, secondary)

    def test_preserves_requested_palette_roles_despite_a_bright_outlier(self) -> None:
        primary = (66, 154, 50)
        secondary = (66, 10, 41)
        source = Image.new("RGBA", (100, 60), (0, 0, 0, 0))
        draw = ImageDraw.Draw(source)
        draw.rounded_rectangle((5, 5, 94, 54), 10, fill=secondary)
        draw.rectangle((25, 15, 74, 44), fill=primary)
        draw.rectangle((74, 15, 77, 18), fill=(250, 250, 20, 255))

        result = normalize_candidate(source, primary, secondary)
        visible = [pixel for pixel in result.get_flattened_data() if pixel[3]]
        primary_ratio = sum(pixel[:3] == primary for pixel in visible) / len(visible)
        self.assertGreater(primary_ratio, 0.20)


if __name__ == "__main__":
    unittest.main()
