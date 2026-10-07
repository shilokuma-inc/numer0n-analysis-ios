//
//  Deduction.swift
//  numer0n-analysis
//

import Observation

/// 片方のプレイヤーの推理（コールと回答の履歴と、そこから残る候補）。
@Observable
final class Deduction {
    let rule: Rule
    /// コールと回答の履歴（古い順）。
    private(set) var history: [HistoryEntry] = []
    /// 履歴と矛盾しない候補（昇順）。
    private(set) var candidates: [Numer0nNumber]

    init(rule: Rule) {
        self.rule = rule
        self.candidates = rule.allNumbers()
    }

    /// 候補の件数。
    var candidateCount: Int { candidates.count }

    /// 当たり（EAT = 桁数）の回答が履歴にあるか。
    var isSolved: Bool {
        history.contains { entry in
            switch entry {
            case let .call(_, result):
                return result.isCorrect(for: rule)
            }
        }
    }

    /// 履歴を 1 件足し、候補を絞り込む。桁数がルールと違う履歴は受け付けない。
    func add(_ entry: HistoryEntry) {
        switch entry {
        case let .call(guess, _):
            precondition(guess.length == rule.length, "桁数がルールと違うコール")
        }
        history.append(entry)
        candidates = candidates.narrowed(by: entry)
    }

    /// コールと回答を 1 件足す。
    func addCall(guess: Numer0nNumber, result: EatBite) {
        add(.call(guess: guess, result: result))
    }
}
