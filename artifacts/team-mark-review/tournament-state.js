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

export function newSession(catalog) {
  return {
    fingerprint: catalog.fingerprint,
    rounds: [{
      candidateIDs: catalog.candidates.filter((candidate) => candidate.teamStableID && candidate.selectionEligible !== false).map((candidate) => candidate.id),
      selectedIDs: [],
    }],
  };
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
  const ineligible = [];
  for (const candidate of chosen) {
    if (candidate.selectionEligible === false) {
      ineligible.push(candidate.id);
      continue;
    }
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
  const ready = chosen.length === catalog.teams.length && !ineligible.length && !unassigned.length && !missingTeamIDs.length && !duplicateTeamIDs.length;
  return { ready, chosen, missingTeamIDs, duplicateTeamIDs, unassigned, ineligible };
}
