import unittest

from PIL import Image

from Tools.TeamLogos.research_and_recolor_curated_logos import color_family, recolor_preserving_shape


class ResearchPaletteRecolorTests(unittest.TestCase):
    def test_recolor_changes_only_visible_rgb(self) -> None:
        source = Image.new("RGBA", (4, 2), (0, 0, 0, 0))
        source.putdata([
            (10, 20, 30, 0), (20, 30, 40, 64), (220, 230, 240, 128), (250, 250, 250, 255),
            (5, 5, 5, 255), (80, 80, 80, 200), (180, 180, 180, 100), (1, 2, 3, 0),
        ])
        result = recolor_preserving_shape(source, "#003594", "#FFD100")
        self.assertEqual(result.size, source.size)
        self.assertEqual(result.getchannel("A").tobytes(), source.getchannel("A").tobytes())
        visible = {pixel[:3] for pixel in result.get_flattened_data() if pixel[3]}
        self.assertEqual(visible, {(0, 53, 148), (255, 209, 0)})

    def test_color_family_handles_common_football_colors(self) -> None:
        self.assertEqual(color_family("#000000"), "black")
        self.assertEqual(color_family("#A5ACAF"), "gray/silver")
        self.assertEqual(color_family("#003594"), "blue/navy")
        self.assertEqual(color_family("#FFB612"), "gold/yellow")
        self.assertEqual(color_family("#5C0025"), "maroon/burgundy")


if __name__ == "__main__":
    unittest.main()
