import assert from "node:assert/strict";
import test from "node:test";
import { advanceRound, finalizationStatus, newSession, restoreSession, rewindRound, setSelected } from "./tournament-state.js";

const catalog = {
  fingerprint: "catalog-v1",
  teams: [
    { stableID: "alpha", name: "Alpha" },
    { stableID: "beta", name: "Beta" },
  ],
  candidates: [
    { id: "a1", teamStableID: "alpha" },
    { id: "a2", teamStableID: "alpha" },
    { id: "b1", teamStableID: "beta" },
  ],
};

test("advance snapshots checked candidates and rewind restores the prior choice", () => {
  let session = newSession(catalog);
  session = setSelected(session, "a1", true);
  session = setSelected(session, "b1", true);
  session = advanceRound(session);
  assert.deepEqual(session.rounds.at(-1), { candidateIDs: ["a1", "b1"], selectedIDs: [] });
  assert.deepEqual(rewindRound(session).rounds.at(-1).selectedIDs, ["a1", "b1"]);
});

test("changing a previous round discards later snapshots", () => {
  let session = setSelected(newSession(catalog), "a1", true);
  session = advanceRound(session);
  session = setSelected(session, "a1", true);
  session = rewindRound(session);
  session = setSelected(session, "a2", true);
  assert.equal(session.rounds.length, 1);
  assert.deepEqual(session.rounds[0].selectedIDs, ["a1", "a2"]);
});

test("final export requires exactly one choice for each team", () => {
  let session = setSelected(newSession(catalog), "a1", true);
  session = setSelected(session, "b1", true);
  assert.equal(finalizationStatus(session, catalog).ready, true);
  session = setSelected(session, "a2", true);
  const status = finalizationStatus(session, catalog);
  assert.equal(status.ready, false);
  assert.deepEqual(status.duplicateTeamIDs, ["alpha"]);
});

test("stale or malformed local state is rejected", () => {
  assert.equal(restoreSession('{"fingerprint":"old","rounds":[]}', catalog), null);
  assert.equal(restoreSession({ fingerprint: catalog.fingerprint, rounds: [{ candidateIDs: ["unknown"], selectedIDs: [] }] }, catalog), null);
  assert.equal(restoreSession({ fingerprint: catalog.fingerprint, rounds: [{ candidateIDs: ["a1"], selectedIDs: [] }] }, catalog), null);
  assert.equal(restoreSession(newSession(catalog), catalog).fingerprint, catalog.fingerprint);
});

test("full inventory variants enter the tournament and can finalize", () => {
  const reviewedCatalog = {
    ...catalog,
    candidates: [...catalog.candidates, { id: "held", teamStableID: "alpha", selectionEligible: false }],
  };
  assert.equal(newSession(reviewedCatalog).rounds[0].candidateIDs.includes("held"), true);
  let session = setSelected(newSession(reviewedCatalog), "held", true);
  session = setSelected(session, "b1", true);
  assert.equal(finalizationStatus(session, reviewedCatalog).ready, true);
});

test("reviewed variants seed the curated first round", () => {
  const reviewedCatalog = {
    ...catalog,
    candidates: [
      { id: "reviewed", teamStableID: "alpha", selectionEligible: true },
      { id: "held", teamStableID: "alpha", selectionEligible: false },
      { id: "unassigned", teamStableID: null, selectionEligible: false },
    ],
  };
  assert.deepEqual(newSession(reviewedCatalog).rounds[0], {
    candidateIDs: ["reviewed", "held", "unassigned"],
    selectedIDs: ["reviewed"],
  });
});

test("a saved session from a narrower inventory is reset", () => {
  const fullCatalog = { ...catalog, candidates: [...catalog.candidates, { id: "held", teamStableID: "alpha", selectionEligible: false }] };
  const legacySession = { fingerprint: fullCatalog.fingerprint, rounds: [{ candidateIDs: ["a1", "a2", "b1"], selectedIDs: ["a1"] }] };
  assert.equal(restoreSession(legacySession, fullCatalog), null);
});

test("unassigned variants can advance but cannot occupy a final team slot", () => {
  const fullCatalog = { ...catalog, candidates: [...catalog.candidates, { id: "unknown", teamStableID: null }] };
  let session = setSelected(newSession(fullCatalog), "a1", true);
  session = setSelected(session, "b1", true);
  session = setSelected(session, "unknown", true);
  const status = finalizationStatus(session, fullCatalog);
  assert.deepEqual(status.unassigned, ["unknown"]);
  assert.equal(status.ready, false);
});
