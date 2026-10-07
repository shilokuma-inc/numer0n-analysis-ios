//
//  GameStateTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class DeductionTests: XCTestCase {
    private let three = Rule(digitCount: .three)

    func testStartsWithAllNumbers() {
        let deduction = Deduction(rule: three)
        XCTAssertEqual(deduction.history, [])
        XCTAssertEqual(deduction.candidateCount, 720)
        XCTAssertFalse(deduction.isSolved)
    }

    func testAddingCallsNarrowsCandidates() throws {
        let deduction = Deduction(rule: three)
        let secret = try Numer0nNumber("765", rule: three)
        var history: [HistoryEntry] = []
        for text in ["012", "345", "678"] {
            let guess = try Numer0nNumber(text, rule: three)
            let result = judge(guess: guess, answer: secret)
            deduction.addCall(guess: guess, result: result)
            history.append(.call(guess: guess, result: result))
            XCTAssertEqual(deduction.history, history)
            XCTAssertEqual(deduction.candidates, three.candidates(matching: history))
            XCTAssertTrue(deduction.candidates.contains(secret))
        }
        XCTAssertFalse(deduction.isSolved)
        deduction.addCall(guess: secret, result: judge(guess: secret, answer: secret))
        XCTAssertTrue(deduction.isSolved)
        XCTAssertEqual(deduction.candidates, [secret])
    }

    func testContradictionLeavesNoCandidates() throws {
        let deduction = Deduction(rule: three)
        deduction.addCall(guess: try Numer0nNumber("123", rule: three), result: try EatBite(eat: 3, bite: 0, rule: three))
        deduction.addCall(guess: try Numer0nNumber("456", rule: three), result: try EatBite(eat: 1, bite: 0, rule: three))
        XCTAssertEqual(deduction.candidateCount, 0)
        XCTAssertEqual(deduction.history.count, 2)
    }
}

final class GameStateTests: XCTestCase {
    func testDefaultsToThreeDigits() {
        let game = GameState()
        XCTAssertEqual(game.digitCount, .three)
        XCTAssertEqual(game.myDeduction.candidateCount, 720)
        XCTAssertEqual(game.opponentDeduction.candidateCount, 720)
    }

    func testStartsWithChosenDigitCount() {
        let game = GameState(digitCount: .four)
        XCTAssertEqual(game.rule, Rule(digitCount: .four))
        XCTAssertEqual(game.myDeduction.rule, game.rule)
        XCTAssertEqual(game.opponentDeduction.rule, game.rule)
        XCTAssertEqual(game.myDeduction.candidateCount, 5_040)
    }

    /// 自分の推理と相手の推理は別々に絞り込まれる。
    func testDeductionsAreIndependent() throws {
        let game = GameState()
        let rule = game.rule
        game.myDeduction.addCall(guess: try Numer0nNumber("012", rule: rule), result: try EatBite(eat: 0, bite: 0, rule: rule))
        XCTAssertEqual(game.myDeduction.candidateCount, 210)
        XCTAssertEqual(game.opponentDeduction.candidateCount, 720)

        game.opponentDeduction.addCall(guess: try Numer0nNumber("987", rule: rule), result: try EatBite(eat: 0, bite: 3, rule: rule))
        XCTAssertEqual(game.opponentDeduction.candidateCount, 2)
        XCTAssertEqual(game.myDeduction.candidateCount, 210)
    }

    func testRestartClearsBothDeductions() throws {
        let game = GameState()
        let rule = game.rule
        game.myDeduction.addCall(guess: try Numer0nNumber("012", rule: rule), result: try EatBite(eat: 1, bite: 0, rule: rule))
        game.opponentDeduction.addCall(guess: try Numer0nNumber("345", rule: rule), result: try EatBite(eat: 0, bite: 1, rule: rule))

        game.restart()
        XCTAssertEqual(game.digitCount, .three)
        XCTAssertEqual(game.myDeduction.history, [])
        XCTAssertEqual(game.opponentDeduction.history, [])
        XCTAssertEqual(game.myDeduction.candidateCount, 720)

        game.restart(digitCount: .five)
        XCTAssertEqual(game.digitCount, .five)
        XCTAssertEqual(game.myDeduction.candidateCount, 30_240)
        XCTAssertEqual(game.opponentDeduction.candidateCount, 30_240)
    }

    /// `@Observable` の変更通知が飛ぶこと。
    func testRestartIsObservable() {
        let game = GameState()
        let changed = expectation(description: "digitCount の変更が通知される")
        withObservationTracking {
            _ = game.rule
        } onChange: {
            changed.fulfill()
        }
        game.restart(digitCount: .four)
        wait(for: [changed], timeout: 1)
    }

    func testAddingCallIsObservable() throws {
        let game = GameState()
        let deduction = game.myDeduction
        let changed = expectation(description: "候補の変更が通知される")
        withObservationTracking {
            _ = deduction.candidates
        } onChange: {
            changed.fulfill()
        }
        deduction.addCall(guess: try Numer0nNumber("012", rule: game.rule), result: try EatBite(eat: 0, bite: 0, rule: game.rule))
        wait(for: [changed], timeout: 1)
    }
}

final class ContradictionAndUndoTests: XCTestCase {
    private let three = Rule(digitCount: .three)

    private func call(_ guess: String, _ eat: Int, _ bite: Int) throws -> HistoryEntry {
        .call(guess: try Numer0nNumber(guess, rule: three), result: try EatBite(eat: eat, bite: bite, rule: three))
    }

    func testFirstContradictionIndex() throws {
        XCTAssertNil(three.firstContradictionIndex(in: []))
        XCTAssertNil(three.firstContradictionIndex(in: [try call("012", 0, 0), try call("345", 1, 0)]))
        // 2 件目で矛盾する（123 が当たりなのに 456 に EAT がある）。3 件目以降は見ない
        let history = [try call("123", 3, 0), try call("456", 1, 0), try call("789", 0, 0)]
        XCTAssertEqual(three.firstContradictionIndex(in: history), 1)
        // 1 件だけで矛盾することは無い（受け付ける回答はどれも候補が残る）
        XCTAssertNil(three.firstContradictionIndex(in: [try call("012", 1, 2)]))
    }

    func testDeductionRecordsContradiction() throws {
        let deduction = Deduction(rule: three)
        deduction.add(try call("012", 0, 3))
        XCTAssertNil(deduction.contradictionIndex)
        deduction.add(try call("345", 1, 0))
        XCTAssertEqual(deduction.candidateCount, 0)
        XCTAssertEqual(deduction.contradictionIndex, 1)
        // 0 件のまま足しても、最初の矛盾の位置は変わらない
        deduction.add(try call("678", 0, 0))
        XCTAssertEqual(deduction.contradictionIndex, 1)
    }

    func testUndoLastRestoresCandidates() throws {
        let deduction = Deduction(rule: three)
        deduction.add(try call("012", 0, 0))
        let afterFirst = deduction.candidates
        deduction.add(try call("345", 1, 1))
        XCTAssertNotEqual(deduction.candidates, afterFirst)

        deduction.undoLast()
        XCTAssertEqual(deduction.history, [try call("012", 0, 0)])
        XCTAssertEqual(deduction.candidates, afterFirst)

        deduction.undoLast()
        XCTAssertEqual(deduction.history, [])
        XCTAssertEqual(deduction.candidateCount, 720)

        // 履歴が無いときは何もしない
        deduction.undoLast()
        XCTAssertEqual(deduction.candidateCount, 720)
    }

    func testUndoClearsContradictionAndSolved() throws {
        let deduction = Deduction(rule: three)
        deduction.add(try call("012", 0, 3))
        deduction.add(try call("345", 1, 0))
        XCTAssertEqual(deduction.contradictionIndex, 1)
        deduction.undoLast()
        XCTAssertNil(deduction.contradictionIndex)
        XCTAssertEqual(deduction.candidateCount, 2)

        deduction.add(try call("120", 3, 0))
        XCTAssertTrue(deduction.isSolved)
        deduction.undoLast()
        XCTAssertFalse(deduction.isSolved)
        XCTAssertEqual(deduction.candidateCount, 2)
    }

    /// 矛盾の後にさらに足してから取り消しても、矛盾の位置は残りの履歴から求め直す。
    func testUndoKeepsEarlierContradiction() throws {
        let deduction = Deduction(rule: three)
        deduction.add(try call("123", 3, 0))
        deduction.add(try call("456", 1, 0))
        deduction.add(try call("789", 0, 0))
        deduction.undoLast()
        XCTAssertEqual(deduction.contradictionIndex, 1)
        deduction.undoLast()
        XCTAssertNil(deduction.contradictionIndex)
        XCTAssertEqual(deduction.candidateCount, 1)
    }
}
