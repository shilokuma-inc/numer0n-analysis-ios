//
//  History.swift
//  numer0n-analysis
//

/// 回答として受け付けられなかった理由。
enum EatBiteError: Error, Equatable, Sendable {
    /// EAT または BITE が負の数。
    case negative
    /// EAT + BITE が桁数を超えている。
    case exceedsLength(length: Int)
    /// EAT = 桁数 - 1 かつ BITE = 1 のように、重複なしのルールでは起こらない組。
    case impossibleCombination
}

extension EatBite {
    /// 入力された回答から作る。ルールの上で起こり得ない組は失敗する。
    init(eat: Int, bite: Int, rule: Rule) throws {
        guard eat >= 0, bite >= 0 else {
            throw EatBiteError.negative
        }
        guard eat + bite <= rule.length else {
            throw EatBiteError.exceedsLength(length: rule.length)
        }
        // 1 桁だけ位置が違えば、その数字は他のどの桁とも一致しない。
        guard !(eat == rule.length - 1 && bite == 1) else {
            throw EatBiteError.impossibleCombination
        }
        self.init(eat: eat, bite: bite)
    }

    /// 当たり（EAT = 桁数）かどうか。
    func isCorrect(for rule: Rule) -> Bool {
        eat == rule.length
    }
}

/// 推理の履歴の 1 件。
/// 今はコールと回答だけを扱う。アイテム（HIGH&LOW・SLASH など）の結果はケースを足して表す。
enum HistoryEntry: Hashable, Sendable {
    /// コールと、それに対する回答。
    case call(guess: Numer0nNumber, result: EatBite)

    /// 候補 `candidate` がこの 1 件と矛盾しないか。
    func isConsistent(with candidate: Numer0nNumber) -> Bool {
        switch self {
        case let .call(guess, result):
            return judge(guess: guess, answer: candidate) == result
        }
    }
}
