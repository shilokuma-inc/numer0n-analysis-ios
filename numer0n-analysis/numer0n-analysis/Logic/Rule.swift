//
//  Rule.swift
//  numer0n-analysis
//

/// 対応する桁数。3〜5 桁以外は作れない。
enum DigitCount: Int, CaseIterable, Hashable, Sendable {
    case three = 3
    case four = 4
    case five = 5
}

/// ゲームのルール（桁数を切り替え・数字の重複なし・0〜9）。
struct Rule: Hashable, Sendable {
    /// 使える数字。
    static let allowedDigits = 0...9

    let digitCount: DigitCount

    var length: Int { digitCount.rawValue }

    /// ルールで許される数字の個数（10 × 9 × 8 …）。
    var numberCount: Int {
        (0..<length).reduce(1) { result, index in
            result * (Rule.allowedDigits.count - index)
        }
    }

    /// ルールで許されるすべての数字を、昇順（"012" が先頭）で返す。
    func allNumbers() -> [Numer0nNumber] {
        var result: [Numer0nNumber] = []
        result.reserveCapacity(numberCount)
        var digits: [Int] = []
        digits.reserveCapacity(length)
        var used = Set<Int>()

        func fill() {
            if digits.count == length {
                result.append(Numer0nNumber(uncheckedDigits: digits))
                return
            }
            for digit in Rule.allowedDigits where !used.contains(digit) {
                digits.append(digit)
                used.insert(digit)
                fill()
                used.remove(digit)
                digits.removeLast()
            }
        }

        fill()
        return result
    }
}
