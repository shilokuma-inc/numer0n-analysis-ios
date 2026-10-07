//
//  BestMoveSearchTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class BestMoveSearchTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)
    private let five = Rule(digitCount: .five)

    /// 1 回目のコールの後で最も候補が多く残る回答（3・4 桁は 0EAT 1BITE、5 桁は 0EAT 2BITE）の後の候補。
    private func candidatesAfterFirstCall(_ rule: Rule) -> [Numer0nNumber] {
        let first = rule.allNumbers()[0]
        let bite = rule.digitCount == .five ? 2 : 1
        return rule.candidates(matching: [.call(guess: first, result: EatBite(eat: 0, bite: bite))])
    }

    func testWorstSecondMoveCandidateCounts() {
        XCTAssertEqual(candidatesAfterFirstCall(three).count, 252)
        XCTAssertEqual(candidatesAfterFirstCall(four).count, 1_440)
        XCTAssertEqual(candidatesAfterFirstCall(five).count, 7_800)
    }

    func testDefaultStrategy() {
        XCTAssertEqual(BestMoveSearch.defaultStrategy(for: three), .exhaustive)
        XCTAssertEqual(BestMoveSearch.defaultStrategy(for: four), .exhaustive)
        XCTAssertEqual(BestMoveSearch.defaultStrategy(for: five), .sampled(.standard))
    }

    func testExhaustiveMatchesSynchronousRanking() async throws {
        let candidates = candidatesAfterFirstCall(three)
        let result = try await BestMoveSearch.search(rule: three, candidates: candidates)
        XCTAssertFalse(result.isApproximate)
        XCTAssertEqual(result.moves, BestMove.rankedMoves(rule: three, candidates: candidates))
        XCTAssertEqual(result.evaluatedGuessCount, 720)
        XCTAssertEqual(result.evaluatedCandidateCount, 252)
    }

    func testSmallCasesAreExact() async throws {
        let empty = try await BestMoveSearch.search(rule: five, candidates: [])
        XCTAssertEqual(empty.moves, [])
        let single = try Numer0nNumber("01234", rule: five)
        let one = try await BestMoveSearch.search(rule: five, candidates: [single])
        XCTAssertEqual(one.moves.map(\.guess), [single])
        // 5 桁の初手は省略計算で全手を正確に出す
        let first = try await BestMoveSearch.search(rule: five, candidates: five.allNumbers())
        XCTAssertFalse(first.isApproximate)
        XCTAssertEqual(first.moves.count, 30_240)
        XCTAssertEqual(first.moves[0].guess.description, "01234")
    }

    /// 種を固定すれば近似の結果は毎回同じ。
    func testSampledIsDeterministicWithFixedSeed() throws {
        let candidates = candidatesAfterFirstCall(five)
        let options = BestMoveSearch.SamplingOptions(guessSampleCount: 200, candidateGuessSampleCount: 50, candidateSampleCount: 300, seed: 42)
        let first = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .sampled(options))
        let second = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .sampled(options))
        XCTAssertEqual(first, second)
        XCTAssertTrue(first.isApproximate)
        XCTAssertEqual(first.evaluatedCandidateCount, 300)
        XCTAssertLessThanOrEqual(first.evaluatedGuessCount, 250)
        XCTAssertGreaterThanOrEqual(first.evaluatedGuessCount, 200)
        XCTAssertTrue(first.moves.contains(where: \.isCandidate), "候補の中の手が混ざる")
        XCTAssertEqual(first.moves, first.moves.sorted(by: BestMove.isBetter))

        var differentSeed = options
        differentSeed.seed = 43
        let other = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .sampled(differentSeed))
        XCTAssertNotEqual(Set(first.moves.map(\.guess)), Set(other.moves.map(\.guess)))
    }

    /// 近似の最悪・期待値の残り候補数は全体の件数に換算される。
    func testSampledScalesRemainingCounts() throws {
        let candidates = candidatesAfterFirstCall(five)
        let options = BestMoveSearch.SamplingOptions(guessSampleCount: 50, candidateGuessSampleCount: 10, candidateSampleCount: 500, seed: 7)
        let result = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .sampled(options))
        for move in result.moves {
            XCTAssertLessThanOrEqual(move.worstCaseRemaining, candidates.count + 1)
            XCTAssertLessThanOrEqual(move.expectedRemaining, Double(candidates.count) + 1)
            XCTAssertGreaterThan(move.expectedRemaining, 0)
        }
    }

    /// 候補がサンプル数より少なければ、候補はすべて使う。
    func testSampledUsesAllCandidatesWhenFew() throws {
        let candidates = Array(candidatesAfterFirstCall(five).prefix(100))
        let result = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .sampled(.standard))
        XCTAssertEqual(result.evaluatedCandidateCount, 100)
        XCTAssertTrue(candidates.allSatisfy { candidate in result.moves.contains { $0.guess == candidate } }, "候補はすべて手として評価される")
    }

    func testSampleHelper() {
        var generator = SeededRandomNumberGenerator(seed: 1)
        let picked = BestMoveSearch.sample(Array(0..<100), count: 10, using: &generator)
        XCTAssertEqual(picked.count, 10)
        XCTAssertEqual(Set(picked).count, 10)
        XCTAssertEqual(BestMoveSearch.sample([1, 2, 3], count: 10, using: &generator), [1, 2, 3])
    }

    /// 呼び出し元の Task をキャンセルすると、計算が止まり CancellationError を投げる。
    func testCancellationStopsComputation() async throws {
        let candidates = candidatesAfterFirstCall(five)
        let task = Task {
            try await BestMoveSearch.search(rule: five, candidates: candidates, strategy: .exhaustive)
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        let started = Date()
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("キャンセルされずに最後まで計算した")
        } catch is CancellationError {
            XCTAssertLessThan(Date().timeIntervalSince(started), 2, "キャンセル後すぐに止まる")
        }
    }

    /// 計算はメインスレッドで行わない。
    @MainActor
    func testRunsOffMainThread() async throws {
        let candidates = candidatesAfterFirstCall(three)
        let ticker = Task { @MainActor in
            var ticks = 0
            while !Task.isCancelled {
                ticks += 1
                await Task.yield()
            }
            return ticks
        }
        _ = try await BestMoveSearch.search(rule: three, candidates: candidates)
        ticker.cancel()
        let ticks = await ticker.value
        XCTAssertGreaterThan(ticks, 0, "計算中もメインアクターが動いている")
    }

    /// 5 桁の近似で選んだ手は、全探索の最善手とほぼ同じ情報量を持つ。
    func testSampledBestMoveIsCloseToExhaustive() throws {
        let candidates = candidatesAfterFirstCall(five)
        let exact = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .exhaustive)
        let approximate = try BestMoveSearch.compute(rule: five, candidates: candidates, strategy: .sampled(.standard))
        let chosen = try XCTUnwrap(approximate.moves.first).guess
        let chosenExactEntropy = BestMove.evaluate(guess: chosen, candidates: candidates, isCandidate: false).entropy
        let bestEntropy = try XCTUnwrap(exact.moves.first).entropy
        print("[accuracy] 5 桁: 近似で選んだ手 \(chosen) の正確な情報量 \(String(format: "%.4f", chosenExactEntropy)) bit / 全探索の最善 \(String(format: "%.4f", bestEntropy)) bit")
        XCTAssertGreaterThan(chosenExactEntropy, bestEntropy - 0.05)
    }

    /// 計算時間の目安を出す（PR に記録するため。失敗はさせない）。
    func testReportTimings() throws {
        for (rule, strategy) in [(four, BestMoveSearch.Strategy.exhaustive), (five, .sampled(.standard)), (five, .exhaustive)] {
            let candidates = candidatesAfterFirstCall(rule)
            let started = Date()
            let result = try BestMoveSearch.compute(rule: rule, candidates: candidates, strategy: strategy)
            let elapsed = Date().timeIntervalSince(started)
            print("[timing] \(rule.length) 桁 \(result.isApproximate ? "近似" : "全探索"): 候補 \(candidates.count) 件 × 手 \(result.evaluatedGuessCount) 件（評価に使った候補 \(result.evaluatedCandidateCount) 件）: \(String(format: "%.2f", elapsed)) 秒")
        }
    }
}
