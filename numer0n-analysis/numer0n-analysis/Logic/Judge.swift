//
//  Judge.swift
//  numer0n-analysis
//

/// コールに対する回答（EAT と BITE の数）。
struct EatBite: Hashable, Sendable, CustomStringConvertible {
    /// 位置も数字も一致した数。
    let eat: Int
    /// 数字は一致したが位置が違う数。
    let bite: Int

    /// 表示用（例: "1EAT 2BITE"）。
    var description: String {
        "\(eat)EAT \(bite)BITE"
    }
}

/// コール `guess` を答え `answer` に対して判定する。
/// 数字の重複が無い前提なので、BITE は「共通する数字の数 - EAT」で一意に決まる。
func judge(guess: Numer0nNumber, answer: Numer0nNumber) -> EatBite {
    precondition(guess.length == answer.length, "桁数の違う数字は判定できない")
    var eat = 0
    var answerMask = 0
    for (guessDigit, answerDigit) in zip(guess.digits, answer.digits) {
        if guessDigit == answerDigit {
            eat += 1
        }
        answerMask |= 1 << answerDigit
    }
    var common = 0
    for digit in guess.digits where answerMask & (1 << digit) != 0 {
        common += 1
    }
    return EatBite(eat: eat, bite: common - eat)
}
