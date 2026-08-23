import assert from "node:assert/strict";
import test from "node:test";
import { advanceRound, curateCatalog, finalizationStatus, newSession, restoreSession, rewindRound, setSelected } from "./tournament-state.js";

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

test("curation preserves unique team mappings and seeds a 166-style final round", () => {
  const curatedCatalog = {
    fingerprint:"curated-v1",
    teams:[
      { stableID:"alpha", name:"Alpha", assetName:"TeamLogo_alpha" },
      { stableID:"beta", name:"Beta", assetName:"TeamLogo_beta" },
      { stableID:"gamma", name:"Gamma", assetName:"TeamLogo_gamma" },
    ],
    candidates:[
      { id:"a1", teamStableID:"alpha", stages:["canonical"] },
      { id:"a2", teamStableID:"alpha", stages:["raw"] },
      { id:"spare", teamStableID:"beta", stages:["raw"] },
    ],
    heldCandidateIDs:["a2"],
    unassignedCandidateIDs:[],
  };
  const duplicateCatalog = structuredClone(curatedCatalog);
  assert.throws(() => curateCatalog(duplicateCatalog, {
    schemaVersion:1,
    selectedCandidateIDs:["a1", "a1"],
    fillCandidates:[{ id:"fill", sha256:"fill-sha", imagePath:"fill.png" }],
  }), /final 166 curation is invalid/);
  assert.equal(duplicateCatalog.candidates[0].teamStableID, "alpha");

  assert.throws(() => curateCatalog(structuredClone(curatedCatalog), {
    schemaVersion:1,
    selectedCandidateIDs:[],
    fillCandidates:[
      { id:"recolor-a1", sha256:"a1-sha", imagePath:"a1.png", sourceCandidateID:"unknown" },
      { id:"recolor-a2", sha256:"a2-sha", imagePath:"a2.png", sourceCandidateID:"a2" },
      { id:"fill", sha256:"fill-sha", imagePath:"fill.png" },
    ],
  }), /final 166 curation is invalid/);

  curateCatalog(curatedCatalog, {
    schemaVersion:1,
    selectedCandidateIDs:[],
    fillCandidates:[
      { id:"recolor-a1", sha256:"a1-sha", imagePath:"a1.png", sourceCandidateID:"a1" },
      { id:"recolor-a2", sha256:"a2-sha", imagePath:"a2.png", sourceCandidateID:"a2" },
      { id:"fill", sha256:"fill-sha", imagePath:"fill.png", name:"Abstract", family:"abstract" },
    ],
  });
  assert.deepEqual(curatedCatalog.curatedCandidateIDs, ["recolor-a1", "recolor-a2", "fill"]);
  assert.deepEqual(curatedCatalog.curatedCandidateIDs.map((id) => curatedCatalog.candidates.find((candidate) => candidate.id === id).teamStableID), ["alpha", "beta", "gamma"]);
  assert.equal(curatedCatalog.candidates.length, 6);
  assert.equal(curatedCatalog.candidates.find((candidate) => candidate.id === "a1").teamStableID, "alpha");
  assert.deepEqual(newSession(curatedCatalog).rounds.at(-1), { candidateIDs:["recolor-a1", "recolor-a2", "fill"], selectedIDs:[] });
  assert.equal(restoreSession(newSession(curatedCatalog), curatedCatalog).rounds.length, 2);
});
