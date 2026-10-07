//
//  CandidateFilterTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class EatBiteValidationTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)

    func testAcceptsEveryResultThatJudgeCanProduce() throws {
        for digitCount in DigitCount.allCases {
            let rule = Rule(digitCount: digitCount)
            let numbers = rule.allNumbers()
            let first = numbers[0]
            let produced = Set(numbers.map { judge(guess: first, answer: $0) })
            for result in produced {
                XCTAssertNoThrow(try EatBite(eat: result.eat, bite: result.bite, rule: rule))
            }
            // 受け付ける組と judge が作り得る組が一致する
            var accepted = Set<EatBite>()
            for eat in 0...rule.length {
                for bite in 0...rule.length {
                    if let result = try? EatBite(eat: eat, bite: bite, rule: rule) {
                        accepted.insert(result)
                    }
                }
            }
            XCTAssertEqual(accepted, produced)
        }
    }

    func testRejectsExceedingLength() {
        XCTAssertThrowsError(try EatBite(eat: 2, bite: 2, rule: three)) { error in
            XCTAssertEqual(error as? EatBiteError, .exceedsLength(length: 3))
        }
        XCTAssertThrowsError(try EatBite(eat: 0, bite: 5, rule: four)) { error in
            XCTAssertEqual(error as? EatBiteError, .exceedsLength(length: 4))
        }
    }

    func testRejectsImpossibleCombination() {
        XCTAssertThrowsError(try EatBite(eat: 2, bite: 1, rule: three)) { error in
            XCTAssertEqual(error as? EatBiteError, .impossibleCombination)
        }
        XCTAssertThrowsError(try EatBite(eat: 3, bite: 1, rule: four)) { error in
            XCTAssertEqual(error as? EatBiteError, .impossibleCombination)
        }
    }

    func testRejectsNegative() {
        XCTAssertThrowsError(try EatBite(eat: -1, bite: 0, rule: three)) { error in
            XCTAssertEqual(error as? EatBiteError, .negative)
        }
        XCTAssertThrowsError(try EatBite(eat: 0, bite: -1, rule: three)) { error in
            XCTAssertEqual(error as? EatBiteError, .negative)
        }
    }

    func testIsCorrect() throws {
        XCTAssertTrue(try EatBite(eat: 3, bite: 0, rule: three).isCorrect(for: three))
        XCTAssertFalse(try EatBite(eat: 1, bite: 2, rule: three).isCorrect(for: three))
    }
}

final class CandidateFilterTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)

    private func call(_ guess: String, _ eat: Int, _ bite: Int, rule: Rule) throws -> HistoryEntry {
        .call(guess: try Numer0nNumber(guess, rule: rule), result: try EatBite(eat: eat, bite: bite, rule: rule))
    }

    func testEmptyHistoryKeepsAllNumbers() {
        XCTAssertEqual(three.candidates(matching: []), three.allNumbers())
    }

    func testEveryCandidateMatchesHistory() throws {
        let history = [try call("123", 0, 1, rule: three), try call("456", 1, 0, rule: three)]
        let candidates = three.candidates(matching: history)
        XCTAssertFalse(candidates.isEmpty)
        for candidate in candidates {
            XCTAssertEqual(judge(guess: try Numer0nNumber("123", rule: three), answer: candidate), EatBite(eat: 0, bite: 1))
            XCTAssertEqual(judge(guess: try Numer0nNumber("456", rule: three), answer: candidate), EatBite(eat: 1, bite: 0))
        }
        // 外したものは矛盾している
        let removed = Set(three.allNumbers()).subtracting(candidates)
        for number in removed {
            XCTAssertFalse(history.allSatisfy { $0.isConsistent(with: number) })
        }
    }

    func testNarrowsToSecretByPlayingAGame() throws {
        let secret = try Numer0nNumber("765", rule: three)
        var history: [HistoryEntry] = []
        var counts: [Int] = []
        for guessText in ["012", "345", "678", "756"] {
            let guess = try Numer0nNumber(guessText, rule: three)
            history.append(.call(guess: guess, result: judge(guess: guess, answer: secret)))
            let candidates = three.candidates(matching: history)
            XCTAssertTrue(candidates.contains(secret))
            counts.append(candidates.count)
        }
        XCTAssertEqual(counts, counts.sorted(by: >), "候補は増えない")
        // 1EAT 2BITE の 756 に合うのは 765・567・657 のうち履歴と矛盾しないもの
        XCTAssertEqual(Set(three.candidates(matching: history).map(\.description)).isSubset(of: ["765", "567", "657"]), true)
    }

    func testKnownCounts() throws {
        // 1 回目のコールに対する回答ごとの残り候補数（3 桁）
        XCTAssertEqual(three.candidates(matching: [try call("012", 0, 0, rule: three)]).count, 210)  // 7 × 6 × 5
        XCTAssertEqual(three.candidates(matching: [try call("012", 3, 0, rule: three)]).count, 1)
        XCTAssertEqual(three.candidates(matching: [try call("012", 0, 3, rule: three)]).count, 2)
        XCTAssertEqual(three.candidates(matching: [try call("012", 2, 0, rule: three)]).count, 21)  // 3 通り × 残り 7 数字
        // 4 桁
        XCTAssertEqual(four.candidates(matching: [try call("0123", 0, 0, rule: four)]).count, 360)  // 6 × 5 × 4 × 3
        XCTAssertEqual(four.candidates(matching: [try call("0123", 0, 4, rule: four)]).count, 9)  // 完全順列
    }

    func testContradictoryHistoryGivesNoCandidates() throws {
        let history = [try call("123", 3, 0, rule: three), try call("456", 1, 0, rule: three)]
        XCTAssertEqual(three.candidates(matching: history), [])
    }

    func testIncrementalNarrowingMatchesBatch() throws {
        let history = [try call("0123", 1, 1, rule: four), try call("4567", 0, 2, rule: four), try call("1840", 1, 0, rule: four)]
        var candidates = four.allNumbers()
        for entry in history {
            candidates = candidates.narrowed(by: entry)
        }
        XCTAssertEqual(candidates, four.candidates(matching: history))
        XCTAssertEqual(candidates, candidates.sorted())
    }
}
