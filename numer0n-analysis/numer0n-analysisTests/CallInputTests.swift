//
//  CallInputTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class CallInputTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)

    func testEmptyTextIsNotValidatedYet() {
        XCTAssertNil(CallInput().validate(rule: three))
    }

    func testValidInputBecomesHistoryEntry() throws {
        let input = CallInput(text: "012", eat: 1, bite: 1)
        XCTAssertEqual(input.validate(rule: three), .success(.call(guess: try Numer0nNumber("012", rule: three), result: EatBite(eat: 1, bite: 1))))
    }

    func testRejectsInvalidNumbers() {
        XCTAssertEqual(CallInput(text: "0123").validate(rule: three), .failure(.number(.wrongLength(expected: 3, actual: 4))))
        XCTAssertEqual(CallInput(text: "112").validate(rule: three), .failure(.number(.duplicateDigit(1))))
        XCTAssertEqual(CallInput(text: "1a2").validate(rule: three), .failure(.number(.invalidCharacter("a"))))
    }

    func testRejectsImpossibleResults() {
        XCTAssertEqual(CallInput(text: "012", eat: 2, bite: 2).validate(rule: three), .failure(.result(.exceedsLength(length: 3))))
        XCTAssertEqual(CallInput(text: "0123", eat: 3, bite: 1).validate(rule: four), .failure(.result(.impossibleCombination)))
    }

    /// 数字の問題を先に知らせる。
    func testNumberProblemComesFirst() {
        XCTAssertEqual(CallInput(text: "11", eat: 3, bite: 3).validate(rule: three), .failure(.number(.wrongLength(expected: 3, actual: 2))))
    }

    func testMessages() {
        XCTAssertEqual(CallInput.Problem.number(.wrongLength(expected: 4, actual: 2)).message(for: four), "4 桁の数字を入力してください。")
        XCTAssertEqual(CallInput.Problem.number(.duplicateDigit(7)).message(for: three), "同じ数字（7）は 2 回使えません。")
        XCTAssertEqual(CallInput.Problem.number(.invalidCharacter("x")).message(for: three), "数字（0〜9）だけを入力してください。")
        XCTAssertEqual(CallInput.Problem.result(.exceedsLength(length: 3)).message(for: three), "EAT と BITE の合計は 3 以下です。")
        XCTAssertEqual(CallInput.Problem.result(.impossibleCombination).message(for: four), "3EAT 1BITE はあり得ません。")
    }

    func testClear() {
        var input = CallInput(text: "012", eat: 1, bite: 2)
        input.clear()
        XCTAssertEqual(input, CallInput())
    }

    /// 入力した組を推理に足すと候補が絞り込まれる（画面の「履歴に追加」と同じ流れ）。
    func testAddingValidatedInputNarrowsDeduction() throws {
        let deduction = Deduction(rule: three)
        guard case let .success(entry) = CallInput(text: "012", eat: 0, bite: 0).validate(rule: three) else {
            return XCTFail("受け付けられるはず")
        }
        deduction.add(entry)
        XCTAssertEqual(deduction.candidateCount, 210)
        XCTAssertEqual(deduction.history, [entry])
    }
}
