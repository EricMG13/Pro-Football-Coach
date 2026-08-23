function candidateMap(catalog) {
  return new Map(catalog.candidates.map((candidate) => [candidate.id, candidate]));
}

function copyRound(round) {
  return {
    candidateIDs: [...round.candidateIDs],
    selectedIDs: [...round.selectedIDs],
  };
}

function copySession(session) {
  return { fingerprint: session.fingerprint, rounds: session.rounds.map(copyRound) };
}

export function curateCatalog(catalog, curation) {
  const candidateByID = candidateMap(catalog);
  const selectedIDs = curation?.selectedCandidateIDs;
  const fillCandidates = curation?.fillCandidates;

  if (
    curation?.schemaVersion !== 1 ||
    !Array.isArray(selectedIDs) ||
    !Array.isArray(fillCandidates)
  ) {
    throw new Error("final 166 curation is invalid");
  }

  if (
    selectedIDs.length + fillCandidates.length !== catalog.teams.length ||
    new Set(selectedIDs).size !== selectedIDs.length ||
    selectedIDs.some((id) => !candidateByID.get(id)) ||
    fillCandidates.some(
      (fill) =>
        !fill?.id ||
        !fill.sha256 ||
        !fill.imagePath ||
        candidateByID.has(fill.id) ||
        (fill.sourceCandidateID && !candidateByID.has(fill.sourceCandidateID)),
    ) ||
    new Set(fillCandidates.map((fill) => fill.id)).size !== fillCandidates.length
  ) {
    throw new Error("final 166 curation is invalid");
  }

  const selectedCandidates = selectedIDs.map((id) => candidateByID.get(id));
  const sourceCandidates = fillCandidates
    .map((fill) => candidateByID.get(fill.sourceCandidateID))
    .filter(Boolean);

  const teamByID = new Map(catalog.teams.map((team) => [team.stableID, team]));
  const reservedTeamIDs = new Set(
    [...selectedCandidates, ...sourceCandidates]
      .map((candidate) => candidate.teamStableID)
      .filter((id) => teamByID.has(id)),
  );
  const availableTeams = catalog.teams.filter(
    (team) => !reservedTeamIDs.has(team.stableID),
  );
  const assignedTeamIDs = new Set();

  const curate = (candidate) => {
    const originalTeamID = candidate.teamStableID;
    const team =
      originalTeamID && !assignedTeamIDs.has(originalTeamID)
        ? teamByID.get(originalTeamID)
        : availableTeams.shift();
    if (!team) {
      throw new Error("final 166 curation cannot assign every logo to a unique team");
    }

    assignedTeamIDs.add(team.stableID);
    Object.assign(candidate, {
      teamStableID:team.stableID,
      assetName:team.assetName,
      selectionEligible:true,
      qualityStatus:"reviewed",
    });
    candidate.stages = [...new Set([...(candidate.stages || []), "curated"])];
    return candidate.id;
  };

  const curatedCandidateIDs = selectedCandidates.map(curate);
  for (const fill of fillCandidates) {
    const sourceCandidate = candidateByID.get(fill.sourceCandidateID);
    const candidate = {
      ...fill,
      teamStableID:sourceCandidate?.teamStableID || null,
      assetName:sourceCandidate?.assetName || null,
      stages:sourceCandidate
        ? ["recolored", "curated"]
        : ["generated", "normalized", "curated"],
      stage:sourceCandidate ? "recolored" : "curated",
      selectionEligible:true,
      qualityStatus:"reviewed",
      origins:[{
        kind:"worktree",
        path:`artifacts/team-mark-review/${fill.imagePath}`,
        stage:"curated",
        worktree:".",
      }],
    };
    catalog.candidates.push(candidate);
    candidateByID.set(candidate.id, candidate);
    curatedCandidateIDs.push(curate(candidate));
  }

  const curatedIDs = new Set(curatedCandidateIDs);
  catalog.heldCandidateIDs = (catalog.heldCandidateIDs || []).filter((id) => !curatedIDs.has(id));
  catalog.unassignedCandidateIDs = (catalog.unassignedCandidateIDs || []).filter((id) => !curatedIDs.has(id));
  catalog.curatedCandidateIDs = curatedCandidateIDs;
  return catalog;
}

export function newSession(catalog) {
  const curatedIDs = catalog.curatedCandidateIDs;
  const candidateIDs = catalog.candidates.map((candidate) => candidate.id);
  const selectedIDs = curatedIDs || catalog.candidates.filter((candidate) => candidate.selectionEligible === true).map((candidate) => candidate.id);
  const rounds = [{ candidateIDs, selectedIDs:[...selectedIDs] }];
  if (curatedIDs) rounds.push({ candidateIDs:[...selectedIDs], selectedIDs:[] });
  return { fingerprint:catalog.fingerprint, rounds };
}

export function restoreSession(raw, catalog) {
  try {
    const session = typeof raw === "string" ? JSON.parse(raw) : raw;
    const knownIDs = candidateMap(catalog);
    const firstRoundIDs = newSession(catalog).rounds[0].candidateIDs;
    if (!session || session.fingerprint !== catalog.fingerprint || !Array.isArray(session.rounds) || !session.rounds.length) {
      return null;
    }
    for (const [index, round] of session.rounds.entries()) {
      if (!Array.isArray(round.candidateIDs) || !Array.isArray(round.selectedIDs)) return null;
      const candidateIDs = new Set(round.candidateIDs);
      if (candidateIDs.size !== round.candidateIDs.length || round.candidateIDs.some((id) => !knownIDs.has(id))) return null;
      if (round.selectedIDs.some((id) => !candidateIDs.has(id))) return null;
      const expectedIDs = index ? session.rounds[index - 1].selectedIDs : firstRoundIDs;
      if (round.candidateIDs.length !== expectedIDs.length || round.candidateIDs.some((id, position) => id !== expectedIDs[position])) return null;
    }
    return copySession(session);
  } catch {
    return null;
  }
}

export function currentRound(session) {
  return session.rounds.at(-1);
}

export function setSelected(session, candidateID, checked) {
  const next = copySession(session);
  const round = currentRound(next);
  if (!round.candidateIDs.includes(candidateID)) return next;
  const selected = new Set(round.selectedIDs);
  checked ? selected.add(candidateID) : selected.delete(candidateID);
  round.selectedIDs = round.candidateIDs.filter((id) => selected.has(id));
  return next;
}

export function advanceRound(session) {
  const next = copySession(session);
  const selectedIDs = currentRound(next).selectedIDs;
  if (!selectedIDs.length) return next;
  next.rounds.push({ candidateIDs: [...selectedIDs], selectedIDs: [] });
  return next;
}

export function rewindRound(session) {
  if (session.rounds.length === 1) return copySession(session);
  return { fingerprint: session.fingerprint, rounds: session.rounds.slice(0, -1).map(copyRound) };
}

export function finalizationStatus(session, catalog) {
  const candidates = candidateMap(catalog);
  const chosen = currentRound(session).selectedIDs.map((id) => candidates.get(id)).filter(Boolean);
  const byTeam = new Map();
  const unassigned = [];
  for (const candidate of chosen) {
    if (!candidate.teamStableID) {
      unassigned.push(candidate.id);
      continue;
    }
    const selections = byTeam.get(candidate.teamStableID) || [];
    selections.push(candidate.id);
    byTeam.set(candidate.teamStableID, selections);
  }
  const missingTeamIDs = catalog.teams.filter((team) => !byTeam.has(team.stableID)).map((team) => team.stableID);
  const duplicateTeamIDs = [...byTeam].filter(([, ids]) => ids.length > 1).map(([teamID]) => teamID);
  const ready = chosen.length === catalog.teams.length && !unassigned.length && !missingTeamIDs.length && !duplicateTeamIDs.length;
  return { ready, chosen, missingTeamIDs, duplicateTeamIDs, unassigned };
}
