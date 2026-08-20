// Test entry point. Add each new suite's runner here.

// Unbuffered, so the per-suite lines `TestKit.suite` now prints reach the log as they happen.
//
// `print` is line-buffered on a terminal and fully buffered down a pipe, which is how every
// automated run reads it. Together with the per-suite reporting, this is what turns an aborted run
// from a two-line log into an account of where it got to.
import Foundation
setvbuf(stdout, nil, _IONBF, 0)
if CommandLine.arguments.contains("--catalog") {
    SuiteCatalog.printCatalog()
} else if CommandLine.arguments.contains("--commitment-coverage") {
    runCommitmentCoverageTest()
} else if CommandLine.arguments.contains("--save-document") {
    runSaveDocumentTests()
} else if CommandLine.arguments.contains("--event-ledger-batch") {
    runEventLedgerBatchTests()
} else if CommandLine.arguments.contains("--roster-population") {
    runRosterPopulationTests()
} else if CommandLine.arguments.contains("--trait-population") {
    runTraitPopulationTests()
} else if CommandLine.arguments.contains("--portal-matching") {
    runPortalMatchingTests()
} else if CommandLine.arguments.contains("--portal-transaction") {
    runPortalTransactionTests()
} else if CommandLine.arguments.contains("--portal-scheduler") {
    runPortalSchedulerTests()
} else if CommandLine.arguments.contains("--career-control") {
    runCareerControlTests()
} else if CommandLine.arguments.contains("--weekly-authority") {
    runWeeklyAuthorityTests()
} else if CommandLine.arguments.contains("--professional-career-session") {
    runProfessionalCareerSessionTests()
} else if CommandLine.arguments.contains("--career-arc") {
    runCareerArcTests()
} else if CommandLine.arguments.contains("--pro-management") {
    runProManagementTests()
} else if CommandLine.arguments.contains("--pro-market") {
    runProMarketTests()
} else if CommandLine.arguments.contains("--cap-compliance") {
    runCapComplianceTests()
} else if CommandLine.arguments.contains("--season-rollover") {
    runSeasonRolloverTests()
} else if CommandLine.arguments.contains("--jersey-numbers") {
    runJerseyNumberTests()
} else if CommandLine.arguments.contains("--depth-chart") {
    runDepthChartTests()
} else if CommandLine.arguments.contains("--discipline") {
    runDisciplineTests()
} else if CommandLine.arguments.contains("--week-advance-timing") {
    runWeekAdvanceTimingProbe()
} else if CommandLine.arguments.contains("--pro-market-root-probe") {
    runProMarketRootProbe()
} else if CommandLine.arguments.contains("--screen-read-models") {
    runReadModelProviderTests()
} else if CommandLine.arguments.contains("--history-read-model") {
    runHistoryReadModelTests()
} else if CommandLine.arguments.contains("--career-portal-decisions") {
    runCareerPortalDecisionTests()
} else if CommandLine.arguments.contains("--tactical-management") {
    runTacticalManagementTests()
} else if CommandLine.arguments.contains("--tactical-state") {
    runTacticalStateTests()
} else if CommandLine.arguments.contains("--match-reducer") {
    runMatchReducerTests()
} else if CommandLine.arguments.contains("--engine") {
    runEngineTests()
    runGameLoopTests()
} else if CommandLine.arguments.contains("--m3-soak") {
    runM3CollegeSoakTests()
} else if CommandLine.arguments.contains("--portal-policy") {
    runPortalPolicyTests()
} else if CommandLine.arguments.contains("--portal-contracts") {
    runPortalContractTests()
} else if CommandLine.arguments.contains("--redshirt-invalid-college-career-games-probe") {
    runInvalidRedshirtCareerGamesProbe(tier: .college)
} else if CommandLine.arguments.contains("--redshirt-invalid-pro-career-games-probe") {
    runInvalidRedshirtCareerGamesProbe(tier: .pro)
} else if CommandLine.arguments.contains("--m3-recruiting-calibration") {
    runM3RecruitingCalibrationTests()
} else if CommandLine.arguments.contains("--calibration") {
    runCalibrationTests()
} else if CommandLine.arguments.contains("--redshirt-only") {
    runCollegeRedshirtTests()
} else if CommandLine.arguments.contains("--college-commitments") {
    runCollegeCommitmentTests()
} else if CommandLine.arguments.contains("--college-state") {
    runCollegeStateTests()
} else if CommandLine.arguments.contains("--college-acquisition-invariant") {
    runCollegeAcquisitionInvariantTests()
} else if CommandLine.arguments.contains("--injury-evidence") {
    runInjuryEvidenceTests()
} else if CommandLine.arguments.contains("--people-lifecycle") {
    runPeopleLifecycleTests()
} else if CommandLine.arguments.contains("--core-contracts") {
    runSeededRandomTests()
    runSeedDerivationTests()
    runContractTests()
    runDesignContractTests()
    runMotionContractTests()
    runAccessibilityReflowTests()
    runReduceMotionContractTests()
    runSaveEnvelopeTests()
    runRulesTests()
    runModelTests()
} else if CommandLine.arguments.contains("--rivalry-order") {
    runRivalryOrderTests()
} else if CommandLine.arguments.contains("--coaching-tree") {
    runCoachingTreeTests()
} else if CommandLine.arguments.contains("--history-archive") {
    runHistoryArchiveTests()
} else if CommandLine.arguments.contains("--news-feed") {
    runNewsFeedTests()
} else if CommandLine.arguments.contains("--programme-evolution") {
    runProgrammeEvolutionTests()
} else if CommandLine.arguments.contains("--roster-tenure") {
    runRosterTenureTests()
} else if CommandLine.arguments.contains("--realignment") {
    runRealignmentTests()
} else if CommandLine.arguments.contains("--m7-gate") {
    runHistoryGateTests()
} else if CommandLine.arguments.contains("--pro-soak") {
    runProSoakTests()
} else if CommandLine.arguments.contains("--pro-draft-probe") {
    runProDraftProbeTests()
} else if CommandLine.arguments.contains("--pro-week-walk") {
    runProWeekWalkTests()
} else if CommandLine.arguments.contains("--legal-only") {
    runLegalTests()
} else if CommandLine.arguments.contains("--competition-only") {
    runCompetitionTests()
} else if CommandLine.arguments.contains("--generation-only") {
    runGenerationTests()
} else if CommandLine.arguments.contains("--design-contracts") {
    runDesignContractTests()
    runMotionContractTests()
    runAccessibilityReflowTests()
    runReduceMotionContractTests()
} else if CommandLine.arguments.contains("--architecture-only") {
    runArchitectureTests()
} else if CommandLine.arguments.contains("--m2-soak") {
    runM2SoakTests(seasons: 20)
} else if CommandLine.arguments.contains("--m1-soak") {
    runM1SoakTests(seasons: 20)
} else if CommandLine.arguments.contains("--snap-anchors") {
    runSnapAnchorTests()
} else if CommandLine.arguments.contains("--reduce-motion") {
    runReduceMotionContractTests()
} else {
    runSeededRandomTests()
    runSeedDerivationTests()
    runContractTests()
    runSaveEnvelopeTests()
    runRulesTests()
    runModelTests()
    runLegalTests()
    runGenerationTests()
    runIdentityDistributionTests()
    runEngineTests()
    runSnapResolverTests()
    runSnapAnchorTests()
    runGameLoopTests()
    runCalibrationTests()
    runArchitectureTests()
    runCompetitionTests()
    runRosterPopulationTests()
    runTraitPopulationTests()
    runPeopleLifecycleTests()
    runCollegeStateTests()
    runCollegeCommitmentTests()
    runCollegeRedshirtTests()
    runCollegeAcquisitionInvariantTests()
    runPortalPolicyTests()
    runPortalMatchingTests()
    runPortalTransactionTests()
    runPortalSchedulerTests()
    runCareerControlTests()
    runCareerArcTests()
    runProManagementTests()
    runProMarketTests()
    runHistoryReadModelTests()
    runRivalryOrderTests()
    runCoachingTreeTests()
    runHistoryArchiveTests()
    runNewsFeedTests()
    runDisciplineTests()
    runProgrammeEvolutionTests()
    runRosterTenureTests()
    runRealignmentTests()
    runCareerPortalDecisionTests()
    runTacticalManagementTests()
    runTacticalStateTests()
    runMatchReducerTests()
    runPortalContractTests()
    runEventLedgerBatchTests()
    runJerseyNumberTests()
    runDepthChartTests()
    runReadModelProviderTests()
    runCapComplianceTests()
    runSeasonRolloverTests()
    // The M8 entry-gate instruments. They ran only under `--design-contracts` and
    // `--core-contracts` until 2026-08-13, so the no-argument run — the one `verify.sh` makes and
    // the one every release claim quotes — did not include the orientation policy, the token sync,
    // the symbol register, the sheet lint or the AX5 contract.
    runDesignContractTests()
    runMotionContractTests()
    runAccessibilityReflowTests()
    runReduceMotionContractTests()
    runCommitmentCoverageTest()
    runSaveDocumentTests()
}

TestKit.finish()
