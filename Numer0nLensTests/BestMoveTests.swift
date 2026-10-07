//
//  BestMoveTests.swift
//  Numer0nLensTests
//

@testable import Numer0nLens
import XCTest

final class BestMoveTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)

    private func numbers(_ texts: [String], rule: Rule) throws -> [Numer0nNumber] {
        try texts.map { try Numer0nNumber($0, rule: rule) }
    }

    /// ビット表現での判定は、すべての組で judge と一致する（3 桁は全組、4・5 桁は間引いた組）。
    func testPackedJudgeMatchesJudge() {
        for rule in [three, four, Rule(digitCount: .five)] {
            let numbers = rule.allNumbers()
            let step = max(1, numbers.count / 720)
            let sampled = stride(from: 0, to: numbers.count, by: step).map { numbers[$0] }
            let packed = sampled.map(PackedNumber.init)
            for (guess, packedGuess) in zip(sampled, packed) {
                for (answer, packedAnswer) in zip(sampled, packed) {
                    let expected = judge(guess: guess, answer: answer)
                    let actual = packedGuess.judge(answer: packedAnswer)
                    XCTAssertEqual(actual.eat, expected.eat)
                    XCTAssertEqual(actual.bite, expected.bite)
                }
            }
        }
    }

    func testNoCandidatesGivesNoMoves() {
        XCTAssertEqual(BestMove.rankedMoves(rule: three, candidates: []), [])
    }

    func testSingleCandidateIsTheOnlyMove() throws {
        let candidate = try Numer0nNumber("765", rule: three)
        let moves = BestMove.rankedMoves(rule: three, candidates: [candidate])
        XCTAssertEqual(moves.map(\.guess), [candidate])
        XCTAssertEqual(moves[0].entropy, 0)
        XCTAssertTrue(moves[0].isCandidate)
        XCTAssertEqual(moves[0].worstCaseRemaining, 1)
        XCTAssertEqual(moves[0].expectedRemaining, 1)
    }

    func testEvaluateComputesEntropyAndRemainingCounts() throws {
        let candidates = try numbers(["012", "013", "014"], rule: three)
        // 012 → 3EAT / 2EAT / 2EAT に分かれる
        let candidateGuess = BestMove.evaluate(guess: candidates[0], candidates: candidates, isCandidate: true)
        XCTAssertEqual(candidateGuess.entropy, -(1.0 / 3 * log2(1.0 / 3) + 2.0 / 3 * log2(2.0 / 3)), accuracy: 1e-12)
        XCTAssertEqual(candidateGuess.worstCaseRemaining, 2)
        XCTAssertEqual(candidateGuess.expectedRemaining, 5.0 / 3, accuracy: 1e-12)
        // 023 → 1EAT 1BITE / 2EAT / 1EAT に分かれ、3 件すべてを見分けられる
        let split = BestMove.evaluate(guess: try Numer0nNumber("023", rule: three), candidates: candidates, isCandidate: false)
        XCTAssertEqual(split.entropy, log2(3), accuracy: 1e-12)
        XCTAssertEqual(split.worstCaseRemaining, 1)
        XCTAssertEqual(split.expectedRemaining, 1, accuracy: 1e-12)
    }

    /// 候補から外れた数字のほうが情報量が多ければ、そちらを勧める。
    func testRecommendsNonCandidateWhenItIsMoreInformative() throws {
        let candidates = try numbers(["012", "013", "014"], rule: three)
        let moves = BestMove.rankedMoves(rule: three, candidates: candidates)
        XCTAssertEqual(moves.count, 720)
        XCTAssertEqual(moves[0].entropy, log2(3), accuracy: 1e-12)
        XCTAssertFalse(moves[0].isCandidate)
        // 候補の中の手（0.918 bit）は log2(3) bit の手より後ろ
        let bestCandidateIndex = try XCTUnwrap(moves.firstIndex(where: \.isCandidate))
        XCTAssertLessThan(moves[bestCandidateIndex].entropy, log2(3))
    }

    /// 同点なら残り候補の中にある手を優先し、その中では数字の昇順。
    func testTieBreaksByCandidateThenAscending() throws {
        let candidates = try numbers(["021", "012"], rule: three)
        let moves = BestMove.rankedMoves(rule: three, candidates: candidates)
        // 2 件を見分けられる手はどれも 1 bit で同点。候補の 012・021 が先頭に来る
        XCTAssertEqual(moves[0].entropy, 1, accuracy: 1e-12)
        XCTAssertEqual(moves.prefix(2).map(\.guess.description), ["012", "021"])
        XCTAssertTrue(moves[2].entropy < 1 + 1e-9)
        XCTAssertFalse(moves[2].isCandidate)
    }

    func testOrderIsDeterministicAndFollowsTheRule() throws {
        let history: [Numer0nNumber: EatBite] = [try Numer0nNumber("123", rule: three): EatBite(eat: 0, bite: 1)]
        let candidates = three.allNumbers().filter { candidate in
            history.allSatisfy { judge(guess: $0.key, answer: candidate) == $0.value }
        }
        let moves = BestMove.rankedMoves(rule: three, candidates: candidates)
        XCTAssertEqual(moves, BestMove.rankedMoves(rule: three, candidates: candidates.reversed()))
        for (lhs, rhs) in zip(moves, moves.dropFirst()) {
            XCTAssertFalse(BestMove.isBetter(rhs, lhs), "\(rhs.guess) が \(lhs.guess) より後ろにある")
            XCTAssertGreaterThanOrEqual(lhs.entropy + BestMove.entropyTolerance, rhs.entropy)
        }
        XCTAssertEqual(Set(moves.map(\.guess)), Set(three.allNumbers()))
    }

    /// 初手は全探索せずに済ませるが、全探索と同じ評価になる。
    func testFirstMoveShortcutMatchesFullEvaluation() {
        for rule in [three, four] {
            let all = rule.allNumbers()
            let moves = BestMove.rankedMoves(rule: rule, candidates: all)
            XCTAssertEqual(moves.map(\.guess), all, "同点なので数字の昇順")
            for index in [0, all.count / 3, all.count - 1] {
                let full = BestMove.evaluate(guess: all[index], candidates: all, isCandidate: true)
                let shortcut = moves[index]
                XCTAssertEqual(shortcut.entropy, full.entropy, accuracy: 1e-12)
                XCTAssertEqual(shortcut.worstCaseRemaining, full.worstCaseRemaining)
                XCTAssertEqual(shortcut.expectedRemaining, full.expectedRemaining, accuracy: 1e-9)
            }
        }
        // 3 桁の初手で最悪なのは 0EAT 1BITE の 252 件
        XCTAssertEqual(BestMove.rankedMoves(rule: three, candidates: three.allNumbers())[0].worstCaseRemaining, 252)
    }

    func testEmptyGuessesGiveNoMoves() throws {
        let candidates = try numbers(["012", "013", "014"], rule: three)
        XCTAssertEqual(BestMove.rankedMoves(rule: three, candidates: candidates, guesses: []), [])
        // 初手の省略計算の分岐でも落ちない
        XCTAssertEqual(BestMove.rankedMoves(rule: three, candidates: three.allNumbers(), guesses: []), [])
    }

    /// 初手で打てる手を一部に絞っても、各手を個別に評価した結果と一致する。
    func testFirstMoveShortcutWithSubsetOfGuesses() throws {
        let all = three.allNumbers()
        let guesses = try numbers(["987", "012", "504"], rule: three)
        let moves = BestMove.rankedMoves(rule: three, candidates: all, guesses: guesses)
        XCTAssertEqual(moves.map(\.guess.description), ["012", "504", "987"])
        for move in moves {
            let full = BestMove.evaluate(guess: move.guess, candidates: all, isCandidate: true)
            XCTAssertEqual(move.entropy, full.entropy, accuracy: 1e-12)
            XCTAssertEqual(move.worstCaseRemaining, full.worstCaseRemaining)
            XCTAssertEqual(move.expectedRemaining, full.expectedRemaining, accuracy: 1e-9)
        }
    }

    func testCustomGuesses() throws {
        let candidates = try numbers(["012", "013", "014"], rule: three)
        let guesses = try numbers(["012", "023"], rule: three)
        let moves = BestMove.rankedMoves(rule: three, candidates: candidates, guesses: guesses)
        XCTAssertEqual(moves.map(\.guess.description), ["023", "012"])
    }
}
