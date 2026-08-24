import unittest
import json
from pathlib import Path

from PIL import Image

from Tools.TeamLogos.remediate_selected_logo_visibility import fit_transparent_square, remove_light_edge_background


class BackgroundRemovalTests(unittest.TestCase):
    def test_removes_only_edge_connected_light_background(self) -> None:
        source = Image.new("RGBA", (5, 5), (250, 250, 250, 255))
        for coordinate in ((1, 1), (2, 1), (3, 1), (1, 2), (3, 2), (1, 3), (2, 3), (3, 3)):
            source.putpixel(coordinate, (20, 20, 20, 255))
        cleaned, removed = remove_light_edge_background(source)
        self.assertEqual(removed, 16)
        self.assertEqual(cleaned.getpixel((0, 0))[3], 0)
        self.assertEqual(cleaned.getpixel((2, 2)), (250, 250, 250, 255))

    def test_already_transparent_assets_are_unchanged(self) -> None:
        source = Image.new("RGBA", (2, 2), (250, 250, 250, 0))
        cleaned, removed = remove_light_edge_background(source)
        self.assertEqual(removed, 0)
        self.assertEqual(cleaned.tobytes(), source.tobytes())

    def test_fits_visible_content_into_a_square_with_padding(self) -> None:
        source = Image.new("RGBA", (20, 10))
        source.paste((10, 20, 30, 255), (2, 1, 18, 9))
        fitted = fit_transparent_square(source, size=100, padding=10)
        self.assertEqual(fitted.size, (100, 100))
        self.assertEqual(fitted.getchannel("A").getbbox(), (10, 30, 90, 70))

    def test_giraffe_repair_retains_its_original_source_path(self) -> None:
        curation = json.loads((Path(__file__).resolve().parents[2] / "artifacts/team-mark-review/final-166-curation.json").read_text())
        giraffe = next(fill for fill in curation["fillCandidates"] if fill["id"] == "final-fill:03-giraffe")
        self.assertEqual(giraffe["sourceImagePath"], "final-166-fill/batch-01/final-candidates/03-giraffe.png")


if __name__ == "__main__":
    unittest.main()
