//
//  Numer0nNumber.swift
//  numer0n-analysis
//

/// 数字を作れなかった理由。
enum Numer0nNumberError: Error, Equatable, Sendable {
    /// 桁数がルールと違う。
    case wrongLength(expected: Int, actual: Int)
    /// 同じ数字が 2 回以上使われている。
    case duplicateDigit(Int)
    /// 0〜9 の範囲外の数字。
    case digitOutOfRange(Int)
    /// 半角数字以外の文字。
    case invalidCharacter(Character)
}

/// コールや相手の数字を表す、重複のない数字の並び。先頭の 0 も許す。
struct Numer0nNumber: Hashable, Comparable, Sendable, CustomStringConvertible {
    /// 各桁の数字（左から順）。
    let digits: [Int]

    /// 検証済みの桁から作る。ルールの列挙など、正しいと分かっている場合だけ使う。
    init(uncheckedDigits digits: [Int]) {
        self.digits = digits
    }

    /// 各桁の数字から作る。ルールに合わない場合は失敗する。
    init(digits: [Int], rule: Rule) throws {
        guard digits.count == rule.length else {
            throw Numer0nNumberError.wrongLength(expected: rule.length, actual: digits.count)
        }
        var seen = Set<Int>()
        for digit in digits {
            guard Rule.allowedDigits.contains(digit) else {
                throw Numer0nNumberError.digitOutOfRange(digit)
            }
            guard seen.insert(digit).inserted else {
                throw Numer0nNumberError.duplicateDigit(digit)
            }
        }
        self.digits = digits
    }

    /// "012" のような文字列から作る。半角数字だけを受け付ける。
    init(_ text: String, rule: Rule) throws {
        var digits: [Int] = []
        for character in text {
            guard let ascii = character.asciiValue, (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(ascii) else {
                throw Numer0nNumberError.invalidCharacter(character)
            }
            digits.append(Int(ascii - UInt8(ascii: "0")))
        }
        try self.init(digits: digits, rule: rule)
    }

    var length: Int { digits.count }

    /// 先頭の 0 を含めた表示（例: "012"）。
    var description: String {
        digits.map(String.init).joined()
    }

    static func < (lhs: Numer0nNumber, rhs: Numer0nNumber) -> Bool {
        lhs.digits.lexicographicallyPrecedes(rhs.digits)
    }
}
