//
//  ProgressComparisonTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class ProgressComparisonTests: XCTestCase {
    func testFewerRemainingCandidatesLeads() {
        XCTAssertEqual(ProgressComparison(myRemaining: 12, opponentRemaining: 40).status, .inProgress(.me))
        XCTAssertEqual(ProgressComparison(myRemaining: 40, opponentRemaining: 12).status, .inProgress(.opponent))
        XCTAssertEqual(ProgressComparison(myRemaining: 7, opponentRemaining: 7).status, .inProgress(.even))
    }

    func testSolvedTakesPriority() {
        XCTAssertEqual(ProgressComparison(myRemaining: 1, opponentRemaining: 100, iSolved: true).status, .iSolved)
        XCTAssertEqual(ProgressComparison(myRemaining: 100, opponentRemaining: 1, opponentSolved: true).status, .opponentSolved)
        XCTAssertEqual(ProgressComparison(myRemaining: 1, opponentRemaining: 1, iSolved: true, opponentSolved: true).status, .bothSolved)
    }

    func testContradictionIsUndetermined() {
        XCTAssertEqual(ProgressComparison(myRemaining: 0, opponentRemaining: 10).status, .undetermined)
        XCTAssertEqual(ProgressComparison(myRemaining: 10, opponentRemaining: 0).status, .undetermined)
    }

    func testRemainingBits() {
        XCTAssertEqual(ProgressComparison.bits(for: 1), 0)
        XCTAssertEqual(ProgressComparison.bits(for: 8), 3, accuracy: 1e-12)
        XCTAssertEqual(ProgressComparison.bits(for: 720), log2(720), accuracy: 1e-12)
        XCTAssertEqual(ProgressComparison.bits(for: 0), 0)
        let comparison = ProgressComparison(myRemaining: 16, opponentRemaining: 2)
        XCTAssertEqual(comparison.myRemainingBits, 4, accuracy: 1e-12)
        XCTAssertEqual(comparison.opponentRemainingBits, 1, accuracy: 1e-12)
    }

    func testFromGameState() throws {
        let game = GameState(digitCount: .three)
        XCTAssertEqual(ProgressComparison(game: game).status, .inProgress(.even))

        let rule = game.rule
        game.myDeduction.addCall(guess: try Numer0nNumber("012", rule: rule), result: try EatBite(eat: 0, bite: 3, rule: rule))
        let afterMyCall = ProgressComparison(game: game)
        XCTAssertEqual(afterMyCall.myRemaining, 2)
        XCTAssertEqual(afterMyCall.opponentRemaining, 720)
        XCTAssertEqual(afterMyCall.status, .inProgress(.me))

        game.opponentDeduction.addCall(guess: try Numer0nNumber("345", rule: rule), result: try EatBite(eat: 3, bite: 0, rule: rule))
        XCTAssertEqual(ProgressComparison(game: game).status, .opponentSolved)
    }
}
