#!/usr/bin/env python3
"""Rewrite the logo manifest so every mark depicts the team it belongs to.

    python3 Tools/TeamLogos/rewrite_manifest.py <names.json>

`names.json` is the id/name/nickname dump the engine produces for the canonical seed. The manifest
keeps its stable IDs, asset names, filenames and colours; what changes is the public name, the motif
family, and the concept and prompt the artwork is generated from.

Two things were wrong before. The concept was a scene -- "a bold falcon shaped by the Heath
landscape of Altus" -- so the image model drew a landscape with a bird in it rather than a mark.
And the concept had nothing to do with the team's nickname, so the Silver Kestrels carried a
compass roundel. Both are fixed here: the subject is the nickname, and the prompt asks for flat
vector artwork with the scene language removed.
"""

import json
import sys
from collections import Counter

# Every nickname noun the grammar can emit, with the shapes it can legitimately become. A noun
# without a field cannot be drawn that way -- an anchor is not a creature -- and that is what drives
# family assignment below. `emblem` is deliberately universal: anything can sit inside a crest.
SUBJECTS = {
    "Wardens": dict(figure="a warden, hood up and jaw set", tool="a warden's lantern and keyring",
                    emblem="a warden's lantern", place="a boundary post and chain"),
    "Drovers": dict(figure="a drover under a broad-brimmed hat", tool="a drover's crook and yoke",
                    emblem="a crossed crook and yoke", place="a drove-road gate"),
    "Delvers": dict(figure="a delver under a lamped helmet", tool="a short delving pick",
                    emblem="crossed picks", place="a mine-adit arch"),
    "Sentinels": dict(figure="a sentinel in a crested helm", tool="a watch horn",
                      emblem="a watchtower", place="a lone watchtower on a ridge"),
    "Bulwarks": dict(tool="a shield boss", emblem="a bulwark wall",
                     place="a stepped rampart wall"),
    "Foresters": dict(figure="a forester under a hooded cowl", tool="a felling axe",
                      emblem="a crossed axe and pine", place="a stand of three pines"),
    "Marauders": dict(figure="a marauder in a horned half-helm", tool="a boarding hook",
                      emblem="a crossed hook and blade"),
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
    "Harriers": dict(creature="a harrier, wings swept back and talons forward",
                     emblem="a harrier's head"),
    "Stalkers": dict(creature="a stalking cat, head low and shoulders high",
                     figure="a stalker, hood drawn", emblem="a stalking cat's head"),
    "Herons": dict(creature="a heron, neck drawn back to strike", emblem="a heron's head",
                   place="a reed bank"),
    "Colliers": dict(figure="a collier under a lamped helmet", tool="a coal hammer and lamp",
                     emblem="a miner's lamp", place="a pit headframe"),
    "Otters": dict(creature="an otter, head up and jaw open", emblem="an otter's head"),
    "Ironsides": dict(figure="an ironside in a face-plate helm", tool="a riveted hull plate",
                      emblem="a riveted plate", place="an ironclad prow"),
    "Quarrymen": dict(figure="a quarryman under a brimmed hard hat", tool="a sledge and wedge",
                      emblem="a crossed sledge and chisel", place="a quarry step face"),
    "Beacons": dict(tool="a beacon brazier", emblem="a beacon flame",
                    place="a beacon fire on a tower"),
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
    # The wrights and carriers the grammar started emitting after the 2026-08-22 calibration
    # merge moved the world. Without an entry a noun cannot be drawn at all, which is how 52
    # marks ended up carrying the previous occupant's animal.
    "Wainwrights": dict(figure="a wainwright under a flat cap",
                        tool="a wagon wheel and spoke shave",
                        emblem="a crossed adze and draw-knife",
                        place="a wain drawn up at a yard gate"),
    "Wheelwrights": dict(figure="a wheelwright under a brimmed cap", tool="a spoked cartwheel",
                         emblem="a traveller wheel", place="a wheel pit and tyring plate"),
    "Millwrights": dict(figure="a millwright in a rolled cap", tool="a crown gear and pinion",
                        emblem="a cogged wheel", place="a mill wheel at a race"),
    "Bargemen": dict(figure="a bargeman in a knit cap", tool="a tiller and quant pole",
                     emblem="a barge prow", place="a mooring bollard on a cut bank"),
    "Lamplighters": dict(figure="a lamplighter under a soft hat",
                         tool="a lamplighter's pole and wick", emblem="a street lantern",
                         place="a lamp standard at a street corner"),
    "Draymen": dict(figure="a drayman under a wide brim", tool="a dray cart and hames",
                    emblem="a harness collar and rein", place="a brewery yard ramp"),
    "Bitterns": dict(creature="a bittern, neck stretched and bill raised",
                     emblem="a bittern's head", place="a reed bed at a dyke"),
}

FIELD_FOR_FAMILY = {
    "animalCreature": "creature",
    "originalCharacter": "figure",
    "equipmentVehicle": "tool",
    "regionalSymbol": "place",
    "framedEmblem": "emblem",
    "abstractMotion": "emblem",
}

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


FRAMES = ["shield", "roundel", "pennant", "hexagon", "diamond"]

def phrasing(family, noun, index):
    # Every branch falls back to the emblem, because the balance pass below can seat a noun in a
    # family it has no dedicated shape for, and a mark that silently loses its nickname is the
    # defect this whole rewrite exists to remove.
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


def build_prompt(record, family, noun, index):
    subject = phrasing(family, noun, index)
    return f"""Draw one original athletics team mark as flat vector artwork.

Subject: {subject}. The mark depicts the team's nickname, the {noun}, and nothing else.

Style: a single subject filling the frame. Two or three flat colours only. No gradient, no shading, \
no texture, no depth, no lighting, no outline sketch. Every shape has a hard edge and one heavy \
dark keyline of even weight. Bold geometric simplification: few large shapes, wide negative space, \
angular cuts, sharp points. Detail that would vanish at 20 points is left out. Centred in a square \
canvas on a transparent background.

Not: a scene, a landscape, a horizon, scenery behind the subject, a photograph, a 3D render, an \
emblem crowded with small parts, watercolour, airbrush, drop shadow, bevel, glow, halftone, or a \
mock-up on a shirt or a helmet.

Colours: {record['primaryColorHex']} and {record['secondaryColorHex']} as the two dominant flats. \
Black or white only where a keyline or a separation needs it.

No words, letters, initials, numerals, dates, slogans, competition marks, uniforms or watermarks. \
Do not reference or resemble any real school, club, conference, trophy or event identity, and do \
not reproduce any real team's combination of colour and shape.

Output one isolated 256 x 256 PNG with transparency around the mark."""


def main():
    names = {r["id"]: r for r in json.load(open(sys.argv[1]))}
    manifest = json.load(open("Tools/TeamLogos/manifest.json"))
    records = sorted(manifest["teams"], key=lambda t: t["stableID"])
    missing = [r["stableID"] for r in records if r["stableID"] not in names]
    if missing:
        raise SystemExit(f"{len(missing)} manifest records are not in the world dump")

    # 166 across six families is four of 28 and two of 27. Assign first preferences until a family
    # is full, then let the overflow fall to the next shape the noun can actually take.
    capacity = {}
    for position, family in enumerate(sorted(FIELD_FOR_FAMILY)):
        capacity[family] = 28 if position < 4 else 27
    assigned = {}
    for depth in range(6):
        for record in records:
            if record["stableID"] in assigned:
                continue
            noun = names[record["stableID"]]["nickname"].split()[-1]
            order = preferences(noun)
            if depth >= len(order):
                continue
            family = order[depth]
            if capacity[family] > 0:
                capacity[family] -= 1
                assigned[record["stableID"]] = family
    leftovers = [r for r in records if r["stableID"] not in assigned]
    for record in leftovers:
        family = max(capacity, key=lambda f: capacity[f])
        capacity[family] -= 1
        assigned[record["stableID"]] = family

    counts = Counter(assigned.values())
    if any(count not in (27, 28) for count in counts.values()) or len(counts) != 6:
        raise SystemExit(f"family balance is wrong: {dict(counts)}")

    per_family_index = Counter()
    stale = 0
    for record in records:
        entry = names[record["stableID"]]
        noun = entry["nickname"].split()[-1]
        family = assigned[record["stableID"]]
        index = per_family_index[family]
        per_family_index[family] += 1
        record["name"] = entry["name"]
        record["abbreviation"] = "".join(c for c in entry["name"] if c.isalpha())[:3].upper()
        record["family"] = family
        record["concept"] = phrasing(family, noun, index).capitalize() + "."
        previous = record["prompt"]
        record["prompt"] = build_prompt(record, family, noun, index)
        # The packaged PNG was drawn from the prompt this record used to carry. If that prompt
        # has moved -- a different subject, a different nickname, or the colours the brief names
        # as its two flats -- the artwork on disk no longer depicts this team and the record is
        # not approved any more. Saying so here is the point: the run that produced this manifest
        # last time left every record marked approved, so 113 marks shipped either depicting a
        # nickname the team no longer has or drawn in colours that are no longer its own, and the
        # suite reported the catalogue as complete and approved throughout.
        #
        # Records whose prompt is unchanged keep their status and their review notes, which carry
        # per-mark contrast findings this pass has no business discarding.
        if record["prompt"] != previous:
            record["generationStatus"] = "pending"
            record["humanApproved"] = False
            record["reviewNotes"] = (
                "Brief rewritten from this team's own nickname and colours; the packaged artwork "
                "still shows the concept this record carried before and must be regenerated "
                "before the record can be approved again."
            )
            stale += 1

    manifest["teams"] = records
    with open("Tools/TeamLogos/manifest.json", "w") as handle:
        json.dump(manifest, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print(f"rewrote {len(records)} records; families {dict(sorted(counts.items()))}")
    print(f"{stale} need new artwork and are no longer approved; "
          f"{len(records) - stale} keep their approved mark")


if __name__ == "__main__":
    main()
