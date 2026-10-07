//
//  RuleTests.swift
//  numer0n-analysisTests
//

import XCTest
@testable import numer0n_analysis

final class RuleTests: XCTestCase {

    func testDigitCountAcceptsOnlyThreeToFive() {
        XCTAssertEqual(DigitCount.allCases.map(\.rawValue), [3, 4, 5])
        XCTAssertNil(DigitCount(rawValue: 2))
        XCTAssertNil(DigitCount(rawValue: 6))
    }

    func testNumberCount() {
        XCTAssertEqual(Rule(digitCount: .three).numberCount, 720)
        XCTAssertEqual(Rule(digitCount: .four).numberCount, 5_040)
        XCTAssertEqual(Rule(digitCount: .five).numberCount, 30_240)
    }

    func testAllNumbersCount() {
        XCTAssertEqual(Rule(digitCount: .three).allNumbers().count, 720)
        XCTAssertEqual(Rule(digitCount: .four).allNumbers().count, 5_040)
        XCTAssertEqual(Rule(digitCount: .five).allNumbers().count, 30_240)
    }

    func testAllNumbersAreUniqueValidAndSorted() throws {
        for digitCount in DigitCount.allCases {
            let rule = Rule(digitCount: digitCount)
            let numbers = rule.allNumbers()
            XCTAssertEqual(Set(numbers).count, numbers.count, "重複した数字がある")
            XCTAssertEqual(numbers, numbers.sorted())
            for number in numbers {
                XCTAssertEqual(try Numer0nNumber(digits: number.digits, rule: rule), number)
            }
        }
    }

    func testAllNumbersFirstAndLast() {
        let three = Rule(digitCount: .three).allNumbers()
        XCTAssertEqual(three.first?.description, "012")
        XCTAssertEqual(three.last?.description, "987")
        let five = Rule(digitCount: .five).allNumbers()
        XCTAssertEqual(five.first?.description, "01234")
        XCTAssertEqual(five.last?.description, "98765")
    }
}

final class Numer0nNumberTests: XCTestCase {
    private let three = Rule(digitCount: .three)
    private let four = Rule(digitCount: .four)

    func testParseKeepsLeadingZero() throws {
        let number = try Numer0nNumber("012", rule: three)
        XCTAssertEqual(number.digits, [0, 1, 2])
        XCTAssertEqual(number.description, "012")
        XCTAssertEqual(number.length, 3)
    }

    func testParseFourDigits() throws {
        XCTAssertEqual(try Numer0nNumber("9081", rule: four).digits, [9, 0, 8, 1])
    }

    func testParseRejectsWrongLength() {
        XCTAssertThrowsError(try Numer0nNumber("0123", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .wrongLength(expected: 3, actual: 4))
        }
        XCTAssertThrowsError(try Numer0nNumber("12", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .wrongLength(expected: 3, actual: 2))
        }
        XCTAssertThrowsError(try Numer0nNumber("", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .wrongLength(expected: 3, actual: 0))
        }
    }

    func testParseRejectsDuplicateDigit() {
        XCTAssertThrowsError(try Numer0nNumber("112", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .duplicateDigit(1))
        }
    }

    func testParseRejectsNonDigit() {
        XCTAssertThrowsError(try Numer0nNumber("1a2", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .invalidCharacter("a"))
        }
        XCTAssertThrowsError(try Numer0nNumber("12 ", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .invalidCharacter(" "))
        }
        XCTAssertThrowsError(try Numer0nNumber("-12", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .invalidCharacter("-"))
        }
        // 全角数字は受け付けない
        XCTAssertThrowsError(try Numer0nNumber("１２３", rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .invalidCharacter("１"))
        }
    }

    func testDigitsInitRejectsOutOfRange() {
        XCTAssertThrowsError(try Numer0nNumber(digits: [1, 2, 10], rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .digitOutOfRange(10))
        }
        XCTAssertThrowsError(try Numer0nNumber(digits: [-1, 2, 3], rule: three)) { error in
            XCTAssertEqual(error as? Numer0nNumberError, .digitOutOfRange(-1))
        }
    }

    func testOrdering() throws {
        XCTAssertLessThan(try Numer0nNumber("012", rule: three), try Numer0nNumber("013", rule: three))
        XCTAssertLessThan(try Numer0nNumber("098", rule: three), try Numer0nNumber("102", rule: three))
    }
}
