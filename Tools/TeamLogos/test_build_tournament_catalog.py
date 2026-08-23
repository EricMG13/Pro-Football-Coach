import hashlib
import tempfile
import unittest
from pathlib import Path

from Tools.TeamLogos import build_tournament_catalog as catalog


TEAMS = [
    {"stableID": "one", "assetName": "TeamLogo_00112233445566778899AABBCCDDEEFF", "name": "Alpha United", "abbreviation": "ALP", "family": "test"},
    {"stableID": "two", "assetName": "TeamLogo_FFEEDDCCBBAA99887766554433221100", "name": "Beta Town", "abbreviation": "BET", "family": "test"},
]


class TournamentCatalogTests(unittest.TestCase):
    def test_exact_asset_and_name_matching_only(self):
        self.assertEqual(catalog.team_for_path("raw/TeamLogo_00112233445566778899aabbccddeeff.png", TEAMS)["stableID"], "one")
        self.assertEqual(catalog.team_for_path("alpha-united.png", TEAMS)["stableID"], "one")
        self.assertIsNone(catalog.team_for_path("alpha-united-candidate.png", TEAMS))

    def test_composite_detection_keeps_individual_stage_images(self):
        self.assertTrue(catalog.is_composite_path("batch-1-phone-preview.png"))
        self.assertTrue(catalog.is_composite_path("review/20pt-review.png"))
        self.assertFalse(catalog.is_composite_path("qa/bear-stage.png"))

    def test_duplicate_bytes_merge_origins(self):
        with tempfile.TemporaryDirectory() as temporary:
            collector = catalog.CandidateCollector(TEAMS, Path(temporary))
            data = b"same logo"
            collector.add(data, "alpha-united.png", catalog.Origin("worktree", "alpha-united.png", "raw"))
            collector.add(data, "alpha-united.png", catalog.Origin("history", "alpha-united.png", "historic", object_id="abc"))
            entries = collector.entries()
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["sha256"], hashlib.sha256(data).hexdigest())
            self.assertEqual(len(entries[0]["origins"]), 2)

    def test_archive_refuses_different_existing_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            archive = Path(temporary)
            data = b"expected"
            digest = hashlib.sha256(data).hexdigest()
            destination = archive / f"{digest}.png"
            archive.mkdir(exist_ok=True)
            destination.write_bytes(b"different")
            with self.assertRaises(RuntimeError):
                catalog.archive_bytes(data, digest, ".png", archive)

    def test_reviewed_replacement_requires_decision_and_candidate_file(self):
        candidate = {
            "assetName": TEAMS[0]["assetName"],
            "origins": [{"path": f"artifacts/team-mark-review/batch-01/candidates/{TEAMS[0]['assetName']}.png"}],
        }
        self.assertTrue(catalog.is_reviewed_replacement(candidate, {TEAMS[0]["assetName"]}))
        self.assertFalse(catalog.is_reviewed_replacement(candidate, set()))


if __name__ == "__main__":
    unittest.main()
