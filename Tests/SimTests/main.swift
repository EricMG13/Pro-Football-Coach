// Test entry point. Add each new suite's runner here.
if CommandLine.arguments.contains("--event-ledger-batch") {
    runEventLedgerBatchTests()
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
} else if CommandLine.arguments.contains("--career-arc") {
    runCareerArcTests()
} else if CommandLine.arguments.contains("--pro-management") {
    runProManagementTests()
} else if CommandLine.arguments.contains("--pro-market") {
    runProMarketTests()
} else if CommandLine.arguments.contains("--history-read-model") {
    runHistoryReadModelTests()
} else if CommandLine.arguments.contains("--career-portal-decisions") {
    runCareerPortalDecisionTests()
} else if CommandLine.arguments.contains("--tactical-management") {
    runTacticalManagementTests()
} else if CommandLine.arguments.contains("--tactical-state") {
    runTacticalStateTests()
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
} else if CommandLine.arguments.contains("--redshirt-only") {
    runCollegeRedshirtTests()
} else if CommandLine.arguments.contains("--college-commitments") {
    runCollegeCommitmentTests()
} else if CommandLine.arguments.contains("--college-state") {
    runCollegeStateTests()
} else if CommandLine.arguments.contains("--people-lifecycle") {
    runPeopleLifecycleTests()
} else if CommandLine.arguments.contains("--core-contracts") {
    runSeededRandomTests()
    runSeedDerivationTests()
    runContractTests()
    runDesignContractTests()
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
} else if CommandLine.arguments.contains("--architecture-only") {
    runArchitectureTests()
} else if CommandLine.arguments.contains("--m2-soak") {
    runM2SoakTests(seasons: 20)
} else if CommandLine.arguments.contains("--m1-soak") {
    runM1SoakTests(seasons: 20)
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
    runProgrammeEvolutionTests()
    runCareerPortalDecisionTests()
    runTacticalManagementTests()
    runTacticalStateTests()
    runPortalContractTests()
    runEventLedgerBatchTests()
}

TestKit.finish()
