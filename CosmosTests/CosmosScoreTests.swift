import Testing
@testable import Cosmos

@Test func cosmosScoreComputesFromObjectives() {
    let score = CosmosScore.compute(objectivesSet: 3, objectivesCompleted: 2)
    #expect(score.pathScore == 66)
    #expect(score.total == 66)
    #expect(score.objectivesSet == 3)
    #expect(score.objectivesCompleted == 2)
}

@Test func cosmosScorePerfectCompletion() {
    let score = CosmosScore.compute(objectivesSet: 3, objectivesCompleted: 3)
    #expect(score.total == 100)
}

@Test func cosmosScoreZeroObjectives() {
    let score = CosmosScore.compute(objectivesSet: 0, objectivesCompleted: 0)
    #expect(score.total == 0)
}

@Test func cosmosScoreNoCompletion() {
    let score = CosmosScore.compute(objectivesSet: 3, objectivesCompleted: 0)
    #expect(score.total == 0)
}
