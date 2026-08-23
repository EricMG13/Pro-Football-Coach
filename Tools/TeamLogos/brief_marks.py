#!/usr/bin/env python3
"""Keep the mark manifest in step with the nickname pool the generator draws from.

    python3 Tools/TeamLogos/brief_marks.py

The manifest is an inventory of *marks*, keyed by the nickname each one depicts. It used to be an
inventory of *teams*, keyed by a team identifier -- and a team identifier is a position in the
random stream, so every change to generation re-keyed the whole catalogue and left marks describing
teams that no longer existed. A nickname is drawn from a fixed pool, so keying on it survives both
a generator change and a change of seed.

This script does two things and nothing else:

  * carries every existing brief forward, dropping any whose nickname has left the pool -- that art
    can never be shown again, because no save can produce the name it depicts;
  * writes `MARKS_PER_NICKNAME` pending briefs for every pool nickname that has no artwork at all,
    so the outstanding work is a list rather than a gap nobody has counted. A nickname that already
    has a mark is left alone: thin is not the same as missing.

It never invents a `generationStatus`. A record it writes is pending and unapproved until artwork
exists and the owner adopts it.
"""

import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Tools/TeamLogos/manifest.json"
GRAMMAR = ROOT / "Sources/FootballSimCore/Generation/NameGrammar.swift"

# The live set averages 4.4 marks per nickname, and at the canonical seed a nickname is carried by
# between two and ten teams. Briefing one mark for a nickname with none would put the same chip on
# ten teams, so a nickname that has to be started from nothing is started at the live average.
MARKS_PER_NICKNAME = 4

# Every nickname noun the grammar can emit, with the shapes it can legitimately become. A noun
# without a field cannot be drawn that way -- an anchor is not a creature -- and that is what drives
# family assignment below. `emblem` is deliberately universal: anything can sit inside a crest.
SUBJECTS = {
    "Wardens": dict(figure="a warden, hood up and jaw set", tool="a warden's lantern and keyring",
                    emblem="a warden's lantern", place="a boundary post and chain"),
    "Delvers": dict(figure="a delver under a lamped helmet", tool="a short delving pick",
                    emblem="crossed picks", place="a mine-adit arch"),
    "Sentinels": dict(figure="a sentinel in a crested helm", tool="a watch horn",
                      emblem="a watchtower", place="a lone watchtower on a ridge"),
    "Bulwarks": dict(tool="a shield boss", emblem="a bulwark wall",
                     place="a stepped rampart wall"),
    "Prospectors": dict(figure="a prospector under a wide hat", tool="a prospecting pick and pan",
                        emblem="a pick over an ore chunk", place="a driven claim stake"),
    "Voyagers": dict(figure="a voyager in a storm hood", tool="a ship's wheel",
                     emblem="a compass rose", place="a headland light"),
    "Reapers": dict(figure="a reaper, hood low", tool="a scythe", emblem="a scythe over a sheaf",
                    place="a cut field ridge"),
    "Anchors": dict(tool="an anchor", emblem="an anchor", place="an anchor set in a harbour wall"),
    "Wayfarers": dict(figure="a wayfarer under a travelling hat", tool="a staff and lantern",
                      emblem="a lantern on a staff", place="a milestone at a crossroads"),
    "Wreckers": dict(figure="a wrecker, jaw forward", tool="a wrecking hook on a chain",
                     emblem="a hook and broken spar", place="a shore of broken spars"),
    "Stalkers": dict(creature="a stalking cat, head low and shoulders high",
                     figure="a stalker, hood drawn", emblem="a stalking cat's head"),
    "Colliers": dict(figure="a collier under a lamped helmet", tool="a coal hammer and lamp",
                     emblem="a miner's lamp", place="a pit headframe"),
    "Ironsides": dict(figure="an ironside in a face-plate helm", tool="a riveted hull plate",
                      emblem="a riveted plate", place="an ironclad prow"),
    "Quarrymen": dict(figure="a quarryman under a brimmed hard hat", tool="a sledge and wedge",
                      emblem="a crossed sledge and chisel", place="a quarry step face"),
    "Kestrels": dict(creature="a kestrel hovering, wings held high", emblem="a kestrel's head"),
    "Tanners": dict(figure="a tanner in a leather apron and cap",
                    tool="a tanner's crescent knife", emblem="a crescent knife over a hide"),
    "Coopers": dict(figure="a cooper under a flat cap", tool="a cooper's adze and barrel hoop",
                    emblem="a barrel hoop and adze"),
    "Sawyers": dict(figure="a sawyer under a brimmed cap", tool="a two-handled pit saw",
                    emblem="a saw blade", place="a stack of cut timber"),
    "Riggers": dict(figure="a rigger in a knit cap", tool="a rigging block and rope",
                    emblem="a block and tackle"),
    "Ferrymen": dict(figure="a ferryman in a boat cloak", tool="a ferry pole and skiff",
                     emblem="a skiff prow and pole", place="a ferry slip"),
    "Smelters": dict(figure="a smelter behind a face shield", tool="a crucible and tongs",
                     emblem="a pouring crucible", place="a furnace stack"),
    "Chandlers": dict(figure="a chandler under a peaked cap", tool="a candle mould and taper",
                      emblem="three tapers"),
    "Fletchers": dict(figure="a fletcher under a hood", tool="a fletched arrow and knife",
                      emblem="three fletched arrows"),
    "Bastions": dict(tool="a gun port", emblem="a star-shaped bastion plan",
                     place="a bastion angle wall"),
    "Ramparts": dict(emblem="a rampart wall", place="a rampart with a stepped parapet"),
    "Palisades": dict(emblem="a palisade line of driven stakes",
                      place="a palisade of driven stakes on a ridge"),
    "Cairns": dict(emblem="a stone cairn", place="a stacked stone cairn on open ground"),
    "Lodestars": dict(tool="a lodestone compass", emblem="a lodestar, one sharp star",
                      place="a lodestar over a ridge"),
    "Shrikes": dict(creature="a shrike, hooked beak forward", emblem="a shrike's head"),
    "Curlews": dict(creature="a curlew, long bill angled down", emblem="a curlew's head"),
    "Goshawks": dict(creature="a goshawk, head turned and brow low", emblem="a goshawk's head"),
    "Martens": dict(creature="a marten, body arched and teeth bared", emblem="a marten's head"),
    "Wyverns": dict(creature="a wyvern, wings spread and tail coiled", emblem="a wyvern's head"),
    # The seven the 2026-08-13 sweep put into the pool in place of real programme nicknames. They
    # are trades and one wading bird, on the same principle as the rest: a shape a mark can be,
    # never a scene it can sit in.
    "Wainwrights": dict(figure="a wainwright in a leather apron", tool="a wagon wheel and adze",
                        emblem="a wagon wheel over crossed adzes", place="a wagon bed on trestles"),
    "Wheelwrights": dict(figure="a wheelwright under a flat cap", tool="a spoke and felloe",
                         emblem="a spoked wheel", place="a tyring plate and wheel pit"),
    "Millwrights": dict(figure="a millwright in a canvas apron", tool="a mill gear and spanner",
                        emblem="a toothed mill gear", place="a mill wheel and race"),
    "Bargemen": dict(figure="a bargeman in a knit cap", tool="a barge pole and cleat",
                     emblem="a barge prow", place="a lock gate on a cut"),
    "Lamplighters": dict(figure="a lamplighter under a tall hat", tool="a lighting pole and taper",
                         emblem="a street lamp alight", place="a lamp standard on a bridge"),
    "Draymen": dict(figure="a drayman in a heavy coat", tool="a dray harness and hames",
                    emblem="a dray wheel under a yoke", place="a loaded dray at a yard gate"),
    "Bitterns": dict(creature="a bittern, bill raised and neck stretched",
                     emblem="a bittern's head", place="a stand of cut reeds"),
}

FIELD_FOR_FAMILY = {
    "animalCreature": "creature",
    "originalCharacter": "figure",
    "equipmentVehicle": "tool",
    "regionalSymbol": "place",
    "framedEmblem": "emblem",
    "abstractMotion": "emblem",
}

FRAMES = ["shield", "roundel", "pennant", "hexagon", "diamond"]


def pool_nouns():
    """The nickname nouns straight out of the grammar, so this cannot drift from what generates.

    The Swift accessor `NameGrammar.nicknameNounVocabulary` is what the test reads; this reads the
    literal it is built from. Two readers of one list, and a mismatch fails the test rather than
    quietly briefing a pool that does not exist.
    """
    source = GRAMMAR.read_text()
    match = re.search(r"private static let nicknameNouns = \[(.*?)\n    \]", source, re.S)
    if match is None:
        raise SystemExit("could not find nicknameNouns in NameGrammar.swift")
    nouns = re.findall(r'"([A-Za-z]+)"', match.group(1))
    if len(nouns) < 20:
        raise SystemExit(f"nicknameNouns parsed as {len(nouns)} entries, which is not the pool")
    return nouns


# Strongest reading first. A noun is only ever offered a family it has a shape for, except the last
# two, which every noun can take.
def preferences(noun):
    fields = SUBJECTS[noun]
    order = []
    for family in ("animalCreature", "originalCharacter", "equipmentVehicle"):
        if fields.get(FIELD_FOR_FAMILY[family]):
            order.append(family)
    # A crest reads as well as a portrait for anything, so it takes overflow before the landscape
    # form and well before the abstract one, which is the weakest reading of a named subject.
    order.append("framedEmblem")
    if fields.get("place"):
        order.append("regionalSymbol")
    order.append("abstractMotion")
    order.append("regionalSymbol")
    return list(dict.fromkeys(order))


def phrasing(family, noun, index):
    # Every branch falls back to the emblem, because a noun can be seated in a family it has no
    # dedicated shape for, and a mark that silently loses its nickname is the defect this whole
    # file exists to remove.
    fields = SUBJECTS[noun]
    emblem = fields["emblem"]
    if family == "animalCreature" and fields.get("creature"):
        return f"{fields['creature']}, drawn as a head-and-shoulders mark"
    if family == "originalCharacter" and fields.get("figure"):
        return f"{fields['figure']}, drawn as a head in profile"
    if family == "equipmentVehicle" and fields.get("tool"):
        return f"{fields['tool']}, drawn square-on"
    if family == "regionalSymbol":
        place = fields.get("place", f"{emblem} standing alone on open ground")
        return f"{place}, reduced to flat geometric planes"
    if family == "framedEmblem":
        return f"{emblem} inside a {FRAMES[index % len(FRAMES)]}, filling the frame"
    if family == "abstractMotion":
        plural = emblem.split()[0].lower() in {"crossed", "three", "two"}
        return (f"{emblem}, cut down to {'their' if plural else 'its'} sharpest angles and swept "
                "into motion")
    return f"{emblem}, drawn square-on"


def build_prompt(noun, family, index):
    """The brief for one mark.

    The colour line asks for separation rather than naming two hex values. A mark is keyed by
    nickname now, so it is worn by every team carrying that nickname and cannot be drawn in any one
    team's colours; what it has to do is stay legible against both surfaces it is drawn on.
    """
    return f"""Draw one original athletics team mark as flat vector artwork.

Subject: {phrasing(family, noun, index)}. The mark depicts the team's nickname, the {noun}, and \
nothing else.

Style: a single subject filling the frame. Two or three flat colours only. No gradient, no shading, \
no texture, no depth, no lighting, no outline sketch. Every shape has a hard edge and one heavy \
dark keyline of even weight. Bold geometric simplification: few large shapes, wide negative space, \
angular cuts, sharp points. Detail that would vanish at 20 points is left out. Centred in a square \
canvas on a transparent background.

Not: a scene, a landscape, a horizon, scenery behind the subject, a photograph, a 3D render, an \
emblem crowded with small parts, watercolour, airbrush, drop shadow, bevel, glow, halftone, or a \
mock-up on a shirt or a helmet.

Colours: two flat colours that separate from each other and stay legible on both a near-black and \
a mid-grey surface. Black or white only where a keyline or a separation needs it.

No words, letters, initials, numerals, dates, slogans, competition marks, uniforms or watermarks. \
Do not reference or resemble any real school, club, conference, trophy or event identity, and do \
not reproduce any real team's combination of colour and shape.

Output one isolated 256 x 256 PNG with transparency around the mark."""


def nickname_of(record):
    """The nickname a record's brief depicts, read out of the brief itself."""
    match = re.search(r"nickname, the ([A-Za-z]+), and nothing else", record["prompt"])
    if match is None:
        raise SystemExit(f"brief for {record.get('assetName')} names no nickname")
    return match.group(1)


def palette_of(record):
    """The two flats the artwork was drawn in, read out of the brief it was drawn from.

    Not from the old `primaryColorHex` and `secondaryColorHex`: those were the *team's* identity
    colours, and the 2026-08-22 re-key moved teams without moving art, so for 84 of the 137 shipped
    marks they name a palette the picture was never drawn in.
    """
    match = re.search(r"Colours: (#[0-9A-Fa-f]{6}) and (#[0-9A-Fa-f]{6})", record["prompt"])
    if match is None:
        return []
    return [match.group(1), match.group(2)]


# The 2026-08-22 re-key left two notes that describe a team pairing this schema no longer has: one
# saying the mark "depicts this team's nickname", and one saying the team it was shown on had no
# mark of its own. A mark is filed under the nickname its own brief names now, so the first is
# reworded and the second no longer says anything true.
ADOPTED_NOTE = (
    "Codex flat two-colour mark, adopted by the owner on 2026-08-21 as the shipped artwork; it "
    "depicts this nickname."
)


def restated(notes):
    if notes.startswith("Re-brief outstanding."):
        return ADOPTED_NOTE
    return notes.replace("it depicts this team's nickname", "it depicts this nickname")


def carried_forward(manifest):
    """Every existing brief, as a schema-2 mark record."""
    if manifest.get("schemaVersion") == 2:
        return list(manifest["marks"])
    marks = []
    for record in manifest["teams"]:
        marks.append({
            "nickname": nickname_of(record),
            "family": record["family"],
            "concept": record["concept"],
            "prompt": record["prompt"],
            "paletteHex": palette_of(record),
            "assetName": record["assetName"],
            "filename": record["filename"],
            "generationStatus": record["generationStatus"],
            "humanApproved": record["humanApproved"],
            "reviewNotes": restated(record["reviewNotes"]),
        })
    return marks


def main():
    pool = pool_nouns()
    unknown = sorted(set(pool) - set(SUBJECTS))
    if unknown:
        raise SystemExit(f"no subject vocabulary for {unknown}; add it before briefing")

    manifest = json.load(MANIFEST.open())
    marks = carried_forward(manifest)
    retired = [m for m in marks if m["nickname"] not in pool]
    marks = [m for m in marks if m["nickname"] in pool]

    by_nickname = defaultdict(list)
    for mark in marks:
        by_nickname[mark["nickname"]].append(mark)

    # A pending brief takes the family the noun reads strongest in that is also the family the live
    # set is thinnest in, so the shortfall is filled where the catalogue is short rather than where
    # the noun happens to sort.
    families = Counter(m["family"] for m in marks)
    added = 0
    for noun in sorted(pool):
        held = by_nickname[noun]
        if held:
            continue
        order = preferences(noun)
        taken = Counter()
        for _ in range(MARKS_PER_NICKNAME):
            family = min(order, key=lambda f: (taken[f], families[f], order.index(f)))
            index = taken[family]
            taken[family] += 1
            families[family] += 1
            held.append({
                "nickname": noun,
                "family": family,
                "concept": phrasing(family, noun, index).capitalize() + ".",
                "prompt": build_prompt(noun, family, index),
                "paletteHex": [],
                "assetName": None,
                "filename": None,
                "generationStatus": "pending",
                "humanApproved": False,
                "reviewNotes": (
                    "Artwork outstanding. This nickname entered the pool on 2026-08-13, replacing "
                    "a real programme nickname, and no mark has been drawn for it yet. Teams "
                    "carrying it wear the initials chip until one is."
                ),
            })
            added += 1

    out = sorted(
        (m for held in by_nickname.values() for m in held),
        key=lambda m: (m["nickname"], m["family"], m["assetName"] or ""),
    )
    manifest = {"schemaVersion": 2, "marks": out}
    with MANIFEST.open("w") as handle:
        json.dump(manifest, handle, indent=2, sort_keys=True)
        handle.write("\n")

    drawn = sum(1 for m in out if m["generationStatus"] == "approved" and m["humanApproved"])
    print(f"{len(out)} marks over {len(pool)} nicknames: "
          f"{drawn} drawn, {len(out) - drawn} pending ({added} briefed this run)")
    if retired:
        counts = Counter(m["nickname"] for m in retired)
        print(f"dropped {len(retired)} marks for nicknames no longer in the pool: "
              f"{dict(sorted(counts.items()))}")
        for mark in retired:
            print(f"  retired asset {mark['assetName']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
