//
//  JudgeTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class JudgeTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)
    private let five = Rule(digitCount: .five)

    private func judge(_ guess: String, _ answer: String, rule: Rule) throws -> EatBite {
        numer0n_analysis.judge(
            guess: try Numer0nNumber(guess, rule: rule),
            answer: try Numer0nNumber(answer, rule: rule)
        )
    }

    func testThreeDigitExamples() throws {
        XCTAssertEqual(try judge("123", "765", rule: three), EatBite(eat: 0, bite: 0))
        XCTAssertEqual(try judge("756", "765", rule: three), EatBite(eat: 1, bite: 2))
        XCTAssertEqual(try judge("567", "765", rule: three), EatBite(eat: 1, bite: 2))
        XCTAssertEqual(try judge("576", "765", rule: three), EatBite(eat: 0, bite: 3))
        XCTAssertEqual(try judge("745", "765", rule: three), EatBite(eat: 2, bite: 0))
        XCTAssertEqual(try judge("657", "765", rule: three), EatBite(eat: 0, bite: 3))
        XCTAssertEqual(try judge("106", "765", rule: three), EatBite(eat: 0, bite: 1))
        XCTAssertEqual(try judge("765", "765", rule: three), EatBite(eat: 3, bite: 0))
    }

    func testLeadingZero() throws {
        XCTAssertEqual(try judge("012", "210", rule: three), EatBite(eat: 1, bite: 2))
        XCTAssertEqual(try judge("012", "345", rule: three), EatBite(eat: 0, bite: 0))
        XCTAssertEqual(try judge("019", "091", rule: three), EatBite(eat: 1, bite: 2))
    }

    func testFourAndFiveDigitExamples() throws {
        XCTAssertEqual(try judge("1234", "4321", rule: four), EatBite(eat: 0, bite: 4))
        XCTAssertEqual(try judge("1234", "1243", rule: four), EatBite(eat: 2, bite: 2))
        XCTAssertEqual(try judge("1234", "5678", rule: four), EatBite(eat: 0, bite: 0))
        XCTAssertEqual(try judge("0123", "0189", rule: four), EatBite(eat: 2, bite: 0))
        XCTAssertEqual(try judge("01234", "43210", rule: five), EatBite(eat: 1, bite: 4))
        XCTAssertEqual(try judge("01234", "56789", rule: five), EatBite(eat: 0, bite: 0))
        XCTAssertEqual(try judge("98765", "98756", rule: five), EatBite(eat: 3, bite: 2))
    }

    func testFullMatchIsAllEat() {
        for digitCount in DigitCount.allCases {
            let rule = Rule(digitCount: digitCount)
            for number in rule.allNumbers() {
                XCTAssertEqual(numer0n_analysis.judge(guess: number, answer: number), EatBite(eat: rule.length, bite: 0))
            }
        }
    }

    /// 3 桁はすべての組（720 × 720）で、対称性と EAT + BITE ≦ 桁数を確かめる。
    func testThreeDigitSymmetryAndBoundsForAllPairs() {
        let numbers = three.allNumbers()
        for guess in numbers {
            for answer in numbers {
                let result = numer0n_analysis.judge(guess: guess, answer: answer)
                XCTAssertEqual(result, numer0n_analysis.judge(guess: answer, answer: guess))
                XCTAssertGreaterThanOrEqual(result.bite, 0)
                XCTAssertLessThanOrEqual(result.eat + result.bite, 3)
                if guess != answer {
                    XCTAssertLessThan(result.eat, 3)
                }
            }
        }
    }

    /// 4・5 桁は一定の間隔で抜き出した組で対称性を確かめる。
    func testFourAndFiveDigitSymmetrySampled() {
        for rule in [four, five] {
            let numbers = rule.allNumbers()
            let step = numbers.count / 97
            for i in stride(from: 0, to: numbers.count, by: step) {
                for j in stride(from: 1, to: numbers.count, by: step) {
                    let a = numbers[i], b = numbers[j]
                    let result = numer0n_analysis.judge(guess: a, answer: b)
                    XCTAssertEqual(result, numer0n_analysis.judge(guess: b, answer: a))
                    XCTAssertLessThanOrEqual(result.eat + result.bite, rule.length)
                }
            }
        }
    }

    func testDescription() {
        XCTAssertEqual(EatBite(eat: 1, bite: 2).description, "1EAT 2BITE")
    }
}
